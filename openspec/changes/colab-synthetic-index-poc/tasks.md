---
title: "Synthetic Colab Notebook Research Tasks"
tags:
  - OpenSpec/Tasks
  - Research/Colab
date: 2026-11-22
type: workflow
status: active
source: ai-assisted
---

# Synthetic Colab Notebook Research Tasks

## Phase 0 — 政策與可行性

- [x] 0.1 讀取 Colab 官方 FAQ／服務條款與公開模型授權。
- [x] 0.2 訂定不將 Colab 作為 24/7 CI Runner，使用 CPU 優先、人工啟動的設計。
- [ ] 0.3 使用者親自確認 AI Pro／Colab Compute Units 實際餘額、可用 GPU（不公開帳戶資料）。

## Phase 1 — OpenSpec 與安全界線

- [x] 1.1 閱讀 Hub README、SECURITY、openspec/project 與現有規格。
- [x] 1.2 完成 proposal、design、spec delta 與測試條件。
- [x] 1.3 OpenSpec strict validation 經 GitHub PR check 通過（PR #42 run #98，2026-11-22）。
- [x] 1.4 安全 reviewer 獨立審查 no-private-data 與 notebook output；依賴 pinning 修正與驗證紀錄見 `evidence/dependency-pinning-2026-11-27.md`。

## Phase 2 — Notebook 與報告

- [x] 2.1 建立合成資料產生器、驗證器（>=100 篇、malformed / unmarked fail closed）。
- [x] 2.2 建立公開模型 Embedding 實驗與 CPU 預設、GPU 可選、無 GPU 降級路徑。
- [x] 2.3 建立 public-safe schema 與 report validator、人工下載選項。
- [x] 2.4 建立標準庫離線單元測試、可選 NumPy 的 mock 全流程測試及 notebook 結構檢查。
- [ ] 2.5 實際 Colab CPU 互動執行、乾淨重啟重現與中斷情境驗收。
- [ ] 2.6 GPU 可用時的選配比較與 Compute Units 觀察（如不可用須記錄 SKIP）。

## Phase 3 — 完成評估與交付

- [x] 3.1 提供操作手冊、驗收表、成本比較範本與回滾方法。
- [ ] 3.2 填寫實測執行時間、模型 revision、CU 等資料，明確標示未測值。
- [ ] 3.3 獨立 review，PR 保持未合併；未完成實測前不 archive。

## 驗證命令（線下）

~~~bash
python3 -m unittest discover -s experiments/colab/tests -v
python3 scripts/security/audit.py
npx --yes @fission-ai/openspec@1.8.0 validate --all --strict --json
~~~

若環境無法安裝 npm / Colab 套件，不得將未實際執行的命令標記完成；以 PR check 與本人 Colab live smoke 補證據。

## 2026-11-27 本機驗證紀錄

- [x] 固定 Hugging Face revision 為 `1110a243fdf4706b3f48f1d95db1a4f5529b4d41`，執行期不使用 `model_info` 動態解析。
- [x] 完整依賴版本鎖 `experiments/colab/requirements.lock`，Notebook 安裝前核對鎖檔 SHA-256。
- [x] 離線測試：exit 0（11 tests；10 passed、1 skipped，因環境未安裝 NumPy）。
- [x] `scripts/security/audit.py`：exit 0。
- [x] OpenSpec strict validate：exit 0（4/4 items passed）。
- [ ] 未執行 Colab live run；CU 與 CPU/GPU 實測仍待人工驗收。詳見 `evidence/dependency-pinning-2026-11-27.md`。