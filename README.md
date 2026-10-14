# Digital Request Prioritisation

Helps organise NUTH digital requests into a structured system. It extracts and standardises
request data with a locally hosted LLM, classifies requests into a controlled set of themes,
generates executive summaries, and reports on common themes and potentially related requests,
so prioritisation does not rely on memory or spreadsheets.

> **Data governance:** the source extract and all LLM outputs stay local and are git-ignored.

## Pipeline overview

```
Excel demand extract (02_data/)
        │  02_data_import.R
        ▼
  data_dig_req  ──►  06_data_dictionary (pointblank informant)
        │                         │
        ▼                         ▼
ellmer_llm_metadata_pipeline.R  ◄── Prompts/prompt-digital-request-analysis.md
   Stage 1 extract → Stage 2 QA → Stage 3 QA   (Ollama, structured output)
        │
        ▼
02_data_output/dig_req_llm_metadata_2.rds
        │
        ▼
digital_request_themes.qmd  →  HTML report
```

### Stages
1. **Startup** – `01_src/01_startup/01_initialise.R` installs/loads packages via `renv` and sets
   ellmer options.
2. **Import** – `01_src/02_data_import/02_data_import.R` reads the Excel extract and cleans
   column names (e.g. using `janitor::clean_names()` to standardise them).
3. **Data dictionary** – `06_data_dictionary/06_data_dictionary - data_dig_req.R` builds a
   `pointblank` informant describing every column. It is passed to the LLM (via `btw`) as context in order to provide a better understanding of the data and associated metadata.
4. **Prompt** – `01_src/03_wrangle/Prompts/prompt-digital-request-analysis.md` defines the
   analyst persona, rules, controlled theme vocabulary, output schema and a worked example.
5. **LLM metadata pipeline** – `01_src/03_wrangle/ellmer_llm_metadata_pipeline.R`:
   - Stage 1 extracts metadata (`summary`, `key_problem`, `requested_outcome`, `stakeholders`,
     `business_area`, `expected_benefits`, `cost_saving_benefit`, `patient_safety_benefit`, `dependencies`, `risks_or_constraints`, `themes`).
   - Stages 2 and 3 review the metadata against the source record and correct it.
   - Output is schema-enforced (ellmer `type_object`), retried up to 3 times, and resumable
     (rows already processed are skipped).
   - Results (`metadata_v1`–`metadata_v3`, plus model and timestamp) are saved to
     `02_data_output/dig_req_llm_metadata_2.rds`.
6. **Report** – `digital_request_themes.qmd` summarises version 3 metadata: theme counts, word
   cloud, searchable summaries, and a theme × business-area heatmap.

## Repository structure

```
01_src/                 numbered pipeline scripts (startup, import, wrangle/LLM, analyse, figures)
06_data_dictionary/     pointblank data dictionary for data_dig_req
digital_request_themes.qmd   Quarto report
_quarto.yml, _brand.yml, mystyle.*, fonts/, logo/   Branding
renv.lock               locked R dependencies
```

## Requirements
- R and [Quarto](https://quarto.org)
- [Ollama](https://ollama.com) running locally with the `gemma4` model pulled
  (`ollama pull gemma4`). 
- The demand extract at `02_data` (not in the repo; git-ignored).

## How to run
1. Run the LLM pipeline (it sources startup, import and the data dictionary itself):
   ```r
   source(here::here("01_src", "03_wrangle", "ellmer_llm_metadata_pipeline.R"))
   ```
   `n_requests` is set to `Inf` to process every request.
2. Render the report:
   ```bash
   quarto render digital_request_themes.qmd
   ```
   Output goes to `02_data_output/render_output_holding`.



