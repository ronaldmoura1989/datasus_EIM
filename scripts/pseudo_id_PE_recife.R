# =============================================================================
# pseudo_id_PE_recife.R — Pseudo-individualização do SIA para PE e RECIFE
# Usa o motor compartilhado scripts/pseudo_id_motor.R (blocking sexo×município[×raça],
# janela ano_nasc±1, ligação certa por nº de APAC, componentes conexos igraph, cap
# span≤1), restrito ao escopo geográfico e, dado o volume menor, em TODOS os
# subgrupos core. Reporta o nº ESTIMADO DE INDIVÍDUOS como INTERVALO
# [frouxa ; estrita], com a referência externa de pacientes/mês no CEAF
# (mediana mensal de APAC com medicamento, 2024) para os grupos dispensados ali.
#
# ESCOPOS: PE (uf_pcn == "PE") e RECIFE (pa_munpcn == "261160").
# Princípio (LGPD, §5.1): pseudo-ID é AGRUPADOR, não identificador; intervalo, não
# ponto; supressão N<5 por subgrupo (o TOTAL agregado é grande, não suprimido);
# razão registros/paciente = INTENSIDADE DE USO. Cautela <1 ano (idade em anos).
# Saídas: manifest/sia_pseudo_pacientes_PE.csv e _Recife.csv.
# =============================================================================

if (!exists("EIM_LOOKUP")) source(here::here("scripts", "00_setup.R"))
source(here::here("scripts", "pseudo_id_motor.R"))

# -----------------------------------------------------------------------------
# Carregar core + normalizar quase-identificadores (uma vez)
# -----------------------------------------------------------------------------
sia_core <- readRDS(here::here("data/consolidated/sia_eim_core_limitrofe.rds")) |>
  dplyr::filter(camada == "core") |>
  dplyr::select(subgrupo, tracadora, sexo, idade_anos, pa_munpcn, pa_racacor,
                competencia, ano, uf_pcn, pa_autoriz, pa_docorig, pa_proc_id) |>
  normalizar_quase_id()

# -----------------------------------------------------------------------------
# Rotina por escopo: gradiente por subgrupo + TOTAL agregado
# -----------------------------------------------------------------------------
resumo_subgrupo <- function(s) {
  dplyr::mutate(resumo_gradiente(s), ref_ceaf_mes = ref_ceaf_mes(s))
}


rodar_escopo <- function(df, rotulo) {
  subs <- sort(unique(df$subgrupo))
  por_sub <- purrr::map_dfr(subs, function(sub) {
    r <- resumo_subgrupo(dplyr::filter(df, subgrupo == sub))
    dplyr::mutate(r, subgrupo = sub, .before = 1) })
  por_sub <- por_sub |>
    dplyr::mutate(razao = round(registros / pseudo_intermediaria, 2))
  # TOTAL agregado (soma sobre subgrupos — inclui os pequenos; grande, não suprimido)
  total <- por_sub |>
    dplyr::summarise(subgrupo = "TOTAL (todos os subgrupos core)",
                     registros = sum(registros),
                     pseudo_estrita = sum(pseudo_estrita),
                     pseudo_intermediaria = sum(pseudo_intermediaria),
                     pseudo_frouxa = sum(pseudo_frouxa),
                     n_chave_incompleta = sum(n_chave_incompleta),
                     ref_ceaf_mes = sum(ref_ceaf_mes, na.rm = TRUE)) |>
    dplyr::mutate(razao = round(registros / pseudo_intermediaria, 2))
  # Supressão N<5 nas CÉLULAS por subgrupo (o TOTAL fica)
  por_sub_sup <- por_sub |>
    dplyr::mutate(dplyr::across(c(dplyr::starts_with("pseudo_"), ref_ceaf_mes),
                   ~ dplyr::if_else(.x < N_SUPRESSAO, NA_integer_, as.integer(.x)))) |>
    dplyr::arrange(dplyr::desc(registros))
  out <- dplyr::bind_rows(por_sub_sup, total)
  cat(sprintf("\n== %s ==\n", rotulo)); print(as.data.frame(out))
  cat(sprintf("→ %s: ~%s registros; indivíduos estimados no INTERVALO [%s (frouxa) ; %s (estrita)]; razão %.1f reg/indivíduo\n",
      rotulo, formatC(total$registros, format="d", big.mark="."),
      formatC(total$pseudo_frouxa, format="d", big.mark="."),
      formatC(total$pseudo_estrita, format="d", big.mark="."), total$razao))
  out
}

pe     <- dplyr::filter(sia_core, uf_pcn == "PE")
recife <- dplyr::filter(sia_core, mun_n == "261160")

res_pe     <- rodar_escopo(pe,     "PERNAMBUCO (SIA core)")
res_recife <- rodar_escopo(recife, "RECIFE (SIA core)")

readr::write_csv(res_pe,     here::here("manifest","sia_pseudo_pacientes_PE.csv"))
readr::write_csv(res_recife, here::here("manifest","sia_pseudo_pacientes_Recife.csv"))
message("\n✓ Pseudo-ID SIA PE/Recife → manifest/sia_pseudo_pacientes_{PE,Recife}.csv")
