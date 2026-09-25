# 任務：automatic-private-ci-sweep

## 1. 每 5 分鐘 detector

- [x] 建立 `.github/workflows/detect-private-changes.yml`。
- [x] 設定 cron：`*/5 * * * *`。
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
- [x] 觀察第一筆 cron event：2026-09-25 12:03 UTC 出現第一筆 `event: schedule` 並 success；但僅此一筆，仍不作為唯一喚醒機制（見第 9 段）。

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


## 8. 六倉更新觸發 CI 證據

- [x] repo-01 private repo 有新 push → detector dispatch `CI — repo-01` → PASS。
- [x] repo-02 private repo 有新 push → detector dispatch `CI — repo-02` → PASS。
- [x] repo-03 private repo 有新 push → detector dispatch `CI — repo-03` → PASS。
- [x] repo-04 先前真實 private push smoke test → detector 只 dispatch `CI — repo-04` → PASS。
- [x] repo-05 private repo 有新 push → detector dispatch `CI — repo-05` → PASS。
- [x] repo-06 private repo 有新 push → detector dispatch `CI — repo-06` → PASS。
- [x] 最近一次五倉 hardening 後，detector 只 dispatch 有變更的 repo-01 / 02 / 03 / 05 / 06；未變更的 repo-04 沒有被多跑。
- [x] 這 5 筆 Public CI log：已知 private repository 名稱命中 0、private report marker 命中 0、Artifact count 0。
- [x] GitHub 原生 schedule 經多輪與 fresh probe workflow 驗證仍為 0 筆 event；已判定不可作為唯一 wakeup mechanism，改採 external scheduler fallback。


## 9. 外部排程備援

- [x] 建立獨立 schedule probe 與全新 workflow ID 驗證 GitHub Scheduler。
- [x] 多輪觀察仍為 0 筆 `event: schedule`，排除 detector script / Secret / private CI 邏輯。
- [x] 測試 Vercel Cron fallback。
- [x] 確認目前 Vercel plan 不接受每 5 分鐘 Cron；加入 `*/5` 後 deployment failure，已完整還原。
- [x] 建立 `docs/external-scheduler.md`，定義 external HTTP scheduler fallback。
- [x] External scheduler 僅 dispatch Public detector，不取得 private repo mapping / read token。
- [x] 建立專用 fine-grained token「Automation-Hub external scheduler」：2026-09-25 於 GitHub 設定頁確認 Repository access 僅 `sodahsu/Automation-Hub`，Repository permissions 僅 Actions Read and write + Metadata Read，無 user permissions，2026-12-24 到期。
- [x] 在 external scheduler 建立每 5 分鐘 POST job：2026-09-25 12:15 / 12:20 / 12:25 / 12:30 UTC 連續出現 `workflow_dispatch` detector run，間隔 5 分鐘，皆 success。
- [x] 驗證 external request → `workflow_dispatch` → detector → changed alias CI 的完整鏈路：12:30 detector run 只 dispatch `CI — repo-02`（private-ci run #30）→ PASS；12:34 手動 dispatch 在無新 push 時未建立 CI run；三份 log 已知 private repository 名稱命中 0，Artifact count 0。
