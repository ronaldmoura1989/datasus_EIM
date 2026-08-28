# =============================================================================
# pezinho_panel.R — Painel COMPLETO do teste do pezinho nas 3 bases DATASUS
# Une os CIDs do pezinho JÁ cobertos (EIM: data/consolidated/{sia_eim_core,
# sih_eim_nacional,sim_eim_nacional}.rds) com os 4 GAPS não-EIM re-extraídos
# (data/consolidated/pezinho_{sia,sih,sim}.rds): D57, D56, D81, P371.
# Produz, por doença do painel (tradicional/expandido), contagens por base e
# detecção no 1º ano de vida por 100 mil NV (SINASC). NÃO soma entre bases.
# Saída: manifest/pezinho_panel.csv
# =============================================================================

source(here::here("scripts", "00_setup.R"))
source(here::here("scripts", "calcular_taxas.R"))   # carregar_nv()
suppressPackageStartupMessages(library(epitools))

# Painel: prefixo → doença/etapa (a partir da lookup + rótulos amigáveis)
PANEL <- EIM_LOOKUP |>
  dplyr::filter(pezinho) |>
  dplyr::transmute(prefixo, subgrupo,
                   etapa = dplyr::if_else(pezinho_tradicional, "Tradicional", "Expandido"),
                   eim   = escopo != "painel_pezinho") |>
  dplyr::distinct()

# NV (SINASC) por período de cada base
nv <- carregar_nv() |> dplyr::group_by(ano) |> dplyr::summarise(nv=sum(nv), .groups="drop")
NV_SIH <- sum(dplyr::filter(nv, ano %in% ANOS)$nv)          # 2021-2025
NV_SIM <- sum(dplyr::filter(nv, ano %in% ANOS_SIM)$nv)      # 2021-2023

norm4 <- function(v) stringr::str_sub(stringr::str_trim(toupper(as.character(v))),1,4)
conta_pref <- function(vec, pref) sum(stringr::str_starts(norm4(vec), pref), na.rm=TRUE)

# ---- Fontes por base: EIM-coberto + GAPS (campo PRINCIPAL) ----
sia_eim <- readRDS(here::here("data/consolidated/sia_eim_core_limitrofe.rds"))
sih_eim <- readRDS(here::here("data/consolidated/sih_eim_nacional.rds"))
sim_eim <- readRDS(here::here("data/consolidated/sim_eim_nacional.rds"))
pz_sia  <- readRDS(here::here("data/consolidated/pezinho_sia.rds"))
pz_sih  <- readRDS(here::here("data/consolidated/pezinho_sih.rds"))
pz_sim  <- readRDS(here::here("data/consolidated/pezinho_sim.rds"))

# CID principal de cada base (une EIM + gaps)
sia_cid <- c(sia_eim$cid_principal, pz_sia$cid_principal)
sih_cid <- c(toupper(sih_eim$diag_princ), toupper(pz_sih$diag_princ))
sim_cid <- c(toupper(sim_eim$causabas),  toupper(pz_sim$causabas))
# idade <1 ano por base (para detecção ao nascimento)
sia_inf <- dplyr::bind_rows(
  dplyr::transmute(sia_eim, cid=cid_principal, idade_anos),
  dplyr::transmute(pz_sia,  cid=cid_principal, idade_anos)) |> dplyr::filter(idade_anos < 1)
sih_inf <- dplyr::bind_rows(
  dplyr::transmute(sih_eim, cid=toupper(diag_princ), idade_anos),
  dplyr::transmute(pz_sih,  cid=toupper(diag_princ), idade_anos)) |> dplyr::filter(idade_anos < 1)
sim_inf <- dplyr::bind_rows(
  dplyr::transmute(sim_eim, cid=toupper(causabas), idade_anos, obito_infantil),
  dplyr::transmute(pz_sim,  cid=toupper(causabas), idade_anos, obito_infantil)) |>
  dplyr::filter(obito_infantil %in% TRUE)

taxa <- function(x, nvv, por=1e5) round(por * x / nvv, 2)

tab <- PANEL |>
  dplyr::rowwise() |>
  dplyr::mutate(
    SIA_princ   = conta_pref(sia_cid, prefixo),
    SIH_princ   = conta_pref(sih_cid, prefixo),
    SIM_cbasica = conta_pref(sim_cid, prefixo),
    SIH_inf     = conta_pref(sih_inf$cid, prefixo),
    SIM_inf     = conta_pref(sim_inf$cid, prefixo),
    SIH_inf_100k_nv = taxa(SIH_inf, NV_SIH),
    SIM_inf_100k_nv = taxa(SIM_inf, NV_SIM)
  ) |>
  dplyr::ungroup() |>
  dplyr::arrange(etapa, dplyr::desc(SIH_princ))

cat("== PAINEL COMPLETO DO PEZINHO nas 3 bases (2021-2025 SIA/SIH; 2021-2023 SIM) ==\n")
cat("Detecção 1º ano por 100 mil NV (SINASC). Supressão N<5 aplicar antes de publicar.\n\n")
print(as.data.frame(tab))

readr::write_csv(tab, here::here("manifest/pezinho_panel.csv"))
message("\n✓ Painel do pezinho → manifest/pezinho_panel.csv")
