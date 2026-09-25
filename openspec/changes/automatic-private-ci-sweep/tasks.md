# 任務：automatic-private-ci-sweep

## 1. 每 5 分鐘 detector

- [x] 建立 `.github/workflows/detect-private-changes.yml`。
- [x] 設定 cron：`2-57/5 * * * *`。
- [x] 保留 detector 的 manual dispatch。
- [x] 加入 detector-file push trigger，供 detector 自身 regression 使用。

## 2. 變更偵測

- [x] 讀取六個 alias 的 private repository metadata。
- [x] 使用 `pushed_at` 作為保守的 private push activity 訊號。
- [x] 讀取 Public Automation-Hub 既有 `private-ci.yml` run/job history。
- [x] 以最近 CI job 的 `started_at` 判斷該次 push 是否已被涵蓋。
- [x] 無新 push → `SKIP`。
- [x] 有新 push → dispatch 對應 alias。
- [x] CI 已執行中 → `WAIT`，避免重複 queue。

## 3. 權限邊界

- [x] Private repository credential 維持 read-only。
- [x] 不新增第二顆 private token。
- [x] Detector 的 `actions: write` 僅作用於 Public Automation-Hub。
- [x] 不保存 private commit SHA 或 alias mapping 到公開檔案。
- [x] 不建立 private webhook/event bridge。

## 4. 既有 CI 行為

- [x] `private-ci.yml` 移除固定 cron 全掃。
- [x] Manual single-target dispatch 保留。
- [x] Hub workflow/adapter code push regression 保留。
- [x] 六倉 CI adapter 與 sanitized log boundary 不變。

## 5. 執行期驗證

- [x] Detector workflow 由建立 commit 自動觸發成功。
- [x] Detector run #1 結論為 success。
- [x] 第一次 detector run 在沒有新 private push 時沒有建立新的 CI workflow_dispatch run。
- [x] Detector log 未輸出 private repository 真名。
- [x] 已使用真實 private push 驗證：只有 repo-04 的 `pushed_at` 晚於最近 CI，detector 只 dispatch `repo-04`，對應 CI 最終 PASS。
- [ ] 觀察第一筆 cron event，確認 5 分鐘 schedule 正常觸發。

## 6. 先前回歸測試證據

- [x] 六倉 matrix regression run #17 全部 PASS。
- [x] run #17 log 掃描：已知 private repository 名稱命中 0。
- [x] run #17 private report 內容標記命中 0。
- [x] run #17 artifact count：0。


## 7. 真實 private push smoke test

- [x] 六倉 metadata 比對確認只有 repo-04 有晚於 regression #17 的新 push。
- [x] Detector run #2 只建立一筆新的 workflow_dispatch。
- [x] 新 run 的唯一 job 為 `CI — repo-04`。
- [x] 對應 repo-04 CI PASS。
- [x] 發現 GitHub dispatch 成功時 API 回傳 HTTP 200，但 detector 原本只接受 204。
- [x] Dispatch success 判斷改為接受所有 HTTP 2xx。
- [x] 修正後 detector run PASS。
- [x] Detector workflow 修改後 security audit PASS。
