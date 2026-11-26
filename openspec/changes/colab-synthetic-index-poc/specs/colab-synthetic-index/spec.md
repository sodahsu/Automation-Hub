# colab-synthetic-index Specification

## Purpose

定義 Automation-Hub 可手動在 Google Colab 執行的公開合成 Markdown 索引實驗，以及不觸碰私有 CI 的資料／證據安全邊界。

## ADDED Requirements

### Requirement: Colab PoC SHALL remain interactive and isolated

The PoC SHALL be a manually initiated notebook using only locally generated synthetic data. It SHALL NOT register a CI runner, serve a background service, schedule automated work, mount Drive, read private repositories, or require secrets.

#### Scenario: User opens the notebook

- **WHEN** a user opens the Public notebook interactively
- **THEN** all source documents SHALL be generated in memory and explicitly marked synthetic
- **AND** the notebook SHALL NOT acquire private repository credentials or modify any CI status

### Requirement: Synthetic input SHALL fail closed

The PoC SHALL reject non-synthetic and malformed documents prior to encoding or exporting results. External private inputs SHALL NOT be supported by the PoC.

#### Scenario: An unmarked document is passed to the validator

- **WHEN** any document lacks the synthetic marker or contains an invalid structure
- **THEN** validation SHALL raise an error before embedding or report generation

### Requirement: Embedding experiment SHALL be bounded and reproducible

The PoC SHALL generate a bounded fixture of at least 100 synthetic Markdown documents, record the model identifier and resolved revision, prefer CPU, permit optional GPU, and use a public model without an API key.

#### Scenario: GPU is unavailable

- **WHEN** the user requests GPU but the runtime reports no GPU
- **THEN** the experiment SHALL use CPU with a visible fallback indication
- **AND** it SHALL NOT claim the GPU path was exercised

#### Scenario: Model download fails

- **WHEN** model acquisition or encoding fails
- **THEN** the notebook SHALL stop without a successful result report
- **AND** it SHALL NOT print raw private exceptions or environment variables

### Requirement: Public report SHALL be strictly allowlisted

The report SHALL include only approved schema fields and SHALL reject unknown keys and arbitrary textual output. A local-only, optional manual download MAY be provided.

#### Scenario: Valid synthetic experiment finishes

- **WHEN** the experiment completes document validation, vector encoding and query smoke checks
- **THEN** the report SHALL record synthetic counts, runtime mode, model identifier/revision, elapsed duration and PASS status
- **AND** raw Markdown, embeddings, query texts and private paths SHALL NOT appear in the report

#### Scenario: Additional field is inserted

- **WHEN** report validation detects an extra field or invalid type
- **THEN** report export SHALL fail closed

### Requirement: PoC evidence SHALL NOT impersonate existing CI

The PoC SHALL NOT change Automation-Hub's detector, CI adapter, private commit status, artifacts or six-repo mapping.

#### Scenario: Notebook succeeds while private CI did not run

- **WHEN** a synthetic notebook execution reports PASS
- **THEN** the result SHALL be labeled `colab-synthetic-poc` only
- **AND** it SHALL NOT imply a private repository CI pass