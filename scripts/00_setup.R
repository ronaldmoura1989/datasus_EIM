# =============================================================================
# 00_setup.R — Ambiente, parâmetros globais, paleta e diretórios
# Projeto DATASUS — Erros Inatos do Metabolismo (EIM, CID-10 E70–E90 + correlatos)
# Ver plano_analise_EIM_datasus.md e ref/ para a metodologia.
# Adapta o 00_setup.R do projeto HS (datasus_HS/scripts/00_setup.R).
# =============================================================================

# -----------------------------------------------------------------------------
# 0. Helper de instalação resiliente (CRAN -> Bioconductor -> GitHub)
# -----------------------------------------------------------------------------
ensure_pkg <- function(pkgs, github = list()) {
  cran <- "https://cloud.r-project.org"
  for (p in pkgs) {
    if (requireNamespace(p, quietly = TRUE)) next
    try(install.packages(p, repos = cran), silent = TRUE)
    if (requireNamespace(p, quietly = TRUE)) next
    if (!requireNamespace("BiocManager", quietly = TRUE))
      install.packages("BiocManager", repos = cran)
    try(BiocManager::install(p, update = FALSE, ask = FALSE), silent = TRUE)
    if (requireNamespace(p, quietly = TRUE)) next
    if (!is.null(github[[p]])) {
      if (!requireNamespace("remotes", quietly = TRUE))
        install.packages("remotes", repos = cran)
      remotes::install_github(github[[p]], upgrade = "never")
    }
    if (!requireNamespace(p, quietly = TRUE)) stop(sprintf("Falha ao instalar '%s'", p))
  }
  invisible(NULL)
}

pkgs_cran <- c("tidyverse","data.table","arrow","janitor","naniar","rstatix",
               "broom","epitools","ggplot2","scales","patchwork","cowplot","ggpubr",
               "flextable","officer","gt","geobr","sidrar","igraph","renv","yaml",
               "digest","here")
pkgs_github <- list(microdatasus = "rfsaldanha/microdatasus",
                    read.dbc     = "danicat/read.dbc")
ensure_pkg(pkgs_cran, github = pkgs_github)

suppressPackageStartupMessages({
  library(tidyverse); library(janitor); library(arrow); library(here)
})
select <- dplyr::select; filter <- dplyr::filter; rename <- dplyr::rename
slice  <- dplyr::slice;  count  <- dplyr::count
set.seed(42)

# -----------------------------------------------------------------------------
# 1. Parâmetros globais
# -----------------------------------------------------------------------------
# Janela: 2021–2026 (pedido). Disponibilidade real no remoto Lika (2026-07-01):
#   SIA/SIH = 2021–2025 (trimestral); SIM-DO = 2021–2023 (2024+ ainda não no DATASUS);
#   SINASC = a baixar (anual). 2026 ainda não existe. ANOS_SIM tratado à parte.
ANOS      <- 2021:2025
ANOS_SIM  <- 2021:2023
MESES <- 1:12                 # SIA/SIH mensais; SIM/SINASC anuais
UFS   <- c("AC","AL","AP","AM","BA","CE","DF","ES","GO","MA","MT","MS","MG",
           "PA","PB","PR","PE","PI","RJ","RN","RS","RO","RR","SC","SP","SE","TO")
TRIMESTRES <- list(T1 = c(1,3), T2 = c(4,6), T3 = c(7,9), T4 = c(10,12))

# Definição de caso — NÃO é um CID único (como no HS), é a LOOKUP (eim_lookup.R).
MODO_CAPTURA <- "restrito"    # "restrito" (só camada core) | "ampliado" (core+limitrofe+envelope)
ESCOPO_CID   <- "nucleo"      # "nucleo" (E70–E90 stricto sensu) | "todos" (inclui triagem fora de E)

# DUAS grades etárias (usos distintos — ver plano §4):
#  (1) FAIXAS_EIM — pediátrico-fina: descrição da idade (esp. idade ao óbito no SIM)
#      e flag de óbito infantil. 0 = neonatal (<1 mês) · 1/12 = 1–11 meses · 1 = 1–4 ...
FAIXAS_EIM <- c(0, 1/12, 1, 5, 10, 15, 20, 30, 40, 50, 60, 70, 80, Inf)
#  (2) FAIXAS_PAD — quinquenal, para PADRONIZAÇÃO por idade/sexo das taxas
#      populacionais (bate com a grade do Censo 2022/SIDRA tab 9514).
FAIXAS_PAD <- c(seq(0, 80, by = 5), Inf)
POP_PADRAO   <- "censo2022"
N_SUPRESSAO  <- 5             # LGPD: suprimir N<5 (REGRA ESTRUTURAL em doença rara)
ANOS_COVID   <- c(2020, 2021)

# Paleta visual (espectro verde-azulado → índigo, distinta do HS rosé-roxo)
PAL_EIM      <- c("#1B6F6A","#2E9E96","#8FD3C7","#3E5C8A","#7FA6D9","#26495C","#0E2F38")
PAL_EIM_GRAD <- c(low = "#8FD3C7", high = "#1B6F6A")

# -----------------------------------------------------------------------------
# 2. Diretórios (criação idempotente)
# -----------------------------------------------------------------------------
DIRS <- c(
  "scripts", "qmd", "ref",
  "data/raw/SIA", "data/raw/SIH", "data/raw/SIM", "data/raw/SINASC",
  "data/filtered/sia_eim", "data/filtered/sih_eim", "data/filtered/sim_eim",
  "data/denominators",
  "data/parquet/sia_eim", "data/parquet/sih_eim", "data/parquet/sim_eim",
  "data/consolidated", "logs", "manifest", "docs"
)
purrr::walk(DIRS, ~ dir.create(here::here(.x), recursive = TRUE, showWarnings = FALSE))

# -----------------------------------------------------------------------------
# 3. Definição de caso + funções utilitárias
# -----------------------------------------------------------------------------
source(here::here("scripts", "eim_lookup.R"))   # EIM_LOOKUP, regex_eim(), TRACADORAS
source(here::here("scripts", "utils.R"))         # classificar_eim(), etc.

# Registra a versão da lookup (a definição de caso) no manifest — auditoria.
registrar_versao_lookup <- function() {
  h <- digest::digest(EIM_LOOKUP, algo = "sha1")
  fp <- here::here("manifest", "eim_lookup_versao.csv")
  linha <- tibble::tibble(ts = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
                          n_prefixos = nrow(EIM_LOOKUP), hash_sha1 = h)
  readr::write_csv(linha, fp, append = file.exists(fp))
  invisible(h)
}

message("00_setup.R carregado — ANOS=", min(ANOS), ":", max(ANOS),
        " | MODO=", MODO_CAPTURA, " | ESCOPO=", ESCOPO_CID,
        " | ", nrow(EIM_LOOKUP), " prefixos na lookup.")
