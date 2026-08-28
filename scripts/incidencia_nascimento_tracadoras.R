# =============================================================================
# incidencia_nascimento_tracadoras.R — Incidência AO NASCIMENTO por traçadora
# O DIFERENCIAL do projeto (plano §4b): para as doenças de TRIAGEM NEONATAL,
# referenciar numeradores à coorte de nascimento (denominador = nascidos vivos,
# SINASC), em vez de população geral.
#
# Métricas por traçadora (por 100 mil NV, IC de Poisson exato, supressão N<5):
#   A) MORTALIDADE INFANTIL específica  = óbitos <1 ano (SIM causa básica) / NV
#   B) DETECÇÃO no 1º ano (proxy)       = AIH <1 ano (SIH princ.) / NV  e
#                                          registros <1 ano (SIA) / NV
# Comparação com a incidência esperada da literatura (moldura de plausibilidade
# p/ dimensionar o gap de captação — TODOS os valores [VERIFICAR]).
# =============================================================================

source(here::here("scripts", "00_setup.R"))
source(here::here("scripts", "calcular_taxas.R"))
suppressPackageStartupMessages(library(epitools))

sim <- readRDS(here::here("data/consolidated/sim_eim_nacional.rds"))
sih <- readRDS(here::here("data/consolidated/sih_eim_nacional.rds"))
sia <- readRDS(here::here("data/consolidated/sia_eim_core_limitrofe.rds"))
nv_ano <- carregar_nv() |> dplyr::group_by(ano) |>
  dplyr::summarise(nv = sum(nv), .groups = "drop")
NV_TOTAL_SIM <- sum(dplyr::filter(nv_ano, ano %in% ANOS_SIM)$nv)   # NV do período do SIM

# Traçadoras de TRIAGEM NEONATAL (lookup: triagem == TRUE)
TRIAGEM <- EIM_LOOKUP |> dplyr::filter(triagem, !is.na(tracadora)) |>
  dplyr::pull(tracadora) |> unique()
# Rótulo amigável de biotinidase
rotular <- function(v) dplyr::if_else(v == "Biotinidase", "Biotinidase (E88.9 TETO)", v)

# Incidência esperada ao nascimento — LITERATURA/triagem [VERIFICAR TODAS as fontes]
# (ordens de grandeza de rastreio; confirmar em Orphanet/PNTN antes de publicar)
LIT <- tibble::tribble(
  ~tracadora,               ~inc_lit_por_100k_nv, ~fonte,
  "Hipotireoidismo_cong",   40,   "~1:2.500 [VERIFICAR]",
  "HAC",                    8,    "~1:12.000 [VERIFICAR]",
  "Fibrose_cistica",        12,   "~1:8.000 [VERIFICAR]",
  "PKU",                    10,   "~1:10.000 [VERIFICAR]",
  "Galactosemia",           2.5,  "~1:40.000 [VERIFICAR]",
  "Biotinidase",            1.7,  "~1:60.000 [VERIFICAR]",
  "MSUD",                   0.8,  "~1:130.000 [VERIFICAR]",
  "Ciclo_ureia",            3,    "~1:35.000 (grupo) [VERIFICAR]"
)

# ---- A) Mortalidade infantil por traçadora (SIM causa básica, <1 ano) ----
# `eim_cb_ampliado` (não `eim_causa_basica`, que agora é core) — mesma regra da §2
# do descritivo: a traçadora é contada pelo seu CID nomeado INDEPENDENTEMENTE da
# camada. Sem isso a linha "Biotinidase (E88.9 TETO)" zeraria, perdendo justamente
# o achado de que o MS codifica a biotinidase num balde inespecífico.
inf_sim <- sim |>
  dplyr::filter(eim_cb_ampliado, obito_infantil, !is.na(tracadora)) |>
  dplyr::count(tracadora, name = "obitos_inf")

# ---- B) Detecção no 1º ano: SIH (AIH princ. <1 ano) e SIA (registros <1 ano) ----
det_sih <- sih |>
  dplyr::filter(eim_principal, !is.na(tracadora),
                !is.na(idade_anos), idade_anos < 1) |>
  dplyr::summarise(aih_inf = dplyr::n_distinct(n_aih), .by = tracadora)
det_sia <- sia |>
  dplyr::filter(!is.na(tracadora), !is.na(idade_anos), idade_anos < 1) |>
  dplyr::count(tracadora, name = "reg_sia_inf")

# ---- Montar tabela por traçadora de triagem (pool do período do SIM p/ estabilidade) ----
ic_pois <- function(x, pt, por = 1e5) {           # taxa + IC Poisson exato /100k
  # pt em unidades de `por` (NV/1e5) → r$rate/lower/upper JÁ vêm por 100 mil NV.
  r <- epitools::pois.exact(x, pt = pt / por)
  tibble::tibble(taxa = r$rate, ic_inf = r$lower, ic_sup = r$upper)
}

tab <- tibble::tibble(tracadora = TRIAGEM) |>
  dplyr::left_join(inf_sim, by = "tracadora") |>
  dplyr::left_join(det_sih, by = "tracadora") |>
  dplyr::left_join(det_sia, by = "tracadora") |>
  dplyr::mutate(dplyr::across(c(obitos_inf, aih_inf, reg_sia_inf), ~ tidyr::replace_na(.x, 0)))

# taxa de mortalidade infantil / 100k NV (pool ANOS_SIM), com supressão N<5
mort <- purrr::pmap_dfr(list(tab$obitos_inf), ~ ic_pois(..1, NV_TOTAL_SIM))
tab <- tab |>
  dplyr::mutate(
    mort_inf_100k_nv = round(mort$taxa, 2),
    mort_ic          = ifelse(obitos_inf < N_SUPRESSAO, "N<5 (suprimido)",
                              sprintf("%.2f–%.2f", mort$ic_inf, mort$ic_sup)),
    mort_inf_100k_nv = ifelse(obitos_inf < N_SUPRESSAO, NA_real_, mort_inf_100k_nv)) |>
  dplyr::left_join(LIT |> dplyr::select(tracadora, inc_lit_por_100k_nv, fonte), by = "tracadora") |>
  dplyr::mutate(tracadora = rotular(tracadora)) |>
  dplyr::arrange(dplyr::desc(obitos_inf))

cat("\n== Incidência AO NASCIMENTO por traçadora de triagem (pool ", min(ANOS_SIM), "–",
    max(ANOS_SIM), "; NV=", format(NV_TOTAL_SIM, big.mark="."), ") ==\n", sep="")
cat("Mortalidade infantil (SIM causa básica <1a) e detecção 1º ano (SIH/SIA), por 100 mil NV.\n")
cat("Incidência da literatura = moldura de plausibilidade [VERIFICAR]; gap = subdetecção.\n\n")
print(as.data.frame(tab))

readr::write_csv(tab, here::here("manifest/incidencia_nascimento_tracadoras.csv"))
message("\n✓ Incidência ao nascimento por traçadora → manifest/incidencia_nascimento_tracadoras.csv")
