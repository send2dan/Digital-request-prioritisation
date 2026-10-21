# Data Dictionary — data_dig_req
#
# Uses {pointblank} to create and maintain a data dictionary (informant object)
# for the data_dig_req table.
#
# Workflow:
#   1. Run prerequisite wrangling script to create data_dig_req.
#   2. Run this script to (re)generate the informant and write the YAML.
#   3. Commit the updated YAML file to version control.
#
# Output: 03_data_dictionary/data_dig_req.yml
#
# See: https://rstudio.github.io/pointblank/articles/INFO-1.html
# IMPORTANT: The output YAML must not contain patient identifiable information.

# Packages ----------------------------------------------------------------

library(pointblank)

# Prerequisite R scripts --------------------------------------------------

# Ensure data_dig_req exists in the environment.

# Create informant --------------------------------------------------------

informant_data_dig_req <- pointblank::create_informant(
  tbl = ~ data_dig_req,  # Lazy evaluation with `~`
  tbl_name = "data_dig_req",
  label = "Digital Request Data Table"
) |>

  # Table-level information -----------------------------------------------

  info_tabular(
    Description = paste(
      "This table contains the wrangled digital request data"
    ),
    Source = paste(
      "Project Management Office (PMO) digital request extract"
    ),
    `Update process` = paste(
      " TBC by PMO "
    ),
    `Key join columns` = "nil",
    Linkage = paste(
      " This table is not linked to any other tables in the data warehouse "
    )
  ) |>

info_columns(
  columns = vars(digital_request_number),
  Items = "This column contains {list_digital_request_number}.",
  info = "Unique identifier assigned to the digital request record."
) |>
  
  info_snippet(
    snippet_name = "list_digital_request_number",
    fn = snip_list(
      column = "digital_request_number",
      limit = 10,
      sorting = "inorder",
      na_rm = TRUE
    )
  ) |>
  
  info_columns(
    columns = vars(effective_number),
    Items = "This column contains {list_effective_number}.",
    info = "The same as digital_request_number, i.e. Unique identifier assigned to the digital request record."
  ) |>
  
  info_snippet(
    snippet_name = "list_effective_number",
    fn = snip_list(
      column = "effective_number",
      limit = 10,
      sorting = "inorder",
      na_rm = TRUE
    )
  ) |>
  
info_columns(
  columns = vars(directorate),
  Items = "This column contains {list_directorate}.",
  info = "The organisational directorate responsible for submitting this digital request, defining its primary department alignment. A directorate may contain multiple specialties. All directorates form part of one of the clinical boards at Newcastle upon Tyne Hospitals NHS Foundation Trust."
) |>
  
  info_snippet(
    snippet_name = "list_directorate",
    fn = snip_list(
      column = "directorate",
      limit = 10,
      sorting = "infreq",
      na_rm = TRUE
    )
  ) |>
  
  info_columns(
    columns = vars(clinical_board),
    Items = "This column contains {list_clinical_board}.",
    info = "The specific clinical board that hosts the directorate that submitted this digital request."
  ) |>
  
  info_snippet(
    snippet_name = "list_clinical_board",
    fn = snip_list(
      column = "clinical_board",
      limit = 10,
      sorting = "infreq",
      na_rm = TRUE
    )
  ) |>
  
info_columns(
  columns = vars(category),
  Items = "This column contains {list_category}.",
  info = "The high-level strategic category or domain that the digital request falls under (e.g., 'Operational Efficiency', 'Patient Safety')."
) |>
  
  info_snippet(
    snippet_name = "list_category",
    fn = snip_list(
      column = "category",
      limit = 10,
      sorting = "infreq",
      na_rm = TRUE
    )
  ) |>
  
  info_columns(
    columns = vars(type),
    Items = "This column contains {list_type}.",
    info = "The defined type or nature of the demand as per the source system's taxonomy (e.g., 'New Capability', 'Process Improvement')."
  ) |>
  
  info_snippet(
    snippet_name = "list_type",
    fn = snip_list(
      column = "type",
      limit = 10,
      sorting = "infreq",
      na_rm = TRUE
    )
  ) |>
  
  info_columns(
    columns = vars(urgency),
    info = "Urgency rating assigned to the request by the user completing the form. i.e. The assessed level of urgency for the request (e.g., 'Critical', 'High', 'Medium', 'Low')",
    Items = "This column contains {list_urgency}."
  ) |>
  
  info_snippet(
    snippet_name = "list_urgency",
    fn = snip_list(
      column = "urgency",
      limit = 10,
      sorting = "infreq",
      na_rm = TRUE
    )
  ) |>
  
  info_columns(
    columns = vars(impact),
    info = "Categorical impact rating assigned to the request (e.g. 'Catastrophic', 'High', 'Medium', 'Low', 'Insignificant'). This is a qualitative assessment of the potential effect or significance of the request on operations, patient care, or system performance. ",
    Items = "This column contains {list_impact}."
  ) |>
  
  info_snippet(
    snippet_name = "list_impact",
    fn = snip_list(
      column = "impact",
      limit = 10,
      sorting = "infreq",
      na_rm = TRUE
    )
  ) |>
  
  info_columns(
    columns = vars(risk_level),
    info = "Risk rating assigned to the request.",
    Items = "This column contains {list_risk_level}."
  ) |>
  
  info_snippet(
    snippet_name = "list_risk_level",
    fn = snip_list(
      column = "risk_level",
      limit = 10,
      sorting = "infreq",
      na_rm = TRUE
    )
  ) |>
  
  info_columns(
    columns = vars(trust_strategy),
    info = "The strategic objective or pillar that the successful implementation of this request is intended to support (e.g., 'Patient Centricity', 'System Resilience').",
    Items = "This column contains {list_trust_strategy}."
  ) |>
  
  info_snippet(
    snippet_name = "list_trust_strategy",
    fn = snip_list(
      column = "trust_strategy",
      limit = 10,
      sorting = "infreq",
      na_rm = TRUE
    )
  ) |>
  
  info_columns(
    columns = vars(funding_availability),
    info = "The specific funding status assigned to the project (e.g., 'Fully Funded', 'Seed Funding Identified'). Confirms financial viability at various stages.",
    Items = "This column contains {list_funding_availability}."
  ) |>
  
  info_snippet(
    snippet_name = "list_funding_availability",
    fn = snip_list(
      column = "funding_availability",
      limit = 10,
      sorting = "infreq",
      na_rm = TRUE
    )
  ) |>
  
info_columns(
  columns = vars(funding_sourced),
  info = "Response to the question: 'Have you sourced the necessary funding for this project?'. Indicates whether the necessary funding for the project has been sourced.",
  Items = "This column contains {list_funding_sourced}."
) |>
  
  info_snippet(
    snippet_name = "list_funding_sourced",
    fn = snip_list(
      column = "funding_sourced",
      limit = 10,
      sorting = "infreq",
      na_rm = TRUE
    )
  ) |>
  
  info_columns(
    columns = vars(impact_analysis_required),
    info = "A flag indicating the necessity for a formal, dedicated impact analysis (e.g., clinical/operational risk assessment) before proceeding with development or implementation.",
    Items = "This column contains {list_impact_analysis_required}."
  ) |>
  
  info_snippet(
    snippet_name = "list_impact_analysis_required",
    fn = snip_list(
      column = "impact_analysis_required",
      limit = 10,
      sorting = "infreq",
      na_rm = TRUE
    )
  ) |>
  
info_columns(
  columns = vars(board_priority_rank),
  info = "Priority rank assigned during the prioritisation process. Lower numbers indicate higher priority (e.g. 1 = highest priority).",
  Items = "Numeric values."
) |>

  info_snippet(
    snippet_name = "list_board_priority_rank",
    fn = snip_list(
      column = "board_priority_rank",
      limit = 10,
      sorting = "infreq",
      na_rm = TRUE
    )
  ) |>
  
  info_columns(
    columns = vars(impact_value),
    info = "Numeric impact score associated with the request, with higher numbers meaning greater potential impact (e.g. 0 = low impact, 5 = high impact).",
    Items = "Numeric values."
  ) |>

  info_snippet(
    snippet_name = "list_impact_value",
    fn = snip_list(
      column = "impact_value",
      limit = 10,
      sorting = "infreq",
      na_rm = TRUE
    )
  ) |>
  
  info_columns(
    columns = vars(risk_score),
    info = "Numeric risk score associated with the request (25 = high risk, 0 = low risk).",
    Items = "Numeric values."
  ) |>
  
  info_snippet(
    snippet_name = "list_risk_score",
    fn = snip_list(
      column = "risk_score",
      limit = 10,
      sorting = "infreq",
      na_rm = TRUE
    )
  ) |>
  
  info_columns(
    columns = vars(updates),
    info = "Number of updates recorded against the request.",
    Items = "Numeric values."
  ) |>
  
  info_snippet(
    snippet_name = "list_updates",
    fn = snip_list(
      column = "updates",
      limit = 10,
      sorting = "infreq",
      na_rm = TRUE
    )
  ) |>
  
info_columns(
    columns = vars(opened),
    info = "The official date and time when the digital request was formally initiated or submitted into the prioritisation system record. Key start metric.",
    Items = "Date-time values."
  ) |>
  
  info_snippet(
    snippet_name = "list_opened",
    fn = snip_list(
      column = "opened",
      limit = 10,
      sorting = "infreq",
      na_rm = TRUE
    )
  ) |>
  
  info_columns(
    columns = vars(created),
    info = "The date and time when the underlying digital request record was first created in the tracking system (System creation timestamp).",
    Items = "Date-time values."
  ) |>
  
  info_snippet(
    snippet_name = "list_created",
    fn = snip_list(
      column = "created",
      limit = 10,
      sorting = "infreq",
      na_rm = TRUE
    )
  ) |>
  
  info_columns(
    columns = vars(closed),
    Items = "Date-time values.",
    info = "The date and time on which the digital request status transitioned to 'Closed', marking its formal completion or archival in the system."
  ) |>
  
  info_snippet(
    snippet_name = "list_closed",
    fn = snip_list(
      column = "closed",
      limit = 10,
      sorting = "infreq",
      na_rm = TRUE
    )
  ) |>
  
  info_columns(
    columns = vars(project_title),
    Items = "Free-text field.",
    info = "The user-generated title for the digital request. This may not be unique and is often a brief summary of the request's purpose or intended outcome. It may not reflect the full scope of the request. The title is often used in reporting and dashboards to identify the request."
  ) |>
  
  info_columns(
    columns = vars(background),
    Items = "Free-text field.",
    info = "Free-text response to the following question: 'What is the context of the project, & why is the work needed? Briefly describe the idea or problem & discuss why this project is relevant & timely. The details will come later. Use this section to highlight briefly how this project came about.' i.e. Detailed free-text narrative context providing the background and justification for why this digital request is necessary, detailing current system gaps or processes needing improvement."
  ) |>
  
  info_columns(
    columns = vars(benefits),
    Items = "Free-text field.",
    info = "Free-text response to the question: 'Why are you carrying out this project, & what benefits do you expect it to deliver? Include information on how these benefits will be measured. What is the scale of the benefits in terms of impact on clinical effectiveness and quality of care provision?'. Describes the expected tangible or intangible benefits, how they will be measured, and their impact on clinical effectiveness and quality of care."
  ) |>
  
  info_columns(
    columns = vars(objectives),
    Items = "Free-text field.",
    info = "Free-text response to the question: 'What specific outcomes will be achieved, & how will you measure these outcomes? Try to limit the number of objectives for your project – four or five goals are typically enough.'. Captures the specific outcomes the digital request aims to achieve and how success will be measured."
  ) |>
  
  info_columns(
    columns = vars(project_scope),
    Items = "Free-text field.",
    info = "Free-text response to the question: 'What are the boundaries for this project (for example, type of work, type of client, type of problem, areas covered)?'. Describes the boundaries of the project, i.e. what is in scope."
  ) |>
  
  info_columns(
    columns = vars(deliverables),
    Items = "Free-text field.",
    info = "Free-text response to the question: 'What will the project deliver as outputs? Where you can, describe deliverables as tangible items like reports, products, or services. If known, include a date that each deliverable is expected.'. Lists the anticipated outputs of the project and, where known, their expected dates."
  ) |>
  
  info_columns(
    columns = vars(requested_for),
    Items = "Staff names.",
    info = "The individual or service (e.g., 'Radiology Department', 'IT Support') that is the primary recipient of the proposed digital solution or workflow enhancement."
  ) |>
  
  info_columns(
    columns = vars(opened_by),
    Items = "Staff names.",
    info = "The name or department of the individual who initiated and authored this digital request record within the system."
  ) |>
  
  info_columns(
    columns = vars(assigned_to),
    Items = "Staff names.",
    info = "The name of the individual currently holding ownership and responsibility for driving the progress of the digital request towards completion."
  ) |>
  
  info_columns(
    columns = vars(demand_manager),
    Items = "Staff names.",
    info = "The designated information services-based Demand Manager responsible for overseeing and guiding the overall progress of this digital request through the prioritisation lifecycle."
  ) |>
  
  info_columns(
    columns = vars(closed_by),
    Items = "Staff names.",
    info = "The name or department of the individual/party authorised to formally close and archive the digital request record in the system. Requires formal sign-off."
  ) |> 
  
  info_columns(
    columns = vars(business_justification),
    Items = "Free-text field.",
    info = "A concise explanation of the underlying business necessity or problem that necessitates this digital request, providing justification for resource allocation."
  ) |>
  
  info_columns(
    columns = vars(purpose),
    Items = "Free-text field.",
    info = "Free-text response to the question: 'Why are you doing this work? Describe the desired result of this project. Is this part of a wider business case? What are the primary clinical drivers for this project? Please elaborate on the underlying motivations and the expected improvements in patient care or operational processes.'. Describes the reason for the work, its desired result, and its clinical drivers."
  ) |>
  
  info_columns(
    columns = vars(risk_identification),
    Items = "Free-text field.",
    info = "Free-text response to the question: 'What are the risks if the project is not done? What specific clinical risks and hazards have been identified in relation to this project? Please provide detailed descriptions of each risk and hazard, including the potential implications for patient safety, clinical outcomes, and operational efficiency.'. Captures identified risks and hazards, including their implications for patient safety, clinical outcomes and operational efficiency."
  ) |>
  
  info_columns(
    columns = vars(risk_monitoring),
    Items = "Free-text field.",
    info = "Free-text response to the question: 'Where you can't prevent risks, what are your contingency plans for dealing with them? What actions will you take should the risk materialise?'. Captures contingency plans and actions to take if identified risks materialise."
  ) |>
  
  info_columns(
    columns = vars(risk_prevention_management),
    Items = "Free-text field.",
    info = "Free-text response to the question: 'What workarounds are currently in place? What are you currently doing to mitigate the risk?'. Describes current workarounds and mitigation measures for the identified risks."
  ) |> 
  
  info_columns(
    columns = vars(previous_ref),
    Items = "Reference identifiers.",
    info = "A reference ID or unique identifier linking this request to a previous, legacy digital project or request informed its current requirements."
  ) |>
  
  info_columns(
    columns = vars(downstream_teams_based_on_initial_analysis),
    Items = "Team names.",
    info = "A comma-separated string of departments, services, and/or clinical teams that are anticipated to be involved in the design, build, or ongoing usage/maintenance of this digital request solution."
  ) |>
  
  info_columns(
    columns = vars(additional_comments),
    Items = "Free-text field.",
    info = "General administrative notes maintained by the PMO or stakeholders regarding operational issues, scope changes, or discussion points throughout the request lifecycle, outside of formal fields."
  ) |>
  
  info_columns(
    columns = vars(approval_history),
    Items = "Free-text field.",
    info = "The name of the individual who approved the digital request so it progressed to the next stage of the prioritisation process, along with the date and time of approval."
  ) |>
  
  info_columns(
    columns = vars(assumptions),
    Items = "Free-text field.",
    info = "Free-text response to the question: 'What assumptions are you making at the start of the project? If necessary, schedule work to confirm these assumptions'. This field is intended to capture any assumptions that may impact the design, implementation, or expected outcomes of the digital request."
  ) |>
  
  info_columns(
    columns = vars(clinical_risk_datix_ref),
    Items = "Reference identifiers.",
    info = "Free-text response to the form field: 'Provide Clinical Risk / Datix Ref (if any)'. Reference number(s) of any related clinical risk or Datix record linked to this request."
  ) |>
  
  # info_columns(
  #   columns = vars(constraints),
  #   Items = "Free-text field.",
  #   info = "Free-text response to the question: 'What things must you take into consideration that will influence your deliverables & schedule? These are external variables that you cannot control but need to manage.'. Captures external constraints that influence deliverables and schedule."
  # ) |>
  
  info_columns(
    columns = vars(contact_type),
    Items = "Contact method.",
    info = "Field of uncertain value. It may indicate the preferred method of contact for the requestor or stakeholders (e.g., 'Email', 'Phone', 'In-person')"
  ) |>
  
  info_columns(
    columns = vars(demand),
    Items = "Free-text field.",
    info = "An alternative project title that provides a descriptive name for the request and also includes the unique identifier (digital_request_number)."
  ) |>
  
  info_columns(
    columns = vars(escalation),
    Items = "Escalation category.",
    info = "Field of uncertain value. It may indicate the escalation status or category of the request (e.g., 'Normal')."
  ) |>
  
  info_columns(
    columns = vars(exclusions_from_scope),
    Items = "Free-text field.",
    info = "Free-text response to the question: 'List any areas excluded that you believe stakeholders might assume are included but are not. The more specific you are, the less opportunity there is for misunderstanding at a later stage in the project.'. Lists areas explicitly out of scope."
  ) |>
  
  info_columns(
    columns = vars(imported_notes),
    Items = "Free-text field.",
    info = "Information pulled forward into this record from previous legacy systems."
  ) |>
  
  info_columns(
    columns = vars(interface),
    Items = "Free-text field.",
    info = "Free-text response to the question: 'Will this change require an interface with existing systems or software e.g. SystmOne or PAS?'. Describes any required interfaces with existing systems or software."
  ) |>
  
  info_columns(
    columns = vars(previous_stage),
    Items = "Workflow stage identifiers.",
    info = "Workflow stage occupied prior to the current stage."
  ) |>
  
  info_columns(
    columns = vars(reporting_resource),
    Items = "Free-text field.",
    info = "Free-text response to the form field 'Reporting / Resource': 'Describe the current & proposed arrangements for: performance & management reporting and financial data flows; mandated national data flows; clinical & operational reporting and data flows - required both internal & external to the Trust'. Captures current and proposed reporting and data flow arrangements."
  ) |>
  
  info_columns(
    columns = vars(work_notes),
    Items = "Free-text field.",
    info = "Audit trail and operational notes recorded during request management."
  ) |>

  # Incorporate ---------------------------------

incorporate()

# Write the informant to YAML ---------------------------------------------

if (!dir.exists("./03_data_dictionary")) {
  dir.create(
    "./03_data_dictionary",
    recursive = TRUE
  )
}

yaml_write(
  informant_data_dig_req,
  filename = "data_dig_req.yml",
  path = "./03_data_dictionary"
)

# View in browser (optional) ----------------------------------------------

informant_data_dig_req

