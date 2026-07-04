# =============================================================================
# descritivo_cross_base.R — Primeiro panorama descritivo das TRÊS bases (EIM)
# Triangula SIA (ambulatorial), SIH (internações) e SIM (mortalidade) SEM somá-las
# (cada base = pergunta própria). Reporta core vs envelope e por traçadora.
# Requer: get_eim_data_from_{SIA,SIH,SIM}.R já rodados.
# Saída: manifest/descritivo_cross_base.csv (+ impressão no console)
# =============================================================================

source(here::here("scripts", "00_setup.R"))
source(here::here("scripts", "calcular_taxas.R"))

sia  <- readRDS(here::here("data/consolidated/sia_eim_core.rds"))        # core+limítrofe
sia_env <- readRDS(here::here("data/consolidated/sia_eim_envelope_agg.rds"))
sih  <- readRDS(here::here("data/consolidated/sih_eim_nacional.rds"))
sim  <- readRDS(here::here("data/consolidated/sim_eim_nacional.rds"))
pop  <- carregar_pop(); nv <- carregar_nv() |> dplyr::group_by(uf,ano) |>
  dplyr::summarise(nv=sum(nv),.groups="drop")

sep <- function(t) cat("\n", strrep("=", 70), "\n", t, "\n", strrep("=",70), "\n", sep="")

# -----------------------------------------------------------------------------
sep("1. VOLUME POR BASE E CAMADA (não somar entre bases)")
tab_camada <- dplyr::bind_rows(
  sia |> dplyr::filter(camada=="core") |> dplyr::summarise(base="SIA (registros, core)", n=dplyr::n()),
  tibble::tibble(base="SIA (registros, envelope)", n=sum(sia_env$n)),
  sih |> dplyr::filter(eim_principal) |> dplyr::summarise(base="SIH (AIH, EIM principal core)", n=sum(camada=="core", na.rm=TRUE)),
  sih |> dplyr::summarise(base="SIH (AIH, EIM qualquer campo)", n=sum(eim_qualquer, na.rm=TRUE)),
  sim |> dplyr::filter(eim_causa_basica) |> dplyr::summarise(base="SIM (óbitos, causa básica)", n=dplyr::n()),
  sim |> dplyr::summarise(base="SIM (óbitos, qualquer linha)", n=sum(eim_qualquer, na.rm=TRUE))
)
print(as.data.frame(tab_camada))

# -----------------------------------------------------------------------------
sep("2. PAINEL DE TRAÇADORAS × TRÊS BASES (por CID nomeado, TODAS as camadas)")
# REGRA UNIFICADA (recomendação do epidemiologista): a traçadora é uma DOENÇA
# NOMEADA, escolhida a dedo — reportada pelo seu CID INDEPENDENTEMENTE da camada,
# com a MESMA regra nas 3 bases (≠ da varredura agregada core/envelope da §1).
# Unidades diferem (SIA=registros, SIH=AIH principal, SIM=óbitos) e NÃO se somam.
conta_trac <- function(df) df |> dplyr::filter(!is.na(tracadora)) |>
  dplyr::count(tracadora, name = "n")
# SIA: traçadoras core+limítrofe (do rds) + Biotinidase (E88.9=envelope) recuperada
# do agregado envelope, rotulada como PROXY/TETO (fora do agregado envelope da §1).
sia_trac <- dplyr::bind_rows(
  conta_trac(sia),
  sia_env |> dplyr::filter(subgrupo == "def_biotinidase_envelope") |>
    dplyr::summarise(tracadora = "Biotinidase", n = sum(n))
)
trac <- list(
  SIA       = sia_trac,
  SIH_princ = conta_trac(sih),                              # tracadora de diag_princ
  SIM_cb    = conta_trac(dplyr::filter(sim, eim_causa_basica))
) |> purrr::imap(~ dplyr::rename(.x, !!.y := n)) |>
  purrr::reduce(dplyr::full_join, by = "tracadora")
trac[is.na(trac)] <- 0
trac <- dplyr::mutate(trac, tracadora = dplyr::if_else(
  tracadora == "Biotinidase", "Biotinidase (E88.9 proxy/TETO)", tracadora))
CONTEXTO <- c("AME","Hemofilia_A","Hemofilia_B")
cat("— Traçadoras de EIM (E88.9=proxy/teto, fora do agregado envelope da §1):\n")
print(as.data.frame(dplyr::arrange(dplyr::filter(trac, !tracadora %in% CONTEXTO),
                                   dplyr::desc(SIA))))
cat("\n— Contexto / benchmark (NÃO-EIM — NUNCA somar ao total de EIM):\n")
print(as.data.frame(dplyr::filter(trac, tracadora %in% CONTEXTO)))

# -----------------------------------------------------------------------------
sep("3. SÉRIE TEMPORAL por base (core) + tendência Poisson")
serie <- dplyr::bind_rows(
  sia |> dplyr::filter(camada=="core") |> dplyr::count(ano, name="eventos") |> dplyr::mutate(base="SIA"),
  sih |> dplyr::filter(eim_principal, camada=="core") |> dplyr::count(ano, name="eventos") |> dplyr::mutate(base="SIH_princ"),
  sim |> dplyr::filter(eim_causa_basica) |> dplyr::count(ano, name="eventos") |> dplyr::mutate(base="SIM_cb")
)
print(tidyr::pivot_wider(serie, names_from=base, values_from=eventos))

# -----------------------------------------------------------------------------
sep("4. MORTALIDADE por EIM (SIM causa básica) padronizada / 100 mil hab")
sim_core <- dplyr::filter(sim, eim_causa_basica, !is.na(idade_anos), ano %in% ANOS_SIM)
num <- contar_estrato(sim_core, col_uf="uf_res")
print(taxas_padronizadas(num, pop, grupos="ano") |>
      dplyr::mutate(dplyr::across(c(taxa_bruta,taxa_pad,ic_inf,ic_sup), ~round(.x,3))))

sep("5. MORTALIDADE INFANTIL por EIM / 100 mil nascidos vivos (SINASC)")
inf <- sim_core |> dplyr::filter(obito_infantil) |>
  dplyr::transmute(uf=uf_res, ano=as.integer(ano), n=1) |> dplyr::filter(!is.na(uf))
print(incidencia_nascimento(inf, nv, grupos="ano") |>
      dplyr::mutate(dplyr::across(dplyr::any_of(c("inc_nasc","ic_inf","ic_sup")), ~round(.x,2))))

# -----------------------------------------------------------------------------
sep("6. INTERNAÇÃO por EIM (SIH principal core) padronizada / 100 mil hab")
sih_core <- dplyr::filter(sih, eim_principal, camada=="core", !is.na(idade_anos))
num_h <- contar_estrato(sih_core, col_uf="uf_res", distinct_por="n_aih")
print(taxas_padronizadas(num_h, pop, grupos="ano") |>
      dplyr::mutate(dplyr::across(c(taxa_bruta,taxa_pad,ic_inf,ic_sup), ~round(.x,3))))

readr::write_csv(trac, here::here("manifest/descritivo_tracadoras_cross_base.csv"))
message("\n✓ Descritivo cross-base concluído. Traçadoras salvas em manifest/.")
