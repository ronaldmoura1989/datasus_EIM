# =============================================================================
# pacientes_cns_bi.R — Pacientes e detecção no 1º ano em CRIANÇAS, com o BPA individualizado
#
# O BI (SIA-BI) traz os mesmos registros individualizados (BPA-I) do PA com o CNS do
# paciente criptografado (mesma criptografia das APAC) e a DATA DE NASCIMENTO completa.
# Dois produtos:
#   1. Pacientes distintos = união dos CNS das APAC (pacientes_cns_apac.R) e do BPA-I, por
#      subgrupo (camada core), Brasil e PE, 2010–2025 e no ano de referência.
#   2. Detecção no 1º ano em crianças distintas por traçadora (qualquer camada, como as
#      demais medidas de traçadora): criança ACOMPANHADA/TRATADA antes de 1 ano de idade —
#      BI: procedimento fora do grupo 02 (diagnóstico) com idade em meses entre DTNASC e o
#      mês de atendimento < 12; APAC: idade 0 —, por coorte de nascimento 2010–2024, ÷
#      nascidos vivos; óbitos infantis (SIM) por 100 crianças detectadas. Substitui a
#      "detecção" em REGISTROS (idade do SIA ruim; parecer 2026-10-25, C1).
#      Exames do grupo 02 sozinhos (cloreto no suor, confirmatório molecular, TSH/T4 de
#      controle) marcam SUSPEITA investigada, não caso: 91% das crianças <1 ano com E84 no
#      BI só têm o teste do suor. Colunas de moldura: crianças investigadas (com exames) e
#      crianças com seguimento após 1 ano (a mais específica).
# PRIVACIDADE: CNS só contado; nenhuma saída o contém. Supressão N<5.
# Saídas: manifest/sia_pacientes_cns_total.csv, manifest/sia_pacientes_cns_bi_ano.csv,
#         manifest/deteccao_1o_ano_criancas.csv
# Rodar no R550-2: Rscript scripts/pacientes_cns_bi.R
# =============================================================================
source(here::here("scripts", "00_setup.R"))
source(here::here("scripts", "calcular_taxas.R"))
suppressPackageStartupMessages(library(data.table))
ANO_REF <- 2024L
COORTES <- ANOS_SIM

ler <- function(base, cols, so_eim = TRUE) {
  fs <- list.files(file.path(DIR_FILTRADO, base, "filtrado"), pattern = "\\.parquet$", full.names = TRUE)
  rbindlist(parallel::mclapply(fs, function(f) {
    x <- as.data.table(arrow::read_parquet(f, col_select = dplyr::any_of(c(cols, "hit_eim"))))
    if (so_eim && "hit_eim" %in% names(x)) x[hit_eim %in% TRUE] else x
  }, mc.cores = 24), fill = TRUE)
}

# ---- APAC ligadas ao CNS ------------------------------------------------------
# todas as APAC filtradas (não só hit_eim): algumas APAC de EIM entram pelo medicamento
ap <- unique(rbind(ler("SIA-AM", c("AP_AUTORIZ", "AP_CNSPCN"), FALSE), ler("SIA-AD", c("AP_AUTORIZ", "AP_CNSPCN"), FALSE), fill = TRUE)[, .(AP_AUTORIZ, AP_CNSPCN)])
ap <- ap[!is.na(AP_CNSPCN) & nchar(AP_CNSPCN) == 30]
# validação da ligação (rastreabilidade): autorizações com mais de um CNS distinto
lig <- data.table(apac_com_cns = uniqueN(ap$AP_AUTORIZ), apac_mais_de_um_cns = ap[, uniqueN(AP_CNSPCN), by = AP_AUTORIZ][V1 > 1, .N])
lig[, pct_mais_de_um_cns := signif(100 * apac_mais_de_um_cns / apac_com_cns, 2)]
readr::write_csv(lig, here::here("manifest/validacao_cns_ligacao.csv"))
ap <- ap[, .(cns = AP_CNSPCN[1]), by = AP_AUTORIZ]
sia <- as.data.table(readRDS(here::here("data/consolidated/sia_eim_core_limitrofe.rds")))
sia <- sia[pa_docorig %chin% c("P", "S"), .(pa_autoriz, ano, uf = uf_pcn, subgrupo, camada, tracadora, idade_anos)]
sia <- merge(sia, ap, by.x = "pa_autoriz", by.y = "AP_AUTORIZ")

# ---- BPA individualizado (BI) -------------------------------------------------
bi <- ler("SIA-BI", c("CIDPRI", "CNS_PAC", "DTNASC", "DT_ATEND", "MUNPAC", "PROC_ID"))
bi <- bi[!is.na(CNS_PAC) & nchar(CNS_PAC) == 30]
cls <- classificar_eim_analitico(bi$CIDPRI)
bi[, `:=`(subgrupo = cls$subgrupo, camada = cls$camada, tracadora = cls$tracadora,
          ano = as.integer(substr(DT_ATEND, 1, 4)), uf = uf_from_mun(MUNPAC),
          nasc = as.Date(DTNASC, "%Y%m%d"), atend = as.Date(paste0(DT_ATEND, "15"), "%Y%m%d"))]
bi <- bi[!is.na(camada) & ano %in% ANOS]
bi[, idade_meses := as.numeric(atend - nasc) / 30.4375]
bi[, diagnostico := substr(PROC_ID, 1, 2) == "02"]                                # grupo 02 SIGTAP (exame)
message(sprintf("BI: %d registros EIM com CNS (%.1f%% core)", nrow(bi), 100 * mean(bi$camada == "core")))

# ---- 1. Pacientes: APAC ∪ BPA-I (core) -----------------------------------------
# BPA-I só com procedimento fora do grupo 02: exame sozinho (cloreto no suor, TSH de
# controle) é suspeita investigada, não paciente — mesma regra da detecção (item 2)
pa_c <- sia[camada == "core", .(cns, subgrupo, ano, uf, fonte = "APAC")]
bi_c <- bi[camada == "core" & !diagnostico, .(cns = CNS_PAC, subgrupo, ano, uf, fonte = "BPA-I")]
so_exame <- bi[camada == "core", .(so_exame = all(diagnostico)), by = .(cns = CNS_PAC, subgrupo)][so_exame == TRUE]
so_exame <- so_exame[!cns %chin% pa_c$cns, .(pessoas_so_exame_bpai = .N), by = subgrupo]
reg  <- rbind(pa_c, bi_c)
conta <- function(d, esc) {
  f <- function(x) x[, .(pacientes_apac = uniqueN(cns[fonte == "APAC"]), pacientes_bpai = uniqueN(cns[fonte == "BPA-I"]),
                         pacientes_total = uniqueN(cns), pacientes_total_ano_ref = uniqueN(cns[ano == ANO_REF]),
                         so_bpai = uniqueN(setdiff(cns[fonte == "BPA-I"], cns[fonte == "APAC"]))), by = subgrupo]
  rbind(f(d), f(copy(d)[, subgrupo := "TOTAL (todos os subgrupos core)"]))[, escopo := esc]
}
tot <- rbind(conta(reg, "Brasil"), conta(reg[uf %chin% "PE"], "PE"))[, ano_ref := ANO_REF]
tot <- merge(tot, so_exame[, escopo := "Brasil"], by = c("subgrupo", "escopo"), all.x = TRUE)
# série anual (Brasil): pacientes distintos por subgrupo e ano, APAC ∪ BPA-I — a medida de
# "mais gente diagnosticada e tratada"; a cobertura do APAC começa em anos diferentes
ano_s <- rbind(reg, copy(reg)[, subgrupo := "TOTAL (todos os subgrupos core)"])[
  , .(pacientes_apac = uniqueN(cns[fonte == "APAC"]), pacientes_bpai = uniqueN(cns[fonte == "BPA-I"]), pacientes_total = uniqueN(cns)), by = .(subgrupo, ano)]

# ---- 2. Detecção no 1º ano em crianças, por traçadora --------------------------
nasc_cns <- bi[!is.na(nasc), .(nasc = min(nasc)), by = .(cns = CNS_PAC)]          # data de nascimento por CNS
d_bi <- bi[!is.na(tracadora) & idade_meses >= -1 & idade_meses < 12,
           .(cns = CNS_PAC, tracadora, coorte = as.integer(format(nasc, "%Y")), fonte = "BPA-I", diagnostico)]
d_ap <- sia[!is.na(tracadora) & idade_anos %in% 0, .(cns, tracadora, coorte_aprox = ano, fonte = "APAC", diagnostico = FALSE)]
d_ap <- merge(d_ap, nasc_cns, by = "cns", all.x = TRUE)[, coorte := fifelse(is.na(nasc), coorte_aprox, as.integer(format(nasc, "%Y")))][, .(cns, tracadora, coorte, fonte, diagnostico)]
inv <- rbind(d_bi, d_ap)[coorte %in% COORTES]
inv <- inv[, .(fonte = paste(sort(unique(fonte[!diagnostico])), collapse = "+"), acompanhada = any(!diagnostico), coorte = min(coorte)), by = .(cns, tracadora)]
# seguimento após 1 ano: qualquer registro da mesma traçadora a partir de 12 meses (BI) ou 1 ano (APAC)
pos1 <- unique(rbind(bi[!is.na(tracadora) & idade_meses >= 12, .(cns = CNS_PAC, tracadora)],
                     sia[!is.na(tracadora) & idade_anos >= 1, .(cns, tracadora)]))[, pos1 := TRUE]
inv <- merge(inv, pos1, by = c("cns", "tracadora"), all.x = TRUE)[, pos1 := !is.na(pos1)]
det <- inv[acompanhada == TRUE]
nv_pool <- sum(data.table::as.data.table(carregar_nv())[ano %in% COORTES]$nv)
inc <- as.data.table(readr::read_csv(here::here("manifest/incidencia_nascimento_tracadoras.csv"), show_col_types = FALSE))
inc[, tracadora := sub(" \\(E88\\.9 proxy/TETO\\)$", "", tracadora)]                  # rótulo → chave da lookup
d1 <- det[, .(criancas_1o_ano = .N, so_bpai = sum(fonte == "BPA-I"), so_apac = sum(fonte == "APAC"), ambas = sum(fonte == "APAC+BPA-I"),
              criancas_seguimento_apos_1a = sum(pos1)), by = tracadora]
d1 <- merge(d1, inv[, .(criancas_investigadas_1o_ano = .N), by = tracadora], by = "tracadora", all = TRUE)
d1 <- merge(d1, inc[, .(tracadora, obitos_inf, registros_1o_ano = aih_inf + reg_sia_inf)], by = "tracadora", all.x = TRUE)
d1[, `:=`(por_100k_nv = round(1e5 * criancas_1o_ano / nv_pool, 2), seguimento_por_100k_nv = round(1e5 * criancas_seguimento_apos_1a / nv_pool, 2),
          obitos_por_100_detectadas = round(100 * obitos_inf / criancas_1o_ano, 1), nv_pool = nv_pool)]

sup5 <- function(d, cols) { d <- copy(d); for (c in cols) set(d, j = c, value = ifelse(d[[c]] > 0 & d[[c]] < N_SUPRESSAO, NA, d[[c]])); d }
readr::write_csv(sup5(tot, c("pacientes_apac", "pacientes_bpai", "pacientes_total", "pacientes_total_ano_ref", "so_bpai", "pessoas_so_exame_bpai"))[order(escopo, -pacientes_total)],
                 here::here("manifest/sia_pacientes_cns_total.csv"))
readr::write_csv(sup5(ano_s, c("pacientes_apac", "pacientes_bpai", "pacientes_total"))[order(subgrupo, ano)], here::here("manifest/sia_pacientes_cns_bi_ano.csv"))
readr::write_csv(sup5(d1, c("criancas_1o_ano", "so_bpai", "so_apac", "ambas", "criancas_seguimento_apos_1a", "criancas_investigadas_1o_ano"))[order(-criancas_1o_ano)], here::here("manifest/deteccao_1o_ano_criancas.csv"))
print(tot[escopo == "Brasil"][order(-pacientes_total)][1:15, .(subgrupo, pacientes_apac, pacientes_bpai, pacientes_total, so_bpai, pacientes_total_ano_ref)])
print(d1[order(-criancas_1o_ano)])
message("✓ pacientes_cns_bi.R")
