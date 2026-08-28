# =============================================================================
# feature_eng_pacientes_SIA.R — Pseudo-individualização do SIA-PA (EIM)
# Adaptado de datasus_HS/scripts/feature_eng_pacientes_SIA.R (ver datasus_hs.md §5.1).
#
# O SIA-PA público NÃO tem identificador de paciente (CNS). Construímos um
# pseudo-ID por record linkage determinístico sobre quase-identificadores:
#   blocking sexo × pa_munpcn, janela ano_nasc±1, resolução de entidade por
#   componentes conexos (igraph). Gradiente estrita↔intermediária↔frouxa.
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
# 1. Carregar core + normalizar quase-identificadores
# -----------------------------------------------------------------------------
sia_core <- readRDS(here::here("data/consolidated/sia_eim_core_limitrofe.rds")) |>
  dplyr::filter(camada == "core", subgrupo %in% SUBGRUPOS_ALVO) |>
  dplyr::select(subgrupo, tracadora, sexo, idade_anos, pa_munpcn, pa_racacor,
                competencia, ano)

message(sprintf("SIA core alvo: %d registros em %d subgrupos.",
                nrow(sia_core), dplyr::n_distinct(sia_core$subgrupo)))

sia_core <- sia_core |>
  dplyr::mutate(
    sexo_n = dplyr::case_when(sexo == "Masculino" ~ "M",
                              sexo == "Feminino"  ~ "F",
                              TRUE ~ NA_character_),
    raca_n = { r <- stringr::str_pad(stringr::str_trim(as.character(pa_racacor)), 2, pad = "0")
               dplyr::if_else(r %in% c("01","02","03","04","05"), r, NA_character_) },
    mun_n  = { m <- stringr::str_pad(stringr::str_trim(as.character(pa_munpcn)), 6, pad = "0")
               dplyr::if_else(stringr::str_detect(m, "^0+$") | m == "999999",
                              NA_character_, m) },
    idade_i = suppressWarnings(as.integer(idade_anos)),
    idade_i = dplyr::if_else(idade_i >= 0 & idade_i <= 110, idade_i, NA_integer_),
    # ano_nasc_proxy = ano(competencia) − idade_anos.  CAUTELA <1 ano (idade em anos inteiros)
    ano_cmp = as.integer(format(competencia, "%Y")),
    ano_nasc_proxy = ano_cmp - idade_i,
    chave_completa = !is.na(sexo_n) & !is.na(raca_n) & !is.na(mun_n) & !is.na(ano_nasc_proxy)
  )

# -----------------------------------------------------------------------------
# 2. Motor de linkage (por subgrupo) — blocking + janela ±1 + componentes conexos
# -----------------------------------------------------------------------------
construir_pares <- function(el, usar_raca, janela) {
  bloco <- if (usar_raca) c("sexo_n","mun_n","raca_n") else c("sexo_n","mun_n")
  a <- el[, c("rid", bloco, "ano_nasc_proxy"), with = FALSE]
  b <- el[, c("rid", bloco, "ano_nasc_proxy"), with = FALSE]
  data.table::setnames(b, "rid", "rid_b")
  offs <- if (janela == 0) 0L else seq(-janela, janela)
  b_exp <- data.table::rbindlist(lapply(offs, function(o) {
    bb <- data.table::copy(b); bb[, ano_nasc_proxy := ano_nasc_proxy + o]; bb
  }))
  on_cols <- c(bloco, "ano_nasc_proxy")
  pr <- a[b_exp, on = on_cols, nomatch = 0L, allow.cartesian = TRUE,
          .(x = rid, y = rid_b)]
  pr <- pr[x < y]
  unique(pr)
}

atribuir_componentes <- function(rids, pares) {
  g <- igraph::graph_from_data_frame(
    as.data.frame(pares[, .(x, y)]), directed = FALSE,
    vertices = data.frame(name = as.character(rids)))
  comp <- igraph::components(g)
  list(membership = comp$membership, csize = comp$csize)
}

# Cap de span ≤1 ano: componentes encadeados transitivamente (span>1) voltam a
# exato por ano de nascimento → some o "encadeamento-rio" em municípios densos.
contar_pacientes <- function(el, usar_raca, janela) {
  pares <- construir_pares(el, usar_raca, janela)
  comp  <- atribuir_componentes(el$rid, pares)
  dt <- data.table::copy(el)
  dt[, comp := comp$membership[as.character(rid)]]
  dt[, span := max(ano_nasc_proxy) - min(ano_nasc_proxy), by = comp]
  dt[, id_final := data.table::fifelse(span <= 1L, paste0("C", comp),
                                       paste0("C", comp, "_", ano_nasc_proxy))]
  data.table::uniqueN(dt$id_final)
}

# -----------------------------------------------------------------------------
# 3. Gradiente de chaves por subgrupo (intervalo de pacientes)
# -----------------------------------------------------------------------------
resumo_subgrupo <- function(sub) {
  s <- dplyr::filter(sia_core, subgrupo == sub)
  n_total   <- nrow(s)
  s <- dplyr::mutate(s, rid = dplyr::row_number())
  elig <- data.table::as.data.table(
    dplyr::filter(s, chave_completa)[, c("rid","sexo_n","mun_n","raca_n","ano_nasc_proxy")]
  )
  n_incompletos <- sum(!s$chave_completa)  # forçados a paciente próprio
  if (nrow(elig) == 0L) {
    return(tibble::tibble(subgrupo = sub, registros = n_total,
                          pseudo_pac_estrita = NA_integer_,
                          pseudo_pac_intermediaria = NA_integer_,
                          pseudo_pac_frouxa = NA_integer_,
                          razao_registros_paciente = NA_real_,
                          pct_chave_completa = 0))
  }
  n_estrita <- contar_pacientes(elig, usar_raca = TRUE,  janela = 0L) + n_incompletos
  n_inter   <- contar_pacientes(elig, usar_raca = TRUE,  janela = 1L) + n_incompletos
  n_frouxa  <- contar_pacientes(elig, usar_raca = FALSE, janela = 1L) + n_incompletos
  tibble::tibble(
    subgrupo = sub,
    registros = n_total,
    pseudo_pac_estrita       = n_estrita,   # limite superior de pacientes
    pseudo_pac_intermediaria = n_inter,     # estimativa central
    pseudo_pac_frouxa        = n_frouxa,    # limite inferior de pacientes
    # razão registros/paciente pela chave central (intensidade de uso)
    razao_registros_paciente = round(n_total / n_inter, 2),
    pct_chave_completa = round(100 * mean(s$chave_completa), 1)
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
    pct_chave_completa
  )
readr::write_csv(saida, here::here("manifest", "sia_pseudo_pacientes.csv"))

message(sprintf(
  "\n✓ Pseudo-ID SIA (core, %d subgrupos alvo). Intervalo agregado de pseudo-pacientes: [%s (frouxa) ; %s (estrita)] sobre %s registros.",
  nrow(res),
  formatC(sum(res$pseudo_pac_frouxa,  na.rm = TRUE), format = "d", big.mark = "."),
  formatC(sum(res$pseudo_pac_estrita, na.rm = TRUE), format = "d", big.mark = "."),
  formatC(sum(res$registros),         format = "d", big.mark = ".")))
message("→ manifest/sia_pseudo_pacientes.csv")
