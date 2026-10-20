# CommentCrop

> **AI-Powered Meme & Image Extractor from Social Media Screenshots**  
> Easily extract clean meme images and photos embedded within YouTube, Twitter/X, Instagram, and community comment sections.  
> Available for **💻 Windows Desktop** and **📱 Android Mobile**.

[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Android-0078D6.svg)](#)
[![Built with AI Assistance](https://img.shields.io/badge/built%20with-AI%20Assistance-8A2BE2.svg)](#)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Languages](https://img.shields.io/badge/Languages-EN%20%7C%20%ED%95%9C%EA%B5%AD%EC%96%B4%20%7C%20%E4%B8%AD%E6%96%87%20%7C%20%E6%97%A5%E6%9C%AC%E8%AA%9E-orange.svg)](#multilingual-support)

---

## 🌟 Overview

When browsing social media (YouTube, Twitter/X, Instagram, Reddit, forums), users frequently want to save meme pictures and reactions attached in comment threads. However, taking a screenshot captures UI elements, usernames, timestamps, and like buttons alongside the image.

**CommentCrop** automates and simplifies cropping these images using smart boundary detection, Sobel multi-channel gradient analysis, and magnetic edge-snapping algorithms.

**100% Offline & Private:** All image processing runs strictly locally on your PC or mobile phone. No photos or personal data are ever uploaded to external servers.

---

## 📦 Downloads & Quick Start

### 📱 1. Android Mobile App (`CommentCrop.apk`)
- **[Download CommentCrop.apk](CommentCrop.apk)**
- **How to Install:** Download the `.apk` file directly to your Android device, open it, and allow installation from unknown sources.
- **Workflow:** 
  1. Take a screenshot in YouTube, Twitter, or any app.
  2. Tap the system **Share (공유)** button and select **CommentCrop**.
  3. The semi-transparent popup instantly detects the meme border. Tap **Crop** to save or **Copy** to paste directly into chat!

---

### 💻 2. Windows Desktop Tool (`crop.bat`)
- **Requirements:** Windows 10/11 with Python 3.8+ installed.
- **How to Run:**
  1. Clone or download this repository.
  2. Place your raw screenshots into the `screenshots/` directory (created automatically).
  3. Double-click **`crop.bat`** (or run `./crop.bat` in Terminal/PowerShell).
  4. Press **Enter** for instant batch auto-cropping (Mode 3). Clean meme PNGs are saved to `extracted_images/`!

---

## 🕹️ Desktop Tool Execution Modes

| Mode | Name | Description | Best For |
| :---: | :--- | :--- | :--- |
| **[3]** | **Auto Batch Save (Default)** | Headless background batch processing with zero user interaction. | Processing multiple screenshots instantly |
| **[2]** | **Auto Detect Mode** | Shows interactive GUI with AI candidate bounding boxes for review. | Checking and tweaking detected borders |
| **[1]** | **Manual Crop Mode** | Opens interactive GUI for manual rectangle dragging with magnetic smart edge snap. | Irregular layouts or custom crop areas |

### Interactive GUI Shortcuts (Modes 1 & 2)
- **Mouse Drag:** Draw or adjust crop selection
- **Space / Enter:** Confirm selection and proceed to next image
- **R:** Reset selection to initial AI detection
- **S:** Skip current image
- **Q / ESC:** Quit program

---

## 📱 Mobile App Key Features

- **⚡ Instant System Share Integration:** Crop directly from screenshot preview via Android's native Share menu.
- **🗂️ Multi-Photo Batch Cropping:** Select multiple screenshots at once to auto-crop all in seconds or review one by one.
- **🧲 Magnetic Smart Edge Snap:** When adjusting the crop box, tap **Snap to Region** to magnetically fit tightly to true image borders.
- **🖼️ Built-in Collection Gallery:** Multi-select to batch save to system Photos or delete.
- **🌗 Theme Modes:** Full support for System Default, Light Mode, and Dark Mode.

---

## 📂 Repository Structure

```text
CommectCrop/
├── crop.bat            # 💻 Windows desktop launcher & environment bootstrap
├── CommentCrop.apk     # 📱 Android ready-to-install signed release APK
├── .gitignore          # Pre-configured ignore rules (caches, inputs, outputs)
├── LICENSE             # MIT License
└── README.md           # Documentation & guides
```

---

## 🌐 Multilingual Support

Both the desktop tool and mobile app support 4 languages:
- **English** (Default)
- **한국어** (Korean)
- **中文** (Chinese)
- **日本語** (Japanese)

---

## 🇰🇷 한국어 설명

**CommentCrop**은 유튜브, 트위터(X), 인스타그램, 커뮤니티 댓글에 첨부된 짤방(사진/밈)을 깔끔하게 자동 추출해 주는 도구입니다. **Windows 컴퓨터 버전**과 **안드로이드 모바일 앱**을 모두 제공합니다.

### 📱 안드로이드 앱 사용법
1. 저장소의 **[CommentCrop.apk](CommentCrop.apk)** 파일을 스마트폰으로 다운로드하여 설치합니다.
2. 스크린샷 캡처 직후 시스템 **[공유]** 버튼에서 **CommentCrop**을 선택하면 즉시 팝업창이 열려 짤 영역을 자동 감지하고 자를 수 있습니다.
3. 앱 메인 화면에서 여러 사진을 한 번에 선택하여 일괄 자동 크롭하거나, 보관함에서 짤방들을 다중 선택해 기기 갤러리로 저장할 수 있습니다.
4. 라이트 모드, 다크 모드, 시스템 기본 테마를 완벽 지원합니다.

### 💻 윈도우 데스크톱 사용법
1. 저장소를 다운로드한 뒤 **`crop.bat`** 파일을 실행합니다 (파이썬 환경 및 라이브러리 자동 구성).
2. `screenshots` 폴더에 캡처 이미지를 넣고 엔터만 누르면 백그라운드에서 짤방만 고화질 PNG로 일괄 추출되어 `extracted_images` 폴더에 저장됩니다.

---

## 🇨🇳 中文说明

**CommentCrop** 是一款专为提取社交媒体评论区（YouTube、Twitter/X、Instagram、各类网络论坛等）中附带的表情包、梗图及照片而设计的智能裁剪工具，同时提供 **Windows 电脑端** 与 **Android 手机端 App**。

- **手机端 (`CommentCrop.apk`)**：截屏后直接通过系统【分享】唤醒，自动识别图片边框，一键裁剪保存或复制，支持多图批量处理与深浅主题切换。
- **电脑端 (`crop.bat`)**：将截图拖入 `screenshots` 文件夹后按回车，后台极速批量自动裁剪并保存至 `extracted_images`。

---

## 🇯🇵 日本語説明

**CommentCrop** は、YouTube、Twitter/X、Instagram、掲示板などのコメント欄に添付されたミーム画像や写真を、自動で綺麗に切り抜いて保存できるツールです。**Windows PC 向け** と **Android スマホアプリ** の両方に対応しています。

- **スマホアプリ (`CommentCrop.apk`)**：スクショ撮影後、システムの「共有」からすぐに起動して自動検出＆保存。複数画像の一括処理やライト・ダークモードに対応。
- **PC 向けツール (`crop.bat`)**：`screenshots` フォルダに画像を入れ Enter を押すだけで、背景処理にて画像部分のみを高画質 PNG として一括抽出。

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
