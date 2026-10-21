
# Digital request MCDA prioritisation
# Version 1
#
# Input:
#   02_data_output/dig_req_llm_metadata_2.rds
#
# Outputs:
#   02_data_output/dig_req_mcda_assessments_1.rds
#   02_data_output/dig_req_mcda_ranked_1.rds
#
# Run after the existing metadata extraction script.
# Requires Ollama and the configured Gemma model.

source(here::here("01_src", "01_startup", "01_initialise.R"))

library(ellmer)
library(jsonlite)
library(purrr)
library(dplyr)
library(tibble)

# Configuration --------------------------------------------------

model_name <- "gemma4"
max_retries <- 3

base_url <- Sys.getenv(
  "OLLAMA_BASE_URL",
  "http://localhost:11434"
)

metadata_file <- here::here(
  "02_data_output",
  "dig_req_llm_metadata_2.rds"
)

assessment_file <- here::here(
  "02_data_output",
  "dig_req_mcda_assessments_1.rds"
)

ranked_file <- here::here(
  "02_data_output",
  "dig_req_mcda_ranked_1.rds"
)

prompt_file <- here::here(
  "01_src", "03_wrangle", "Prompts",
  "prompt-digital-request-mcda_2.md"
)

# Use 6 for a pilot; set to Inf for all requests.
n_requests <- 6

# Weights are percentages and must sum to 100.
# mcda_weights <- c(
#   patient_safety = 25,
#   strategic_alignment = 20,
#   operational_benefits = 15,
#   scale_of_impact = 15,
#   urgency = 15,
#   evidence_confidence = 10
# )

mcda_weights <- c(
  patient_safety = 30,
  system_criticality = 20,
  operational_benefits = 20,
  scale_of_impact = 15,
  urgency = 10,
  implementation_feasibility = 5
)

stopifnot(sum(mcda_weights) == 100)
stopifnot(sum(mcda_weights) == 100)

# Load scoring instructions and existing metadata ----------------

stopifnot(file.exists(metadata_file))
stopifnot(file.exists(prompt_file))

metadata_data <- readRDS(metadata_file)

prompt_text <- paste(
  readLines(prompt_file, warn = FALSE),
  collapse = "\n"
)

# JSON helper ----------------------------------------------------

to_json <- function(x, ...) {
  jsonlite::toJSON(
    x,
    auto_unbox = TRUE,
    null = "null",
    na = "string",
    dataframe = "rows",
    ...,
    pretty = TRUE
  )
}

# Output schema --------------------------------------------------

criterion_type <- function(description) {
  ellmer::type_object(
    score = ellmer::type_integer(
      paste(description, "Integer from 1 to 5.")
    ),
    rationale = ellmer::type_string(
      "Concise justification for the score."
    ),
    evidence = ellmer::type_string(
      "Evidence from the source record; state if absent."
    )
  )
}


mcda_type <- ellmer::type_object(
  patient_safety = criterion_type(
    "Immediate patient safety impact."
  ),
  system_criticality = criterion_type(
    "System criticality and consequences of system failure or degradation."
  ),
  operational_benefits = criterion_type(
    "Resource and cost-saving potential, including operational efficiency and workforce benefits."
  ),
  scale_of_impact = criterion_type(
    "Reach and scale of impact across patients, staff, teams and services."
  ),
  urgency = criterion_type(
    "Absolute necessity, urgency and consequences of delay."
  ),
  implementation_feasibility = criterion_type(
    "Implementation feasibility, complexity, dependencies and delivery risk. Higher scores mean easier implementation."
  ),
  safety_review_required = ellmer::type_boolean(
    "Potential patient-safety concern requiring human review."
  ),
  mandatory_review_required = ellmer::type_boolean(
    "Possible statutory, regulatory, contractual or formally mandated obligation requiring verification."
  ),
  review_notes = ellmer::type_array(
    ellmer::type_string(),
    description = "Material uncertainties, missing evidence, potential safety concerns and obligations requiring human review."
  )
)

# Structured Ollama call with retries ----------------------------

ask_mcda <- function(prompt) {
  chat <- ellmer::chat_ollama(
    system_prompt = paste(
      "You are an evidence-based NHS digital request assessor.",
      "Follow the supplied MCDA rubric exactly.",
      "Do not invent facts or make final clinical or legal decisions."
    ),
    base_url = base_url,
    model = model_name,
    params = ellmer::params(
      max_tokens = 8192,
      temperature = 0,
      reasoning_effort = "none"
    ),
    api_args = list(
      think = FALSE,
      options = list(
        num_ctx = 32768,
        num_predict = 8192,
        temperature = 0
      )
    ),
    echo = "none"
  )
  
  last_error <- NULL
  
  for (attempt in seq_len(max_retries)) {
    result <- tryCatch(
      chat$chat_structured(
        prompt,
        type = mcda_type,
        echo = "none"
      ),
      error = function(e) e
    )
    
    if (!inherits(result, "error") &&
        !is.null(result)) {
      return(result)
    }
    
    last_error <- result
    
    message(
      "MCDA attempt ", attempt, " failed: ",
      conditionMessage(last_error)
    )
  }
  
  warning(
    "MCDA failed after ", max_retries,
    " attempts: ", conditionMessage(last_error)
  )
  
  NULL
}

# Unwrap nested list-columns safely -------------------------------

unwrap_one <- function(x) {
  if (is.null(x) || length(x) == 0) {
    return(NULL)
  }
  
  if (is.list(x) && length(x) == 1 &&
      (is.list(x[[1]]) || is.null(x[[1]]))) {
    return(x[[1]])
  }
  
  x
}

# Assess one request ---------------------------------------------

assess_request <- function(row) {
  metadata <- unwrap_one(row$metadata_v3)
  source <- unwrap_one(row$source_record)
  
  if (is.null(metadata) || is.null(source)) {
    warning(
      "Missing source or metadata for request row ",
      row$request_row_id
    )
    return(NULL)
  }
  
  assessment_prompt <- paste(
    prompt_text,
    "",
    "ORIGINAL SOURCE RECORD:",
    to_json(source),
    "",
    "EXTRACTED METADATA (supporting evidence only):",
    to_json(metadata),
    "",
    "Assess the request against every criterion.",
    "Keep each rationale to 1-2 concise sentences.",
    "Keep each evidence field to 1-2 concise sentences.",
    "Use an empty review_notes array if there are no specific uncertainties.",
    "Do not provide extended reasoning or repeat the source record.",
    "Return the structured assessment only.",
    sep = "\n"
  )
  
  result <- ask_mcda(assessment_prompt)
  
  tibble(
    request_row_id = row$request_row_id,
    digital_request_number = row$digital_request_number,
    mcda = list(result),
    model = model_name,
    rubric_version = "1",
    processed_at = Sys.time()
  )
}

# Select records to process --------------------------------------

metadata_data <- metadata_data |>
  arrange(request_row_id)

if (is.finite(n_requests)) {
  metadata_data <- head(metadata_data, n_requests)
}

if (file.exists(assessment_file)) {
  assessments_done <- readRDS(assessment_file)
} else {
  assessments_done <- tibble()
}

if (nrow(assessments_done) == 0) {
  todo <- metadata_data
} else {
  todo <- metadata_data |>
    filter(
      !request_row_id %in%
        assessments_done$request_row_id
    )
}

# Run and save incrementally -------------------------------------

for (i in seq_len(nrow(todo))) {
  message(
    "Assessing request ", i, " of ", nrow(todo),
    ": ", todo$digital_request_number[i]
  )
  
  new_result <- tryCatch(
    assess_request(as.list(todo[i, ])),
    error = function(e) {
      warning(conditionMessage(e))
      NULL
    }
  )
  
  if (is.null(new_result) || nrow(new_result) == 0) {
    next
  }
  
  assessments_done <- bind_rows(
    assessments_done,
    new_result
  ) |>
    distinct(request_row_id, .keep_all = TRUE)
  
  dir.create(
    dirname(assessment_file),
    recursive = TRUE,
    showWarnings = FALSE
  )
  
  saveRDS(assessments_done, assessment_file)
}

# Validate individual assessments -------------------------------

criterion_names <- names(mcda_weights)

validate_assessment <- function(x) {
  if (is.null(x)) return(FALSE)
  
  for (nm in criterion_names) {
    item <- x[[nm]]
    
    if (is.null(item) ||
        is.null(item$score) ||
        length(item$score) != 1 ||
        !is.numeric(item$score) ||
        !is.finite(item$score) ||
        item$score != as.integer(item$score) ||
        item$score < 1 ||
        item$score > 5 ||
        is.null(item$rationale) ||
        is.null(item$evidence)) {
      return(FALSE)
    }
  }
  
  !is.null(x$safety_review_required) &&
    length(x$safety_review_required) == 1 &&
    is.logical(x$safety_review_required) &&
    !is.null(x$mandatory_review_required) &&
    length(x$mandatory_review_required) == 1 &&
    is.logical(x$mandatory_review_required)
}

calculate_score <- function(x) {
  if (!validate_assessment(x)) {
    return(NA_real_)
  }
  
  scores <- vapply(
    criterion_names,
    function(nm) as.numeric(x[[nm]]$score),
    numeric(1)
  )
  
  sum(
    ((scores - 1) / 4) *
      unname(mcda_weights)
  )
}

flag_value <- function(x, field) {
  if (is.null(x) || is.null(x[[field]])) {
    return(NA)
  }
  
  value <- x[[field]]
  
  if (length(value) != 1 || is.na(value)) {
    return(NA)
  }
  
  as.logical(value)
}

# Produce the ranking --------------------------------------------

ranked <- assessments_done |>
  mutate(
    assessment_valid = map_lgl(
      mcda, validate_assessment
    ),
    mcda_score = map_dbl(
      mcda, calculate_score
    ),
    safety_review_required = map_lgl(
      mcda,
      ~ isTRUE(flag_value(
        .x, "safety_review_required"
      ))
    ),
    mandatory_review_required = map_lgl(
      mcda,
      ~ isTRUE(flag_value(
        .x, "mandatory_review_required"
      ))
    ),
    safety_flag_missing = map_lgl(
      mcda,
      ~ is.na(flag_value(
        .x, "safety_review_required"
      ))
    ),
    mandatory_flag_missing = map_lgl(
      mcda,
      ~ is.na(flag_value(
        .x, "mandatory_review_required"
      ))
    ),
    human_review_required =
      safety_review_required |
      mandatory_review_required |
      safety_flag_missing |
      mandatory_flag_missing |
      !assessment_valid
  ) |>
  arrange(
    desc(assessment_valid),
    desc(mcda_score),
    digital_request_number
  ) |>
  mutate(
    priority_rank = if_else(
      assessment_valid,
      cumsum(assessment_valid),
      NA_integer_
    )
  )

saveRDS(ranked, ranked_file)

message("MCDA assessment complete.")
message("Assessments: ", assessment_file)
message("Ranking: ", ranked_file)
