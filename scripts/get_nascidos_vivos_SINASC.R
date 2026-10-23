# =============================================================================
# get_nascidos_vivos_SINASC.R — Denominador de INCIDÊNCIA AO NASCIMENTO (SINASC)
# Nascidos vivos por UF de residência da mãe (CODMUNRES) × ano × sexo, 2010+.
#
# FONTE: denominadores agregados pela filtragem dos DBC do DATASUS no R550-2
# (scripts/r550/filtrar_um.R → <DIR_FILTRADO>/SINASC/denominador/DN{UF}{AAAA}.parquet),
# calculados sobre TODAS as declarações de nascido vivo do arquivo. Substitui o
# download por microdatasus::fetch_datasus (que só cobria 2021–2024).
# Anos: ANOS_SINASC (definitivos); o ano PRELIMINAR (subpasta PRELIM no FTP) fica
# marcado em status_dado e fora do denominador padrão.
# Saída: data/denominators/nascidos_vivos.{parquet,rds} (uf, sexo, nv, ano, status_dado)
# Rodar: Rscript scripts/get_nascidos_vivos_SINASC.R
# =============================================================================

source(here::here("scripts", "00_setup.R"))

fs <- list.files(file.path(DIR_FILTRADO, "SINASC", "denominador"), pattern = "\\.parquet$", full.names = TRUE)
if (!length(fs)) stop("Sem denominadores do SINASC em ", DIR_FILTRADO)

nv <- purrr::map_dfr(fs, arrow::read_parquet) |>
  dplyr::transmute(uf = uf_res, ano = as.integer(arq_ano), status_dado,
                   sexo = dplyr::recode(as.character(sexo), "1" = "Masculino", "2" = "Feminino",
                                        .default = NA_character_),
                   nascidos) |>
  dplyr::filter(!is.na(uf)) |>
  dplyr::group_by(uf, sexo, ano, status_dado) |>
  dplyr::summarise(nv = sum(nascidos), .groups = "drop") |>
  dplyr::select(uf, sexo, nv, ano, status_dado) |>
  dplyr::arrange(ano, uf, sexo)

cat("\n• nascidos vivos por ano (Brasil):\n")
print(nv |> dplyr::group_by(ano, status_dado) |>
        dplyr::summarise(nv = sum(nv), ufs = dplyr::n_distinct(uf), .groups = "drop"), n = 30)
faltam <- setdiff(ANOS_SINASC, nv$ano[nv$status_dado == "DEFINITIVO"])
if (length(faltam)) warning("anos definitivos ausentes: ", paste(faltam, collapse = ", "))

arrow::write_parquet(nv, here::here("data/denominators/nascidos_vivos.parquet"))
saveRDS(nv, here::here("data/denominators/nascidos_vivos.rds"))
message(sprintf("\n✓ SINASC: %d linhas (UF×ano×sexo) → nascidos_vivos.parquet", nrow(nv)))
