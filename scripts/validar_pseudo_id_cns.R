# =============================================================================
# validar_pseudo_id_cns.R — Validação do pseudo-ID contra o CNS criptografado
#
# O pseudo-ID (pseudo_id_motor.R) estima pacientes distintos por quase-identificadores e
# publica um intervalo (frouxa–estrita, central = intermediária). O CNS criptografado das
# APAC (AM/AD, ligado ao PA pelo número da APAC — ver pacientes_cns_apac.R) dá o número
# verdadeiro. A comparação justa usa os MESMOS registros: APAC (pa_docorig P/S) da camada
# core, ligadas a um CNS. Mede, por subgrupo × escopo: o intervalo contém o verdadeiro? Qual
# o erro da estimativa central?
# PRIVACIDADE: o CNS só é contado; nenhuma saída o contém.
# Saída: manifest/validacao_pseudo_id_cns.csv
# Rodar no R550-2: Rscript scripts/validar_pseudo_id_cns.R
# =============================================================================
source(here::here("scripts", "00_setup.R"))
source(here::here("scripts", "pseudo_id_motor.R"))
suppressPackageStartupMessages(library(data.table))

ler_apac <- function(base) {
  fs <- list.files(file.path(DIR_FILTRADO, base, "filtrado"), pattern = "\\.parquet$", full.names = TRUE)
  rbindlist(parallel::mclapply(fs, function(f)
    as.data.table(arrow::read_parquet(f, col_select = c("AP_AUTORIZ", "AP_CNSPCN"))), mc.cores = 24))
}
ap <- unique(rbind(ler_apac("SIA-AM"), ler_apac("SIA-AD")))[!is.na(AP_CNSPCN) & nchar(AP_CNSPCN) == 30]
ap <- ap[, .(cns = AP_CNSPCN[1]), by = AP_AUTORIZ]

sia <- readRDS(here::here("data/consolidated/sia_eim_core_limitrofe.rds")) |>
  dplyr::filter(camada == "core", pa_docorig %in% c("P", "S")) |>
  dplyr::select(subgrupo, uf_pcn, sexo, idade_anos, pa_munpcn, pa_racacor, competencia, ano, pa_autoriz, pa_docorig, pa_proc_id)
sia <- dplyr::inner_join(sia, as.data.frame(ap), by = c("pa_autoriz" = "AP_AUTORIZ"))   # só registros com CNS
sia <- normalizar_quase_id(sia)

valida <- function(s, escopo) {
  r <- resumo_gradiente(s)
  tibble::tibble(escopo = escopo, subgrupo = s$subgrupo[1], registros = nrow(s),
                 pacientes_cns = dplyr::n_distinct(s$cns),
                 pseudo_frouxa = r$pseudo_frouxa, pseudo_central = r$pseudo_intermediaria, pseudo_estrita = r$pseudo_estrita)
}
grupos_br <- c("fibrose_cistica", "aminoacidopatia_PKU", "esfingolipidose_outras", "mucopolissacaridose",
               "hiperplasia_adrenal_cong", "amiloidose_familiar", "metab_cobre")
res <- dplyr::bind_rows(
  purrr::map(grupos_br, ~ valida(dplyr::filter(sia, subgrupo == .x), "Brasil")),
  purrr::map(unique(sia$subgrupo[sia$uf_pcn %in% "PE"]), ~ valida(dplyr::filter(sia, subgrupo == .x, uf_pcn %in% "PE"), "PE"))) |>
  dplyr::filter(pacientes_cns >= N_SUPRESSAO) |>
  dplyr::mutate(dentro_do_intervalo = pacientes_cns >= pseudo_frouxa & pacientes_cns <= pseudo_estrita,
                erro_central_pct = round(100 * (pseudo_central / pacientes_cns - 1), 1),
                erro_frouxa_pct = round(100 * (pseudo_frouxa / pacientes_cns - 1), 1),
                erro_estrita_pct = round(100 * (pseudo_estrita / pacientes_cns - 1), 1)) |>
  dplyr::arrange(escopo, dplyr::desc(pacientes_cns))
readr::write_csv(res, here::here("manifest/validacao_pseudo_id_cns.csv"))
print(as.data.frame(res))
cat(sprintf("\nIntervalo contém o verdadeiro em %d de %d subgrupos; erro absoluto mediano da central: %.1f%%\n",
            sum(res$dentro_do_intervalo), nrow(res), median(abs(res$erro_central_pct))))
message("✓ validar_pseudo_id_cns.R")
