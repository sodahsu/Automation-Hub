---
title: "Synthetic Colab Notebook Research and Safety Contract"
tags:
  - OpenSpec/Change
  - Governance/Automation
  - Research/Colab
date: 2026-11-22
type: decision
status: active
source: ai-assisted
---

# Synthetic Colab Notebook Research and Safety Contract

## Why

Automation-Hub 的既有工作是公開、唯讀的六倉 CI 協調。GitHub Actions 分鐘額度與 Colab Compute Units 是不同資源；將 Colab 接為常駐 runner 不符合互動式用途與穩定性需求。需要一個可驗證的、與私有 CI 完全隔離的實驗，評估 CPU/GPU 批次 Embedding 是否有價值。

## What Changes

- 新增手動執行的 Google Colab Python Notebook，僅產生公開合成 Markdown 文件、Embedding 和合成索引查詢。
- 新增僅由固定白名單欄位組成、可手動匯出的 public-safe JSON 報告；不得包含內容、向量、原始路徑或自由格式例外。
- 新增離線測試、操作手冊、權益／成本／政策檢查表，標明雲端實測待驗證。
- 不接入既有 GitHub Actions，不新增 workflow，不變更 detector、runner、PR status、Secrets、權限、計費或私有 repo。

## Capabilities

新增 `colab-synthetic-index` capability，定義輸入隔離、模型執行、報告安全及失敗語意。

## Impact

- 只影響 `experiments/colab/**`、`docs/colab-evaluation-2026-11.md` 與本次 OpenSpec。
- GitHub 上的 PR 可以對規格執行既有 strict validation；Notebook 真正的 Colab CPU/GPU live smoke、實際 CU 用量及帳戶方案仍需本人操作，未經證據不得標完成。
- 使用的 Hugging Face 模型為 `sentence-transformers/all-MiniLM-L6-v2`（Apache-2.0），互動時會下載公開模型，不使用 API 金鑰。

## Tracking

Epic #36；子票 #37～#41；依存的 CI evidence/security 改良 #34 只作參考、不修改其範圍。