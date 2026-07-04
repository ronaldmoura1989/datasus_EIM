# =============================================================================
# sia_procedimentos_sigtap.R — Procedimentos SIGTAP mais frequentes no SIA-EIM
#
# A coluna pa_proc_id (10 dígitos) do SIA carrega o procedimento SIGTAP. Este
# script tabula os procedimentos mais frequentes (global e por traçadora) e
# resolve os NOMES via a tabela SIGTAP.
#
# FONTE DOS NOMES: microdatasus::sigtab (dataset embutido no pacote,
#   COD 10-díg + nome_proced; ~5.472 procedimentos). Fallback opcional:
#   microdatasus::fetch_sigtab() (baixa competência mais recente; requer rede).
#   Cobertura observada nos top-N do EIM: ~96% dos códigos têm nome. Códigos sem
#   nome saem marcados "[VERIFICAR nome SIGTAP]".
#
# Saída: manifest/sia_procedimentos_top.csv (global + por traçadora, com nome,
#   contagem, valor aprovado). Supressão N<5 (LGPD).
#
# Rodar: source("scripts/00_setup.R"); source("scripts/sia_procedimentos_sigtap.R")
# =============================================================================

if (!exists("EIM_LOOKUP")) source(here::here("scripts", "00_setup.R"))

# -----------------------------------------------------------------------------
# 1. Tabela SIGTAP de nomes de procedimento
# -----------------------------------------------------------------------------
carregar_sigtap <- function() {
  # Preferir dataset embutido (offline, reprodutível). fetch_sigtab só se ausente.
  ok <- requireNamespace("microdatasus", quietly = TRUE)
  if (ok) {
    sig <- tryCatch({
      e <- new.env()
      utils::data("sigtab", package = "microdatasus", envir = e)
      get("sigtab", envir = e)
    }, error = function(...) NULL)
    if (!is.null(sig)) {
      return(tibble::as_tibble(sig) |>
               dplyr::transmute(pa_proc_id = as.character(COD),
                                nome_proc  = as.character(nome_proced)))
    }
    # fallback: download da competência mais recente
    sig <- tryCatch(microdatasus::fetch_sigtab(), error = function(...) NULL)
    if (!is.null(sig)) {
      nm <- names(sig)
      cod_col  <- nm[grepl("^COD", nm, ignore.case = TRUE)][1]
      nome_col <- nm[grepl("nome|proced|descr", nm, ignore.case = TRUE)][1]
      return(tibble::as_tibble(sig) |>
               dplyr::transmute(pa_proc_id = as.character(.data[[cod_col]]),
                                nome_proc  = as.character(.data[[nome_col]])))
    }
  }
  warning("SIGTAP indisponível — nomes marcados [VERIFICAR nome SIGTAP].")
  tibble::tibble(pa_proc_id = character(), nome_proc = character())
}

sigtap <- carregar_sigtap()
message(sprintf("SIGTAP: %d procedimentos com nome carregados.", nrow(sigtap)))

# -----------------------------------------------------------------------------
# 1b. OVERRIDES manuais de nomes SIGTAP
# -----------------------------------------------------------------------------
# Alguns procedimentos de alto custo (moduladores de CFTR, terapias avançadas)
# entram no SIA antes de constar na competência do dataset embutido
# microdatasus::sigtab, saindo marcados "[VERIFICAR nome SIGTAP]". Este
# data.frame cod->nome SOBRESCREVE/COMPLEMENTA a tabela SIGTAP: tem prioridade
# sobre o join padrão e cobre códigos ausentes. Fonte: tabela SIGTAP/SIGTAP-web
# (DATASUS) da competência vigente. Manter cod com 10 dígitos (character).
overrides <- tibble::tribble(
  ~pa_proc_id,   ~nome_proc,
  "0604860021",  "Elexacaftor 100 mg/tezacaftor 50 mg/ivacaftor 75 mg + ivacaftor 150 mg (por comprimido revestido)"
)

resolver_nome <- function(df) {
  df |>
    dplyr::left_join(sigtap, by = "pa_proc_id") |>
    # override manual tem prioridade: se houver nome em `overrides`, usa-o
    dplyr::left_join(dplyr::rename(overrides, nome_override = nome_proc),
                     by = "pa_proc_id") |>
    dplyr::mutate(
      nome_proc = dplyr::coalesce(nome_override, nome_proc),
      nome_proc = dplyr::if_else(is.na(nome_proc) | nome_proc == "",
                                 "[VERIFICAR nome SIGTAP]", nome_proc)) |>
    dplyr::select(-nome_override)
}

# -----------------------------------------------------------------------------
# 2. SIA core
# -----------------------------------------------------------------------------
sia <- readRDS(here::here("data/consolidated/sia_eim_core.rds")) |>
  dplyr::filter(camada == "core") |>
  dplyr::select(pa_proc_id, tracadora, subgrupo, pa_qtdapr, pa_valapr)

# -----------------------------------------------------------------------------
# 3. Top procedimentos GLOBAL (por volume de registros)
# -----------------------------------------------------------------------------
top_global <- sia |>
  dplyr::group_by(pa_proc_id) |>
  dplyr::summarise(registros = dplyr::n(),
                   qtd_apr   = sum(pa_qtdapr, na.rm = TRUE),
                   valor_apr = sum(pa_valapr, na.rm = TRUE),
                   .groups = "drop") |>
  dplyr::filter(registros >= N_SUPRESSAO) |>
  dplyr::arrange(dplyr::desc(registros)) |>
  resolver_nome() |>
  dplyr::mutate(tracadora = "TODAS") |>
  dplyr::slice_head(n = 30)

# -----------------------------------------------------------------------------
# 4. Top procedimentos POR traçadora (top 8 de cada)
# -----------------------------------------------------------------------------
top_tracadora <- sia |>
  dplyr::filter(!is.na(tracadora)) |>
  dplyr::group_by(tracadora, pa_proc_id) |>
  dplyr::summarise(registros = dplyr::n(),
                   qtd_apr   = sum(pa_qtdapr, na.rm = TRUE),
                   valor_apr = sum(pa_valapr, na.rm = TRUE),
                   .groups = "drop") |>
  dplyr::filter(registros >= N_SUPRESSAO) |>
  dplyr::group_by(tracadora) |>
  dplyr::slice_max(registros, n = 8, with_ties = FALSE) |>
  dplyr::ungroup() |>
  resolver_nome()

# -----------------------------------------------------------------------------
# 5. Persistir manifest (global + por traçadora, empilhados)
# -----------------------------------------------------------------------------
manifest <- dplyr::bind_rows(
  dplyr::select(top_global,   tracadora, pa_proc_id, nome_proc, registros, qtd_apr, valor_apr),
  dplyr::select(top_tracadora, tracadora, pa_proc_id, nome_proc, registros, qtd_apr, valor_apr)
)
readr::write_csv(manifest, here::here("manifest", "sia_procedimentos_top.csv"))

cat("\n== Top 15 procedimentos SIGTAP (global) ==\n")
print(as.data.frame(dplyr::select(dplyr::slice_head(top_global, n = 15),
                                  pa_proc_id, nome_proc, registros)))

match_rate <- mean(top_global$nome_proc != "[VERIFICAR nome SIGTAP]")
message(sprintf("\n✓ SIGTAP: %.0f%% dos top-30 globais nomeados. → manifest/sia_procedimentos_top.csv",
                100 * match_rate))
