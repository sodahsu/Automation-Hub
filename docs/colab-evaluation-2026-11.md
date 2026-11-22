# Google Colab 與 Automation-Hub 運算使用場景評估（2026-11-22）

> 狀態：**設計與離線 PoC 已準備；Colab 帳號及雲端實測未完成**。此份文件不宣稱使用者有何種訂閱或剩餘運算額度。對應 Epic #36、子票 #37～#41。

## 官方可驗證事實

- Colab 以互動式運算為優先，無保證的 VM / GPU 資源，閒置時可被終止；不適用作永續的自動 Runner。來源：<https://research.google.com/colaboratory/intl/zh-TW/faq.html>（查核 2026-11-22）。
- Colab 提供付費服務時仍受附加服務條款及平台限制拘束。來源：<https://research.google.com/colaboratory/intl/zh-TW/tos_v6.html>（條款標示更新 2026-08-13；查核 2026-11-22）。
- 選用公開 Embedding 模型 `sentence-transformers/all-MiniLM-L6-v2`，模型卡標示 Apache-2.0。來源：<https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2>（查核 2026-11-22）。
- Google AI 方案與 Colab 專屬訂閱可能影響可用 Compute Units；**個別帳戶餘額只能由使用者登入查核**。

## 工作負載分類

| 工作 | Mac Runner | Colab | GitHub-hosted Runner |
| --- | --- | --- | --- |
| Vue / Vite lint、test、build | 第一順位 | 不推薦 | Mac 不在線時的既有 CI 備援 |
| 交互式公開 Embedding 實驗 | 可當 CPU baseline | 合適，手動啟動 | 不推薦 GPU 實驗 |
| 合成 Markdown 批次索引 | 可跑 Python | 合適，CPU / GPU 比較 | 只適合有明確腳本的短期 CI |
| 私有 private knowledge vault 原文索引 | 可在授權的本機隔離執行 | **首期禁止輸入** | 僅依既有安全合約處理 |
| 24/7 排程、隨時接單、CI fallback | Self-hosted Runner 受開機狀態限制 | **不適合** | 使用現有 Hub，遵守 GitHub 限額及平台政策 |

## Baseline（全部尚待實測）

| 量測 | Mac CPU | Colab CPU | Colab GPU | GitHub-hosted |
| --- | --- | --- | --- | --- |
| 120 synthetic docs embedding / query time | 待測 | 待測 | 待測／無 GPU 則 SKIP | 不納入首期 |
| 冷啟動 + 模型下載時間 | 待測 | 待測 | 待測 | 不納入首期 |
| CU / Actions minutes 消耗 | 不是 Colab CU | **需從 UI 人工記錄** | **需從 UI 人工記錄** | 依公開／私有 workflow 計量方式另查 |
| 中斷與重跑 | 待測 | 待測 | 待測 | 不納入首期 |
| 資料安全與人工成本 | 本機權限／依賴管理 | 公開合成資料、需人工啟動 | 同左 | Hub 既有契約 |

請使用**同一份合成資料、相同模型 revision 及版本**再比較執行時間；Notebook 內包含可重現生成器。不得在沒有實測前填入速度、CU 或成本。GitHub Actions 分鐘數與 Colab Compute Units 不可互相抵扣。

## GO / NO-GO 判準

- **GO（互動式 PoC）**：有使用者可用額度，模型下載與 CPU 運作正常，安全報告 schema 驗證通過，沒有私有輸入。
- **GO（GPU 選配）**：GPU 可用，實測同模型基準且效益抵得過 CU 消耗；否則維持 CPU。
- **NO-GO（Colab 整合為 Hub Runner）**：需要 24/7 常駐、遠端自動觸發、長期擁有特定 VM／GPU、私有程式碼執行或將 private embedding 上傳。
- **另案討論**：未來若需要保證自動派工，另評估合規的正式受管計算平台（例如 GCP 工作負載），另開 Epic + OpenSpec、安全／金額審核。

## 人工驗收與回滾

1. 本人在 Colab 確認訂閱與運算單位（不貼帳戶截圖）。
2. CPU 第一次完整執行、乾淨 runtime 第二次重跑；保存只含白名單欄位的 report。
3. 故障案例：無模型連線、無 GPU、手動中斷、內容安全測試（離線測試足以覆蓋的部分註明）。
4. 安全 reviewer 檢查 Public PR / log / notebook 無私有源碼、筆記或 credential；嚴格 OpenSpec 驗證通過。
5. 不需要／發現問題：停止 runtime、刪除暫存報告，關閉 PR 或移除工作分支；既有 Hub workflow 完全不變。未完成實際 Colab 驗收前，不勾完所有 tasks，也不歸檔 OpenSpec。