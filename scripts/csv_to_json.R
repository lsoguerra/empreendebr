library(tidyverse)
library(jsonlite)

PASTA_CSVS  <- "~/Documents/GitHub/empreender/data"
PASTA_SAIDA <- "~/Documents/GitHub/empreender/data/"
dir.create(PASTA_SAIDA, showWarnings = FALSE)

ARQUIVOS <- list(
  #numero  = "numero.csv",
  #vinc    = "vinc.csv",
  #salario = "salario.csv",
  #admissoes = "admissoes.csv",
  #demissoes = "demissoes.csv",
   hhi     = "hhi.csv"
)

walk(names(ARQUIVOS), function(indicador) {
  cat("Processando:", indicador, "\n")
  
  df <- read_csv(file.path(PASTA_CSVS, ARQUIVOS[[indicador]]), show_col_types = FALSE) |>
    mutate(
      id_municipio = as.character(id_municipio),
      cnae1        = as.character(cnae1),
      ano          = as.integer(ano)
    ) |>
    rename(valor = last_col())
  
  # Estrutura: { "3543402": { "G": { anos: [...], valores: [...] } } }
  resultado <- df |>
    group_by(id_municipio, cnae1) |>
    arrange(ano) |>
    summarise(anos = list(ano), valores = list(valor), .groups = "drop") |>
    group_by(id_municipio) |>
    group_map(~ setNames(
      map2(.x$anos, .x$valores, ~list(anos = .x, valores = .y)),
      .x$cnae1
    )) |>
    setNames(group_keys(df |> group_by(id_municipio))$id_municipio)
  
  write_json(resultado, file.path(PASTA_SAIDA, paste0(indicador, ".json")),
             auto_unbox = TRUE, pretty = FALSE)
  
  cat("  →", file.size(file.path(PASTA_SAIDA, paste0(indicador, ".json"))) / 1024, "KB\n")
})

cat("\nPronto!\n")
