# =============================================================================
# qmd/_discussao_numeros.R — Números da página de Discussão (CALCULADOS)
#
# Os textos ref/discussao_epidemiologica.md e ref/discussao_genetica.md entram na
# página por {{< include >}}, que acontece ANTES do knitr — por isso podem usar R inline.
# Este arquivo dá a eles funções de acesso aos manifestos e às séries, para que nenhum
# número seja digitado à mão (a versão 2021–2025 desses textos citava "mortalidade
# estável ~1,66/100 mil" e "internação +9%/ano", ambos desfeitos pela série longa).
# Requer _common.R já carregado (D, fmt_*, tendencia_txt, serie_txt, PER, PER_SIM).
#
# Uso no texto:  `r N(trac("Fibrose_cistica", "SIA"))`, `r D2(inc("PKU", "mi"))`, …
# =============================================================================

N  <- function(x) fmt_n(round(x))
D1 <- function(x) fmt_1(x)
D2 <- function(x) fmt_2(x)

.m_inc  <- readr::read_csv(here::here("manifest/incidencia_nascimento_tracadoras.csv"), show_col_types = FALSE)
.m_trac <- readr::read_csv(here::here("manifest/descritivo_tracadoras_cross_base.csv"), show_col_types = FALSE)
.m_pz   <- readr::read_csv(here::here("manifest/pezinho_panel.csv"), show_col_types = FALSE)

#' Incidência ao nascimento / 1º ano por traçadora (pool ANOS_SIM).
#' col: "obitos" (óbitos <1 ano), "aih" (AIH no 1º ano), "sia" (registros SIA no 1º ano),
#'      "mi" (mortalidade infantil por 100 mil NV)
inc <- function(t, col) {
  c_ <- c(obitos = "obitos_inf", aih = "aih_inf", sia = "reg_sia_inf", mi = "mort_inf_100k_nv")[[col]]
  v <- .m_inc[[c_]][.m_inc$tracadora == t]; if (!length(v)) stop("traçadora sem incidência: ", t); v
}
#' Volume por traçadora nas três bases (série completa). base: "SIA" | "SIH" | "SIM"
trac <- function(t, base) {
  c_ <- c(SIA = "SIA", SIH = "SIH_princ", SIM = "SIM_cb")[[base]]
  v <- .m_trac[[c_]][.m_trac$tracadora == t]; if (!length(v)) stop("traçadora sem descritivo: ", t); v
}
#' Painel do pezinho por prefixo CID. col: "SIA", "SIH", "SIM", "SIH_inf_nv" (por 100 mil NV)
pz <- function(prefixo, col) {
  c_ <- c(SIA = "SIA_princ", SIH = "SIH_princ", SIM = "SIM_cbasica", SIH_inf_nv = "SIH_inf_100k_nv",
          SIM_inf_nv = "SIM_inf_100k_nv")[[col]]
  v <- .m_pz[[c_]][.m_pz$prefixo == prefixo]; if (!length(v)) stop("prefixo fora do painel: ", prefixo); v[1]
}

# Séries e tendências (mesmas da home)
tx_sim_d <- D$sim |> dplyr::filter(eim_causa_basica) |>
  contar_estrato(col_uf = "uf_res") |> taxas_padronizadas(D$pop, grupos = "ano")
tx_sih_d <- D$sih |> dplyr::filter(eim_principal) |>
  contar_estrato(col_uf = "uf_res", distinct_por = "n_aih") |> taxas_padronizadas(D$pop, grupos = "ano")
serie_sia_d <- D$sia |> dplyr::filter(camada == "core") |> dplyr::select(ano) |> dplyr::collect() |>
  dplyr::count(ano, name = "eventos")
TR <- list(sim = tendencia_txt(tx_sim_d), sih = tendencia_txt(tx_sih_d), sia = tendencia_txt(serie_sia_d))
SERIE <- list(sim = serie_txt(tx_sim_d), sih = serie_txt(tx_sih_d),
              sia = serie_txt(serie_sia_d, col = "eventos", fmt = fmt_n))
SIA_INI <- serie_sia_d$eventos[serie_sia_d$ano == min(ANOS)]
SIA_FIM <- serie_sia_d$eventos[serie_sia_d$ano == max(ANOS)]

# SIM: causa básica core, teto e qualquer linha
SIM_CB      <- sum(D$sim$eim_causa_basica, na.rm = TRUE)
SIM_CB_MAX  <- sum(D$sim$eim_cb_ampliado,  na.rm = TRUE)
SIM_QUALQ   <- sum(D$sim$eim_qualquer,     na.rm = TRUE)
SIM_SO_LINHA <- sum(D$sim$eim_qualquer & !D$sim$eim_cb_ampliado, na.rm = TRUE)

# Mortalidade infantil por EIM (óbitos <1 ano, causa básica core ÷ NV), por ano
.mi <- D$sim |> dplyr::filter(eim_causa_basica, obito_infantil) |> dplyr::count(ano, name = "obitos") |>
  dplyr::left_join(D$nv |> dplyr::filter(ano %in% ANOS_SIM) |> dplyr::group_by(ano) |>
                     dplyr::summarise(nv = sum(nv), .groups = "drop"), by = "ano") |>
  dplyr::mutate(por_100k = 1e5 * obitos / nv)
MI <- list(min = min(.mi$por_100k), max = max(.mi$por_100k),
           obitos_min = min(.mi$obitos), obitos_max = max(.mi$obitos),
           serie = serie_txt(dplyr::rename(.mi, taxa_pad = por_100k)),
           tr = tendencia_txt(dplyr::transmute(.mi, ano, eventos = obitos, pop = nv)))

# Escala do envelope no SIA
.vol <- D$sia_vol_agg |> dplyr::group_by(camada) |> dplyr::summarise(r = sum(registros), .groups = "drop")
RAZAO_ENV <- .vol$r[.vol$camada == "envelope"] / .vol$r[.vol$camada == "core"]

# Recife × PE (SIA core vs óbitos causa básica)
.pe_sia <- D$sia |> dplyr::filter(camada == "core", uf_pcn == "PE") |> dplyr::select(pa_munpcn) |> dplyr::collect()
.pe_sim <- D$sim |> dplyr::filter(eim_causa_basica, uf_res == "PE")
REC <- list(sia = 100 * mean(substr(.pe_sia$pa_munpcn, 1, 6) == "261160", na.rm = TRUE),
            obitos = 100 * mean(substr(.pe_sim$codmunres, 1, 6) == "261160", na.rm = TRUE))
