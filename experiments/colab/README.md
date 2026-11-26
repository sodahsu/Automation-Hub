# Google Colab 合成 Markdown 索引實驗

此資料夾是 Automation-Hub 的**公開、可手動操作的 AI 計算實驗**，不是 GitHub Actions Runner、常駐 API 或自動排程器。OpenSpec：`openspec/changes/colab-synthetic-index-poc/`。追蹤票：[Epic #36](https://github.com/sodahsu/Automation-Hub/issues/36)。

## 如何使用

1. 在 GitHub PR 分支中開啟 `synthetic_markdown_index.ipynb`，由 Google Colab 的 GitHub 匯入功能載入；先使用 CPU runtime。
2. 登入自己的 Colab，查看 **執行階段／運算單位** 頁面，確認本次是否有可用額度；**不得假設 Google AI Pro 必然已在帳戶入帳**。不啟用任何加購或自動付款。
3. 互動式逐格執行：Notebook 下載並核對本分支的 `requirements.lock` SHA-256，再安裝鎖定的全部 Python 套件，產生 120 篇**公開合成** Markdown，下載 Hugging Face 公開模型並計算向量／一次合成查詢。模型下載需要網路，不使用任何 API key。
4. 如果 Colab 有 GPU 可用，可把 `USE_GPU = False` 改成 `True` 再重新執行；否則會明確降級到 CPU。沒有 GPU 不代表失敗。
5. 檢視輸出的 `public_report`（只有欄位白名單）。若需要手動下載，於最後一格把 `SAVE_PUBLIC_REPORT = False` 改成 `True`。預設**不寫檔**。
6. 記錄開始／結束時間、CPU/GPU、Colab 畫面中人工讀取的 CU 前後值以及任何 session interruption；公開 Issue 只記錄去識別的量測結果，不貼帳戶截圖或私人資料。完成後中斷並刪除執行階段。

## 安全禁令

- **禁止** Google Drive 掛載、私有 repo clone、token / PAT、真實 private knowledge vault 筆記、真實 Embedding 或向量索引載入此 Notebook。
- **禁止**改造成 24/7 GitHub Runner、定期觸發器、反向代理、Web 服務或平台限制規避。
- 本 PoC 的 `PASS` 只代表合成資料 Notebook 成功，不代表 Automation-Hub 的 repo-01～06 CI 通過。
- Notebook 不保存 cell output。報告 `compute_units_observed = null`；實際 CU 只記在**人工審核的非公開驗收紀錄**。不會將帳戶資訊輸出公開 artifact。
- 若模型下載／編碼失敗：明確停止、無 `PASS` report。中斷時需重開 runtime，從頭執行。不要截取完整 traceback / 環境變數貼在 Public Issue。

## 驗證（本機、免網路）

```bash
python3 -m unittest discover -s experiments/colab/tests -v
```

`requirements.lock` 精確固定直接與傳遞依賴版本；本次未產生 hash lock，安裝時依固定版本安裝。核心離線測試只用 Python 標準庫；完整 fake-model 流程需要 NumPy（若未安裝會跳過該項）。離線測試**不能替代**真實 Google Colab CPU/GPU 執行。OpenSpec 嚴格驗證與 Security Audit 仍依 Hub 原有流程執行。

## 平台與模型官方文件

- [Google Colab FAQ（繁體中文）](https://research.google.com/colaboratory/intl/zh-TW/faq.html)
- [Google Colab 附加服務條款](https://research.google.com/colaboratory/intl/zh-TW/tos_v6.html)
- [all-MiniLM-L6-v2 model card（Apache-2.0）](https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2)