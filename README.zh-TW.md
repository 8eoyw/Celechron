# Celechron 桌面版（Windows / macOS）

**Windows 與 macOS 都能用的浙大課表桌面端。** 基於 Celechron 移植，登入與抓取沿用原版，介面照著電腦鍵鼠習慣重新寫了一遍。

**[下載最新版](../../releases/latest)** · [Windows 安裝包 (`.exe`)](https://github.com/8eoyw/Celechron/releases/latest/download/Celechron-Setup-x64.exe) · [Windows 可攜版 (`.zip`)](https://github.com/8eoyw/Celechron/releases/latest/download/Celechron-Windows-x64.zip) · [macOS (`.dmg`)](https://github.com/8eoyw/Celechron/releases/latest/download/Celechron-macOS.dmg)

![日程總覽](docs/screenshots/overview.png)

<sub>截圖使用虛構示範資料，僅校曆為真實結構。</sub>

## 主要改了什麼

- **Windows & macOS 原生執行，鍵鼠互動重寫**：支援 `Ctrl+K`（macOS `⌘+K`）搜課程／作業／考試、雙擊空白時段建日程、右鍵選單、`Ctrl+1~3` 切頁面，也支援深色模式。
- **點課程直接看考試、作業、成績與課時**：在課表、成績或課時裡點任意一門課，右側直接展開教師、學分、課時進度、關聯作業、考場座號與已出成績，按 `Esc` 退回待辦，不用來回切頁。

![點課程查看作業、考試與課時](docs/screenshots/course-inspector.png)

- **點作業直接跳學在浙大**：右側掛著近期考試與依截止時間分組的作業；雙擊（或右鍵／點詳情按鈕）直接用瀏覽器打開學在浙大對應那次作業的頁面，不用進首頁一層層找。

![任務與作業](docs/screenshots/tasks.png)

- **課表按實際時長排**：日／週／月三視圖，午休不壓扁，左側標 1–13 節次，視窗拉寬自動並排顯示今明兩天，**衝突選課**自動並排顯示不遮擋。

![週課表](docs/screenshots/timetable-week.png)

- **同步更快更穩 + 防社死小功能**：拿掉桌面用不上的請求，開代理時也會優先走校內直連、失敗再自動切代理，**同步成功率更高**，減少一直轉圈或教務網限頻把課表刷空（[Celechron#186](https://github.com/Celechron/Celechron/pull/186)）。成績頁右上角帶一鍵「隱藏績點」，在圖書館開著不怕被看到。

![成績與績點](docs/screenshots/grades.png)

## 快捷鍵

| 操作 | 快捷鍵 |
|---|---|
| 全域搜尋（課程 / 作業 / 考試 / 任務） | `Ctrl+K`（macOS `⌘+K`） |
| 切換 日程 / 任務 / 學業 | `Ctrl+1` ~ `3` |
| 收放右側欄 | `Ctrl+\` |
| 回到今天 / 新增任務 | `T` / `N` |
| 立即同步 | `Ctrl+R` |
| 退出詳情 / 關閉彈窗 | `Esc` |

## 下載與開啟（Windows & macOS）

使用統一身分認證（ZJUAM）學號與密碼登入。

- **Windows（10 / 11 64 位元）**：下載 [`Celechron-Setup-x64.exe`](https://github.com/8eoyw/Celechron/releases/latest/download/Celechron-Setup-x64.exe) 直接安裝，不需管理員權限也不用裝執行期元件；免安裝版 [`Celechron-Windows-x64.zip`](https://github.com/8eoyw/Celechron/releases/latest/download/Celechron-Windows-x64.zip) 需**先解壓縮**再執行 `Celechron.exe`。未購程式碼簽章，若跳出「Windows 已保護您的電腦」點 **其他資訊 → 仍要執行**。
- **macOS（10.15+，Intel / Apple 晶片通用）**：下載 [`Celechron-macOS.dmg`](https://github.com/8eoyw/Celechron/releases/latest/download/Celechron-macOS.dmg) 拖進「應用程式」。未購 Apple 簽章，首次被攔後到「系統設定 → 隱私權與安全性」點 **強制開啟**；若提示「已損毀」，在終端機執行 `xattr -cr /Applications/Celechron.app`。

## 安全說明

純本機用戶端，沒有自己的伺服器。帳密只存在本機系統加密儲存 / macOS 鑰匙圈裡，直連學校系統，原始碼全公開。

## 致謝與授權條款

本專案基於開源專案 [Celechron/Celechron](https://github.com/Celechron/Celechron)（[GPL-3.0](LICENSE)），感謝原作者 [nosig](https://github.com/nosig) 及所有貢獻者的工作。這是非官方桌面分支，桌面版問題請在 [Issues](../../issues) 回報，不要打擾原作者；手機端請繼續使用官方版。
