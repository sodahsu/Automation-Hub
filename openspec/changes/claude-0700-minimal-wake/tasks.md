# 任務：claude-0700-minimal-wake

> 2026-10-23 使用者授權主代理裁決（環境收拾 session）：觸發來源改為「cron-job.org 在 07:00 Asia/Taipei 以 `workflow_dispatch` 為主、GitHub `schedule` 為備援（加冪等防呆）」。新增第 10 節記錄這次修訂；第 5、7、8 節的未完成項目已依證據更新或標記【移交使用者】。
>
> **為什麼這個 change 仍留在 active（不 archive）**：(1) 第 10 節的 implementation 還在 PR，尚未合併；(2) `openspec/project.md` 規定「仍有 runtime observation 未完成的 change 必須留在 active 區」，而外部排程的準時性（連續 3 天 07:00 ± 5 分）正是 runtime 驗收，`openspec-first-delivery` 的延後規則在 repo 規則更嚴格時不適用；(3) 沒有使用者針對本 change 的「延後歸檔」明確批准（2026-10-09 `run-private-pr-heads` 的例外是當次對話批准的，不能援引）。歸檔條件見檔尾。

## 1. Workflow 實作

- [x] 建立分支 `feat/claude-0700-wake`。
- [x] 新增 `.github/workflows/claude-0700-wake.yml`。
- [x] 設定每天 07:00、timezone `Asia/Taipei`。
- [x] 保留 `workflow_dispatch`。
- [x] 使用 GitHub-hosted `ubuntu-latest`。
- [x] 設定短 job timeout。
- [x] 加入 concurrency group，避免同一 wake job 重疊。
- [x] 補上 Claude Code Action 所需 `id-token: write`。
- [x] 第三方 Actions 固定 immutable 40 字元 commit SHA。

## 2. Claude 最小觸發

- [x] 使用 `anthropics/claude-code-action`。
- [x] OAuth secret key 指向 `CLAUDE_PISCEAN0619_OAUTH_TOKEN`。
- [x] Prompt 僅要求 `Reply exactly: OK`，並明確禁止讀檔、工具與 repository mutation。
- [x] 設定 `--max-turns 1`。
- [x] 使用低成本 Claude model。
- [x] 不加入 retry loop。

## 3. 權限與公開 Repo 安全

- [x] Workflow repository content permission 僅 `contents: read`。
- [x] `id-token: write` 僅供 OIDC 身分交換，不授予 repository content write。
- [x] Checkout 使用 `persist-credentials: false`。
- [x] 不加入 private repository credential。
- [x] 不加入 private repository alias mapping。
- [x] 不在 committed file 中保存 OAuth token value。
- [x] 不建立 repository write step。

## 4. OpenSpec

- [x] 建立 active change `claude-0700-minimal-wake`。
- [x] 建立符合 spec-driven schema 的 proposal。
- [x] 建立 requirement delta spec，含新 capability 的 Purpose。
- [x] 建立 design。
- [x] 建立 tasks checklist。
- [x] OpenSpec strict validation 通過；Run 36398605893（2026-09-28）PASS。

## 5. 帳號認證

- [ ] 5.1 確認 OAuth token 的實際 Claude 帳號為指定帳號。 — **【移交使用者】** 只有使用者能登入該 Claude 帳號查看 usage；token 在 GitHub Secret 內不可讀回。步驟與驗收條件見檔尾「使用者驗收清單」U1。
- [x] Automation-Hub 已存在可用的 `CLAUDE_PISCEAN0619_OAUTH_TOKEN`；成功 smoke test Run 36393598504 證明 credential 可用。
- [x] Run 36393598504 Actions log 中 OAuth token 顯示為 `***`，未出現明文。

## 6. Manual smoke test

- [x] 已由 `workflow_dispatch` 手動啟動；Run 36393598504。
- [x] Run 36393598504 結論為 success。
- [x] Claude step 正常完成單回合。
- [x] 無由 wake run 產生的 repository mutation。
- [x] 無額外 Agent / tool execution。
- [x] Actions log 無 OAuth token 明文洩漏。

## 7. Scheduled runtime 驗證

- [x] Workflow 已合併至 default branch 並具備 scheduled trigger。
- [ ] 7.1 在本機 Mac 關閉或不在線情況下觀察一筆 07:00 scheduled run。 — **dropped**：沒有任何 Mac 在線狀態的紀錄，無法回溯證明某次 run 時 Mac 離線；改以 7.3 的結構性證據覆蓋（runner 是 GitHub-hosted、無 self-hosted label，不依賴 Mac）。且 07:00 的主要來源已改為外部排程，「schedule 在 07:00 準時」不再是目標。
- [x] 7.2 確認 trigger event 為 `schedule`。 — 2026-09-29 至 2026-10-23 共 25 筆 run 的 event 皆為 `schedule`，證據：`evidence/scheduled-runs-2026-10-23.md`（`gh run list -R sodahsu/Automation-Hub --workflow claude-0700-wake.yml --limit 30 --json createdAt,event,conclusion,databaseId`）。
- [x] 7.3 確認 runner 為 GitHub-hosted。 — 27 筆 run 的 job 皆為 `runner_group_name: GitHub Actions`、label `ubuntu-latest`（`gh api repos/sodahsu/Automation-Hub/actions/runs/<id>/jobs`），同一份 evidence。
- [x] 7.4 記錄實際開始時間與排程延遲。 — 25 筆 schedule run 落在台北 08:28–11:15，比 07:00 晚 1 小時 28 分至 4 小時 15 分（中位數 2 小時 30 分）；cron／`timezone` 設定本身沒有寫錯。這是第 10 節的起因。
- [x] 7.5 確認 Claude request 成功。 — 25 筆 schedule run 的 `Trigger Claude for piscean0619` step conclusion 皆為 `success`。
- [ ] 7.6 外部排程觸發後的準時性。 — **【移交使用者】** 見第 10 節 10.10–10.12 與「使用者驗收清單」U2、U3；驗收條件：連續 3 天在 07:00 ± 5 分鐘觸發。

## 8. 額度行為觀察

- [ ] 8.1 僅記錄 07:00 request 對 Claude usage window 的實際結果。 — **【移交使用者】** usage window 只有在該 Claude 帳號的 Usage 頁看得到；步驟與驗收條件見「使用者驗收清單」U4。
- [ ] 8.2 不把單次觀察推論為固定 reset contract。 — **【移交使用者】** 這是對 8.1 觀察者的約束（至少連續 3 天的紀錄才下結論），與 8.1 同一份清單 U4；spec 的「Wake MUST NOT 被定義為額度 reset 保證」已涵蓋。
- [x] 若未來確認需要多階段 wake，另開 OpenSpec change，不在本 change 擴張。

## 9. 完成與歸檔

- [x] Security audit PASS；Run 36398477062（2026-09-28）PASS。
- [x] 2026-10-23 第 10 節改動後重跑：`python3 scripts/security/audit.py` PASS、`openspec validate --all --strict` PASS（指令與 exit code 見 10.8）。
- [ ] Manual smoke test、scheduled runtime 驗證與 strict validation 全部完成。 — 尚缺外部排程的 runtime 驗收（7.6、10.10–10.12）與 5.1、8.1 的使用者觀察。
- [ ] 補上 review / runtime evidence。 — 已補 `evidence/scheduled-runs-2026-10-23.md`；外部排程的 runtime evidence 待使用者驗收後補。
- [ ] 完成後才移至 `openspec/changes/archive/`。 — 歸檔條件見檔尾。

## 10. 外部排程為主、schedule 為備援（2026-10-23 使用者授權主代理裁決）

- [x] 10.1 核對 cron 時區：`0 7 * * *` + `timezone: "Asia/Taipei"` 的目標是 UTC 23:00（前一天）；25 筆 schedule run 落在 UTC 00:28–03:15，晚 1 小時 28 分至 4 小時 15 分。若 `timezone` 被忽略，run 會落在台北 15:00 之後，與觀察不符，所以不是時區寫錯，延遲來自 GitHub scheduler。不調整 cron（延遲原因無法從外部驗證）。證據：`evidence/scheduled-runs-2026-10-23.md`。
- [x] 10.2 新增 `scripts/wake/wake-guard.sh`：只對 `schedule` 事件生效；以台北日期（固定 UTC+8）查本 workflow 當日 `status=success` 的 run，再逐個查 jobs，Claude step conclusion 為 `success` 才算已喚醒；查詢失敗或回應格式不符 fail closed（不喚醒、step 失敗）。
- [x] 10.3 `.github/workflows/claude-0700-wake.yml`：加入 `Idempotency guard` step 與 `actions: read`；Claude step 加 `if: steps.guard.outputs.should_wake == 'true'`；`workflow_dispatch` 保留且不受防呆限制；Claude 請求內容（模型、prompt、`--max-turns 1`）與固定 SHA 不變。
- [x] 10.4 本機 stub 測試：`bash scripts/wake/test-wake-guard.sh` 全數通過（當日已成功 → SKIP、當日沒有 → 執行、Claude step 被跳過或失敗的 run 不算、前後一日的 run 不算、本 run 自己不算、台北 23:59:59／00:00:00 日界線、runs／jobs API 失敗與格式錯誤 → 不喚醒且 exit 1、`workflow_dispatch` 不查 API、step 名稱與 workflow 一致）。API 失敗選擇「不喚醒」的理由：誤喚醒會白燒額度而且沒有訊號，漏喚醒只是視窗晚開始且 run 紅燈可見（design 決策 8）。另做三組變異測試（API 失敗改放行、不看 Claude step 結論、對所有 event 套用防呆），測試皆能抓到。
- [x] 10.5 對真實 GitHub API 唯讀回放（把「現在」固定在歷史日期，不 dispatch、不寫入）：2026-10-23 → 命中 run 39881796745、2026-10-22 → 39703385899、2026-10-13 → 38340794666、2026-09-28 → 36393598504（同日失敗的 36393454452 沒被計入）、2026-09-27（當天沒有 run）→ 放行。確認 `created=<起>..<迄>` 區間語法與 jobs 查詢在真實 API 上可用。
- [x] 10.6 文件：`docs/external-scheduler.md` 新增「07:00 Claude wake job」（endpoint、專用 token、cron-job.org 設定、驗收、常見失敗、輪替）；`README.md` 具名例外段落同步（觸發來源、`actions: read`、外部排程 token 的殘留風險）。
- [x] 10.7 spec delta 更新（`specs/claude-minimal-wake/spec.md`）：觸發來源、冪等規則、外部排程 credential、`actions: read` 權限。維持 `ADDED`：canonical 目前沒有 `claude-minimal-wake`，沒有既有 requirement 可 `MODIFIED`，歸檔時整個 capability 一次新增。
- [x] 10.8 驗證：`python3 scripts/security/audit.py` exit 0；`openspec validate --all --strict` exit 0；5 個 workflow 皆通過 `yaml.safe_load`；`shellcheck scripts/wake/*.sh` exit 0。
- [x] 10.9 PR 合併至 `main`。 — PR #26 已於 2026-10-23T04:33:20Z 合併（merge commit `9edcad7b`）。
- [ ] 10.10 【移交使用者】建立專用 dispatch token，並在 cron-job.org 建立 07:00 job（URL、method、headers、body 見 U2）。
- [ ] 10.11 【移交使用者】首次 test run 與設定確認（U2）。
- [ ] 10.12 【移交使用者】連續 3 天 07:00 ± 5 分鐘觸發的準時性驗收（U3）；通過後把證據寫入 `evidence/`。
- [x] 10.13 合併後第一個 `schedule` run 的防呆實測：step summary 應為 `SKIP`（外部排程當天已喚醒）或 `WAKE`（當天外部排程缺席），且 `SKIP` 時 Claude step 為 `skipped`。任何人唯讀觀察即可（`gh run list` 與 `gh api .../jobs`），不需要使用者本人。 — 唯讀觀察 2026-10-24：合併後第一個 `schedule` run 是 [40048770740](https://github.com/sodahsu/Automation-Hub/actions/runs/40048770740)（2026-10-24T01:13:03Z、head `3453f32f`）；`Idempotency guard` step 成功、Claude step 為 `success`（未 skipped），屬 `WAKE` 路徑，與「外部排程當天缺席」一致（10.10–10.12 尚未做）。`SKIP` 路徑待外部排程上線後才有機會觀察。

## 使用者驗收清單（【移交使用者】項目的具體步驟）

負責者：使用者本人（需要 GitHub token 設定頁、cron-job.org 登入、Claude 帳號 Usage 頁，代理無法代勞）。這些項目都不是安全或 release-blocking 驗收，但依 `openspec/project.md` 仍會讓本 change 留在 active。

### U1（對應 5.1）：確認 OAuth token 屬於指定 Claude 帳號

1. 登入 `piscean0619` 對應的 Claude 帳號，開啟 Usage 頁（或在 Claude Code 內 `/usage`），記下目前的用量與 session reset 時間。
2. 在 GitHub Actions 手動執行一次 `Claude 07:00 Wake`（`Run workflow`，branch `main`），等 run 成功。
3. 回到同一個 Claude 帳號的 Usage 頁重新整理。
4. **驗收條件**：該帳號的用量在 dispatch 時間點之後有增加（或 session 在該時間點開始），而其他 Claude 帳號沒有。UI 的實際欄位名稱未在本環境核對（Unknown）。

### U2（對應 10.10、10.11）：建立 cron-job.org 07:00 job

**前置條件：先等 10.9 的 PR 合併。** 合併前 `main` 上的 wake workflow 沒有冪等防呆，此時建立外部排程，當天稍晚的 `schedule` 會再喚醒一次。

1. 建立專用 fine-grained personal access token：Repository 只選 `sodahsu/Automation-Hub`；Actions 選 `Read and write`；Metadata 選 `Read`；不得使用 `PRIVATE_REPOS_*`。**不要把 token 值貼進 repo、PR 或對話。**
2. 在 cron-job.org 建立 job：
   - URL：`https://api.github.com/repos/sodahsu/Automation-Hub/actions/workflows/claude-0700-wake.yml/dispatches`
   - Method：`POST`
   - Body：`{"ref":"main"}`
   - Headers：`Accept: application/vnd.github+json`、`Content-Type: application/json`、`X-GitHub-Api-Version: 2022-11-28`、`Authorization: Bearer <專用 token>`
   - Schedule：每天 07:00，Timezone `Asia/Taipei`（沒有這個選項就用 UTC 23:00）
   - Save response：Off、Failure notification：On、重試／重送：關閉
3. 按 test run。
4. **驗收條件**：cron-job.org 顯示 HTTP `204`；GitHub Actions 出現 `Claude 07:00 Wake` 的 `workflow_dispatch` run 且 success，Claude step（`Trigger Claude for piscean0619`）為 `success`。詳細說明與常見失敗見 `docs/external-scheduler.md`。

### U3（對應 7.6、10.12）：連續 3 天準時性

1. 連續 3 天，各執行一次：
   `gh run list -R sodahsu/Automation-Hub --workflow claude-0700-wake.yml --limit 10 --json databaseId,createdAt,event,conclusion`
2. **驗收條件**：每天有一個 `event=workflow_dispatch` 的 run，`createdAt` 在 UTC 22:55–23:05（= 台北 06:55–07:05），`conclusion=success`；同一天稍晚若出現 `schedule` run，其 Claude step 為 `skipped`、Summary 為 `SKIP`。
3. 通過後告知代理，補寫 `evidence/` 並歸檔。

### U4（對應 8.1、8.2）：記錄 usage window 的實際結果

1. U3 的 3 天期間，每天 07:00 之後到 07:30 之前，開啟 Claude 帳號 Usage 頁，記下 session 的 reset 時間與用量。
2. **驗收條件**：留下 3 天的紀錄（日期、wake 時間、Usage 頁顯示的 reset 時間）。結論只描述「觀察到什麼」，不宣稱固定的 07:00 reset 契約。

## 歸檔條件

下列全部完成後才 `openspec archive claude-0700-minimal-wake --yes`（**不加** `--skip-specs`，因為要把 `claude-minimal-wake` capability 新增到 canonical spec）：

1. 10.9 PR 已合併。
2. 10.10–10.13、7.6 完成並補上 evidence；5.1、8.1、8.2 由使用者完成。
3. 若使用者決定不等 5.1、8.1、8.2 就歸檔，需要使用者在對話中針對本 change 明確批准（比照 `archive/2026-10-09-run-private-pr-heads/DEFERRED.md`），歸檔時改標「歸檔時延後」並補 `DEFERRED.md`，且 SHALL NOT 宣稱這些驗證已通過。
