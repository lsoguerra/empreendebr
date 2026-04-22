
###############################
## RADAR
################################

#' Library dos pacotes necessários 
library(basedosdados)
library(dplyr)
library(fixest)
library(data.table)
library(tidyverse)
library(bit64)
library(tidyr)
library(readxl)
library(here)

here()
set_billing_id("empreendebr")

df <- read_sql(
  "SELECT 
     ano, 
     id_municipio, 
     SUBSTRING(cnae_2_subclasse, 1, 4) AS quatro, 
     COUNT(*) AS numero, 
     SUM(quantidade_vinculos_ativos) AS vinc_atv,
     SUM(indicador_rais_negativa) AS numero_negativas
   FROM `basedosdados.br_me_rais.microdados_estabelecimentos`
   WHERE ano >= 2017
      AND quantidade_vinculos_ativos >= 1 
      AND CAST(natureza_juridica as INT64) > 2038
   GROUP BY 
     ano, 
     id_municipio, 
     SUBSTRING(cnae_2_subclasse, 1, 4)
   ORDER BY 
     ano, 
     id_municipio"
)

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
df <- df %>% left_join(cnae_1dig, by=c("quatro"="cnae"))

#' Reagrupando RAIS
setDT(df)
df1 <- df[, .(numero = sum(numero)
             ),
         by = .(ano, id_municipio, cnae1)]
write.csv(df1, file="numero.csv", row.names = FALSE)


df2 <- df[, .(vinc_atv = sum(vinc_atv)
),
by = .(ano, id_municipio, cnae1)]
write.csv(df2, file="vinc.csv", row.names = FALSE)

