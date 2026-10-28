# =============================================================================
# incidencia_nascimento_tracadoras.R — Incidência AO NASCIMENTO por traçadora
# O DIFERENCIAL do projeto (plano §4b): para as doenças de TRIAGEM NEONATAL,
# referenciar numeradores à coorte de nascimento (denominador = nascidos vivos,
# SINASC), em vez de população geral.
#
# Métricas por traçadora (por 100 mil NV, IC de Poisson exato, supressão N<5):
#   A) MORTALIDADE INFANTIL específica  = óbitos <1 ano (SIM causa básica) / NV
#   B) DETECÇÃO no 1º ano (proxy)       = AIH <1 ano (SIH princ.) / NV  e
#                                          registros <1 ano (SIA), anos com SINASC
#   Detecção em CRIANÇAS distintas (BI ∪ APAC): pacientes_cns_bi.R
# Comparação com a incidência esperada da literatura (moldura de plausibilidade
# p/ dimensionar o gap de captação — TODOS os valores [VERIFICAR]).
# =============================================================================

source(here::here("scripts", "00_setup.R"))
source(here::here("scripts", "calcular_taxas.R"))
suppressPackageStartupMessages(library(epitools))

sim <- readRDS(here::here("data/consolidated/sim_eim_nacional.rds"))
sih <- readRDS(here::here("data/consolidated/sih_eim_nacional.rds"))
sia <- readRDS(here::here("data/consolidated/sia_eim_core_limitrofe.rds"))
pz_sim <- readRDS(here::here("data/consolidated/pezinho_sim.rds"))   # gaps não-EIM do painel
pz_sih <- readRDS(here::here("data/consolidated/pezinho_sih.rds"))   # (D57, D56, D81, P371)
pz_sia <- readRDS(here::here("data/consolidated/pezinho_sia.rds"))
nv_ano <- carregar_nv() |> dplyr::group_by(ano) |>
  dplyr::summarise(nv = sum(nv), .groups = "drop")
NV_TOTAL_SIM <- sum(dplyr::filter(nv_ano, ano %in% ANOS_SIM)$nv)   # NV do período do SIM
# Detecção: numerador e denominador nos MESMOS anos — só onde há SINASC definitivo
# (mesma regra de pezinho_panel.R; parecer 2026-10-25, C3)
ANOS_NV <- intersect(ANOS, nv_ano$ano)
NV_DETECCAO <- sum(dplyr::filter(nv_ano, ano %in% ANOS_NV)$nv)

# Traçadoras de TRIAGEM NEONATAL (lookup: triagem == TRUE)
TRIAGEM <- EIM_LOOKUP |> dplyr::filter(triagem, !is.na(tracadora)) |>
  dplyr::pull(tracadora) |> unique()
# Traçadoras do painel do pezinho fora do pipeline EIM (escopo="painel_pezinho"): vêm
# dos rds pezinho_* (pipeline próprio, ref. get_pezinho_gaps.R), nunca dos rds EIM
PZ <- EIM_LOOKUP |> dplyr::filter(escopo == "painel_pezinho", !is.na(tracadora)) |>
  dplyr::pull(tracadora) |> unique()
# Traçadoras do envelope: o rds individual do SIA é core+limítrofe → não medidas no SIA
ENVELOPE <- EIM_LOOKUP |> dplyr::filter(camada == "envelope", !is.na(tracadora), !tracadora %in% PZ) |>
  dplyr::pull(tracadora) |> unique()
# Rótulo da biotinidase: o MESMO de descritivo_cross_base.R (parecer C2)
rotular <- function(v) dplyr::if_else(v == "Biotinidase", "Biotinidase (E88.9 proxy/TETO)", v)

# Incidência esperada ao nascimento — LITERATURA/triagem [VERIFICAR TODAS as fontes]
# A taxa sai da razão 1:N (não digitada à mão; parecer M7). Sem fonte verificada,
# a coluna não entra no manuscrito.
LIT <- tibble::tribble(
  ~tracadora,             ~um_em,  ~fonte,
  "Hipotireoidismo_cong",   2500,  "~1:2.500 [VERIFICAR]",
  "HAC",                   12000,  "~1:12.000 [VERIFICAR]",
  "Fibrose_cistica",        8000,  "~1:8.000 [VERIFICAR]",
  "PKU",                   10000,  "~1:10.000 [VERIFICAR]",
  "Galactosemia",          40000,  "~1:40.000 [VERIFICAR]",
  "Biotinidase",           60000,  "~1:60.000 [VERIFICAR]",
  "MSUD",                 130000,  "~1:130.000 [VERIFICAR]",
  "Ciclo_ureia",           35000,  "~1:35.000 (grupo) [VERIFICAR]"
) |> dplyr::mutate(inc_lit_por_100k_nv = round(1e5 / um_em, 1))
stopifnot(LIT$tracadora %in% TRIAGEM)

# ---- A) Mortalidade infantil por traçadora (SIM causa básica, <1 ano) ----
# `eim_cb_ampliado` (não `eim_causa_basica`, que agora é core) — mesma regra da §2
# do descritivo: a traçadora é contada pelo seu CID nomeado INDEPENDENTEMENTE da
# camada. Sem isso a linha da biotinidase (E88.9) zeraria, perdendo justamente
# o achado de que o MS codifica a biotinidase num balde inespecífico.
# ATENÇÃO (ref/avaliacao_critica_externa.md, achado E3 da auditoria de 2026-08-28):
# este número usa a camada AMPLIADA, diferente do KPI "mortalidade infantil" da
# home/sim_eim.qmd (que usa `eim_causa_basica`, camada core). As duas contagens
# NÃO são o mesmo indicador.
inf_sim <- dplyr::bind_rows(
  dplyr::filter(sim, eim_cb_ampliado, !tracadora %in% PZ),
  dplyr::filter(pz_sim, tracadora %in% PZ)) |>
  dplyr::filter(obito_infantil %in% TRUE, !is.na(tracadora)) |>
  dplyr::count(tracadora, name = "obitos_inf")

# ---- B) Detecção no 1º ano: SIH (AIH princ. <1 ano) e SIA (registros <1 ano) ----
# REGRA CANÔNICA (parecer C2/C3; idêntica a pezinho_panel.R): traçadora pelo CID
# PRINCIPAL em QUALQUER camada; idade < 1 ano; anos com SINASC definitivo (ANOS_NV);
# AIH distintas. Antes: só camada core (`eim_principal`) — zerava biotinidase/AME/
# hemofilias — e 2010–2025 no numerador contra NV até 2024 (+5–12%).
det_sih <- dplyr::bind_rows(
  dplyr::filter(sih, !tracadora %in% PZ) |> dplyr::select(n_aih, tracadora, idade_anos, ano),
  dplyr::filter(pz_sih, tracadora %in% PZ) |> dplyr::select(n_aih, tracadora, idade_anos, ano)) |>
  dplyr::filter(!is.na(tracadora), idade_anos < 1, ano %in% ANOS_NV) |>
  dplyr::summarise(aih_inf = dplyr::n_distinct(n_aih), .by = tracadora)
det_sia <- dplyr::bind_rows(
  dplyr::filter(sia, !tracadora %in% PZ) |> dplyr::select(tracadora, idade_anos, ano),
  dplyr::filter(pz_sia, tracadora %in% PZ) |> dplyr::select(tracadora, idade_anos, ano)) |>
  dplyr::filter(!is.na(tracadora), idade_anos < 1, ano %in% ANOS_NV) |>
  dplyr::count(tracadora, name = "reg_sia_inf")
# Toda traçadora contada tem de existir na lookup (chave não encontrada = erro, nunca 0)
stopifnot(c(inf_sim$tracadora, det_sih$tracadora, det_sia$tracadora) %in% EIM_LOOKUP$tracadora)

# ---- Montar tabela por traçadora de triagem ----
ic_pois <- function(x, pt, por = 1e5) {           # taxa + IC Poisson exato /100k
  # pt em unidades de `por` (NV/1e5) → r$rate/lower/upper JÁ vêm por 100 mil NV.
  r <- epitools::pois.exact(x, pt = pt / por)
  tibble::tibble(taxa = r$rate, ic_inf = r$lower, ic_sup = r$upper)
}

# Ausente numa base em que a traçadora É medida = 0 verdadeiro; ausente numa base em
# que NÃO é medida (envelope no SIA individual) = NA, nunca 0 (parecer C2)
tab <- tibble::tibble(tracadora = TRIAGEM) |>
  dplyr::left_join(inf_sim, by = "tracadora") |>
  dplyr::left_join(det_sih, by = "tracadora") |>
  dplyr::left_join(det_sia, by = "tracadora") |>
  dplyr::mutate(
    obitos_inf  = tidyr::replace_na(obitos_inf, 0L),
    aih_inf     = tidyr::replace_na(aih_inf, 0L),
    reg_sia_inf = dplyr::if_else(tracadora %in% ENVELOPE, NA_integer_, tidyr::replace_na(reg_sia_inf, 0L)),
    aih_inf_100k_nv = round(1e5 * aih_inf / NV_DETECCAO, 2),
    anos_deteccao = paste0(min(ANOS_NV), "-", max(ANOS_NV)), nv_deteccao = NV_DETECCAO,
    fonte_dados = dplyr::if_else(tracadora %in% PZ, "pezinho_* (painel, não-EIM)", "EIM"))

# taxa de mortalidade infantil / 100k NV (pool ANOS_SIM), com supressão N<5
mort <- purrr::pmap_dfr(list(tab$obitos_inf), ~ ic_pois(..1, NV_TOTAL_SIM))
tab <- tab |>
  dplyr::mutate(
    mort_inf_100k_nv = round(mort$taxa, 2),
    mort_ic          = dplyr::case_when(
      obitos_inf < N_SUPRESSAO                     ~ "N<5 (suprimido)",
      TRUE                                          ~ sprintf("%.2f–%.2f", mort$ic_inf, mort$ic_sup)),
    mort_inf_100k_nv = ifelse(obitos_inf < N_SUPRESSAO, NA_real_, mort_inf_100k_nv)) |>
  dplyr::left_join(LIT |> dplyr::select(tracadora, inc_lit_por_100k_nv, fonte), by = "tracadora") |>
  dplyr::mutate(tracadora = rotular(tracadora)) |>
  dplyr::arrange(dplyr::desc(obitos_inf))

cat("\n== Incidência AO NASCIMENTO por traçadora de triagem (pool ", min(ANOS_SIM), "–",
    max(ANOS_SIM), "; NV=", format(NV_TOTAL_SIM, big.mark="."), ") ==\n", sep="")
cat("Mortalidade infantil = SIM causa básica <1a, CAMADA AMPLIADA (core+limítrofe+envelope;\n")
cat("DIFERENTE do KPI core da home/sim_eim.qmd) e detecção 1º ano (SIH/SIA, ", min(ANOS_NV), "–", max(ANOS_NV),
    "; NV=", format(NV_DETECCAO, big.mark="."), "), por 100 mil NV.\n", sep="")
cat("Incidência da literatura = moldura de plausibilidade [VERIFICAR]; gap = subdetecção.\n\n")
print(as.data.frame(tab))

readr::write_csv(tab, here::here("manifest/incidencia_nascimento_tracadoras.csv"))
message("\n✓ Incidência ao nascimento por traçadora → manifest/incidencia_nascimento_tracadoras.csv")
