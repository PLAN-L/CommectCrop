<# :
@echo off
setlocal
chcp 65001 > nul
title CommentCrop
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Expression ([System.IO.File]::ReadAllText('%~f0', [System.Text.Encoding]::UTF8))" %*
exit /b %ERRORLEVEL%
: #>
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

$ScriptDir = (Get-Location).Path

# 1. Language Setup / 언어 선택 (Order: English [1], 한국어 [2], 中文 [3], 日本語 [4])
$langFile = Join-Path $ScriptDir ".lang"
$currentLang = "en"

if (Test-Path $langFile) {
    $savedLang = (Get-Content $langFile -Raw -ErrorAction SilentlyContinue).Trim().ToLower()
    if (@("en", "ko", "zh", "ja") -contains $savedLang) {
        $currentLang = $savedLang
    }
} else {
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host "    CommentCrop - Language Setup / 언어 선택" -ForegroundColor Cyan
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host "  [1] English    (Default - Press Enter)" -ForegroundColor White
    Write-Host "  [2] 한국어     (Korean)" -ForegroundColor White
    Write-Host "  [3] 中文       (Chinese)" -ForegroundColor White
    Write-Host "  [4] 日本語     (Japanese)" -ForegroundColor White
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host "Select language [1/2/3/4] (Default: 1): " -NoNewline
    $inputLang = [Console]::ReadLine().Trim()

    if ($inputLang -eq "2" -or $inputLang -eq "ko") {
        $currentLang = "ko"
    } elseif ($inputLang -eq "3" -or $inputLang -eq "zh") {
        $currentLang = "zh"
    } elseif ($inputLang -eq "4" -or $inputLang -eq "ja") {
        $currentLang = "ja"
    } else {
        $currentLang = "en"
    }
    [System.IO.File]::WriteAllText($langFile, $currentLang, [System.Text.Encoding]::UTF8)
    Write-Host ""
}

# 2. Localized build status notice
if ($currentLang -eq "ko") {
    Write-Host "[시스템] 한국어 환경으로 도구를 구성합니다..." -ForegroundColor Green
} elseif ($currentLang -eq "zh") {
    Write-Host "[系统] 正在配置中文环境工具..." -ForegroundColor Green
} elseif ($currentLang -eq "ja") {
    Write-Host "[システム] 日本語環境でツールを設定しています..." -ForegroundColor Green
} else {
    Write-Host "[System] Configuring CommentCrop in English..." -ForegroundColor Green
}

# 3. Ensure essential directories exist
$screenshotsDir = Join-Path $ScriptDir "screenshots"
$extractedDir = Join-Path $ScriptDir "extracted_images"
if (-not (Test-Path $screenshotsDir)) { New-Item -ItemType Directory -Path $screenshotsDir -Force | Out-Null }
if (-not (Test-Path $extractedDir)) { New-Item -ItemType Directory -Path $extractedDir -Force | Out-Null }

# 4. Automatically generate extractor.py and requirements.txt tailored to $currentLang
$extractorPath = Join-Path $ScriptDir "extractor.py"
$requirementsPath = Join-Path $ScriptDir "requirements.txt"

$requirementsContent = @"
opencv-python
numpy
Pillow
"@
[System.IO.File]::WriteAllText($requirementsPath, $requirementsContent, [System.Text.Encoding]::UTF8)

$pythonSourceCode = @'
from pathlib import Path
import argparse
import sys
import time
import cv2
import numpy as np

# ==============================================================================
# Internationalization / 다국어 지원 (en, ko, zh, ja)
# ==============================================================================
LANGUAGES = ["en", "ko", "zh", "ja"]
DEFAULT_LANG = "en"
CURRENT_LANG = "en"

MESSAGES = {
    "en": {
        "title": "CommentCrop - Social Media Meme & Image Cropper",
        "manual_mode": "Manual Crop Mode",
        "auto_mode": "Auto Detect Mode",
        "batch_mode": "Auto Batch Save (No Window)",
        "menu_prompt": "Select mode [1/2/3] (Press Enter for [3] - Auto Batch Crop): ",
        "menu_1": "  [1] Manual Crop Mode (Drag to crop directly)",
        "menu_2": "  [2] Auto Detect Mode (AI auto-detection + manual adjustment)",
        "menu_3": "  [3] Auto Batch Save without Window (Instant Headless Crop) [Default]",
        "running": "CommentCrop Running [{mode}]",
        "target_count": "Target files: {count} | Output folder: {out_dir}",
        "user_quit": "User stopped the task.",
        "not_found": "Path not found: {path}",
        "no_images": "No supported images found in folder: {path}",
        "win_title": "{prefix}CommentCrop | Drag: Crop | Click/C: Toggle | Enter: Save | Esc: Skip | Q: Quit",
        "badge_saved": "Saved",
        "badge_excluded": "Excluded",
        "badge_manual_saved": "Manual-Saved",
        "badge_manual_excluded": "Manual-Excluded",
        "header_info_l1": "To Save: {selected} (Total {count}) | Auto: {auto_len} | Manual: {manual_len}",
        "header_info_l2": "[Click/C/1-9]: Toggle | Drag: Crop | S: Snap | Enter: Save | Esc: Skip | Q: Quit",
        "drawing": "Drawing: {w}x{h}",
        "manual_added_snap": "Manual box added & auto-snapped: #{idx} (drag: {orig} -> snap: {snapped})",
        "manual_added": "Manual box added: #{idx} (x={x}, y={y}, w={w}, h={h})",
        "deselected_click": "[Deselected (Click)] #{idx} excluded (will NOT be saved).",
        "selected_click": "[Selected (Click)] #{idx} included (will be saved).",
        "deselected_key": "[Deselected (Key)] #{idx} excluded.",
        "selected_key": "[Selected (Key)] #{idx} included.",
        "manual_deleted": "[Deleted] Manual crop #{idx} removed.",
        "all_cleared": "[Reset] All manual crop boxes removed.",
        "saved_success": "[Saved #{idx}] {path} ({w}x{h})",
        "saved_summary": "-> {stem}: Saved {count} image(s) to {out_dir}",
        "skipped": "Skipped {name} (No images saved)",
        "smart_snap_applied": "[Smart Snap] Box #{idx} snapped to true border: {before} -> {after}",
        "toggle_all_select": "[Select All] All candidates marked to save.",
        "toggle_all_deselect": "[Deselect All] All candidates excluded.",
        "controls_guide": "Controls: [Click / C / 1-9] Toggle | [Drag] Manual Crop | [Enter] Save & Next | [S] Smart Snap | [Esc] Skip",
        "target_file_banner": ">>> Target File: {name} ({w}x{h})",
        "cannot_read_image": "Cannot read image: {path}",
        "auto_detected_candidates": "  Auto-detected candidates: {count} ({ms:.1f} ms)",
        "auto_detected_preview": "  Auto-detected candidates: {count} ({ms:.1f} ms) | Preview: {preview}",
        "auto_saved_item": "  Auto saved: {name}",
        "skip_current_image": "Skipping current image (not saving).",
        "quitting_task": "Exiting task.",
        "manual_box_deleted_full": "Manual box (#{idx}) has been completely deleted.",
        "reselected_key": "[Reselected (Key)] Box #{idx} has been reselected (to be saved).",
        "last_manual_deleted": "Last manual box (#{idx}) deleted.",
        "no_box_selected": "No area selected.",
        "deselected_num_key": "[Deselected (Key {key})] Area #{idx} excluded (will NOT be saved).",
        "selected_num_key": "[Selected (Key {key})] Area #{idx} selected (to be saved).",
        "all_manual_cleared": "All manual boxes cleared.",
        "all_candidates_deselected": "All candidates deselected.",
        "all_candidates_selected": "All candidates ({count}) selected.",
        "manual_edge_snapped": "Manual box border precision snap: {orig} -> {snapped}",
        "tag_manual": "Manual Crop #{idx}",
        "tag_auto": "Auto Detect #{idx}",
        "save_item_success": "Saved successfully ({tag}): {name} ({w}x{h})",
        "save_item_fail": "Save failed: {name}",
        "cleaned_old_file": "  [Cleanup] Deleted unselected previous file: {name}",
        "summary_saved": "-> {stem}: Successfully saved total {count} selected image(s)",
        "summary_none": "-> {stem}: No images selected, nothing saved.",
        "err_path_not_found": "Path not found: {path}",
        "err_min_area": "--min-area must be between 0 and 1.",
        "err_no_images_folder": "No supported image files found in folder: {path}",
        "all_done_banner": "All tasks completed! Check output folder: {out_dir}",
        "cli_description": "Automatically detects or manually extracts image candidates from screenshots.",
        "cli_image_help": "Input screenshot file or directory (default: screenshots)",
        "cli_out_help": "Output folder (default: extracted_images)",
        "cli_min_area_help": "Minimum candidate area ratio (default: 0.008)",
        "cli_manual_help": "Skip auto-detection and open manual drag crop window directly.",
        "cli_auto_help": "Run in auto-detect mode directly without menu prompt.",
        "cli_no_ui_help": "Do not open interactive window.",
        "cli_save_all_help": "Save all detected candidates immediately without window.",
        "cli_save_preview_help": "Also save candidate preview (_candidates.jpg) and contact sheet (_contact_sheet.jpg)."
    },
    "ko": {
        "title": "CommentCrop - SNS 댓글 짤/GIF 스마트 크롭 도구",
        "manual_mode": "수동 크롭 모드",
        "auto_mode": "자동 감지 모드",
        "batch_mode": "자동 일괄 저장 (창 없음)",
        "menu_prompt": "모드를 선택하세요 [1/2/3] (Enter 누르면 [3번] 자동 자르기): ",
        "menu_1": "  [1] 수동 크롭 모드 (마우스 드래그로 직접 영역 지정)",
        "menu_2": "  [2] 자동 감지 모드 (AI 자동 감지 + 수동 보정 창)",
        "menu_3": "  [3] 창 없이 자동 크롭 및 일괄 저장 (초고속 자동 자르기) [기본값]",
        "running": "CommentCrop 실행 중 [{mode}]",
        "target_count": "대상 파일: {count}개 | 저장 폴더: {out_dir}",
        "user_quit": "사용자가 전체 작업을 중단했습니다.",
        "not_found": "경로를 찾을 수 없습니다: {path}",
        "no_images": "폴더 안에 지원하는 이미지 파일이 없습니다: {path}",
        "win_title": "{prefix}CommentCrop | 드래그: 크롭 | 클릭/C: 선택토글 | Enter: 저장 | Esc: 스킵 | Q: 종료",
        "badge_saved": "저장됨",
        "badge_excluded": "제외됨",
        "badge_manual_saved": "수동-저장됨",
        "badge_manual_excluded": "수동-제외됨",
        "header_info_l1": "저장 예정: {selected} (총 {count}개) | 자동 감지: {auto_len} | 수동: {manual_len}",
        "header_info_l2": "[클릭/C/1-9]: 선택/해제 토글 | 드래그: 크롭 | S: 스냅 | Enter: 저장 | Esc: 스킵 | Q: 종료",
        "drawing": "드래그: {w}x{h}",
        "manual_added_snap": "수동 크롭 영역 추가 및 자동 엣지 스냅: #{idx} (드래그: {orig} -> 스냅: {snapped})",
        "manual_added": "수동 크롭 영역 추가: #{idx} (x={x}, y={y}, w={w}, h={h})",
        "deselected_click": "[선택 해제 (클릭)] #{idx}번 영역이 제외되었습니다. (저장 안 됨)",
        "selected_click": "[선택됨 (클릭)] #{idx}번 영역이 선택되었습니다. (저장 예정)",
        "deselected_key": "[선택 해제 (키보드)] #{idx}번 영역이 제외되었습니다.",
        "selected_key": "[선택됨 (키보드)] #{idx}번 영역이 선택되었습니다.",
        "manual_deleted": "[삭제] 수동 크롭 영역 #{idx}번이 삭제되었습니다.",
        "all_cleared": "[초기화] 모든 수동 크롭 영역이 제거되었습니다.",
        "saved_success": "[저장 완료 #{idx}] {path} ({w}x{h})",
        "saved_summary": "-> {stem}: 총 {count}개 선택된 이미지 저장 완료 ({out_dir})",
        "skipped": "{name} 건너뜀 (저장하지 않음)",
        "smart_snap_applied": "[스마트 스냅] #{idx}번 박스가 외곽 테두리에 정밀 보정되었습니다: {before} -> {after}",
        "toggle_all_select": "[전체 선택] 모든 후보가 저장 대상으로 선택되었습니다.",
        "toggle_all_deselect": "[전체 해제] 모든 후보가 저장 대상에서 제외되었습니다.",
        "controls_guide": "조작 방법: [클릭 / C키 / 1~9] 선택 및 해제 | [드래그] 수동 크롭 | [Enter] 저장&다음 | [S] 정밀스냅 | [Esc] 건너뛰기",
        "target_file_banner": ">>> 대상 파일: {name} ({w}x{h})",
        "cannot_read_image": "이미지를 읽을 수 없습니다: {path}",
        "auto_detected_candidates": "  자동 탐지 후보: {count}개 ({ms:.1f} ms)",
        "auto_detected_preview": "  자동 탐지 후보: {count}개 ({ms:.1f} ms) | 미리보기: {preview}",
        "auto_saved_item": "  자동 저장: {name}",
        "skip_current_image": "현재 이미지를 건너뜁니다. (저장 안 함)",
        "quitting_task": "작업을 종료합니다.",
        "manual_box_deleted_full": "수동 박스(#{idx})가 완전히 삭제되었습니다.",
        "reselected_key": "[다시 선택 (C키)] #{idx}번 영역이 다시 선택되었습니다. (저장 예정)",
        "last_manual_deleted": "마지막 수동 박스(#{idx}) 삭제됨",
        "no_box_selected": "선택된 영역이 없습니다.",
        "deselected_num_key": "[선택 해제 (숫자키 {key})] #{idx}번 영역이 제외되었습니다. (저장 안 됨)",
        "selected_num_key": "[선택됨 (숫자키 {key})] #{idx}번 영역이 선택되었습니다. (저장 예정)",
        "all_manual_cleared": "모든 수동 박스 초기화됨",
        "all_candidates_deselected": "모든 후보 선택 해제됨",
        "all_candidates_selected": "모든 후보({count}개) 선택됨",
        "manual_edge_snapped": "수동 박스 테두리 정밀 스냅: {orig} -> {snapped}",
        "tag_manual": "수동 크롭 #{idx}",
        "tag_auto": "자동 감지 #{idx}",
        "save_item_success": "저장 완료 ({tag}): {name} ({w}x{h})",
        "save_item_fail": "저장 실패: {name}",
        "cleaned_old_file": "  [파일 정리] 선택 해제된 이전 파일 삭제: {name}",
        "summary_saved": "-> {stem}: 총 {count}개 선택된 이미지 저장 완료",
        "summary_none": "-> {stem}: 선택된 이미지가 없어 저장하지 않았습니다.",
        "err_path_not_found": "경로를 찾을 수 없습니다: {path}",
        "err_min_area": "--min-area는 0과 1 사이여야 합니다.",
        "err_no_images_folder": "폴더 안에 지원하는 이미지 파일이 없습니다: {path}",
        "all_done_banner": "모든 작업이 완료되었습니다! 결과 폴더를 확인하세요: {out_dir}",
        "cli_description": "스크린샷에서 이미지 후보를 자동 탐지하거나 수동 드래그로 추출합니다.",
        "cli_image_help": "입력 스크린샷 파일 또는 스크린샷 폴더 경로 (기본값: screenshots)",
        "cli_out_help": "결과 폴더 (기본값: extracted_images)",
        "cli_min_area_help": "최소 후보 면적 비율 (기본값: 0.008)",
        "cli_manual_help": "자동 탐지를 건너뛰고 바로 마우스 드래그 수동 크롭 창을 엽니다.",
        "cli_auto_help": "메뉴 없이 바로 자동 감지 모드로 실행",
        "cli_no_ui_help": "대화형 창을 열지 않음",
        "cli_save_all_help": "--no-ui 모드에서도 탐지된 모든 후보를 PNG로 즉시 저장",
        "cli_save_preview_help": "후보 미리보기(_candidates.jpg) 및 썸네일 시트(_contact_sheet.jpg) 파일도 함께 저장"
    },
    "zh": {
        "title": "CommentCrop - 社交媒体表情包与截图裁剪工具",
        "manual_mode": "手动裁剪模式",
        "auto_mode": "自动检测模式",
        "batch_mode": "自动批量保存 (无界面)",
        "menu_prompt": "请选择模式 [1/2/3] (按 Enter 默认选择 [3] - 自动批量裁剪): ",
        "menu_1": "  [1] 手动裁剪模式 (鼠标拖拽直接选择)",
        "menu_2": "  [2] 自动检测模式 (AI自动识别 + 手动微调窗口)",
        "menu_3": "  [3] 自动批量保存 (无需窗口立即自动裁剪保存) [默认]",
        "running": "正在运行 CommentCrop [{mode}]",
        "target_count": "目标文件数: {count} | 输出目录: {out_dir}",
        "user_quit": "用户中止了操作。",
        "not_found": "找不到路径: {path}",
        "no_images": "文件夹中未找到支持的图像文件: {path}",
        "win_title": "{prefix}CommentCrop | 拖拽: 裁剪 | 点击/C: 切换选择 | Enter: 保存 | Esc: 跳过 | Q: 退出",
        "badge_saved": "已保存",
        "badge_excluded": "已排除",
        "badge_manual_saved": "手动-保存",
        "badge_manual_excluded": "手动-排除",
        "header_info_l1": "待保存: {selected} (共 {count} 个) | 自动: {auto_len} | 手动: {manual_len}",
        "header_info_l2": "[点击/C/1-9]: 切换选择 | 拖拽: 裁剪 | S: 智能贴边 | Enter: 保存 | Esc: 跳过 | Q: 退出",
        "drawing": "拖拽中: {w}x{h}",
        "manual_added_snap": "已添加手动区域并自动贴边: #{idx} (拖拽: {orig} -> 贴边: {snapped})",
        "manual_added": "已添加手动区域: #{idx} (x={x}, y={y}, w={w}, h={h})",
        "deselected_click": "[已取消选择 (点击)] #{idx} 号区域已排除 (不保存)。",
        "selected_click": "[已选择 (点击)] #{idx} 号区域已选中 (待保存)。",
        "deselected_key": "[已取消选择 (按键)] #{idx} 号区域已排除。",
        "selected_key": "[已选择 (按键)] #{idx} 号区域已选中。",
        "manual_deleted": "[已删除] 已移除手动裁剪区域 #{idx}。",
        "all_cleared": "[已重置] 已清除所有手动裁剪区域。",
        "saved_success": "[保存成功 #{idx}] {path} ({w}x{h})",
        "saved_summary": "-> {stem}: 已保存 {count} 张图像至 {out_dir}",
        "skipped": "已跳过 {name} (未保存任何图像)",
        "smart_snap_applied": "[智能贴边] #{idx} 号区域已精准吸附至边缘: {before} -> {after}",
        "toggle_all_select": "[全选] 所有候选区域均已标记为保存。",
        "toggle_all_deselect": "[全不选] 所有候选区域均已排除。",
        "controls_guide": "操作说明: [点击 / C键 / 1-9] 切换选择 | [拖拽] 手动裁剪 | [Enter] 保存并继续 | [S] 智能吸附 | [Esc] 跳过",
        "target_file_banner": ">>> 目标文件: {name} ({w}x{h})",
        "cannot_read_image": "无法读取图像: {path}",
        "auto_detected_candidates": "  自动检测候选: {count} 个 ({ms:.1f} ms)",
        "auto_detected_preview": "  自动检测候选: {count} 个 ({ms:.1f} ms) | 预览图: {preview}",
        "auto_saved_item": "  自动保存: {name}",
        "skip_current_image": "跳过当前图像 (不保存)。",
        "quitting_task": "退出操作。",
        "manual_box_deleted_full": "手动选区(#{idx})已完全删除。",
        "reselected_key": "[重新选择 (按键)] #{idx} 号区域已重新选中 (待保存)。",
        "last_manual_deleted": "已删除最后一个手动选区(#{idx})。",
        "no_box_selected": "未选择任何区域。",
        "deselected_num_key": "[取消选择 (数字键 {key})] #{idx} 号区域已排除 (不保存)。",
        "selected_num_key": "[已选择 (数字键 {key})] #{idx} 号区域已选中 (待保存)。",
        "all_manual_cleared": "所有手动选区已重置。",
        "all_candidates_deselected": "所有候选区域已取消选择。",
        "all_candidates_selected": "所有候选区域({count} 个)已选中。",
        "manual_edge_snapped": "手动选区边缘精准吸附: {orig} -> {snapped}",
        "tag_manual": "手动裁剪 #{idx}",
        "tag_auto": "自动检测 #{idx}",
        "save_item_success": "保存成功 ({tag}): {name} ({w}x{h})",
        "save_item_fail": "保存失败: {name}",
        "cleaned_old_file": "  [文件清理] 已删除未选中的旧文件: {name}",
        "summary_saved": "-> {stem}: 共完成保存 {count} 张选中的图片",
        "summary_none": "-> {stem}: 未选择任何图片，未进行保存。",
        "err_path_not_found": "找不到路径: {path}",
        "err_min_area": "--min-area 必须介于 0 到 1 之间。",
        "err_no_images_folder": "文件夹中未找到支持的图像文件: {path}",
        "all_done_banner": "全部操作已完成！请查看输出文件夹: {out_dir}",
        "cli_description": "从截图中自动检测或手动框选提取图像候选。",
        "cli_image_help": "输入截图文件或文件夹路径 (默认: screenshots)",
        "cli_out_help": "输出文件夹 (默认: extracted_images)",
        "cli_min_area_help": "最小候选区域面积比例 (默认: 0.008)",
        "cli_manual_help": "跳过自动检测，直接打开手动拖拽裁剪窗口。",
        "cli_auto_help": "无需菜单直接以自动检测模式运行",
        "cli_no_ui_help": "不打开交互窗口。",
        "cli_save_all_help": "无需窗口立即将所有检测到的候选保存为 PNG",
        "cli_save_preview_help": "同时保存候选预览图(_candidates.jpg)和缩略图集(_contact_sheet.jpg)"
    },
    "ja": {
        "title": "CommentCrop - SNSコメント画像・GIF切り取りツール",
        "manual_mode": "手動トリミングモード",
        "auto_mode": "自動検出モード",
        "batch_mode": "自動一括保存 (UIなし)",
        "menu_prompt": "モードを選択してください [1/2/3] (Enterで [3] 自動一括保存): ",
        "menu_1": "  [1] 手動トリミングモード (ドラッグで範囲指定)",
        "menu_2": "  [2] 自動検出モード (AI自動検出＋手動調整ウィンドウ)",
        "menu_3": "  [3] ウィンドウなし自動切り取り・一括保存 (超高速) [デフォルト]",
        "running": "CommentCrop 実行中 [{mode}]",
        "target_count": "対象ファイル数: {count} | 保存先: {out_dir}",
        "user_quit": "ユーザーによって処理が中断されました。",
        "not_found": "パスが見つかりません: {path}",
        "no_images": "フォルダ内に対応する画像ファイルがありません: {path}",
        "win_title": "{prefix}CommentCrop | ドラッグ: 切り取り | クリック/C: 選択切替 | Enter: 保存 | Esc: スキップ | Q: 終了",
        "badge_saved": "保存",
        "badge_excluded": "除外",
        "badge_manual_saved": "手動-保存",
        "badge_manual_excluded": "手動-除外",
        "header_info_l1": "保存予定: {selected} (計 {count}個) | 自動: {auto_len} | 手動: {manual_len}",
        "header_info_l2": "[クリック/C/1-9]: 選択切替 | ドラッグ: 範囲指定 | S: スナップ | Enter: 保存 | Esc: スキップ | Q: 終了",
        "drawing": "選択中: {w}x{h}",
        "manual_added_snap": "手動エリア追加＆境界スナップ完了: #{idx} (ドラッグ: {orig} -> スナップ: {snapped})",
        "manual_added": "手動エリア追加: #{idx} (x={x}, y={y}, w={w}, h={h})",
        "deselected_click": "[選択解除 (クリック)] #{idx}番エリアを除外しました (保存されません)。",
        "selected_click": "[選択 (クリック)] #{idx}番エリアを選択しました (保存予定)。",
        "deselected_key": "[選択解除 (キー)] #{idx}番エリアを除外しました。",
        "selected_key": "[選択 (キー)] #{idx}番エリアを選択しました。",
        "manual_deleted": "[削除] 手動トリミング #{idx}番を削除しました。",
        "all_cleared": "[リセット] すべての手動エリアをクリアしました。",
        "saved_success": "[保存完了 #{idx}] {path} ({w}x{h})",
        "saved_summary": "-> {stem}: {count}枚の画像を保存しました ({out_dir})",
        "skipped": "{name} をスキップしました (保存なし)",
        "smart_snap_applied": "[スマートスナップ] #{idx}番が境界線に吸着しました: {before} -> {after}",
        "toggle_all_select": "[全選択] すべての候補を保存対象にしました。",
        "toggle_all_deselect": "[全解除] すべての候補を除外しました。",
        "controls_guide": "操作方法: [クリック / Cキー / 1~9] 選択切替 | [ドラッグ] 手動トリミング | [Enter] 保存＆次へ | [S] スナップ | [Esc] スキップ",
        "target_file_banner": ">>> 対象画像: {name} ({w}x{h})",
        "cannot_read_image": "画像を読み込めません: {path}",
        "auto_detected_candidates": "  自動検出候補: {count} 個 ({ms:.1f} ms)",
        "auto_detected_preview": "  自動検出候補: {count} 個 ({ms:.1f} ms) | プレビュー: {preview}",
        "auto_saved_item": "  自動保存: {name}",
        "skip_current_image": "現在の画像をスキップします (保存なし)。",
        "quitting_task": "処理を終了します。",
        "manual_box_deleted_full": "手動エリア(#{idx})が完全に削除されました。",
        "reselected_key": "[再選択 (キー)] #{idx}番エリアが再び選択されました (保存予定)。",
        "last_manual_deleted": "最後の手動エリア(#{idx})を削除しました。",
        "no_box_selected": "選択されたエリアがありません。",
        "deselected_num_key": "[選択解除 (数字キー {key})] #{idx}番エリアを除外しました (保存されません)。",
        "selected_num_key": "[選択 (数字キー {key})] #{idx}番エリアを選択しました (保存予定)。",
        "all_manual_cleared": "すべての手動エリアが初期化されました。",
        "all_candidates_deselected": "すべての候補の選択を解除しました。",
        "all_candidates_selected": "すべての候補({count} 個)が選択されました。",
        "manual_edge_snapped": "手動エリア境界線の精密スナップ: {orig} -> {snapped}",
        "tag_manual": "手動トリミング #{idx}",
        "tag_auto": "自動検出 #{idx}",
        "save_item_success": "保存完了 ({tag}): {name} ({w}x{h})",
        "save_item_fail": "保存失敗: {name}",
        "cleaned_old_file": "  [整理] 選択解除された以前のファイルを削除: {name}",
        "summary_saved": "-> {stem}: 合計 {count}枚の選択された画像を保存完了",
        "summary_none": "-> {stem}: 選択された画像がないため保存しませんでした。",
        "err_path_not_found": "パスが見つかりません: {path}",
        "err_min_area": "--min-area は 0 と 1 の間である必要があります。",
        "err_no_images_folder": "フォルダ内に対応する画像ファイルがありません: {path}",
        "all_done_banner": "すべての処理が完了しました！出力フォルダを確認してください: {out_dir}",
        "cli_description": "スクリーンショットから画像候補を自動検出または手動ドラッグで抽出します。",
        "cli_image_help": "入力スクリーンショットファイルまたはフォルダパス (デフォルト: screenshots)",
        "cli_out_help": "出力フォルダ (デフォルト: extracted_images)",
        "cli_min_area_help": "最小候補エリア面積比率 (デフォルト: 0.008)",
        "cli_manual_help": "自動検出をスキップし、直接手動ドラッグトリミングウィンドウを開きます。",
        "cli_auto_help": "メニューなしで直接自動検出モードで実行",
        "cli_no_ui_help": "対話型ウィンドウを開かない。",
        "cli_save_all_help": "ウィンドウなしですべての検出候補を即座にPNG保存",
        "cli_save_preview_help": "候補プレビュー(_candidates.jpg)とサムネイルシート(_contact_sheet.jpg)も保存"
    }
}


def tr(key: str, **kwargs) -> str:
    """Returns localized message string."""
    lang_dict = MESSAGES.get(CURRENT_LANG, MESSAGES[DEFAULT_LANG])
    template = lang_dict.get(key, MESSAGES[DEFAULT_LANG].get(key, key))
    if kwargs:
        try:
            return template.format(**kwargs)
        except Exception:
            return template
    return template


def put_multilingual_text(img, text, pos, font_size=15, color=(255, 255, 255)):
    """Renders multilingual text (EN/KO/ZH/JA) using PIL if available, falling back to cv2.putText."""
    try:
        from PIL import Image, ImageDraw, ImageFont
        img_pil = Image.fromarray(cv2.cvtColor(img, cv2.COLOR_BGR2RGB))
        draw = ImageDraw.Draw(img_pil)
        font = None
        font_candidates = {
            "ko": ["malgun.ttf", "gulim.ttc", "arial.ttf"],
            "zh": ["msyh.ttc", "simsun.ttc", "simhei.ttf", "arial.ttf"],
            "ja": ["meiryo.ttc", "msgothic.ttc", "yugoth.ttc", "arial.ttf"],
            "en": ["arial.ttf", "segoeui.ttf", "malgun.ttf"]
        }
        chosen_fonts = font_candidates.get(CURRENT_LANG, font_candidates["en"]) + ["arial.ttf", "malgun.ttf", "msyh.ttc", "meiryo.ttc"]
        for font_name in chosen_fonts:
            try:
                font = ImageFont.truetype(font_name, font_size)
                break
            except Exception:
                pass
        if font is None:
            font = ImageFont.load_default()
        rgb_color = (int(color[2]), int(color[1]), int(color[0]))
        draw.text(pos, text, font=font, fill=rgb_color)
        return cv2.cvtColor(np.array(img_pil), cv2.COLOR_RGB2BGR)
    except Exception:
        ascii_text = text.encode("ascii", "replace").decode("ascii")
        cv2.putText(img, ascii_text, (pos[0], pos[1] + font_size), cv2.FONT_HERSHEY_SIMPLEX, 0.45, color, 1, cv2.LINE_AA)
        return img


if hasattr(sys.stdout, "reconfigure"):
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass


def imread_safe(path: Path):
    """Safely read image file including non-ASCII/Unicode paths."""
    try:
        data = np.fromfile(str(path), dtype=np.uint8)
        if data.size == 0:
            return None
        return cv2.imdecode(data, cv2.IMREAD_COLOR)
    except Exception:
        return cv2.imread(str(path), cv2.IMREAD_COLOR)


def imwrite_safe(path: Path, image) -> bool:
    """Safely write image file including non-ASCII/Unicode paths."""
    try:
        path.parent.mkdir(parents=True, exist_ok=True)
        ext = path.suffix if path.suffix else ".png"
        ok, encoded = cv2.imencode(ext, image)
        if not ok:
            return False
        encoded.tofile(str(path))
        return True
    except Exception:
        return bool(cv2.imwrite(str(path), image))


def _compute_iou(box_a, box_b) -> float:
    ax, ay, aw, ah = box_a
    bx, by, bw, bh = box_b
    ix1, iy1 = max(ax, bx), max(ay, by)
    ix2, iy2 = min(ax + aw, bx + bw), min(ay + ah, by + bh)
    inter = max(0, ix2 - ix1) * max(0, iy2 - iy1)
    union = aw * ah + bw * bh - inter
    return inter / union if union > 0 else 0.0


def smart_snap_box(image, box, search_range=40):
    """Snaps rectangle to true Sobel gradient peaks within search_range pixels."""
    height, width = image.shape[:2]
    x, y, w, h = box
    x1, y1, x2, y2 = max(0, x), max(0, y), min(width, x + w), min(height, y + h)
    if x2 - x1 < 24 or y2 - y1 < 24:
        return (x1, y1, max(16, x2 - x1), max(16, y2 - y1))

    sobel_y = np.maximum.reduce([np.abs(cv2.Sobel(image[:, :, c], cv2.CV_32F, 0, 1, ksize=3)) for c in range(3)])
    sobel_x = np.maximum.reduce([np.abs(cv2.Sobel(image[:, :, c], cv2.CV_32F, 1, 0, ksize=3)) for c in range(3)])

    inset_x = int((x2 - x1) * 0.12)
    inset_y = int((y2 - y1) * 0.12)
    xs1, xs2 = x1 + inset_x, x2 - inset_x
    ys1, ys2 = y1 + inset_y, y2 - inset_y
    if xs2 <= xs1 or ys2 <= ys1:
        return (x1, y1, max(16, x2 - x1), max(16, y2 - y1))

    def _find_best_edge(slice_vals, current_pos, search_min):
        peak = float(np.max(slice_vals))
        mean_val = float(np.mean(slice_vals))
        if peak > 7.0 and (peak / max(mean_val, 1.0)) > 1.25:
            return search_min + int(np.argmax(slice_vals))
        return current_pos

    # 1. Top y1
    y_min = max(0, y1 - search_range)
    y_max = min(height - 1, y1 + search_range)
    if y_max > y_min + 4:
        slice_y = np.mean(sobel_y[y_min:y_max, xs1:xs2], axis=1)
        y1 = _find_best_edge(slice_y, y1, y_min)

    # 2. Bottom y2
    y_min = max(0, y2 - search_range)
    y_max = min(height - 1, y2 + search_range)
    if y_max > y_min + 4:
        slice_y = np.mean(sobel_y[y_min:y_max, xs1:xs2], axis=1)
        y2 = _find_best_edge(slice_y, y2, y_min)

    # 3. Left x1
    x_min = max(0, x1 - search_range)
    x_max = min(width - 1, x1 + search_range)
    if x_max > x_min + 4:
        slice_x = np.mean(sobel_x[ys1:ys2, x_min:x_max], axis=0)
        x1 = _find_best_edge(slice_x, x1, x_min)

    # 4. Right x2
    x_min = max(0, x2 - search_range)
    x_max = min(width - 1, x2 + search_range)
    if x_max > x_min + 4:
        slice_x = np.mean(sobel_x[ys1:ys2, x_min:x_max], axis=0)
        x2 = _find_best_edge(slice_x, x2, x_min)

    return (x1, y1, max(16, x2 - x1), max(16, y2 - y1))


def _is_ui_or_text_noise(image, box) -> bool:
    """Filters UI status bars, comment input bars, and small profile avatars."""
    height, width = image.shape[:2]
    total_area = width * height
    x, y, w, h = box
    ratio = w / max(h, 1)

    # 1. Profile avatar icon filter
    if x < width * 0.22 and w < width * 0.20 and h < width * 0.20 and 0.70 <= ratio <= 1.40 and (w * h) < total_area * 0.04:
        return True

    # 2. Status bars and bottom comment inputs
    if ratio > 4.5 or ratio < 0.20:
        return True
    if y > height * 0.82 and h < height * 0.08 and w > width * 0.60:
        return True
    if y < height * 0.08 and h < height * 0.06:
        return True

    roi = image[y:y+h, x:x+w]
    if roi.size == 0:
        return True

    # 3. Plain background with simple text line noise
    small = cv2.resize(roi, (min(w, 64), min(h, 64)), interpolation=cv2.INTER_AREA)
    pixels = small.reshape(-1, 3).astype(np.float32)
    median_color = np.median(pixels, axis=0)
    med_brightness = float(np.mean(median_color))

    if med_brightness > 230.0 or med_brightness < 25.0:
        border = np.vstack([small[0, :], small[-1, :], small[:, 0], small[:, -1]]).astype(np.float32)
        border_med = np.median(border, axis=0)
        border_interior_dist = float(np.linalg.norm(border_med - median_color))

        if border_interior_dist < 120.0:
            hsv = cv2.cvtColor(roi, cv2.COLOR_BGR2HSV)
            color_fraction = float(np.mean(hsv[..., 1] > 25))
            if color_fraction > 0.03:
                return False

            dists = np.linalg.norm(pixels - median_color, axis=1)
            uniform_fraction = float(np.mean(dists < 16.0))
            gray = cv2.cvtColor(roi, cv2.COLOR_BGR2GRAY)
            edges = cv2.Canny(gray, 40, 120)
            edge_density = float(np.mean(edges > 0))
            if uniform_fraction > 0.85 and edge_density < 0.020:
                return True

    return False


def _find_low_contrast_media_regions(image, min_pixels, max_pixels):
    """Detects low-contrast media regions using CLAHE and background color subtraction."""
    height, width = image.shape[:2]
    extra_boxes = []

    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    clahe = cv2.createCLAHE(clipLimit=3.0, tileGridSize=(8, 8))
    enhanced = clahe.apply(gray)
    enhanced_blur = cv2.GaussianBlur(enhanced, (5, 5), 0)
    low_edges = cv2.Canny(enhanced_blur, 18, 60)
    kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (5, 5))
    low_closed = cv2.morphologyEx(low_edges, cv2.MORPH_CLOSE, kernel, iterations=2)
    contours, _ = cv2.findContours(low_closed, cv2.RETR_LIST, cv2.CHAIN_APPROX_SIMPLE)
    for cnt in contours:
        x, y, w, h = cv2.boundingRect(cnt)
        if min_pixels <= w * h <= max_pixels:
            extra_boxes.append((x, y, w, h))

    y1, y2 = int(height * 0.15), int(height * 0.85)
    lx1, lx2 = int(width * 0.03), max(int(width * 0.03) + 1, int(width * 0.08))
    rx1, rx2 = int(width * 0.92), max(int(width * 0.92) + 1, int(width * 0.97))
    margin_samples = np.vstack([
        image[y1:y2:4, lx1:lx2].reshape(-1, 3),
        image[y1:y2:4, rx1:rx2].reshape(-1, 3),
    ]).astype(np.float32)

    bg_color = np.median(margin_samples, axis=0)
    if float(np.mean(np.std(margin_samples, axis=0))) < 22.0:
        scale = 0.5
        sw, sh = max(32, int(width * scale)), max(32, int(height * scale))
        small_img = cv2.resize(image, (sw, sh), interpolation=cv2.INTER_AREA).astype(np.float32)
        diff = np.linalg.norm(small_img - bg_color, axis=2)
        fg_mask = (diff > 8.0).astype(np.uint8) * 255

        mask_border = np.zeros((sh + 2, sw + 2), dtype=np.uint8)
        for seed in [(0, 0), (sw - 1, 0), (0, sh - 1), (sw - 1, sh - 1), (sw // 2, 0), (sw // 2, sh - 1)]:
            if fg_mask[seed[1], seed[0]] > 0:
                cv2.floodFill(fg_mask, mask_border, seed, 0)

        open_k = cv2.getStructuringElement(cv2.MORPH_RECT, (3, 3))
        close_k = cv2.getStructuringElement(cv2.MORPH_RECT, (7, 7))
        fg_clean = cv2.morphologyEx(fg_mask, cv2.MORPH_OPEN, open_k, iterations=1)
        fg_clean = cv2.morphologyEx(fg_clean, cv2.MORPH_CLOSE, close_k, iterations=2)

        fg_contours, _ = cv2.findContours(fg_clean, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        for cnt in fg_contours:
            sx, sy, bw, bh = cv2.boundingRect(cnt)
            cnt_area = cv2.contourArea(cnt)
            if cnt_area / max(bw * bh, 1) >= 0.65:
                x, y, w, h = int(sx / scale), int(sy / scale), int(bw / scale), int(bh / scale)
                if min_pixels <= w * h <= max_pixels:
                    extra_boxes.append((x, y, w, h))

    return extra_boxes


def _is_outer_container_panel(box, all_boxes, width, height, image) -> bool:
    """Checks if box is an overall screen container or comments sheet panel."""
    x, y, w, h = box
    box_area = w * h
    total_area = width * height

    if w > width * 0.88 and box_area > total_area * 0.45:
        for ox, oy, ow, oh in all_boxes:
            if (ox, oy, ow, oh) == box:
                continue
            inner_area = ow * oh
            if inner_area < box_area * 0.65 and inner_area >= total_area * 0.015:
                if ox >= x - 4 and oy >= y - 4 and (ox + ow) <= (x + w + 4) and (oy + oh) <= (y + h + 4):
                    return True

    if w >= width * 0.85 and box_area >= total_area * 0.20:
        for ox, oy, ow, oh in all_boxes:
            if (ox, oy, ow, oh) == box:
                continue
            inner_area = ow * oh
            if inner_area <= box_area * 0.75 and inner_area >= total_area * 0.008:
                if ox >= x - 8 and oy >= y - 8 and (ox + ow) <= (x + w + 8) and (oy + oh) <= (y + h + 8):
                    mask = np.zeros((h, w), dtype=bool)
                    rel_x1 = max(0, ox - x)
                    rel_y1 = max(0, oy - y)
                    rel_x2 = min(w, ox + ow - x)
                    rel_y2 = min(h, oy + oh - y)
                    mask[rel_y1:rel_y2, rel_x1:rel_x2] = True
                    roi = image[y:y+h, x:x+w]
                    margin = roi[~mask]
                    if margin.size > 0:
                        med = np.median(margin, axis=0)
                        dists = np.linalg.norm(margin.astype(float) - med, axis=1)
                        if np.mean(dists < 22.0) > 0.60:
                            return True
    return False


def _filter_and_tighten_raw_boxes(image, raw_boxes, min_pixels, max_pixels):
    height, width = image.shape[:2]
    valid = []
    for x, y, w, h in raw_boxes:
        area = w * h
        if area < min_pixels or area > max_pixels:
            continue
        if w < 48 or h < 36:
            continue
        ratio = w / max(h, 1)
        if not 0.22 <= ratio <= 4.5:
            continue
        if w > width * 0.985 and h > height * 0.92:
            continue
        if w < width * 0.055 or h < height * 0.018:
            continue

        tight_box = smart_snap_box(image, (x, y, w, h), search_range=8)
        tx, ty, tw, th = tight_box
        if tw < 48 or th < 36 or (tw * th) < min_pixels:
            continue
        if _is_ui_or_text_noise(image, tight_box):
            continue
        valid.append(tight_box)
    return valid


def find_candidates(image, min_area=0.008):
    """Finds image candidates in a screenshot."""
    height, width = image.shape[:2]
    total_area = width * height

    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    blurred = cv2.GaussianBlur(gray, (5, 5), 0)

    edge_a = cv2.Canny(blurred, 35, 110)
    edge_b = cv2.Canny(blurred, 70, 180)
    edges = cv2.bitwise_or(edge_a, edge_b)

    kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (5, 5))
    closed = cv2.morphologyEx(edges, cv2.MORPH_CLOSE, kernel, iterations=2)

    contours, _ = cv2.findContours(closed, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)

    min_pixels = total_area * min_area
    max_pixels = total_area * 0.92

    # 1. Primary Canny contours
    primary_raw = [cv2.boundingRect(c) for c in contours]
    primary_candidates = _filter_and_tighten_raw_boxes(image, primary_raw, min_pixels, max_pixels)
    primary_candidates.sort(key=lambda b: b[2] * b[3], reverse=True)

    # 2. Low-contrast contours
    low_contrast_raw = _find_low_contrast_media_regions(image, min_pixels, max_pixels)
    low_contrast_candidates = _filter_and_tighten_raw_boxes(image, low_contrast_raw, min_pixels, max_pixels)
    low_contrast_candidates.sort(key=lambda b: b[2] * b[3], reverse=True)

    deduped = []
    for box in primary_candidates + low_contrast_candidates:
        if any(_compute_iou(box, existing) >= 0.65 for existing in deduped):
            continue
        deduped.append(box)

    # Remove outer container panels
    without_panels = [
        box for box in deduped
        if not _is_outer_container_panel(box, deduped, width, height, image)
    ]

    # Suppress redundant internal fragments (faces, text bubbles, subtitles, stickers)
    without_panels.sort(key=lambda b: b[2] * b[3], reverse=True)
    filtered = []
    for box in without_panels:
        x, y, w, h = box
        is_inner_fragment = False
        for ox, oy, ow, oh in filtered:
            ix1, iy1 = max(x, ox), max(y, oy)
            ix2, iy2 = min(x + w, ox + ow), min(y + h, oy + oh)
            inter = max(0, ix2 - ix1) * max(0, iy2 - iy1)
            smaller_area = min(w * h, ow * oh)
            if smaller_area > 0 and (inter / smaller_area) > 0.80:
                is_inner_fragment = True
                break
        if not is_inner_fragment:
            filtered.append(box)
        if len(filtered) >= 40:
            break

    filtered.sort(key=lambda b: (b[1], b[0]))
    return filtered


def make_contact_sheet(image, boxes, output_path):
    """Saves candidate contact sheet."""
    if not boxes:
        return

    thumb_w, thumb_h = 220, 160
    card_h = thumb_h + 34
    columns = 3
    rows = (len(boxes) + columns - 1) // columns

    sheet = np.full(
        (rows * card_h, columns * thumb_w, 3),
        235, dtype=np.uint8
    )

    height, width = image.shape[:2]
    for index, (x, y, w, h) in enumerate(boxes, start=1):
        x1, y1 = max(0, x), max(0, y)
        x2, y2 = min(width, x + w), min(height, y + h)
        crop = image[y1:y2, x1:x2]
        if crop.size == 0:
            continue

        thumb = cv2.resize(
            crop, (thumb_w, thumb_h),
            interpolation=cv2.INTER_AREA
        )

        row = (index - 1) // columns
        col = (index - 1) % columns
        px = col * thumb_w
        py = row * card_h

        sheet[py:py+thumb_h, px:px+thumb_w] = thumb
        cv2.putText(
            sheet, f"#{index}  {w}x{h}",
            (px + 6, py + thumb_h + 23),
            cv2.FONT_HERSHEY_SIMPLEX, 0.5,
            (20, 20, 20), 1, cv2.LINE_AA
        )

    imwrite_safe(Path(output_path), sheet)


def select_and_save(image, boxes, output_dir, stem, title_prefix=""):
    """Interactive GUI window to select and save cropped memes."""
    height, width = image.shape[:2]

    scale = min(1200 / width, 820 / height, 1.0)
    disp_w = int(width * scale)
    disp_h = int(height * scale)

    if scale < 1.0:
        display_base = cv2.resize(image, (disp_w, disp_h), interpolation=cv2.INTER_AREA)
    else:
        display_base = image.copy()

    header_h = 44
    auto_boxes = list(boxes)
    manual_boxes = []

    selected = set(range(1, len(auto_boxes) + 1))
    selection_history = list(range(1, len(auto_boxes) + 1))
    hover_coords = (-1.0, -1.0)

    is_dragging = False
    drag_start = (0, 0)
    drag_current = (0, 0)

    window = tr("win_title", prefix=title_prefix)

    def get_box_at(cx, cy):
        matches = []
        for m_idx, (bx, by, bw, bh) in enumerate(manual_boxes, start=1):
            if bx <= cx <= bx + bw and by <= cy <= by + bh:
                matches.append((bw * bh, len(auto_boxes) + m_idx, True, m_idx - 1))
        for idx, (bx, by, bw, bh) in enumerate(auto_boxes, start=1):
            if bx <= cx <= bx + bw and by <= cy <= by + bh:
                matches.append((bw * bh, idx, False, idx - 1))
        if matches:
            matches.sort(key=lambda m: m[0])
            return matches[0][1], matches[0][2], matches[0][3]
        return None, False, -1

    def redraw():
        canvas = np.zeros((disp_h + header_h, disp_w, 3), dtype=np.uint8)
        canvas[:header_h, :] = (24, 27, 36)
        canvas[header_h:, :] = display_base

        # 1. Auto candidates
        for idx, (x, y, w, h) in enumerate(auto_boxes, start=1):
            x1 = int(x * scale)
            y1 = int(y * scale) + header_h
            x2 = int((x + w) * scale)
            y2 = int((y + h) * scale) + header_h

            if idx in selected:
                color = (40, 220, 60)
                thick = 3
                label = f"#{idx} [{tr('badge_saved')}] {w}x{h}"
            else:
                color = (0, 120, 200)
                thick = 1
                label = f"#{idx} [{tr('badge_excluded')}] {w}x{h}"

            cv2.rectangle(canvas, (x1, y1), (x2, y2), color, thick)
            canvas = put_multilingual_text(canvas, label, (x1 + 4, max(y1 + 4, header_h + 4)), font_size=14, color=color)

        # 2. Manual boxes
        for m_idx, (x, y, w, h) in enumerate(manual_boxes, start=1):
            global_idx = len(auto_boxes) + m_idx
            x1 = int(x * scale)
            y1 = int(y * scale) + header_h
            x2 = int((x + w) * scale)
            y2 = int((y + h) * scale) + header_h

            if global_idx in selected:
                color = (255, 215, 0)
                thick = 3
                label = f"#{global_idx} [{tr('badge_manual_saved')}] {w}x{h}"
            else:
                color = (130, 80, 150)
                thick = 1
                label = f"#{global_idx} [{tr('badge_manual_excluded')}] {w}x{h}"

            cv2.rectangle(canvas, (x1, y1), (x2, y2), color, thick)
            canvas = put_multilingual_text(canvas, label, (x1 + 4, max(y1 + 4, header_h + 4)), font_size=14, color=color)

        # 3. Live drag rectangle
        if is_dragging:
            sx, sy = drag_start
            cx, cy = drag_current
            rx1, ry1 = min(sx, cx), min(sy, cy) + header_h
            rx2, ry2 = max(sx, cx), max(sy, cy) + header_h
            rw = int(abs(cx - sx) / scale)
            rh = int(abs(cy - sy) / scale)
            cv2.rectangle(canvas, (rx1, ry1), (rx2, ry2), (0, 255, 255), 2)
            canvas = put_multilingual_text(canvas, tr("drawing", w=rw, h=rh), (rx1 + 6, max(ry1 - 18, header_h + 4)), font_size=13, color=(0, 255, 255))

        # 4. Header status info
        info_l1 = tr("header_info_l1", selected=sorted(selected), count=len(selected), auto_len=len(auto_boxes), manual_len=len(manual_boxes))
        info_l2 = tr("header_info_l2")
        canvas = put_multilingual_text(canvas, info_l1, (10, 4), font_size=13, color=(0, 240, 255))
        canvas = put_multilingual_text(canvas, info_l2, (10, 22), font_size=12, color=(200, 200, 200))

        cv2.imshow(window, canvas)

    def on_mouse(event, px, py, flags, userdata):
        nonlocal is_dragging, drag_start, drag_current, selected, hover_coords, selection_history

        img_px = px
        img_py = py - header_h

        if event == cv2.EVENT_LBUTTONDOWN:
            if img_py >= 0:
                is_dragging = True
                drag_start = (img_px, img_py)
                drag_current = (img_px, img_py)

        elif event == cv2.EVENT_MOUSEMOVE:
            hover_coords = (img_px / scale, img_py / scale)
            if is_dragging:
                drag_current = (img_px, max(0, min(disp_h, img_py)))
                redraw()

        elif event == cv2.EVENT_LBUTTONUP:
            if is_dragging:
                is_dragging = False
                end_x, end_y = img_px, max(0, min(disp_h, img_py))
                dx = abs(end_x - drag_start[0])
                dy = abs(end_y - drag_start[1])

                if dx >= 12 and dy >= 12:
                    rx1 = int(min(drag_start[0], end_x) / scale)
                    ry1 = int(min(drag_start[1], end_y) / scale)
                    rx2 = int(max(drag_start[0], end_x) / scale)
                    ry2 = int(max(drag_start[1], end_y) / scale)

                    rx1 = max(0, min(width - 1, rx1))
                    ry1 = max(0, min(height - 1, ry1))
                    rx2 = max(0, min(width, rx2))
                    ry2 = max(0, min(height, ry2))

                    bw = rx2 - rx1
                    bh = ry2 - ry1
                    if bw >= 16 and bh >= 16:
                        snapped_box = smart_snap_box(image, (rx1, ry1, bw, bh), search_range=40)
                        manual_boxes.append(snapped_box)
                        new_idx = len(auto_boxes) + len(manual_boxes)
                        selected.add(new_idx)
                        selection_history.append(new_idx)
                        if snapped_box != (rx1, ry1, bw, bh):
                            print(tr("manual_added_snap", idx=new_idx, orig=f"{rx1},{ry1},{bw},{bh}", snapped=f"{snapped_box[0]},{snapped_box[1]},{snapped_box[2]},{snapped_box[3]}"))
                        else:
                            print(tr("manual_added", idx=new_idx, x=rx1, y=ry1, w=bw, h=bh))
                else:
                    click_x = img_px / scale
                    click_y = img_py / scale
                    target_idx, _, _ = get_box_at(click_x, click_y)
                    if target_idx is not None:
                        if target_idx in selected:
                            selected.remove(target_idx)
                            if target_idx in selection_history:
                                selection_history.remove(target_idx)
                            print(tr("deselected_click", idx=target_idx))
                        else:
                            selected.add(target_idx)
                            selection_history.append(target_idx)
                            print(tr("selected_click", idx=target_idx))
                redraw()

    cv2.namedWindow(window, cv2.WINDOW_NORMAL)
    cv2.setMouseCallback(window, on_mouse)
    redraw()

    print(tr("controls_guide"))

    user_action = "next"

    while True:
        if cv2.getWindowProperty(window, cv2.WND_PROP_VISIBLE) < 1:
            user_action = "quit"
            break

        key = cv2.waitKey(30) & 0xFF

        if key in (10, 13, 32):  # Enter or Space
            user_action = "saved"
            break
        elif key == 27:  # Esc
            selected.clear()
            user_action = "skipped"
            print(tr("skip_current_image"))
            break
        elif key in (ord('q'), ord('Q')):  # Q
            selected.clear()
            user_action = "quit"
            print(tr("quitting_task"))
            break
        elif key in (ord('c'), ord('C'), 8):  # C or Backspace
            target_idx, is_man, int_idx = get_box_at(hover_coords[0], hover_coords[1])
            if target_idx is not None:
                if target_idx in selected:
                    selected.remove(target_idx)
                    if target_idx in selection_history:
                        selection_history.remove(target_idx)
                    print(tr("deselected_key", idx=target_idx))
                    redraw()
                elif is_man:
                    manual_boxes.pop(int_idx)
                    new_sel = set()
                    for idx in selected:
                        if idx < target_idx:
                            new_sel.add(idx)
                        elif idx > target_idx:
                            new_sel.add(idx - 1)
                    selected = new_sel
                    selection_history = [i if i < target_idx else i - 1 for i in selection_history if i != target_idx]
                    print(tr("manual_box_deleted_full", idx=target_idx))
                    redraw()
                else:
                    selected.add(target_idx)
                    selection_history.append(target_idx)
                    print(tr("reselected_key", idx=target_idx))
                    redraw()
            elif selection_history:
                last_sel = selection_history.pop()
                selected.discard(last_sel)
                print(tr("deselected_key", idx=last_sel))
                redraw()
            elif manual_boxes:
                removed_idx = len(auto_boxes) + len(manual_boxes)
                manual_boxes.pop()
                selected.discard(removed_idx)
                print(tr("last_manual_deleted", idx=removed_idx))
                redraw()
            elif selected:
                last_sel = max(selected)
                selected.remove(last_sel)
                print(tr("deselected_key", idx=last_sel))
                redraw()
            else:
                print(tr("no_box_selected"))
        elif ord('1') <= key <= ord('9'):  # Number keys
            target_idx = key - ord('0')
            total_count = len(auto_boxes) + len(manual_boxes)
            if 1 <= target_idx <= total_count:
                if target_idx in selected:
                    selected.remove(target_idx)
                    if target_idx in selection_history:
                        selection_history.remove(target_idx)
                    print(tr("deselected_num_key", key=target_idx, idx=target_idx))
                else:
                    selected.add(target_idx)
                    selection_history.append(target_idx)
                    print(tr("selected_num_key", key=target_idx, idx=target_idx))
                redraw()
        elif key in (ord('r'), ord('R')):  # R
            for m_i in range(1, len(manual_boxes) + 1):
                selected.discard(len(auto_boxes) + m_i)
            manual_boxes.clear()
            selection_history = [i for i in selection_history if i <= len(auto_boxes)]
            print(tr("all_manual_cleared"))
            redraw()
        elif key in (ord('a'), ord('A')):  # A
            total_count = len(auto_boxes) + len(manual_boxes)
            if len(selected) == total_count:
                selected.clear()
                selection_history.clear()
                print(tr("all_candidates_deselected"))
            else:
                selected = set(range(1, total_count + 1))
                selection_history = list(range(1, total_count + 1))
                print(tr("all_candidates_selected", count=total_count))
            redraw()
        elif key in (ord('s'), ord('S')):  # S
            if manual_boxes:
                last_box = manual_boxes[-1]
                snapped = smart_snap_box(image, last_box, search_range=60)
                manual_boxes[-1] = snapped
                print(tr("manual_edge_snapped", orig=last_box, snapped=snapped))
                redraw()

    cv2.destroyAllWindows()

    saved = 0
    output_dir = Path(output_dir)
    all_boxes = auto_boxes + manual_boxes
    saved_indices = set()

    for index in sorted(selected):
        if not (1 <= index <= len(all_boxes)):
            continue
        x, y, w, h = all_boxes[index - 1]
        x1, y1 = max(0, x), max(0, y)
        x2, y2 = min(width, x + w), min(height, y + h)
        crop = image[y1:y2, x1:x2]

        is_manual = index > len(auto_boxes)
        tag_str = tr("tag_manual", idx=index - len(auto_boxes)) if is_manual else tr("tag_auto", idx=index)
        output_path = output_dir / f"{stem}_crop_{index:02d}.png"

        if imwrite_safe(output_path, crop):
            print(tr("save_item_success", tag=tag_str, name=output_path.name, w=crop.shape[1], h=crop.shape[0]))
            saved += 1
            saved_indices.add(index)
        else:
            print(tr("save_item_fail", name=output_path.name))

    for old_file in output_dir.glob(f"{stem}_crop_*.png"):
        try:
            num_part = old_file.stem.split(f"{stem}_crop_")[-1]
            old_idx = int(num_part)
            if old_idx not in saved_indices:
                old_file.unlink(missing_ok=True)
                print(tr("cleaned_old_file", name=old_file.name))
        except Exception:
            pass

    if saved > 0:
        print(tr("summary_saved", stem=stem, count=saved))
    else:
        print(tr("summary_none", stem=stem))

    return user_action


def save_candidates_headless(image, boxes, output_dir: Path, stem: str, indices=None):
    """Saves candidate rectangles directly to PNG files."""
    height, width = image.shape[:2]
    target_indices = indices if indices is not None else range(1, len(boxes) + 1)
    saved_paths = []
    for index in target_indices:
        if not (1 <= index <= len(boxes)):
            continue
        x, y, w, h = boxes[index - 1]
        x1, y1 = max(0, x), max(0, y)
        x2, y2 = min(width, x + w), min(height, y + h)
        crop = image[y1:y2, x1:x2]
        output_path = output_dir / f"{stem}_crop_{index:02d}.png"
        if imwrite_safe(output_path, crop):
            saved_paths.append(output_path)
    return saved_paths


def process_single_image(input_path: Path, args, output_dir: Path, title_prefix=""):
    """Processes a single screenshot image."""
    image = imread_safe(input_path)
    if image is None:
        print(tr("cannot_read_image", path=input_path))
        return "skipped"

    print(f"\n{title_prefix}" + tr("target_file_banner", name=input_path.name, w=image.shape[1], h=image.shape[0]))

    if args.manual:
        boxes = []
    else:
        t0 = time.perf_counter()
        boxes = find_candidates(image, args.min_area)
        elapsed_ms = (time.perf_counter() - t0) * 1000.0

        if getattr(args, "save_preview", False):
            preview = image.copy()
            for index, (x, y, w, h) in enumerate(boxes, start=1):
                cv2.rectangle(preview, (x, y), (x + w, y + h), (0, 165, 255), 2)
                cv2.putText(preview, str(index), (x + 4, max(y + 22, 22)),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2, cv2.LINE_AA)

            preview_path = output_dir / f"{input_path.stem}_candidates.jpg"
            imwrite_safe(preview_path, preview)

            contact_path = output_dir / f"{input_path.stem}_contact_sheet.jpg"
            make_contact_sheet(image, boxes, contact_path)

            print(tr("auto_detected_preview", count=len(boxes), ms=elapsed_ms, preview=preview_path.name))
        else:
            print(tr("auto_detected_candidates", count=len(boxes), ms=elapsed_ms))

        if args.save_all:
            saved_paths = save_candidates_headless(image, boxes, output_dir, input_path.stem)
            for sp in saved_paths:
                print(tr("auto_saved_item", name=sp.name))
            return "saved"

    if not args.no_ui:
        action = select_and_save(
            image, boxes, output_dir, input_path.stem, title_prefix=title_prefix
        )
        return action
    return "saved"


def main():
    global CURRENT_LANG
    temp_parser = argparse.ArgumentParser(add_help=False)
    temp_parser.add_argument("--lang", choices=LANGUAGES, default=None)
    temp_args, _ = temp_parser.parse_known_args()

    if temp_args.lang:
        CURRENT_LANG = temp_args.lang
    else:
        lang_file = Path(".lang")
        if lang_file.exists():
            try:
                saved = lang_file.read_text(encoding="utf-8").strip().lower()
                if saved in LANGUAGES:
                    CURRENT_LANG = saved
            except Exception:
                pass

    parser = argparse.ArgumentParser(
        description=tr("cli_description")
    )
    parser.add_argument(
        "--lang", choices=["en", "ko", "zh", "ja"], default=CURRENT_LANG,
        help="Interface language: en (English), ko (Korean), zh (Chinese), ja (Japanese)"
    )
    parser.add_argument(
        "image", nargs="?", default="screenshots",
        help=tr("cli_image_help")
    )
    parser.add_argument(
        "--out", default="extracted_images",
        help=tr("cli_out_help")
    )
    parser.add_argument(
        "--min-area", type=float, default=0.008,
        help=tr("cli_min_area_help")
    )
    parser.add_argument(
        "--manual", action="store_true",
        help=tr("cli_manual_help")
    )
    parser.add_argument(
        "--auto", action="store_true",
        help=tr("cli_auto_help")
    )
    parser.add_argument(
        "--no-ui", action="store_true",
        help=tr("cli_no_ui_help")
    )
    parser.add_argument(
        "--save-all", action="store_true",
        help=tr("cli_save_all_help")
    )
    parser.add_argument(
        "--save-preview", action="store_true",
        help=tr("cli_save_preview_help")
    )

    args = parser.parse_args()
    if args.lang:
        CURRENT_LANG = args.lang

    if not args.manual and not args.auto and not args.no_ui:
        if sys.stdin and sys.stdin.isatty():
            print("====================================================")
            print(f"       {tr('title')}")
            print("====================================================")
            print(tr("menu_3"))
            print(tr("menu_2"))
            print(tr("menu_1"))
            print("====================================================")
            try:
                choice = input(tr("menu_prompt")).strip()
            except (EOFError, KeyboardInterrupt):
                choice = "3"
            if choice == "1":
                args.manual = True
            elif choice == "2":
                args.manual = False
            else:
                args.no_ui = True
                args.save_all = True
            print()
        else:
            args.no_ui = True
            args.save_all = True

    input_path = Path(args.image)

    if not input_path.exists():
        raise SystemExit(tr("err_path_not_found", path=input_path))

    output_dir = Path(args.out)
    output_dir.mkdir(parents=True, exist_ok=True)

    if not 0 < args.min_area < 1:
        raise SystemExit(tr("err_min_area"))

    if input_path.is_file():
        image_files = [input_path]
    else:
        valid_exts = {".jpg", ".jpeg", ".png", ".webp", ".bmp"}
        image_files = sorted([
            p for p in input_path.iterdir()
            if p.is_file() and p.suffix.lower() in valid_exts
        ])
        if not image_files:
            raise SystemExit(tr("err_no_images_folder", path=input_path))

    total_images = len(image_files)
    if args.no_ui or args.save_all:
        mode_name = tr("batch_mode")
    elif args.manual:
        mode_name = tr("manual_mode")
    else:
        mode_name = tr("auto_mode")

    print(f"====================================================")
    print(f"  " + tr("running", mode=mode_name))
    print(f"  " + tr("target_count", count=total_images, out_dir=output_dir))
    print(f"====================================================")

    for idx, img_path in enumerate(image_files, start=1):
        prefix = f"[{idx}/{total_images}] " if total_images > 1 else ""
        action = process_single_image(img_path, args, output_dir, title_prefix=prefix)
        if action == "quit":
            print("\n" + tr("user_quit"))
            break

    print(f"\n" + tr("all_done_banner", out_dir=output_dir.resolve()))


if __name__ == "__main__":
    main()

'@
# Inject chosen language as default directly into extractor.py
$tailoredSourceCode = $pythonSourceCode -replace 'DEFAULT_LANG = "en"', "DEFAULT_LANG = `"$currentLang`""
$tailoredSourceCode = $tailoredSourceCode -replace 'CURRENT_LANG = "en"', "CURRENT_LANG = `"$currentLang`""
[System.IO.File]::WriteAllText($extractorPath, $tailoredSourceCode, [System.Text.Encoding]::UTF8)

# 5. Detect Python runtime
$pythonExe = $null
$localVenvPy = Join-Path $ScriptDir ".venv\Scripts\python.exe"
if (Test-Path $localVenvPy) {
    $pythonExe = $localVenvPy
} else {
    $sysPy = (Get-Command "python" -ErrorAction SilentlyContinue)
    if ($sysPy) {
        $pythonExe = "python"
    }
}

if (-not $pythonExe) {
    Write-Host "====================================================" -ForegroundColor Red
    if ($currentLang -eq "ko") {
        Write-Host "[오류] 시스템에 Python이 설치되어 있지 않습니다!" -ForegroundColor Red
        Write-Host "https://www.python.org/downloads/ 에서 Python을 설치한 후 다시 실행해주세요." -ForegroundColor Yellow
        Write-Host "===================================================="
        Write-Host "아무 키나 누르면 종료됩니다..."
    } elseif ($currentLang -eq "zh") {
        Write-Host "[错误] 系统中未安装 Python！" -ForegroundColor Red
        Write-Host "请从 https://www.python.org/downloads/ 安装 Python 后重试。" -ForegroundColor Yellow
        Write-Host "===================================================="
        Write-Host "按任意键退出..."
    } elseif ($currentLang -eq "ja") {
        Write-Host "[エラー] Pythonがシステムにインストールされていません！" -ForegroundColor Red
        Write-Host "https://www.python.org/downloads/ からPythonをインストールして再試行してください。" -ForegroundColor Yellow
        Write-Host "===================================================="
        Write-Host "任意のキーを押して終了..."
    } else {
        Write-Host "[ERROR] Python is not installed on this system!" -ForegroundColor Red
        Write-Host "Please install Python from https://www.python.org/downloads/ and try again." -ForegroundColor Yellow
        Write-Host "===================================================="
        Write-Host "Press any key to exit..."
    }
    [Console]::ReadKey($true) | Out-Null
    exit 1
}

# 6. Check & auto-install required packages (OpenCV, NumPy, Pillow)
& $pythonExe -c "import cv2, numpy, PIL" 2>$null
if ($LASTEXITCODE -ne 0) {
    if ($currentLang -eq "ko") {
        Write-Host "[1/3] 필수 패키지 확인 및 자동 설치 중 (OpenCV, NumPy, Pillow)..." -ForegroundColor Yellow
    } elseif ($currentLang -eq "zh") {
        Write-Host "[1/3] 正在检查并自动安装所需依赖包 (OpenCV, NumPy, Pillow)..." -ForegroundColor Yellow
    } elseif ($currentLang -eq "ja") {
        Write-Host "[1/3] 必要なパッケージを確認・自動インストール中 (OpenCV, NumPy, Pillow)..." -ForegroundColor Yellow
    } else {
        Write-Host "[1/3] Checking & installing required packages (OpenCV, NumPy, Pillow)..." -ForegroundColor Yellow
    }

    & $pythonExe -m pip install -r $requirementsPath
    if ($LASTEXITCODE -ne 0) {
        if ($currentLang -eq "ko") {
            Write-Host "[오류] 필수 패키지 설치에 실패했습니다. 인터넷 연결을 확인해주세요." -ForegroundColor Red
            Write-Host "아무 키나 누르면 종료됩니다..."
        } elseif ($currentLang -eq "zh") {
            Write-Host "[错误] 依赖包安装失败，请检查网络连接。" -ForegroundColor Red
            Write-Host "按任意键退出..."
        } elseif ($currentLang -eq "ja") {
            Write-Host "[エラー] パッケージのインストールに失敗しました。インターネット接続を確認してください。" -ForegroundColor Red
            Write-Host "任意のキーを押して終了..."
        } else {
            Write-Host "[ERROR] Failed to install required packages. Please check your internet connection." -ForegroundColor Red
            Write-Host "Press any key to exit..."
        }
        [Console]::ReadKey($true) | Out-Null
        exit 1
    }
}

# 7. Check images in screenshots folder
$validExtensions = @(".jpg", ".jpeg", ".png", ".webp", ".bmp")
$imageFiles = Get-ChildItem -Path $screenshotsDir -File | Where-Object { $validExtensions -contains $_.Extension.ToLower() }

if ($imageFiles.Count -eq 0) {
    Write-Host "====================================================" -ForegroundColor Green
    if ($currentLang -eq "ko") {
        Write-Host "       CommentCrop 준비 완료!" -ForegroundColor Green
        Write-Host "====================================================" -ForegroundColor Green
        Write-Host "  1. 열린 [screenshots] 폴더에 자르고 싶은 스크린샷 이미지를 넣어주세요." -ForegroundColor Yellow
        Write-Host "  2. 사진을 넣은 뒤 crop.bat을 다시 실행하면 바로 크롭이 시작됩니다!" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "지금 screenshots 폴더를 엽니다..." -ForegroundColor Cyan
        Write-Host "엔터를 누르면 창이 닫힙니다..."
    } elseif ($currentLang -eq "zh") {
        Write-Host "       CommentCrop 准备就绪！" -ForegroundColor Green
        Write-Host "====================================================" -ForegroundColor Green
        Write-Host "  1. 请将需要裁剪的截图放入已打开的 [screenshots] 文件夹中。" -ForegroundColor Yellow
        Write-Host "  2. 放入图片后，重新运行 crop.bat 即可立即开始裁剪！" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "正在打开 screenshots 文件夹..." -ForegroundColor Cyan
        Write-Host "按回车键退出..."
    } elseif ($currentLang -eq "ja") {
        Write-Host "       CommentCrop 準備完了！" -ForegroundColor Green
        Write-Host "====================================================" -ForegroundColor Green
        Write-Host "  1. 開いた [screenshots] フォルダに切り取りたい画像を入れてください。" -ForegroundColor Yellow
        Write-Host "  2. 画像を入れた後、再度 crop.bat を実行すると切り取りが始まります！" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "screenshots フォルダを開きます..." -ForegroundColor Cyan
        Write-Host "Enterキーを押して終了します..."
    } else {
        Write-Host "       CommentCrop Ready!" -ForegroundColor Green
        Write-Host "====================================================" -ForegroundColor Green
        Write-Host "  1. Place your screenshot images into the [screenshots] folder." -ForegroundColor Yellow
        Write-Host "  2. Run crop.bat again to start cropping!" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Opening [screenshots] folder now..." -ForegroundColor Cyan
        Write-Host "Press Enter to exit..."
    }
    Invoke-Item $screenshotsDir
    [Console]::ReadLine() | Out-Null
    exit 0
}

# 8. Run crop engine with chosen language
& $pythonExe $extractorPath --lang $currentLang $args

# 9. Open results folder if cropped images exist
$croppedFiles = Get-ChildItem -Path $extractedDir -File
if ($croppedFiles.Count -gt 0) {
    Invoke-Item $extractedDir
}

if ($currentLang -eq "ko") {
    Write-Host "작업이 종료되었습니다. 엔터를 누르면 창이 닫힙니다..." -ForegroundColor Cyan
} elseif ($currentLang -eq "zh") {
    Write-Host "操作已完成。按回车键退出..." -ForegroundColor Cyan
} elseif ($currentLang -eq "ja") {
    Write-Host "処理が完了しました。Enterキーを押して終了します..." -ForegroundColor Cyan
} else {
    Write-Host "Done. Press Enter to exit..." -ForegroundColor Cyan
}
[Console]::ReadLine() | Out-Null
