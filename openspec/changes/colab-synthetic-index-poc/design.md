# Design: colab-synthetic-index-poc

## 決策 1：Colab 是人工啟動的實驗室，不是 Runner

選擇可從 GitHub Public branch 手動開啟的 `.ipynb`，不開放 Web server、背景常駐、reverse tunnel、排程自啟與自動回寫 GitHub。VM 可能中斷，不以 notebook success 代表六倉 CI PASS。

## 決策 2：只使用程式產生的公開合成資料

測試集固定由 Notebook 在記憶體產生（>=100 篇），每個文件都含 `SYNTHETIC_PUBLIC_DEMO` 標記；不接受任何使用者輸入路徑、Drive mount、GitHub token、private checkout 或 ObsidianBook 原文。標記不能作為通用資料防洩漏保證，安全性來自**沒有讀取外部私有資料的輸入介面**。不得拿真實私有筆記複製貼入 Notebook。

## 決策 3：公開模型與 CPU 優先

使用 Hugging Face 公開 Apache-2.0 模型 `sentence-transformers/all-MiniLM-L6-v2`，查詢當次解析到的模型 commit SHA，再以 revision 固定該次執行；Python 套件指定固定版本。預設 CPU；只有使用者主動改 `USE_GPU=True` 且可用時才使用 GPU。模型不可下載時停止並顯示固定、無敏感資料的錯誤字串；不偽裝成功。

## 決策 4：去敏 report 是白名單而非過濾原始 log

報告只包含固定 schema、enum、整數、布林及測試耗時。沒有 `source_text`、`query_text`、`path`、`embedding`、`token`、`repo_name`、`private_sha`、`error_detail`，也不寫入未經審查的 model outputs。CU 只有在本人從 Colab UI 實測後才記錄，Notebook 的 `compute_units_observed` 固定為 `null`。

## 決策 5：區分工具功能與現場驗證

離線測試驗證資料產生、fail-closed、報告 schema 與 notebook 結構；不將其宣稱為 live Colab／Embedding 模型測試。Colab runtime、模型下載、CU、GPU 實測與獨立安全審查仍為待完成，未達成不得 archive change。

## 風險與回滾

- 執行錯誤：Notebook 停止、不產生 PASS 報告；session 中斷需重啟完整執行。
- 資源／金額風險：CPU 預設、無自動加購；無可用 CU 時使用者自行停止。
- 敏感資料風險：PoC 沒有 private input；任何提案加入 private source、Drive 或 credentials 均須另外開 OpenSpec 安全評估。
- 回滾：關閉 Colab runtime、刪除暫存報告、關閉 PR／移除分支即可；既有 CI 不受影響。

## 來源

- https://research.google.com/colaboratory/intl/zh-TW/faq.html
- https://research.google.com/colaboratory/intl/zh-TW/tos_v6.html
- https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2