# CommentCrop

> **AI-Powered Meme & Image Extractor from Social Media Screenshots**  
> Easily extract clean meme images and photos embedded within YouTube, Twitter/X, Instagram, and community comment sections.

[![Python](https://img.shields.io/badge/Python-3.8%2B-blue.svg)](https://www.python.org/)
[![Platform](https://img.shields.io/badge/Platform-Windows-0078D6.svg)](https://www.microsoft.com/windows)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Languages](https://img.shields.io/badge/Languages-EN%20%7C%20%ED%95%9C%EA%B5%AD%EC%96%B4%20%7C%20%E4%B8%AD%E6%96%87%20%7C%20%E6%97%A5%E6%9C%AC%E8%AA%9E-orange.svg)](#multilingual-support)

---

## 🌟 Overview

When browsing social media (YouTube, Twitter/X, Instagram, TikTok, Reddit, forums), users frequently want to save meme pictures and reactions attached in comment threads. However, taking a screenshot captures UI elements, usernames, timestamps, and like buttons alongside the image.

**CommentCrop** automates and simplifies cropping these images using smart boundary detection, Sobel multi-channel gradient analysis, and magnetic edge-snapping algorithms.

**100% Offline & Private:** All image processing runs locally on your PC. No photos or data are ever uploaded to external servers.

---

## 🚀 Key Features

- **⚡ Fast Headless Auto-Crop (Mode 3 - Default)**  
  Drop your screenshots into `screenshots/`, press **Enter**, and cleanly cropped meme images are automatically generated in `extracted_images/` in seconds without popups or manual steps.
- **🎯 Smart Boundary Detection (Multi-channel Sobel Gradient)**  
  Accurately locates image cards and separates them from comment backgrounds, UI avatars, dividers, and text lines.
- **🧲 Interactive Magnetic Edge Snapping (Modes 1 & 2)**  
  When fine-tuning crops in GUI mode, dragging selection boxes automatically snaps magnetic anchors to exact image borders.
- **🌍 Built-in Multilingual Support**  
  Full native prompt and menu support for **English**, **한국어 (Korean)**, **中文 (Chinese)**, and **日本語 (Japanese)**.
- **📦 Zero-Fuss Windows Launcher (`crop.bat`)**  
  One double-click setup. Automatically checks Python environment, installs dependencies (`opencv-python`, `numpy`, `Pillow`) if missing, and executes.

---

## 💻 Quick Start

### Prerequisites
- **OS:** Windows 10 / 11
- **Python:** Python 3.8 or higher installed and added to `PATH` ([Download Python](https://www.python.org/downloads/))

### How to Use

1. **Clone or Download this repository**
   ```bash
   git clone https://github.com/<your-username>/CommentCrop.git
   cd CommentCrop
   ```
2. **Add screenshots**
   - Place your raw screenshots into the `screenshots/` directory.
   - *(If the directory doesn't exist yet, simply run `crop.bat` once and it will be created automatically).*
3. **Run the program**
   - Double-click **`crop.bat`** (or execute `./crop.bat` in Terminal / PowerShell).
4. **Choose Mode**
   ```text
   ====================================================
     CommentCrop - Mode Selection
   ====================================================
     [1] Manual Crop Mode (Drag to crop directly)
     [2] Auto Detect Mode (AI auto-detection + review)
     [3] Auto Batch Save  (Headless - No Window) [DEFAULT]
   ====================================================
   Select mode [1/2/3] (Press Enter for [3]):
   ```
   - **Press Enter** for instant batch auto-cropping (Mode 3).
5. **Collect cropped images**
   - Clean, cropped meme images will be saved in `extracted_images/` as high-quality PNG files.

---

## 🕹️ Execution Modes

| Mode | Name | Description | Best For |
| :---: | :--- | :--- | :--- |
| **[3]** | **Auto Batch Save (Default)** | Completely headless. Automatically detects and crops every screenshot in `screenshots/` in the background with zero user interaction. | Processing multiple screenshots instantly |
| **[2]** | **Auto Detect Mode** | Shows interactive GUI displaying AI-suggested candidate bounding boxes. Allows confirmation, adjustment, or switching. | Checking and tweaking detected borders |
| **[1]** | **Manual Crop Mode** | Opens interactive GUI for manual rectangle dragging with magnetic smart edge snap. | Irregular layouts or custom crop areas |

### Interactive GUI Shortcuts (Modes 1 & 2)
- **Mouse Drag:** Draw or adjust crop selection
- **Space / Enter:** Confirm selection and proceed to next image
- **R:** Reset selection to initial AI detection
- **S:** Skip current image
- **Q / ESC:** Quit program

---

## 📂 Repository Structure

```text
imagecrop/
├── crop.bat            # Self-contained Windows launcher & environment bootstrap
├── .gitignore          # Pre-configured ignore rules (caches, inputs, outputs)
├── LICENSE             # MIT License
└── README.md           # Documentation
```
*Note: `screenshots/`, `extracted_images/`, and generated script caches (`extractor.py`, `requirements.txt`) are maintained locally and excluded from git.*

---

## 🌐 Multilingual Support

The tool prompts for language on its first run and stores your preference in `.lang`:
- `1`: English (Default)
- `2`: 한국어 (Korean)
- `3`: 中文 (Chinese)
- `4`: 日本語 (Japanese)

To change the language at any time, delete the `.lang` file or edit its content (`en`, `ko`, `zh`, `ja`).

---

## 🇰🇷 한국어 설명 요약

**CommentCrop**은 유튜브, 트위터(X), 인스타그램, 커뮤니티 댓글 등에 첨부된 짤방(사진/밈)을 깔끔하게 자동 추출해 주는 데스크톱 도구입니다.

### 핵심 기능
- **초고속 배치 자동 크롭 (모드 3 - 기본값):** `screenshots` 폴더에 스크린샷을 넣고 엔터만 치면 백그라운드에서 UI와 댓글 텍스트를 제외한 짤방 이미지 영역만 자동으로 잘라내어 `extracted_images` 폴더에 고화질 PNG로 저장합니다.
- **스마트 경계선 감지 및 마그네틱 스냅:** 멀티채널 소벨(Sobel) 그라디언트 기반 경계선 인식과 수동 조절 시 가장자리에 자석처럼 달라붙는 스마트 스냅 기능을 제공합니다.
- **완전한 로컬 오프라인 처리:** 외부 서버 전송 없이 내 PC에서 100% 안전하게 동작합니다.
- **원클릭 실행 (`crop.bat`):** 파이썬 및 필수 라이브러리 자동 확인/설치 지원.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
