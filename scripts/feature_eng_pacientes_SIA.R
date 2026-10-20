# =============================================================================
# feature_eng_pacientes_SIA.R — Pseudo-individualização do SIA-PA (EIM)
# Adaptado de datasus_HS/scripts/feature_eng_pacientes_SIA.R (ver datasus_hs.md §5.1).
#
# O SIA-PA público NÃO tem identificador de paciente (CNS). Construímos um
# pseudo-ID por record linkage determinístico sobre quase-identificadores:
#   blocking sexo × pa_munpcn [× raça], janela ano_nasc±1, ligação certa por nº de
#   APAC, resolução de entidade por componentes conexos (igraph). Gradiente
#   estrita↔intermediária↔frouxa. Motor em scripts/pseudo_id_motor.R (v2, out/2026:
#   raça deixou de ser requisito de chave completa — ver cabeçalho do motor).
#
# PRINCÍPIO INEGOCIÁVEL (LGPD, §5.1 HS): o pseudo-ID é um AGRUPADOR de registros
#   compatíveis, NÃO um identificador de pessoas. O nº de pacientes sai como
#   INTERVALO [registros ; pseudo-pacientes], nunca ponto. Só agregados; supressão
#   N<5; nunca publicar a chave.
#
# CAUTELA ESPECÍFICA DO EIM: a idade no SIA está em ANOS INTEIROS → ano_nasc_proxy
#   tem RESOLUÇÃO RUIM em <1 ano (não distingue neonatos de lactentes). O pseudo-ID
#   é, portanto, um limite grosseiro; interpretar razão registros/paciente como
#   INTENSIDADE DE USO, não contagem de pessoas.
#
# ESCOPO: aplica só à camada CORE e, dado o volume (~1M registros), foca nos
#   subgrupos crônicos de ALTO VOLUME (supressão domina os raros). Salva
#   manifest/sia_pseudo_pacientes.csv.
#
# Rodar: source("scripts/00_setup.R"); source("scripts/feature_eng_pacientes_SIA.R")
#   ou   Rscript scripts/feature_eng_pacientes_SIA.R
# =============================================================================

if (!exists("EIM_LOOKUP")) source(here::here("scripts", "00_setup.R"))
suppressPackageStartupMessages({ library(data.table); library(igraph) })

# Subgrupos-alvo: crônicos de alto volume (mapeados aos subgrupos do core do EIM).
# Doenças de N baixo são puladas (supressão N<5 domina o linkage).
SUBGRUPOS_ALVO <- c(
  "fibrose_cistica",            # fibrose_cistica
  "aminoacidopatia_PKU",        # aminoacidopatia_PKU
  "esfingolipidose_outras",     # esfingolipidose (Gaucher/Fabry/NP-C)
  "mucopolissacaridose",        # mucopolissacaridose
  "hipotireoidismo_congenito"   # hipotireoidismo_congenito
)

# -----------------------------------------------------------------------------
# 1. Carregar core + normalizar quase-identificadores (motor compartilhado)
# -----------------------------------------------------------------------------
source(here::here("scripts", "pseudo_id_motor.R"))

sia_core <- readRDS(here::here("data/consolidated/sia_eim_core_limitrofe.rds")) |>
  dplyr::filter(camada == "core", subgrupo %in% SUBGRUPOS_ALVO) |>
  dplyr::select(subgrupo, tracadora, sexo, idade_anos, pa_munpcn, pa_racacor,
                competencia, ano, pa_autoriz, pa_docorig, pa_proc_id)

message(sprintf("SIA core alvo: %d registros em %d subgrupos.",
                nrow(sia_core), dplyr::n_distinct(sia_core$subgrupo)))

sia_core <- normalizar_quase_id(sia_core)

# -----------------------------------------------------------------------------
# 2. Gradiente de chaves por subgrupo (intervalo de pacientes) — ver pseudo_id_motor.R
# -----------------------------------------------------------------------------
resumo_subgrupo <- function(sub) {
  s <- dplyr::filter(sia_core, subgrupo == sub)
  r <- resumo_gradiente(s)
  tibble::tibble(
    subgrupo = sub,
    registros = r$registros,
    pseudo_pac_estrita       = r$pseudo_estrita,        # limite superior de pacientes
    pseudo_pac_intermediaria = r$pseudo_intermediaria,  # estimativa central
    pseudo_pac_frouxa        = r$pseudo_frouxa,         # limite inferior de pacientes
    # razão registros/paciente pela chave central (intensidade de uso)
    razao_registros_paciente = round(r$registros / r$pseudo_intermediaria, 2),
    pct_chave_completa = r$pct_chave_completa,
    # referência externa: pacientes/mês no CEAF (APAC com medicamento, mediana 2024)
    ref_ceaf_mes = ref_ceaf_mes(s)
  )
}

message("== Linkage por subgrupo (gradiente estrita↔frouxa) ==")
res <- purrr::map_dfr(SUBGRUPOS_ALVO, function(sub) {
  message("  · ", sub)
  resumo_subgrupo(sub)
})

# Supressão LGPD N<5 nos pseudo-pacientes (defensivo; alvos são alto volume)
res <- res |>
  dplyr::mutate(dplyr::across(dplyr::starts_with("pseudo_pac_"),
                              ~ dplyr::if_else(!is.na(.x) & .x < N_SUPRESSAO, NA_integer_, .x)))

cat("\n"); print(as.data.frame(res))

# -----------------------------------------------------------------------------
# 4. Persistir manifest
# -----------------------------------------------------------------------------
saida <- res |>
  dplyr::transmute(
    subgrupo,
    registros,
    pseudo_pac_estrita,
    pseudo_pac_frouxa,
    pseudo_pac_intermediaria,
    razao = razao_registros_paciente,
    pct_chave_completa,
    ref_ceaf_mes
  )
readr::write_csv(saida, here::here("manifest", "sia_pseudo_pacientes.csv"))

message(sprintf(
  "\n✓ Pseudo-ID SIA (core, %d subgrupos alvo). Intervalo agregado de pseudo-pacientes: [%s (frouxa) ; %s (estrita)] sobre %s registros.",
  nrow(res),
  formatC(sum(res$pseudo_pac_frouxa,  na.rm = TRUE), format = "d", big.mark = "."),
  formatC(sum(res$pseudo_pac_estrita, na.rm = TRUE), format = "d", big.mark = "."),
  formatC(sum(res$registros),         format = "d", big.mark = ".")))
message("→ manifest/sia_pseudo_pacientes.csv")
