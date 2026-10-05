# Three-stage LLM metadata extraction, validation and thematic classification
# for every row of data_dig_req (issue #5).
# Prerequisites: run 01_initialise.R, 02_data_import.R and
# "06_data_dictionary - data_dig_req.R" (for informant_data_dig_req) first.
# Output: 02_data_output/dig_req_llm_metadata_2.rds (read by 07_report/digital_request_themes.qmd)

source(here::here("01_src", "01_startup", "01_initialise.R"))
source(here::here("01_src", "02_data_import", "02_data_import.R"))
source(here::here("06_data_dictionary", "06_data_dictionary - data_dig_req.R"))
# source(here::here("01_src", "03_wrangle", "ellmer_chat_with_ollama - digital request analysis.R"))

# library(ellmer)
# library(jsonlite)
# library(purrr)
# library(dplyr)

## Config ----------------
model_name <- "gemma4"
max_retries <- 3
base_url <- Sys.getenv("OLLAMA_BASE_URL", "http://localhost:11434")
output_file <- here::here("02_data_output", "dig_req_llm_metadata_2.rds")
n_requests <- Inf # number of requests to process while testing; use Inf for all

# Output schema, enforced by Ollama via structured output (so no JSON parsing is needed).
# Field guidance lives in the prompt file.
str_list <- function(desc) ellmer::type_array(ellmer::type_string(), description = desc)
metadata_type <- ellmer::type_object(
  summary = ellmer::type_string("2-3 sentence executive summary"),
  key_problem = ellmer::type_string(),
  requested_outcome = ellmer::type_string(),
  stakeholders = str_list("people, teams or services affected"),
  business_area = ellmer::type_string(),
  expected_benefits = str_list(NULL),
  dependencies = str_list(NULL),
  risks_or_constraints = str_list(NULL),
  themes = str_list("1-4 themes selected exactly from the controlled vocabulary")
)
system_prompt <- paste(
  readLines(here::here("01_src", "03_wrangle", "Prompts", "prompt-digital-request-analysis.md")),
  collapse = "\n"
)
dictionary <- paste(as.character(btw::btw(informant_data_dig_req)), collapse = "\n")

## Helpers ----------------
# Ask a fresh chat for output matching `type`; retry on failure (e.g. truncated output)
ask_json <- function(prompt, type) {
  chat <- chat_ollama(
    system_prompt = system_prompt, base_url = base_url, model = model_name,
    api_args = list(options = list(num_ctx = 32768, temperature = 0)), echo = "none"
  )
  for (i in seq_len(max_retries)) {
    out <- tryCatch(chat$chat_structured(prompt, type = type, echo = "none"), error = function(e) e)
    if (!inherits(out, "error")) return(out)
  }
  warning("No valid output after ", max_retries, " attempts: ", conditionMessage(out))
  NULL
}

to_json <- function(x, ...) jsonlite::toJSON(x, auto_unbox = TRUE, null = "null", ...)

# Stage 1: extract metadata from the source record
extract <- function(row) {
  ask_json(
    paste0("Analyse this digital request record and return the metadata JSON object.\n\n",
           "Data dictionary:\n", dictionary, "\n\nSource record:\n", to_json(row, na = "string")),
    metadata_type
  )
}

# Stages 2 and 3: check metadata against the record and correct it
review <- function(row, metadata, stage) {
  ask_json(
    paste0("Quality assurance review (stage ", stage, "). Compare the metadata below with the original record ",
           "for omissions, unsupported statements, errors and poor themes, then correct it.\n",
           "Return the corrected metadata JSON object, with the same keys as before.\n\n",
           "Original record:\n", to_json(row, na = "string"), "\n\nMetadata to review:\n", to_json(metadata)),
    metadata_type
  )
}

process_row <- function(row) {
  v1 <- extract(row)
  
  r2 <- if (!is.null(v1)) review(row, v1, 2) else NULL
  v2 <- if (is.null(r2)) v1 else r2
  
  r3 <- if (!is.null(v2)) review(row, v2, 3) else NULL
  v3 <- if (is.null(r3)) v2 else r3
  
  tibble::tibble(
    request_row_id = row$request_row_id,
    digital_request_number = row$digital_request_number,
    metadata_v1 = list(v1),
    metadata_v2 = list(v2),
    metadata_v3 = list(v3),
    model = model_name,
    processed_at = Sys.time(),
    source_record = list(row)
  )
}

## Run (resumable: rows already in output_file are skipped) ----------------
requests <- data_dig_req |>
  mutate(request_row_id = row_number(), .before = 1) |>
  head(n_requests)
done <- if (file.exists(output_file)) {
  readRDS(output_file)
} else {
  tibble::tibble()
}
todo <- if (nrow(done) == 0) {
  requests
} else {
  filter(
    requests,
    !request_row_id %in% done$request_row_id
  )
}

results <- purrr::map(seq_len(nrow(todo)), \(i) {
  message("Processing request ", i, " of ", nrow(todo))
  process_row(as.list(todo[i, ]))
}) |> bind_rows()

dir.create(dirname(output_file), showWarnings = FALSE, recursive = TRUE)
saveRDS(
  bind_rows(done, results) |>
    distinct(
      request_row_id,
      .keep_all = TRUE
    ),
  output_file
) # contains both request_row_id and digital_request_number

