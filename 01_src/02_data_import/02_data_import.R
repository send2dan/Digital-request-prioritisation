data_dig_req_original <- read_excel(here::here("02_data", "dmn_demand (3).xlsx")) |> 
  clean_names()

data_dig_req <- data_dig_req_original |> 
  filter_out(!is.na(closed_by))
             
# data_dig_req |>
#   skimr::skim()

# data_dig_req |>
#   btw::btw()

