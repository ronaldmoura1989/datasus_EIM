# =============================================================================
# get_denominadores_ibge.R — Denominador populacional IBGE (Censo 2022, SIDRA 9514)
# Estrutura UF × sexo × faixa QUINQUENAL (FAIXAS_PAD), CONSTANTE para 2021–2025.
# Herdado do projeto HS (mesma decisão: estrutura Censo 2022 constante evita o degrau
# Censo↔projeção; taxas são de detecção/uso e a tendência é guiada pelo numerador).
# Denominador das taxas populacionais (SIA/SIH/SIM por 100 mil hab, padronizadas).
# (Para incidência ao nascimento, o denominador é o SINASC — script à parte.)
# Cache: skip-if-exists. Saída: data/denominators/pop_ibge.parquet
# =============================================================================

source(here::here("scripts", "00_setup.R"))
suppressPackageStartupMessages(library(sidrar))
options(timeout = 600)

OUT_PARQUET <- here::here("data/denominators/pop_ibge.parquet")
OUT_RDS     <- here::here("data/denominators/pop_ibge.rds")
if (file.exists(OUT_PARQUET)) { message("Denominadores em cache — skip. Apague p/ refazer."); quit(save="no") }

# Grupos quinquenais (c287) da tab 9514. O agregado "80+" (113623) vem vazio →
# somar 49108(80-84)+49109(85-89)+49110(90+).
GRUPOS <- c(93070,93084,93085,93086,93087,93088,93089,93090,93091,93092,
            93093,93094,93095,93096,93097,93098, 49108,49109,49110)
FAIXA_LEVELS <- levels(harmonizar_faixa(seq(0, 85, by = 5), breaks = FAIXAS_PAD))

uf_sigla <- function(nome) {
  m <- c("Rondônia"="RO","Acre"="AC","Amazonas"="AM","Roraima"="RR","Pará"="PA",
         "Amapá"="AP","Tocantins"="TO","Maranhão"="MA","Piauí"="PI","Ceará"="CE",
         "Rio Grande do Norte"="RN","Paraíba"="PB","Pernambuco"="PE","Alagoas"="AL",
         "Sergipe"="SE","Bahia"="BA","Minas Gerais"="MG","Espírito Santo"="ES",
         "Rio de Janeiro"="RJ","São Paulo"="SP","Paraná"="PR","Santa Catarina"="SC",
         "Rio Grande do Sul"="RS","Mato Grosso do Sul"="MS","Mato Grosso"="MT",
         "Goiás"="GO","Distrito Federal"="DF")
  unname(m[nome])
}
faixa_label <- function(desc) {
  lo <- suppressWarnings(as.integer(stringr::str_extract(desc, "^\\d+")))
  dplyr::case_when(is.na(lo) ~ NA_character_, lo >= 80 ~ "80+",
                   TRUE ~ stringr::str_replace(desc, "(\\d+) a (\\d+) anos", "\\1-\\2"))
}

message("== SIDRA 9514: Censo 2022 (UF × sexo × idade) ==")
api_censo <- paste0("/t/9514/n3/all/v/93/p/2022/c2/4,5/c287/",
                    paste(GRUPOS, collapse=","), "/c286/113635")
censo <- sidrar::get_sidra(api = api_censo) |> janitor::clean_names()

pop_estrutura <- censo |>
  dplyr::transmute(uf = uf_sigla(unidade_da_federacao),
                   sexo = dplyr::recode(sexo, "Homens"="Masculino","Mulheres"="Feminino"),
                   faixa = faixa_label(idade), pop = as.numeric(valor)) |>
  dplyr::filter(!is.na(uf), !is.na(faixa), !is.na(pop)) |>
  dplyr::group_by(uf, sexo, faixa) |>
  dplyr::summarise(pop = sum(pop), .groups = "drop")

pop_ibge <- tidyr::expand_grid(ano = ANOS, pop_estrutura) |>
  dplyr::mutate(faixa = factor(faixa, levels = FAIXA_LEVELS),
                regiao = mapear_uf_regiao(uf), base_pop = "censo2022_constante") |>
  dplyr::select(regiao, uf, ano, sexo, faixa, pop, base_pop)

cat(sprintf("\n• dimensões: %d (esperado 27×%d×2×%d) | faixa NA: %d\n",
            nrow(pop_ibge), length(ANOS), length(FAIXA_LEVELS), sum(is.na(pop_ibge$faixa))))
cat(sprintf("• Brasil 2022: %s\n", format(sum(dplyr::filter(pop_ibge, ano==2022)$pop),
            big.mark=".", scientific=FALSE)))

arrow::write_parquet(pop_ibge, OUT_PARQUET); saveRDS(pop_ibge, OUT_RDS)
message(sprintf("\n✓ Denominadores IBGE (Censo 2022 constante): %d linhas → %s",
                nrow(pop_ibge), basename(OUT_PARQUET)))
