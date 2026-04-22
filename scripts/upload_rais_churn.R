
###############################
## Upload: RAIS churn
################################

data <- read_sql("
  SELECT
    ano,
    id_municipio,
    SUBSTRING(cnae_2_subclasse, 1, 4) AS quatro, 
    COUNT(*) AS vinc_rvinc,

    -- admissões em FTE
    SUM(
      CASE WHEN mes_admissao IS NOT NULL AND mes_admissao <> 0
           THEN  1 
           ELSE 0 END
    ) AS admissoes,

    -- demissões em FTE
    SUM(
      CASE WHEN mes_desligamento IS NOT NULL AND mes_desligamento <> 0
           THEN 1
           ELSE 0 END
    ) AS demissoes

  FROM `basedosdados.br_me_rais.microdados_vinculos`
  WHERE ano >= 2017
    AND SAFE_CAST(natureza_juridica AS INT64) > 2038
  GROUP BY ano, id_municipio, quatro
  ORDER BY ano, id_municipio, quatro
")

# CNAE-1
cnae_1dig <- read_excel("~/Documents/CCDandF/Bases/cnae_1dig.xlsx")
setnames(cnae_1dig, c("Seção A - Agricultura, pecuária, produção florestal, pesca e aqüicultura", "...2"), c("cnae", "cnae1"))
cnae_1dig$cnae <- str_replace(cnae_1dig$cnae, "-", "")
cnae_1dig$cnae <- str_remove(cnae_1dig$cnae, "\\.")
cnae_1dig$cnae <- as.numeric(cnae_1dig$cnae)
cnae_1dig$cnae <- ifelse(str_length(cnae_1dig$cnae)==4, paste0("0",cnae_1dig$cnae),cnae_1dig$cnae)
cnae_1dig$cnae <- str_sub(cnae_1dig$cnae,1,4)
cnae_1dig <- cnae_1dig %>% distinct(cnae, .keep_all=TRUE)
cnae_1dig <- cnae_1dig %>% filter(is.na(cnae)==FALSE)
#' Merge com RAIS
df <- data %>% left_join(cnae_1dig, by=c("quatro"="cnae"))

#' Reagrupando RAIS
setDT(df)
df3 <- df[, .(admissoes = sum(admissoes)),
          by = .(ano, id_municipio, cnae1)]
write.csv(df3, file="admissoes.csv", row.names = FALSE)

df4 <- df[, .(demissoes = sum(demissoes)),
          by = .(ano, id_municipio, cnae1)]
write.csv(df3, file="demissoes.csv", row.names = FALSE)
