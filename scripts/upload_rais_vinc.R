
###############################
## Upload: RAIS
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

set_billing_id("empreendebr")
data <- read_sql("
  SELECT ano, 
    id_municipio, 
    SUBSTRING(cnae_2_subclasse, 1, 4) AS quatro, 
    AVG(valor_remuneracao_dezembro) AS avg_wage,
    FROM `basedosdados.br_me_rais.microdados_vinculos`
  WHERE ano >= 2017
  AND CAST(natureza_juridica as INT64) > 2038
  AND CAST(vinculo_ativo_3112 as INT64) = 1
  AND quantidade_horas_contratadas > 0
  GROUP BY 
     ano, 
     id_municipio, 
     quatro
   ORDER BY 
     ano, 
     id_municipio")

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
df3 <- df[, .(avg_wage = mean(avg_wage)),
          by = .(ano, id_municipio, cnae1)]
writexl::write_xlsx(df3, path="raisvinc_cnae1.xlsx")
write.csv(df3, file="salario.csv", row.names = FALSE)
