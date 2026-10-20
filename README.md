# CommentCrop

Automatically detects and crops memes/photos from social media comment screenshots (YouTube, X, Instagram, communities).  
Available for **Windows** and **Android**.

[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Android-0078D6.svg)](#)
[![Built with AI Assistance](https://img.shields.io/badge/built%20with-AI%20Assistance-8A2BE2.svg)](#)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Languages](https://img.shields.io/badge/Languages-EN%20%7C%20%ED%95%9C%EA%B5%AD%EC%96%B4%20%7C%20%E4%B8%AD%E6%96%87%20%7C%20%E6%97%A5%E6%9C%AC%E8%AA%9E-orange.svg)](#)

All image processing runs 100% locally on your device using on-device vision AI (no cloud servers, completely private and offline).

---

## 📱 Android App

Download: **[CommentCrop.apk](CommentCrop.apk)** (Requires Android 8.0+)

### Highlights
- **On-Device Vision AI**: Uses ML Kit OCR to filter out messy comment text, IDs, and timestamps, isolating pure meme image boundaries.
- **Tap-to-Snap**: Tap anywhere on a meme inside the screenshot preview, and the crop box snaps tightly to the image borders automatically.
- **System Share Integration**: Crop immediately after taking a screenshot via system Share without switching apps.
- **Batch Cropping**: Pick multiple screenshots from your gallery to auto-crop them all in one go.

### How to use
1. Download and install `CommentCrop.apk` on your phone.
2. Take a screenshot of any comment thread with a photo/meme.
3. Tap system **Share** → **CommentCrop**.
4. The AI highlights the detected meme. Tap **Crop** to save, or **Copy** to paste directly into chats. (You can also tap anywhere on the image to re-snap, or adjust manually).
5. Open the app directly to batch-crop multiple screenshots or manage saved memes.

---

## 💻 Windows Tool

Run: **`crop.bat`** (Requires Windows 10/11 & Python 3.8+)

### How to use
1. Put your screenshots in the `screenshots/` folder.
2. Run `crop.bat`.
3. Press **Enter** (Mode 3: headless auto-batch crop).
4. Cropped images are saved in `extracted_images/`.

### Modes
- `[3]` **Auto Batch (Default)**: Crops all images in the background without opening windows.
- `[2]` **Auto Detect**: Shows AI-detected borders for confirmation before cropping.
- `[1]` **Manual Crop**: Lets you drag and adjust borders with magnetic edge snapping.

---

## 🌐 Languages

Both versions support English, Korean (한국어), Chinese (中文), and Japanese (日本語).

---

## 🇰🇷 한국어 요약

유튜브, 트위터(X), 인스타그램, 커뮤니티 댓글에 달린 짤방(사진/밈)을 자동으로 깔끔하게 잘라주는 툴입니다. 외부 서버 전송 없이 스마트폰/PC에서 100% 로컬로 작동합니다.

- **안드로이드 앱 ([CommentCrop.apk](CommentCrop.apk))**:
  - **온디바이스 비전 AI**: 텍스트를 감지해 걸러내고 순수 짤 영역만 정밀하게 인식합니다.
  - **Tap-to-Snap**: 화면 속 짤을 손가락으로 툭 터치하면 테두리에 자석처럼 딱 달라붙습니다.
  - **초간편 사용**: 캡처 후 시스템 [공유] → [CommentCrop]을 누르면 즉시 크롭 및 복사/저장.
  - 앱에서 여러 스크린샷을 한 번에 일괄 자동 크롭할 수도 있습니다.
- **윈도우 PC ([crop.bat](crop.bat))**: `screenshots` 폴더에 이미지를 넣고 `crop.bat` 실행 후 엔터만 치면 `extracted_images` 폴더에 짤방만 잘라내어 저장합니다.

---

## 🇨🇳 中文简述

自动识别并裁剪 YouTube、X (Twitter)、Instagram 和各类论坛评论区中表情包与配图的工具。纯本地离线处理，无需上传数据。

- **Android 客户端 ([CommentCrop.apk](CommentCrop.apk))**：
  - **端侧 Vision AI**：自动过滤评论文字干扰，精准锁定纯图片区域。
  - **点击吸附（Tap-to-Snap）**：在预览中轻点图片任意位置，选框即可自动吸附到图片边缘。
  - **系统分享联动**：截图后点击“分享”选择 CommentCrop 即可快速裁剪、复制或保存，支持多图批量处理。
- **Windows 电脑端 ([crop.bat](crop.bat))**：将截图放入 `screenshots` 文件夹，运行 `crop.bat` 按回车即可自动批量裁剪至 `extracted_images`。

---

## 🇯🇵 日本語要約

YouTube、X（Twitter）、Instagram、掲示板などのコメント欄に添付されたミーム画像・写真を自動で切り抜くツールです。外部通信なしで端末内のみで完結します。

- **Android アプリ ([CommentCrop.apk](CommentCrop.apk))**：
  - **オンデバイス Vision AI**：コメント文字を事前除去し、純粋な画像領域のみを高精度に認識。
  - **Tap-to-Snap**：プレビュー上の画像をタップするだけで、四方の境界線に吸着して枠を自動調整。
  - **共有メニュー連携**：スクショ撮影後「共有」→ CommentCrop を選ぶだけですぐに切り抜き・コピー・保存が可能。複数画像の一括処理にも対応。
- **Windows ツール ([crop.bat](crop.bat))**：`screenshots` フォルダに画像を入れて `crop.bat` を起動し Enter を押すだけで、`extracted_images` に一括保存されます。

---

## 📄 License

MIT License
