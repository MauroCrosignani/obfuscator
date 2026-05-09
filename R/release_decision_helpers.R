release_contract_default <- function(x, default) {
  if (is.null(x)) default else x
}

release_workflow_statuses <- function() {
  c(
    "No evaluado",
    "En revision",
    "Bloqueado",
    "Liberable",
    "No liberable sin rediseno"
  )
}

build_release_state <- function(status, reasons = list(), metadata = list()) {
  allowed_statuses <- release_workflow_statuses()
  if (!is.character(status) || length(status) != 1 || !(status %in% allowed_statuses)) {
    stop(sprintf(
      "`status` must use one of: %s.",
      paste(allowed_statuses, collapse = ", ")
    ))
  }

  state <- list(
    status = status,
    reasons = if (is.list(reasons)) reasons else as.list(reasons),
    metadata = if (is.list(metadata)) metadata else list(value = metadata),
    can_export_external = identical(status, "Liberable")
  )
  class(state) <- c("release_state", "list")
  state
}

initial_release_state <- function() {
  build_release_state("No evaluado")
}

can_export_external_release <- function(state) {
  isTRUE(state$can_export_external) && identical(state$status, "Liberable")
}

transition_release_state <- function(current_state, event, context = list()) {
  allowed_events <- c("start_review", "block", "approve", "mark_non_releasable", "material_change")
  if (!is.character(event) || length(event) != 1 || !(event %in% allowed_events)) {
    stop(sprintf(
      "`event` must use one of: %s.",
      paste(allowed_events, collapse = ", ")
    ))
  }

  if (is.null(current_state) || !inherits(current_state, "release_state")) {
    current_state <- initial_release_state()
  }

  if (identical(current_state$status, "No liberable sin rediseno") && !identical(event, "material_change")) {
    return(current_state)
  }

  reasons <- context$reasons %||% list()
  metadata <- utils::modifyList(current_state$metadata %||% list(), context$metadata %||% list())

  switch(
    event,
    start_review = build_release_state("En revision", metadata = metadata),
    block = build_release_state("Bloqueado", reasons = reasons, metadata = metadata),
    approve = build_release_state("Liberable", metadata = metadata),
    mark_non_releasable = build_release_state("No liberable sin rediseno", reasons = reasons, metadata = metadata),
    material_change = build_release_state("No evaluado", metadata = context$metadata %||% list())
  )
}

derive_release_state_from_obfuscation <- function(
  privacy_enabled,
  privacy_satisfied = FALSE,
  has_internal_preview = TRUE
) {
  metadata <- list(
    has_internal_preview = isTRUE(has_internal_preview),
    artifact = release_artifact("internal_work")
  )

  if (!isTRUE(privacy_enabled)) {
    return(build_release_state(
      "Bloqueado",
      reasons = list("La liberacion externa requiere activar k-anonymity."),
      metadata = metadata
    ))
  }

  if (isTRUE(privacy_satisfied)) {
    metadata$artifact <- release_artifact("releasable_external")
    return(build_release_state("Liberable", metadata = metadata))
  }

  build_release_state(
    "Bloqueado",
    reasons = list("La configuracion actual no satisface k-anonymity para liberacion externa."),
    metadata = metadata
  )
}

release_artifact <- function(type, name = NULL) {
  allowed_types <- c("preview", "internal_work", "releasable_external")
  if (!is.character(type) || length(type) != 1 || !(type %in% allowed_types)) {
    stop("`artifact` must use one of: preview, internal_work, releasable_external.")
  }

  artifact <- list(
    type = type,
    name = release_contract_default(name, NA_character_)
  )
  class(artifact) <- c("release_artifact", "list")
  artifact
}

release_alert <- function(code, severity, message, fields = character(0), artifact_type, evidence = list()) {
  allowed_severity <- c("info", "warning", "critical")
  if (!is.character(code) || length(code) != 1 || identical(code, "")) {
    stop("`code` must be a non-empty scalar character value.")
  }
  if (!is.character(severity) || length(severity) != 1 || !(severity %in% allowed_severity)) {
    stop("`severity` must use one of: info, warning, critical.")
  }
  if (!is.character(message) || length(message) != 1 || identical(message, "")) {
    stop("`message` must be a non-empty scalar character value.")
  }

  artifact <- release_artifact(artifact_type)
  alert <- list(
    code = code,
    severity = severity,
    message = message,
    fields = as.character(fields),
    artifact_type = artifact$type,
    evidence = if (is.list(evidence)) evidence else list(value = evidence)
  )
  class(alert) <- c("release_alert", "list")
  alert
}

manual_review_evidence <- function(kind, summary, fields = character(0), examples = character(0), recommendation) {
  if (!is.character(kind) || length(kind) != 1 || identical(kind, "")) {
    stop("`kind` must be a non-empty scalar character value.")
  }
  if (!is.character(summary) || length(summary) != 1 || identical(summary, "")) {
    stop("`summary` must be a non-empty scalar character value.")
  }
  if (!is.character(recommendation) || length(recommendation) != 1 || identical(recommendation, "")) {
    stop("`recommendation` must be a non-empty scalar character value.")
  }

  evidence <- list(
    kind = kind,
    summary = summary,
    fields = as.character(fields),
    examples = as.character(examples),
    recommendation = recommendation
  )
  class(evidence) <- c("manual_review_evidence", "list")
  evidence
}

normalize_release_scenario <- function(input, path = c("api", "ui")) {
  path <- match.arg(path)

  if (identical(path, "ui")) {
    list(
      artifact = list(
        type = input$artifact_type,
        name = input$artifact_name
      ),
      signals = list(
        direct_identifiers_removed = input$direct_identifiers_removed,
        dates_generalized = input$dates_generalized,
        distinctive_numerics_masked = input$distinctive_numerics_masked,
        rare_categories_grouped = input$rare_categories_grouped,
        text_like_risk = input$text_like_risk
      ),
      evidence = release_contract_default(input$evidence, list())
    )
  } else {
    input
  }
}

release_contract_alerts <- function(artifact, signals, evidence = list()) {
  alerts <- list()

  add_alert <- function(code, severity, message, fields = character(0), extra = list()) {
    alerts[[length(alerts) + 1L]] <<- release_alert(
      code = code,
      severity = severity,
      message = message,
      fields = fields,
      artifact_type = artifact$type,
      evidence = extra
    )
  }

  if (!isTRUE(signals$direct_identifiers_removed)) {
    add_alert(
      "direct_identifiers_present",
      "critical",
      "Direct identifiers are still present in the release artifact.",
      fields = "identifiers",
      extra = evidence
    )
  }

  if (!isTRUE(signals$dates_generalized)) {
    add_alert(
      "exact_dates_exposed",
      "critical",
      "Exact dates remain visible for third-party release.",
      fields = "dates",
      extra = evidence
    )
  }

  if (!isTRUE(signals$distinctive_numerics_masked)) {
    add_alert(
      "distinctive_numeric_risk",
      "critical",
      "Distinctive numeric values remain visible in the artifact.",
      fields = "numeric_values",
      extra = evidence
    )
  }

  if (!isTRUE(signals$rare_categories_grouped)) {
    add_alert(
      "rare_category_risk",
      "warning",
      "Rare categories remain visible in the artifact.",
      fields = "rare_categories",
      extra = evidence
    )
  }

  if (isTRUE(signals$text_like_risk)) {
    add_alert(
      "text_like_risk",
      "critical",
      "Free-text or text-like content still carries re-identification risk.",
      fields = "text",
      extra = evidence
    )
  }

  alerts
}

manual_review_from_alerts <- function(alerts) {
  warning_alerts <- Filter(function(alert) identical(alert$severity, "warning"), alerts)
  if (length(warning_alerts) == 0) {
    return(list(required = FALSE, evidence = list()))
  }

  fields <- unique(unlist(lapply(warning_alerts, function(alert) alert$fields), use.names = FALSE))
  evidence <- manual_review_evidence(
    kind = "warning_review",
    summary = "Residual warning-level risks require manual review before release.",
    fields = fields,
    examples = vapply(warning_alerts, `[[`, character(1), "message"),
    recommendation = "Review warning signals and confirm they are acceptable for the intended audience."
  )

  list(required = TRUE, evidence = list(evidence))
}

evaluate_release_contract <- function(scenario) {
  artifact <- do.call(release_artifact, scenario$artifact)
  signals <- release_contract_default(scenario$signals, list())
  evidence <- release_contract_default(scenario$evidence, list())
  alerts <- release_contract_alerts(artifact, signals, evidence = evidence)

  critical_present <- any(vapply(alerts, function(alert) identical(alert$severity, "critical"), logical(1)))

  if (identical(artifact$type, "releasable_external")) {
    if (critical_present) {
      verdict <- "No liberable sin rediseno"
      can_release <- FALSE
      manual_review <- list(required = FALSE, evidence = list())
    } else if (length(alerts) == 0) {
      verdict <- "Liberable"
      can_release <- TRUE
      manual_review <- list(required = FALSE, evidence = list())
    } else {
      verdict <- "Requiere revision manual"
      can_release <- FALSE
      manual_review <- manual_review_from_alerts(alerts)
    }
  } else {
    verdict <- "Requiere revision manual"
    can_release <- FALSE
    manual_review <- manual_review_from_alerts(alerts)
  }

  state <- list(
    verdict = verdict,
    can_release = can_release,
    artifact = artifact,
    alerts = alerts,
    manual_review = manual_review
  )
  class(state) <- c("release_state", "list")
  state
}

release_decision_for_api <- function(input) {
  evaluate_release_contract(normalize_release_scenario(input, path = "api"))
}

release_decision_for_ui <- function(input) {
  evaluate_release_contract(normalize_release_scenario(input, path = "ui"))
}
