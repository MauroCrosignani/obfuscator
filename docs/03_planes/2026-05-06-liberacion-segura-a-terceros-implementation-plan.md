# Liberacion Segura a Terceros Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reorient ObfuscatoR from a dual-purpose obfuscation studio into a defensible third-party release tool with a single coherent UI, blocked-by-default export flow, and auditable release decisions.

**Architecture:** Keep the existing transformation core in `R/obfuscator_core.R`, but do **not** let the release-decision model live primarily inside `R/shiny_app.R`. First define a shared, pure release contract and helper layer that can be consumed consistently by the Shiny app, generated R code, and direct script/package usage. The implementation should proceed in phases: first lock the shared contract and continuity constraints, then stabilize UI contradictions, then introduce risk and release-state behavior, then wire manual review and reporting, and only afterwards refine generated outputs and README alignment.

**Tech Stack:** R, Shiny, base R, testthat, existing local JS/CSS assets under `www/`

---

## File Structure

### Existing files to modify
- `R/shiny_app.R`
  - Current Shiny UI, server state, code generation, role classification, persistence hooks, and export controls.
  - Will become the main integration point for the release-decision flow.
- `R/obfuscator_core.R`
  - Existing transformation and privacy engine.
  - Will be reused, with narrowly scoped extensions for release metadata, report helpers, and API-level alignment required by the new release model.
- `tests/testthat/test_obfuscator.R`
  - Current automated coverage for core and UI-adjacent helpers.
  - Will receive regression tests for new release-state behavior and new helper functions extracted from the UI/server.
- `www/app.css`
  - Styling for cards, panels, role zones, tooltips, and controls.
  - Will be simplified to support one parameters flow and new release-state visuals.
- `www/app.js`
  - Current client behavior for theme, drag/drop, hierarchy interactions, and copy fallback.
  - Should only be changed when UI interactions require it; avoid adding decision logic here if it belongs in R.
- `README.md`
  - Public description of the product.
  - Must be updated only after the new model is implemented enough to avoid overpromising.
- `README_gitlab.md`
  - Corporate-oriented README variant.
  - Must be checked for alignment after the release model is live.

### Existing files to use as normative context
- `ESPECIFICACION_DE_REQUERIMIENTOS_v3.1.md`
- `docs/AUDITORIA_ESTADO_ACTUAL_2026-05-06.md`
- `docs/superpowers/specs/2026-05-06-liberacion-segura-a-terceros-design.md`
- `docs/2026-05-09_Contraste entre Spec v3.1 e Investigación de Anonimización.md`

### New files to create
- `R/release_decision_helpers.R` (strongly recommended)
  - Pure helper layer for release states, alert objects, manual review evidence, artifact typing, and export gating.
  - Prefer this over allowing release-decision logic to accumulate deeper inside the Shiny server block.
- `tests/testthat/test_release_decision.R`
  - Dedicated tests for release-state helpers, risk blocking logic, and release/export gating.
- `tests/testthat/test_release_contract.R`
  - Cross-path contract tests asserting the same release semantics across UI-facing helpers, generated code metadata, and direct API/script usage.
- `tests/testthat/test_persistence_release_flow.R`
  - Dedicated tests for JSON persistence, fuzzy suggestions, and their interaction with release-state behavior.
- `tests/testthat/test_release_realistic_scenarios.R`
  - End-to-end fixture-style tests covering at least one clearly releasable scenario and one clearly non-releasable scenario.
- `docs/superpowers/specs/2026-05-06-liberacion-segura-a-terceros-review-notes.md` (optional if needed during implementation)
  - Use only if implementation reveals spec ambiguities that require documented resolution.

### Strong recommendation before coding
- Extract pure helper functions from `R/shiny_app.R` rather than letting release logic sprawl deeper into the server block.
- Prefer a small, focused extraction such as `R/release_decision_helpers.R` as soon as the release contract becomes real. This is not an optional cleanup if `R/shiny_app.R` starts acting as policy engine, state machine, and integration bus at once.
- Treat persistence/fuzzy continuity as a contract-preservation concern, not as late polish.
- Treat realistic release fixtures as part of the minimum proof burden. The implementation is not done when it can block; it is done when it can also demonstrate credible `Liberable` and `No liberable sin rediseno` outcomes on realistic scenarios.

---

## Premortem-driven adjustments

This section supersedes any implied assumption that task numbering alone defines the safest execution order.

### Critical blind spots exposed by the premortem
- The release model can fragment across Shiny UI, generated R code, and direct API usage unless a shared contract is defined first.
- `R/shiny_app.R` can become an unstable policy engine if release semantics are implemented mainly through reactive patches.
- Persistence JSON and fuzzy matching are part of the product's continuity contract and must not be treated as a late alignment task.
- Auditability can become superficial if review objects do not capture alert-specific evidence, before/after state, and reevaluation results.
- The plan can overfit to blocking/reporting logic without proving that real datasets can be transformed into defensibly releasable outputs.
- The implementation can falsely equate `k-anonymity` with release approval unless risk residual, class homogeneity, and external linkability are tested explicitly.
- The product can look methodologically stronger than it is if it blocks text fields and risky combinations but never exercises attacker-style validation or realistic non-release proofs.

### Revised execution order
Execute the work in this order even if some later task numbers remain for readability:
1. Shared release contract and cross-path tests.
2. Realistic scenario fixtures and baseline proof cases.
3. Persistence/fuzzy continuity baseline.
4. Canonical parameter defaults and dataset naming.
5. Removal of duplicate parameter controls.
6. Release states and artifact separation.
7. High-risk heuristics and combination checks.
8. Manual review evidence model.
9. Release and non-release reports.
10. Generated code and API alignment.
11. Full verification.
12. README alignment.

## Phase Overview

### Phase 0: Lock the shared contract before UI rewiring
Outcome:
- Canonical shared definitions for release state, release verdict, alert object, manual review evidence, and artifact type.
- At least one cross-path test asserting the same release semantics across UI helpers, generated code metadata, and direct API/script usage.
- At least one realistic releasable fixture and one realistic non-releasable fixture defined early enough to steer implementation.
- A testing direction that explicitly distinguishes formal threshold checks from residual-risk validation.

### Phase 1: Preserve continuity and remove current UI contradictions
Outcome:
- One coherent parameters flow in the app.
- No duplicate input IDs.
- Dataset name bug fixed.
- Persistence JSON and fuzzy recovery remain intact while the UI is being simplified.
- UI semantics aligned with the new product purpose.

### Phase 2: Introduce release-state model and export gating
Outcome:
- Explicit release states.
- Export blocked unless state is `Liberable`.
- Internal preview/output separated from third-party releasable output.
- The same release verdict is representable outside the Shiny app.

### Phase 3: Add risk review workflow
Outcome:
- High-risk columns and risky combinations can block release.
- Manual review becomes active and auditable.
- The app can explain why it blocked release.
- Review evidence is reconstructible per alert, not just per session.
- Residual-risk checks cover more than `k`, including attacker-plausible linkability and homogeneity-style failures.

### Phase 4: Align artifacts and communications
Outcome:
- Persistence and fuzzy recovery remain intact under the new release model.
- Script, package, and app commitments remain aligned.
- Code generation, README(s), and docs match the new release model.
- The product can show both a credible `Liberable` example and a credible `No liberable sin rediseno` example.
- No misleading “IA-friendly” overpromises remain.

---

### Task 0: Define the shared release contract and prove it across paths

**Files:**
- Create: `R/release_decision_helpers.R`
- Create: `tests/testthat/test_release_contract.R`
- Create: `tests/testthat/test_release_realistic_scenarios.R`
- Modify: `R/obfuscator_core.R` only if helper exposure is needed for direct API/script alignment
- Test: `tests/testthat/test_release_contract.R`
- Test: `tests/testthat/test_release_realistic_scenarios.R`

- [ ] **Step 1: Write failing contract tests before touching the UI**

Cover at least:
- canonical release-state shape
- canonical alert shape
- canonical manual-review evidence shape
- canonical artifact typing (`preview`, `internal_work`, `releasable_external`)
- one assertion that the same scenario yields the same release verdict in UI-facing helpers and direct API/script-facing helpers
- one assertion that release approval is a stronger claim than mere transformation success

- [ ] **Step 2: Define realistic baseline fixtures**

Create at least:
- one realistic scenario that should become `Liberable`
- one realistic scenario that should become `No liberable sin rediseno`
- fixtures should involve dates, distinctive numerics, rare categories, or text-like risk where relevant
- whenever possible, fixtures should already be shaped so they can later support residual-risk tests such as homogeneity, unique combinations, or temporal overprecision

- [ ] **Step 3: Run the new tests and confirm failure**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_release_contract.R')"
Rscript -e "library(testthat); test_file('tests/testthat/test_release_realistic_scenarios.R')"
```

- [ ] **Step 4: Implement the minimal pure contract layer**

Prefer a focused file such as `R/release_decision_helpers.R`. The goal here is not UI behavior yet; it is one shared semantic contract.

- [ ] **Step 5: Re-run the contract tests**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_release_contract.R')"
Rscript -e "library(testthat); test_file('tests/testthat/test_release_realistic_scenarios.R')"
```

- [ ] **Step 6: Commit**

```bash
git add R/release_decision_helpers.R R/obfuscator_core.R tests/testthat/test_release_contract.R tests/testthat/test_release_realistic_scenarios.R
git commit -m "feat: define shared release contract"
```

---

### Task 1: Lock the spec and doc baseline into tests and helper expectations

**Files:**
- Modify: `tests/testthat/test_obfuscator.R`
- Test: `tests/testthat/test_obfuscator.R`

- [ ] **Step 1: Add a regression test for the current documented bug around duplicated parameter semantics**

Write a new test block that asserts the app helper layer must expose only one canonical set of parameter defaults for:
- `k_value`
- `id_prefix`
- `project_key`
- `numeric_mode`

The test can start as a failing test against a small helper you will introduce later, for example:

```r
test_that("release UI uses one canonical parameter configuration", {
  cfg <- studio_parameter_defaults()
  expect_equal(cfg$k_value, 5)
  expect_equal(cfg$id_prefix, "999")
  expect_null(cfg$project_key)
  expect_equal(cfg$numeric_mode, "range_random")
})
```

- [ ] **Step 2: Add a regression test for dataset naming in the hero state**

Use a pure helper expectation instead of testing the full live app:

```r
test_that("dataset display name comes from the loaded source", {
  expect_equal(resolve_dataset_display_name("environment", object_name = "iris"), "iris")
  expect_equal(
    resolve_dataset_display_name("file", file_name = "personas.xlsx"),
    "personas.xlsx"
  )
})
```

- [ ] **Step 3: Run the focused tests and verify they fail**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_obfuscator.R')"
```

Expected:
- new tests fail because helpers do not exist yet

- [ ] **Step 4: Commit the failing-test checkpoint**

```bash
git add tests/testthat/test_obfuscator.R
git commit -m "test: define canonical release UI expectations"
```

---

### Task 2: Introduce canonical UI helper defaults and dataset-name resolution

**Files:**
- Modify: `R/shiny_app.R`
- Test: `tests/testthat/test_obfuscator.R`

- [ ] **Step 1: Add pure helper functions near other top-level UI helpers**

Add small focused helpers such as:

```r
studio_parameter_defaults <- function() {
  list(
    seed = 123,
    id_prefix = "999",
    project_key = NULL,
    numeric_mode = "range_random",
    k_value = 5,
    k_suppression = "rows",
    group_ids = FALSE
  )
}

resolve_dataset_display_name <- function(source_mode, object_name = NULL, file_name = NULL) {
  if (identical(source_mode, "environment") && nzchar(object_name %||% "")) {
    return(object_name)
  }
  if (identical(source_mode, "file") && nzchar(file_name %||% "")) {
    return(file_name)
  }
  "Ninguno"
}
```

- [ ] **Step 2: Update the current `load_data` flow to store a source display name**

Use a dedicated `reactiveVal()` such as `loaded_dataset_name <- shiny::reactiveVal("Ninguno")`, and set it inside `observeEvent(input$load_data, ...)`.

- [ ] **Step 3: Update the hero chip UI to read from the new reactive state**

Stop using `input$dataset_name`. Replace it with the canonical reactive value.

- [ ] **Step 4: Run the focused tests and verify they pass**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_obfuscator.R')"
```

Expected:
- helper tests pass

- [ ] **Step 5: Commit**

```bash
git add R/shiny_app.R tests/testthat/test_obfuscator.R
git commit -m "fix: add canonical dataset naming and parameter defaults"
```

---

### Task 3: Remove the duplicate parameters panel and define a single release-oriented parameters block

**Files:**
- Modify: `R/shiny_app.R`
- Modify: `www/app.css`
- Test: `tests/testthat/test_obfuscator.R`

- [ ] **Step 1: Add a failing UI-render test asserting only one `Parametros` block**

Example:

```r
test_that("the main UI renders a single parameters section", {
  ui_text <- paste(capture.output(print(run_obfuscator_app_ui_for_test())), collapse = "\n")
  expect_equal(length(gregexpr("Parametros", ui_text)[[1]]), 1)
})
```

If the full app UI is too heavy to test directly, extract a small `build_release_parameters_card()` helper and test that instead.

- [ ] **Step 2: Run the UI-focused test to confirm failure**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_obfuscator.R')"
```

- [ ] **Step 3: Refactor `R/shiny_app.R` to build one canonical parameters card**

Target structure:
- one card for release controls
- one location for seed / id prefix / project key / numeric mode
- one explicit `k-anonymity` section tied to third-party release
- no duplicated `inputId`

Recommended canonical defaults:
- `seed = 123`
- `id_prefix = "999"`
- `project_key = NULL`
- `numeric_mode = "range_random"`
- `k_value = 5`
- `k_suppression = "rows"`

- [ ] **Step 4: Ensure labels match one meaning each**

Examples:
- `Prefijo de IDs`
- `Llave del proyecto`
- `Modo numerico general`
- `Valor de k`
- `Supresion residual`

Do not keep multiple labels for the same underlying setting.

- [ ] **Step 5: Adjust CSS only as needed**

Use `www/app.css` only to preserve clean layout after the duplicate card is removed. Do not start a cosmetic redesign here.

- [ ] **Step 6: Re-run the focused tests**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_obfuscator.R')"
```

- [ ] **Step 7: Commit**

```bash
git add R/shiny_app.R www/app.css tests/testthat/test_obfuscator.R
git commit -m "refactor: unify release parameter controls"
```

---

### Task 4: Create a release-state helper layer

**Files:**
- Create: `tests/testthat/test_release_decision.R`
- Modify: `R/release_decision_helpers.R`
- Modify: `R/shiny_app.R`
- Test: `tests/testthat/test_release_decision.R`

- [ ] **Step 1: Write failing tests for release states and transitions**

Cover:
- initial state
- transition to `En revision`
- transition to `Bloqueado`
- transition to `Liberable`
- transition to `No liberable sin rediseno`
- restart from `No liberable sin rediseno` only after material changes

Example:

```r
test_that("release state starts as not evaluated", {
  st <- initial_release_state()
  expect_equal(st$status, "No evaluado")
  expect_false(st$can_export_external)
})
```

```r
test_that("blocked state cannot export", {
  st <- build_release_state("Bloqueado", reasons = list("texto libre"))
  expect_false(st$can_export_external)
})
```

- [ ] **Step 2: Run the new test file to confirm failure**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_release_decision.R')"
```

- [ ] **Step 3: Implement minimal helper functions in the shared helper layer**

Add pure functions such as:
- `initial_release_state()`
- `build_release_state(status, reasons = list(), metadata = list())`
- `can_export_external_release(state)`
- `transition_release_state(current_state, event, context = list())`

Keep them pure and small. Default to `R/release_decision_helpers.R` unless a narrower existing helper location is clearly better.

- [ ] **Step 4: Wire these helpers into server state**

Introduce one dedicated `reactiveVal()` for release state instead of inferring release/export status from scattered inputs.

- [ ] **Step 5: Re-run the release-state tests**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_release_decision.R')"
```

- [ ] **Step 6: Commit**

```bash
git add R/shiny_app.R tests/testthat/test_release_decision.R
git commit -m "feat: add release state model"
```

---

### Task 5: Separate internal artifacts from third-party export

**Files:**
- Modify: `R/shiny_app.R`
- Modify: `tests/testthat/test_release_decision.R`
- Test: `tests/testthat/test_release_decision.R`

- [ ] **Step 1: Add failing tests for internal vs external artifacts**

Cover:
- preview is allowed while blocked
- external export is not allowed while blocked
- internal transformed output is not automatically marked releasable

Example:

```r
test_that("internal preview does not imply releasable export", {
  st <- build_release_state("Bloqueado", metadata = list(has_internal_preview = TRUE))
  expect_true(st$metadata$has_internal_preview)
  expect_false(can_export_external_release(st))
})
```

- [ ] **Step 2: Implement explicit server behavior**

Use separate concepts for:
- live preview
- transformed internal artifact
- external download/save eligibility

Do not let `obfuscated_data()` alone imply release approval.

- [ ] **Step 3: Disable external export actions when state is not `Liberable`**

At minimum, gate:
- `download_csv`
- any “save for release” action

If environment save remains available, it must be labeled clearly as internal/non-liberating unless later design says otherwise.

- [ ] **Step 4: Re-run focused tests**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_release_decision.R')"
```

- [ ] **Step 5: Commit**

```bash
git add R/shiny_app.R tests/testthat/test_release_decision.R
git commit -m "feat: separate internal artifacts from releasable export"
```

---

### Task 6: Add high-risk column heuristics

**Files:**
- Modify: `R/shiny_app.R`
- Modify: `tests/testthat/test_release_decision.R`
- Test: `tests/testthat/test_release_decision.R`

- [ ] **Step 1: Write failing tests for nominal high-risk detection**

Include the newly approved patterns:

```r
test_that("nominal high-risk detector includes approved patterns", {
  cols <- c("pers_id", "emp", "telefono", "comentario", "monto")
  flagged <- detect_high_risk_name_patterns(cols)
  expect_true(all(c("pers_id", "emp", "telefono", "comentario") %in% flagged))
  expect_false("monto" %in% flagged)
})
```

- [ ] **Step 2: Write failing tests for text-like columns**

Example:

```r
test_that("text-like long fields are flagged for review", {
  df <- data.frame(observacion = c("texto largo uno", "texto largo dos"), stringsAsFactors = FALSE)
  alerts <- detect_high_risk_columns(df)
  expect_true("observacion" %in% alerts$columns)
})
```

- [ ] **Step 3: Run the tests to confirm failure**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_release_decision.R')"
```

- [ ] **Step 4: Implement minimal detectors**

Add pure helpers for:
- name-pattern detection
- text-like field detection
- high-cardinality / unique-ratio screening
- high-precision date detection
- highly distinctive numeric-granularity screening
- severity / confidence labeling for generated alerts
- a first explicit marker for alerts that should later participate in attacker-style or residual-risk review

Do not overengineer domain-specific semantics yet.

- [ ] **Step 5: Re-run the tests**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_release_decision.R')"
```

- [ ] **Step 6: Commit**

```bash
git add R/shiny_app.R tests/testthat/test_release_decision.R
git commit -m "feat: add general high-risk column heuristics"
```

---

### Task 7: Add initial risky-combination detection

**Files:**
- Modify: `R/shiny_app.R`
- Modify: `tests/testthat/test_release_decision.R`
- Test: `tests/testthat/test_release_decision.R`

- [ ] **Step 1: Write failing tests for 1-, 2-, and 3-column risky combinations**

Use tiny synthetic data to confirm:
- combinations under `k` are flagged
- review is based on candidate quasi-identifiers

Example:

```r
test_that("combinations below k are flagged", {
  df <- data.frame(
    edad = c("40-49", "40-49", "50-59"),
    zona = c("A", "A", "B"),
    sector = c("x", "x", "y"),
    stringsAsFactors = FALSE
  )
  alerts <- detect_risky_combinations(df, cols = c("edad", "zona", "sector"), k = 2)
  expect_true(nrow(alerts) > 0)
})
```

- [ ] **Step 2: Run the tests and verify failure**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_release_decision.R')"
```

- [ ] **Step 3: Implement a conservative first version**

Requirements:
- evaluate combinations of size 1, 2, 3
- return structured rows with combination, min class size, severity, confidence, and reason
- keep algorithm simple and auditable

- [ ] **Step 4: Add failing tests for residual-risk combinations beyond strict k failure**

Cover at least:
- a dataset that meets `k` but leaves a highly homogeneous sensitive outcome within an equivalence class
- a dataset whose combination is not strictly unique but remains too linkable given time/location/category precision

Example:

```r
test_that("meeting k does not automatically clear homogeneous sensitive classes", {
  df <- data.frame(
    edad = c("40-49", "40-49", "40-49", "40-49"),
    zona = c("A", "A", "A", "A"),
    sector = c("x", "x", "x", "x"),
    condicion = c("rara", "rara", "rara", "rara"),
    stringsAsFactors = FALSE
  )
  residual <- detect_residual_risk_after_k(
    df,
    quasi_identifiers = c("edad", "zona", "sector"),
    sensitive_columns = c("condicion"),
    k = 4
  )
  expect_true(nrow(residual) > 0)
})
```

- [ ] **Step 5: Run the combination and residual-risk tests**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_release_decision.R')"
```

- [ ] **Step 6: Implement a conservative first residual-risk layer**

Minimum requirements:
- identify highly homogeneous sensitive classes after `k` is satisfied;
- identify combinations that remain overly precise in time, geography, category, or distinctive numerics;
- return structured alert objects with explicit reason and severity;
- keep the first version explainable and auditable rather than statistically ambitious.

- [ ] **Step 7: Re-run the combination tests**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_release_decision.R')"
```

- [ ] **Step 8: Commit**

```bash
git add R/shiny_app.R tests/testthat/test_release_decision.R
git commit -m "feat: add risky combination and residual-risk detection"
```

---

### Task 8: Add manual review objects and active-verification requirements

**Files:**
- Modify: `R/shiny_app.R`
- Modify: `tests/testthat/test_release_decision.R`
- Test: `tests/testthat/test_release_decision.R`

- [ ] **Step 1: Write failing tests for review requirements**

Cover:
- text fields require active review
- blocked combinations require active review
- review alone does not unlock export without reevaluation

Example:

```r
test_that("active review alone does not unlock export", {
  review <- build_manual_review_result(
    object_id = "observacion",
    review_type = "text_free",
    verified = TRUE
  )
  st <- build_release_state("Bloqueado", reasons = list("texto libre"), metadata = list(reviews = list(review)))
  expect_false(can_export_external_release(st))
})
```

- [ ] **Step 2: Implement review data structures**

Add pure helpers like:
- `required_manual_reviews(...)`
- `build_manual_review_result(...)`
- `review_satisfies_requirement(...)`

The review object must be able to carry at least:
- alert id
- timestamp
- acting user when available from the environment
- reviewed object id
- risk type
- suggested action
- applied action
- verification datum provided by the user
- before/after state snapshot or equivalent structured reevaluation reference
- reevaluation result

- [ ] **Step 3: Wire review state into the server**

Keep the first implementation simple:
- structured pending reviews
- structured completed reviews
- no advanced UI yet beyond placeholder flows if necessary

- [ ] **Step 4: Re-run the review tests**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_release_decision.R')"
```

- [ ] **Step 5: Commit**

```bash
git add R/shiny_app.R tests/testthat/test_release_decision.R
git commit -m "feat: add auditable manual review requirements"
```

---

### Task 9: Generate release and non-release reports

**Files:**
- Modify: `R/shiny_app.R`
- Modify: `tests/testthat/test_release_decision.R`
- Test: `tests/testthat/test_release_decision.R`

- [ ] **Step 1: Write failing tests for report structure**

Test for at least:
- release report includes status, controls passed, and reviews
- non-release report includes reasons, unresolved risks, and next actions

Example:

```r
test_that("non-release report explains unresolved blockers", {
  report <- build_non_release_report(
    reasons = list("texto libre", "combinacion singular"),
    next_steps = list("excluir observacion", "generalizar fecha")
  )
  expect_match(report, "texto libre")
  expect_match(report, "generalizar fecha")
})
```

- [ ] **Step 2: Implement minimal report builders**

Prefer pure text/structured list helpers first, then render in the app.

Minimum contents:
- release status
- controls passed
- controls failed
- manual reviews performed
- unresolved blockers
- next actions
- alert-level references for resolved and unresolved risks
- reference to any restricted internal artifacts not exported
- note that internal artifacts do not imply releasable output
- explicit mention when `k` was satisfied but residual risk still blocked release
- explicit mention of the attacker-plausible rationale when blocking depends on linkability or homogeneity rather than direct uniqueness

- [ ] **Step 3: Add UI surfacing for blocked vs releasable outcomes**

At minimum:
- blocked summary panel
- releasable summary panel

- [ ] **Step 4: Re-run tests**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_release_decision.R')"
```

- [ ] **Step 5: Commit**

```bash
git add R/shiny_app.R tests/testthat/test_release_decision.R
git commit -m "feat: add release decision reporting"
```

---

### Task 10: Preserve persistence JSON and fuzzy matching under the release model

**Files:**
- Modify: `R/shiny_app.R`
- Create: `tests/testthat/test_persistence_release_flow.R`
- Test: `tests/testthat/test_persistence_release_flow.R`

**Execution note:** Despite its numbering, this task should be pulled forward and executed immediately after the shared contract baseline is in place, before the main UI simplification work is considered safe.

- [ ] **Step 1: Write failing tests for persistence continuity**

Cover:
- role templates still save and load under the new UI
- fuzzy suggestions still appear for near-match schemas
- release-state metadata does not corrupt existing role persistence
- restricted release-review artifacts are not silently persisted as if they were ordinary templates

- [ ] **Step 2: Run the persistence test file to confirm failure**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_persistence_release_flow.R')"
```

- [ ] **Step 3: Implement minimal persistence alignment**

Requirements:
- keep existing schema-hash based persistence working
- keep fuzzy recovery working
- prove that canonical release-contract objects do not silently bleed into ordinary role-template persistence
- explicitly separate persisted classification artifacts from restricted review/release artifacts
- document in code what is persisted and what is intentionally not persisted

- [ ] **Step 4: Re-run persistence tests**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_persistence_release_flow.R')"
```

- [ ] **Step 5: Commit**

```bash
git add R/shiny_app.R tests/testthat/test_persistence_release_flow.R
git commit -m "feat: preserve persistence and fuzzy recovery in release flow"
```

---

### Task 11: Align generated R code with real release semantics and API commitments

**Files:**
- Modify: `R/shiny_app.R`
- Modify: `R/obfuscator_core.R` only if API-level metadata helpers are required
- Modify: `tests/testthat/test_obfuscator.R`
- Modify: `tests/testthat/test_release_decision.R`
- Test: `tests/testthat/test_obfuscator.R`
- Test: `tests/testthat/test_release_decision.R`

- [ ] **Step 1: Write failing tests for generated code**

Test that generated code:
- distinguishes internal transformation from releasable configuration
- includes `quasi_identifiers`, `suppression`, and other actual privacy inputs when release mode is configured
- does not imply that code generation equals approved release

- [ ] **Step 2: Write failing tests for API and legacy compatibility**

Cover at least:
- `obfuscator_config()` still accepts valid release-related inputs
- `obfuscate_dataset()` still returns `privacy_report` when release-mode privacy is configured
- legacy script-style usage still works without UI-specific objects
- any new metadata attached for release decisions does not break core return expectations
- a blocked UI-equivalent scenario does not appear as implicitly approved merely because it is executed via generated code or direct API use

- [ ] **Step 3: Implement the minimal changes to code generation and API alignment**

Requirements:
- if release mode is active, generated code must reflect real privacy parameters
- if release is blocked, generated code should still be internal/review-oriented, not presented as “ready to share”
- if core-level helpers need extra metadata, keep them optional and backward-compatible
- the same dataset and configuration must not produce contradictory release semantics across UI, generated code, and direct API paths

- [ ] **Step 4: Re-run focused core/UI tests**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_obfuscator.R')"
```

- [ ] **Step 5: Re-run release-decision tests if helper logic is shared**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_release_decision.R')"
```

- [ ] **Step 6: Commit**

```bash
git add R/shiny_app.R R/obfuscator_core.R tests/testthat/test_obfuscator.R tests/testthat/test_release_decision.R
git commit -m "fix: align generated code and api with release model"
```

---

### Task 12: Run full automated verification

**Files:**
- Modify: none unless failures demand follow-up fixes
- Test: `tests/testthat.R`, targeted test files

- [ ] **Step 1: Run focused release tests**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_release_decision.R')"
```

Expected:
- PASS

- [ ] **Step 1b: Ensure residual-risk cases are covered explicitly**

Before calling the focused release tests sufficient, confirm that the focused suite includes at least:
- one case where `k` fails;
- one case where `k` passes but residual risk still blocks;
- one case where a scenario reaches `Liberable` for explainable reasons.

- [ ] **Step 2: Run persistence tests**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_persistence_release_flow.R')"
```

Expected:
- PASS

- [ ] **Step 3: Run existing UI/core tests**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_obfuscator.R')"
```

Expected:
- PASS

- [ ] **Step 4: Run full suite**

Run:

```powershell
Rscript tests/testthat.R
```

Expected:
- PASS all tests

- [ ] **Step 5: Commit verification checkpoint**

```bash
git add .
git commit -m "test: verify release decision implementation"
```

---

### Task 13: Align README(s) only after behavior exists

**Files:**
- Modify: `README.md`
- Modify: `README_gitlab.md`
- Modify: `docs/AUDITORIA_ESTADO_ACTUAL_2026-05-06.md` only if implementation changed one of the audit findings materially
- Test: docs/manual review

- [ ] **Step 1: Remove or soften overpromises**

Update README language so the product is described first as a release-safety tool, not as an “IA obfuscation helper”.

- [ ] **Step 2: Add explicit warning language**

Document:
- IA is treated as a third party
- not every dataset becomes releasable
- blocked release generates an explanatory report

- [ ] **Step 3: Review corporate README alignment**

Ensure `README_gitlab.md` does not contradict the release model or imply looser export semantics.

- [ ] **Step 4: Commit**

```bash
git add README.md README_gitlab.md
git commit -m "docs: align readmes with release-safe product model"
```

---

## Notes for the Implementer

- Do not begin with a huge UI redesign. First lock the shared release contract and realistic proof cases, then remove contradictions, then add release-state logic, then add review/reporting.
- Keep decision logic in pure helpers whenever possible so tests do not depend on a running Shiny session.
- Treat `R/release_decision_helpers.R` or an equivalent focused helper layer as the default home for release semantics. `R/shiny_app.R` should orchestrate, not define policy.
- Prefer adding new tests in `tests/testthat/test_release_decision.R` rather than bloating `test_obfuscator.R` with unrelated release-policy assertions.
- Do not claim “safe release” from heuristics alone. The helpers should support a conservative, explainable system, not magical certainty.
- If implementation reveals that `R/shiny_app.R` is too crowded, a small extraction into one additional focused R file is acceptable, but only after at least one helper cluster is stable.
- Preserve JSON persistence and fuzzy recovery unless the specification is explicitly changed again.
- Treat auditability as a deliverable, not as commentary: if something must be reviewable later, it needs structured data and tests.
- Guard the script/package/app contract while changing the app layer; do not let the Shiny refactor silently redefine the API.
- Do not let the plan "pass by blocking." At least one realistic fixture must reach `Liberable` for reasons the team can explain and defend.

---

## Suggested commit sequence

1. `feat: define shared release contract`
2. `test: define canonical release UI expectations`
3. `feat: preserve persistence and fuzzy recovery in release flow`
4. `fix: add canonical dataset naming and parameter defaults`
5. `refactor: unify release parameter controls`
6. `feat: add release state model`
7. `feat: separate internal artifacts from releasable export`
8. `feat: add general high-risk column heuristics`
9. `feat: add risky combination detection`
10. `feat: add auditable manual review requirements`
11. `feat: add release decision reporting`
12. `fix: align generated code and api with release model`
13. `test: verify release decision implementation`
14. `docs: align readmes with release-safe product model`

---

## Plan review checklist

- Does the implementation define one shared release contract before UI rewiring?
- Does the same scenario receive the same release verdict in UI, generated code, and direct API/script usage?
- Does the implementation keep `k-anonymity` mandatory for third-party release?
- Does it explicitly test and evaluate residual risk after `k-anonymity` is satisfied?
- Does it distinguish internal artifacts from exportable artifacts?
- Does it remove duplicate parameter controls and duplicate `inputId` values?
- Does it add release states with explicit export gating?
- Does it require active manual review for blocked high-risk cases?
- Does it generate a non-release explanation instead of offering “liberar igual”?
- Does it keep the README from overpromising?
- Does it preserve schema-hash persistence and fuzzy recovery?
- Does it emit auditable structured evidence for manual review and release reports?
- Does it preserve alert-level evidence with verifiable review inputs and reevaluation outputs?
- Does it prove at least one realistic `Liberable` case and one realistic `No liberable sin rediseno` case?
- Does it cover at least one case where `k` is satisfied but release is still blocked for residual-risk reasons?
- Does it preserve script/package/app compatibility while changing the Shiny release model?
