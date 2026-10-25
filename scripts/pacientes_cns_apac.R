# =============================================================================
# pacientes_cns_apac.R — Pacientes distintos pelo CNS criptografado das APAC (AM/AD)
#
# Cada APAC do PA (pa_docorig P/S) é ligada à APAC de medicamentos (AM) ou de laudos
# diversos (AD) pelo número da autorização (pa_autoriz = AP_AUTORIZ). AM e AD trazem o
# CNS do paciente criptografado (AP_CNSPCN, gravado em hexadecimal por filtrar_um.R),
# estável entre meses, anos e arquivos: dá pacientes DISTINTOS de verdade, sem o intervalo
# do pseudo-ID. A validação do pseudo-ID contra o CNS está em validar_pseudo_id_cns.R e
# ref/validacao_pseudo_id_cns.md.
#
# Escopo: registros de APAC da camada CORE do SIA (sia_eim_core_limitrofe.rds), como as
# demais tabelas do painel. Quem só tem BPA-I (consulta/exame, sem APAC) fica fora até o BI
# (também com CNS) ser incorporado.
# PRIVACIDADE: o CNS criptografado só é contado; nenhuma saída o contém. Supressão N<5.
# Saídas: manifest/sia_pacientes_cns.csv      (escopo × subgrupo: 2010–2025 e ano de referência)
#         manifest/sia_pacientes_cns_ano.csv  (escopo × subgrupo × ano)
# Rodar no R550-2: Rscript scripts/pacientes_cns_apac.R
# =============================================================================
source(here::here("scripts", "00_setup.R"))
suppressPackageStartupMessages(library(data.table))
ANO_REF <- 2024L   # último ano completo no SIA

ler_apac <- function(base) {
  fs <- list.files(file.path(DIR_FILTRADO, base, "filtrado"), pattern = "\\.parquet$", full.names = TRUE)
  rbindlist(parallel::mclapply(fs, function(f)
    as.data.table(arrow::read_parquet(f, col_select = c("AP_AUTORIZ", "AP_CNSPCN"))), mc.cores = 24))
}
ap <- unique(rbind(ler_apac("SIA-AM"), ler_apac("SIA-AD")))[!is.na(AP_CNSPCN) & nchar(AP_CNSPCN) == 30]
multi <- ap[, uniqueN(AP_CNSPCN), by = AP_AUTORIZ][V1 > 1, .N]   # APAC com mais de um CNS (deve ser ~0)
ap <- ap[, .(cns = AP_CNSPCN[1]), by = AP_AUTORIZ]
message(sprintf("APAC com CNS: %d (com mais de um CNS: %d)", nrow(ap), multi))

sia <- as.data.table(readRDS(here::here("data/consolidated/sia_eim_core_limitrofe.rds")))
sia <- sia[camada == "core" & pa_docorig %chin% c("P", "S"), .(pa_autoriz, ano, uf = uf_pcn, subgrupo)]
sia <- merge(sia, ap, by.x = "pa_autoriz", by.y = "AP_AUTORIZ", all.x = TRUE)
message(sprintf("registros de APAC (core): %d; ligados a um CNS: %.1f%%", nrow(sia), 100 * mean(!is.na(sia$cns))))

resumo <- function(d, esc) {
  f <- function(x, sub) x[, .(registros_apac = .N, apac = uniqueN(pa_autoriz), ligados_pct = round(100 * mean(!is.na(cns)), 1),
                              pacientes = uniqueN(cns[!is.na(cns)]), pacientes_ano_ref = uniqueN(cns[!is.na(cns) & ano == ANO_REF])),
                          by = sub]
  por_sub <- f(d, "subgrupo")
  total   <- f(copy(d)[, subgrupo := "TOTAL (todos os subgrupos core)"], "subgrupo")
  rbind(por_sub, total)[, escopo := esc]
}
tot <- rbind(resumo(sia, "Brasil"), resumo(sia[uf %chin% "PE"], "PE"))
tot[, registros_por_paciente := round(registros_apac / pacientes, 1)]
tot[, ano_ref := ANO_REF]
anual <- rbind(sia[, .(pacientes = uniqueN(cns[!is.na(cns)]), escopo = "Brasil"), by = .(subgrupo, ano)],
               sia[uf %chin% "PE", .(pacientes = uniqueN(cns[!is.na(cns)]), escopo = "PE"), by = .(subgrupo, ano)])

sup5 <- function(d, cols) { d <- copy(d); for (c in cols) set(d, j = c, value = ifelse(d[[c]] > 0 & d[[c]] < N_SUPRESSAO, NA, d[[c]])); d }
readr::write_csv(sup5(tot, c("registros_apac", "apac", "pacientes", "pacientes_ano_ref"))[order(escopo, -pacientes)],
                 here::here("manifest/sia_pacientes_cns.csv"))
readr::write_csv(sup5(anual, "pacientes")[order(escopo, subgrupo, ano)], here::here("manifest/sia_pacientes_cns_ano.csv"))
print(tot[order(escopo, -pacientes)][, .(escopo, subgrupo, ligados_pct, pacientes, pacientes_ano_ref, registros_por_paciente)], nrows = 80)
message("✓ pacientes_cns_apac.R")
