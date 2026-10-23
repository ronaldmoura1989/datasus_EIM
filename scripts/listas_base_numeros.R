# =============================================================================
# listas_base_numeros.R — Base de números para as listas de prioridade
# (EIM, nefropatias hereditárias, hemoglobinopatias/sangue), série 2010+
#
# Lê os parquet filtrados (<DIR_FILTRADO>/<BASE>/filtrado) de forma LAZY (arrow): agrega
# dentro do arrow e só coleta tabelas pequenas — o SIA tem dezenas de milhões de linhas
# nos escopos (o envelope E78 sozinho passa de 50 M).
#   1. contagens por CID de 4 caracteres × UF de residência × ano: SIA (CID principal),
#      SIH (diagnóstico principal, AIH distintas), SIM (causa básica, definitivos, e se há
#      DRC/IRA — N17/N18/N19 — em alguma linha);
#   2. pacientes/mês (APAC distintas por competência) por medicamento marcador e UF;
#      e o CID das APAC de quelante (sobrecarga de ferro tem causa diversa);
#   3. testes genéticos/confirmatórios (hit_genetica) por procedimento × CID × UF de
#      residência × ano (só BPA-I/APAC, que trazem CID e residência).
# Saída: data/consolidated/listas_base_numeros.rds (lista de tibbles, sem microdado)
# Rodar no R550-2: Rscript scripts/listas_base_numeros.R
# =============================================================================

source(here::here("scripts", "00_setup.R"))
suppressPackageStartupMessages(library(arrow))

ds <- function(base) arrow::open_dataset(file.path(DIR_FILTRADO, base, "filtrado"), unify_schemas = TRUE)
uf_cod <- setNames(.UF_COD$uf, .UF_COD$cod)

# --- 1. contagens por CID ----------------------------------------------------
message("SIA por CID …")
sia_cid <- ds("SIA-PA") |>
  dplyr::filter(hit_eim | hit_hemato | hit_nefro) |>
  dplyr::transmute(cid4 = substr(PA_CIDPRI, 1, 4), ufc = substr(PA_MUNPCN, 1, 2),
                   ano = as.integer(substr(PA_CMP, 1, 4))) |>
  dplyr::filter(ano >= !!min(ANOS), ano <= !!max(ANOS)) |>
  dplyr::count(cid4, ufc, ano) |> dplyr::collect()

message("SIH por CID …")
sih_cid <- ds("SIH-RD") |>
  dplyr::filter(hit_eim | hit_hemato | hit_nefro) |>
  dplyr::transmute(cid4 = substr(DIAG_PRINC, 1, 4), ufc = substr(MUNIC_RES, 1, 2),
                   ano = as.integer(arq_ano), N_AIH) |>
  dplyr::filter(ano >= !!min(ANOS), ano <= !!max(ANOS)) |>
  dplyr::group_by(cid4, ufc, ano) |> dplyr::summarise(n = dplyr::n_distinct(N_AIH)) |>
  dplyr::collect()

message("SIM por CID …")
lin <- c("LINHAA", "LINHAB", "LINHAC", "LINHAD", "LINHAII")
sim_raw <- ds("SIM-DO") |>
  dplyr::filter(hit_eim | hit_hemato | hit_nefro, status_dado == "DEFINITIVO") |>
  dplyr::select(dplyr::any_of(c("CAUSABAS", "CODMUNRES", "arq_ano", lin))) |> dplyr::collect()
sim_raw$renal <- Reduce(`|`, lapply(intersect(lin, names(sim_raw)),
                                    function(c) grepl("N1[789]", sim_raw[[c]]) & !is.na(sim_raw[[c]])))
sim_cid <- sim_raw |>
  dplyr::transmute(cid4 = substr(CAUSABAS, 1, 4), ufc = substr(CODMUNRES, 1, 2),
                   ano = as.integer(arq_ano), renal) |>
  dplyr::filter(ano %in% ANOS_SIM) |>
  dplyr::group_by(cid4, ufc, ano) |>
  dplyr::summarise(n = dplyr::n(), renal = sum(renal), .groups = "drop")
rm(sim_raw); invisible(gc())

# --- 2. medicamentos marcadores ----------------------------------------------
MARCADOR <- c("0604480" = "hidroxiureia", "0604020" = "quelante de ferro", "0604870" = "burosumabe")
message("Medicamentos marcadores …")
med <- ds("SIA-PA") |>
  dplyr::filter(hit_medicamento) |>
  dplyr::transmute(p7 = substr(PA_PROC_ID, 1, 7), PA_AUTORIZ, PA_CMP,
                   ufc = substr(PA_MUNPCN, 1, 2), cid4 = substr(PA_CIDPRI, 1, 4),
                   cidsec = substr(PA_CIDSEC, 1, 3)) |>
  dplyr::filter(p7 %in% !!names(MARCADOR)) |> dplyr::collect()
med_mes <- med |>
  dplyr::group_by(p7, ufc, PA_CMP) |>
  dplyr::summarise(apac = dplyr::n_distinct(PA_AUTORIZ), .groups = "drop")
quel_cid <- med |> dplyr::filter(p7 == "0604020") |>
  dplyr::count(cid4, cidsec, ano = substr(PA_CMP, 1, 4))
rm(med); invisible(gc())

# --- 3. testes genéticos -----------------------------------------------------
message("Testes genéticos …")
gen <- ds("SIA-PA") |>
  dplyr::filter(hit_genetica, PA_DOCORIG %in% c("I", "P", "S")) |>
  dplyr::transmute(PA_PROC_ID, cid4 = substr(PA_CIDPRI, 1, 4), ufc = substr(PA_MUNPCN, 1, 2),
                   ano = as.integer(substr(PA_CMP, 1, 4)), qtd = as.numeric(PA_QTDAPR)) |>
  dplyr::filter(ano >= !!min(ANOS), ano <= !!max(ANOS)) |>
  dplyr::group_by(PA_PROC_ID, cid4, ufc, ano) |> dplyr::summarise(exames = sum(qtd, na.rm = TRUE)) |>
  dplyr::collect()

fix_uf <- function(d) dplyr::mutate(d, uf = unname(uf_cod[ufc])) |> dplyr::select(-ufc)
out <- list(sia_cid = fix_uf(sia_cid), sih_cid = fix_uf(sih_cid), sim_cid = fix_uf(sim_cid),
            med_mes = fix_uf(med_mes) |> dplyr::mutate(marcador = MARCADOR[p7]),
            quel_cid = quel_cid, gen = fix_uf(gen))
saveRDS(out, here::here("data/consolidated/listas_base_numeros.rds"))
for (n in names(out)) message(sprintf("  %-9s %8d linhas", n, nrow(out[[n]])))
message("✓ listas_base_numeros.rds")
