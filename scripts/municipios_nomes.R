library(tidyverse)
library(geobr)

municipios <- read_csv("~/Documents/GitHub/empreender/data/numero.csv", show_col_types = FALSE) |>
  distinct(id_municipio) |>
  arrange(id_municipio)

nomes <- read_municipality(year = 2020, showProgress = FALSE) |>
  as_tibble() |>
  select(code_muni, name_muni, abbrev_state) |>
  mutate(code_muni = as.character(code_muni))

municipios |>
  mutate(id_municipio = as.character(id_municipio)) |>
  left_join(nomes, by = c("id_municipio" = "code_muni")) |>
  mutate(
    js = paste0('  ["', id_municipio, '","', name_muni, '","', abbrev_state, '"]')
  ) |>
  arrange(abbrev_state, name_muni) |>
  pull(js) |>
  paste(collapse = ",\n") |>
  writeLines("municipios_js.txt")