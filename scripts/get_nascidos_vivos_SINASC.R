# =============================================================================
# get_nascidos_vivos_SINASC.R — Denominador de INCIDÊNCIA AO NASCIMENTO (SINASC)
# Baixa o SINASC (nascidos vivos) por UF × ano via microdatasus (FTP DATASUS),
# agrega a CONTAGENS por UF × ano × sexo (residência da mãe = CODMUNRES) e
# DESCARTA os microdados. É o denominador das taxas de incidência ao nascimento
# das doenças-traçadoras de triagem neonatal (plano §4b).
#
# Estratégia (sugestão do usuário): baixar ANUAL para todos os estados, como o SIM.
# Disponibilidade: 2021–2024 (2025 provavelmente ainda não publicado → tenta e ignora).
# Cache: pula UF×ano já agregado. Saída: data/denominators/nascidos_vivos.parquet
# Rodar: Rscript scripts/get_nascidos_vivos_SINASC.R
# =============================================================================

source(here::here("scripts", "00_setup.R"))
suppressPackageStartupMessages(library(microdatasus))
options(timeout = 600)

ANOS_SINASC <- 2021:2024                      # 2025 raramente disponível; ajustar se sair
OUT <- here::here("data/denominators/nascidos_vivos.parquet")
CACHE <- here::here("data/denominators/_nv_cache")
dir.create(CACHE, showWarnings = FALSE, recursive = TRUE)

agrega_uf_ano <- function(uf, ano) {
  cache_fp <- file.path(CACHE, sprintf("nv_%s_%d.rds", uf, ano))
  if (file.exists(cache_fp)) return(readRDS(cache_fp))
  x <- tryCatch(
    fetch_datasus(year_start = ano, year_end = ano, uf = uf, information_system = "SINASC"),
    error = function(e) { message(sprintf("  %s %d: ERRO (%s) — pulando", uf, ano, conditionMessage(e))); NULL })
  if (is.null(x) || !nrow(x)) return(NULL)
  x <- janitor::clean_names(x)
  out <- x |>
    dplyr::mutate(
      uf   = uf_from_mun(codmunres),                 # UF de residência da mãe
      sexo = dplyr::recode(as.character(sexo), "1"="Masculino","2"="Feminino",
                           .default = NA_character_)) |>
    dplyr::filter(!is.na(uf)) |>
    dplyr::count(uf, sexo, name = "nv") |>
    dplyr::mutate(ano = ano)
  saveRDS(out, cache_fp)
  log_run("sinasc", uf, ano, "ok", n_lidas = nrow(x), n_eim = sum(out$nv))
  message(sprintf("  %s %d: %d nascidos vivos", uf, ano, sum(out$nv)))
  out
}

message("== SINASC: baixando e agregando nascidos vivos (UF × ano × sexo) ==")
grade <- tidyr::expand_grid(uf = UFS, ano = ANOS_SINASC)
nv <- purrr::pmap(grade, function(uf, ano) agrega_uf_ano(uf, ano)) |>
  purrr::compact() |> dplyr::bind_rows()

# QC: completude UF×ano e total nacional por ano
cat("\n• nascidos vivos por ano (Brasil):\n")
print(nv |> dplyr::group_by(ano) |> dplyr::summarise(nv = sum(nv),
      ufs = dplyr::n_distinct(uf)))

arrow::write_parquet(nv, OUT)
saveRDS(nv, here::here("data/denominators/nascidos_vivos.rds"))
message(sprintf("\n✓ SINASC: %d linhas (UF×ano×sexo) → %s", nrow(nv), basename(OUT)))
