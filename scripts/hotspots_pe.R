# =============================================================================
# hotspots_pe.R — Pessoas com EIM por município e por região de saúde de RESIDÊNCIA em PE
#
# Para planejar uma rota itinerante de coleta: onde moram as pessoas com EIM (camada core)
# em SEGUIMENTO ambulatorial no SUS, não onde o atendimento é registrado. Pessoa = CNS
# criptografado distinto, em duas fontes:
#   - BPA-I (SIA-BI): município = MUNPAC do atendimento mais recente. Só conta como pessoa
#     quem tem procedimento fora do grupo 02 (exame sozinho = suspeita investigada, não
#     caso), a mesma regra de pacientes_cns_bi.R.
#   - APAC (PA ligado às APAC AM/AD pelo nº da autorização): município tirado do BPA-I do
#     mesmo CNS ou, sem BPA-I, do PA fora do grupo 0604. O município das APAC do CEAF
#     (grupo 0604) de PE sai quase sempre Recife e não é usado: quem só tem CEAF fica
#     "sem município confiável".
# O SIH fica FORA da contagem de pessoas: sem CNS, a pessoa seria a chave nascimento × sexo
# × município, e em PE essa chave infla com erro de codificação de hospital local (ex.:
# um hospital de Limoeiro com E70.0 recorrente em 2010–2020, >180 "pessoas com PKU").
# Vai à saída só como auditoria: pessoas_sih_sem_cns = chaves do SIH (AIH com EIM principal,
# core) que não casam com nenhum CNS do BPA-I.
# Doença = subgrupo da lookup, o mesmo das tabelas de pacientes. A pessoa conta uma vez em
# cada subgrupo que tem e uma vez no total da área.
# Saída: manifest/pe_hotspots.csv (nivel municipio | regiao | estado × subgrupo).
# PRIVACIDADE: CNS e chave só contados; nenhuma saída os contém. Supressão N<5.
# Rodar no R550-2: Rscript scripts/hotspots_pe.R   (HOTSPOTS_TESTE=1 lê só arquivos de PE)
# =============================================================================
source(here::here("scripts", "00_setup.R"))
suppressPackageStartupMessages(library(data.table))
RECENTES <- (max(ANOS) - 2L):max(ANOS)   # atendimento nos 3 últimos anos: em seguimento, alcançável
TESTE    <- Sys.getenv("HOTSPOTS_TESTE") == "1"
REG <- fread(here::here("ref/pe_regioes_saude.csv"), colClasses = c(munic_6 = "character"))

ler <- function(base, cols, filtro, so_eim = TRUE) {
  fs <- list.files(file.path(DIR_FILTRADO, base, "filtrado"), pattern = "\\.parquet$", full.names = TRUE)
  if (TESTE) fs <- fs[substr(basename(fs), 3, 4) == "PE"]
  rbindlist(parallel::mclapply(fs, function(f) {
    x <- as.data.table(arrow::read_parquet(f, col_select = dplyr::any_of(c(cols, "hit_eim"))))
    if (so_eim && "hit_eim" %in% names(x)) x <- x[hit_eim %in% TRUE]
    filtro(x)[, intersect(cols, names(x)), with = FALSE]
  }, mc.cores = 24), fill = TRUE)
}

# ---- BPA-I de residentes em PE --------------------------------------------------
bi <- ler("SIA-BI", c("CIDPRI", "CNS_PAC", "DTNASC", "SEXOPAC", "MUNPAC", "PROC_ID", "DT_ATEND"),
          function(x) x[startsWith(MUNPAC, "26") & nchar(CNS_PAC) == 30])
cls <- classificar_eim_analitico(bi$CIDPRI)
bi[, `:=`(subgrupo = cls$subgrupo, camada = cls$camada, ano = as.integer(substr(DT_ATEND, 1, 4)))]
bi <- bi[camada %chin% "core" & ano %in% ANOS]
# residência e chave de ligação com o SIH: atendimento mais recente (qualquer procedimento)
res_bi <- bi[order(DT_ATEND), .(munic_6 = MUNPAC[.N]), by = .(id = CNS_PAC)]
chave_bi <- unique(bi[!is.na(DTNASC) & SEXOPAC %chin% c("M", "F"),
                      .(chave = paste(DTNASC, SEXOPAC, MUNPAC), id = CNS_PAC)])
chave_bi <- chave_bi[, if (.N == 1L) .SD, by = chave]                # chave de 2+ CNS: não liga
p_bi <- bi[substr(PROC_ID, 1, 2) != "02", .(id = CNS_PAC, subgrupo, ano, fonte = "BPA-I")]

# ---- APAC de PE ligadas ao CNS ---------------------------------------------------
sia <- as.data.table(readRDS(here::here("data/consolidated/sia_eim_core_limitrofe.rds")))
sia <- sia[pa_docorig %chin% c("P", "S") & uf_pcn %chin% "PE" & camada %chin% "core" & ano %in% ANOS,
           .(pa_autoriz, ano, subgrupo, munpcn = pa_munpcn, ceaf = startsWith(pa_proc_id, "0604"))]
aut <- unique(sia$pa_autoriz)
ap  <- rbind(ler("SIA-AM", c("AP_AUTORIZ", "AP_CNSPCN"), function(x) x[AP_AUTORIZ %chin% aut], FALSE),
             ler("SIA-AD", c("AP_AUTORIZ", "AP_CNSPCN"), function(x) x[AP_AUTORIZ %chin% aut], FALSE))
ap  <- unique(ap)[nchar(AP_CNSPCN) == 30, .(id = AP_CNSPCN[1]), by = AP_AUTORIZ]
sia <- merge(sia, ap, by.x = "pa_autoriz", by.y = "AP_AUTORIZ")
p_ap   <- sia[, .(id, subgrupo, ano, fonte = "APAC")]
res_ap <- sia[ceaf == FALSE][order(ano), .(munic_6 = munpcn[.N]), by = id]

# ---- SIH (auditoria): chaves sem CNS ligado ----------------------------------------
sih <- as.data.table(readRDS(here::here("data/consolidated/sih_eim_nacional.rds")))
sih <- sih[eim_principal & camada %chin% "core" & uf_res %chin% "PE" & ano %in% ANOS &
             !is.na(nasc) & sexo %chin% c("Masculino", "Feminino") & munic_res %chin% REG$munic_6]
sih[, chave := paste(nasc, substr(sexo, 1, 1), munic_res)]
sih_sem <- sih[!chave %chin% chave_bi$chave, .(id = chave, subgrupo, munic_6 = munic_res)]
sih_sem <- merge(sih_sem, REG[, .(munic_6, geres)], by = "munic_6")

# ---- Pessoas (CNS) e residência --------------------------------------------------
pes <- rbind(p_bi, p_ap)[!is.na(subgrupo)]
res <- rbind(res_bi[, prio := 1L], res_ap[, prio := 2L])
res <- res[order(prio)][, .(munic_6 = munic_6[1]), by = id]
pes <- merge(pes, res, by = "id", all.x = TRUE)
pes[!munic_6 %chin% REG$munic_6, munic_6 := NA_character_]          # ignorado/inválido ou CEAF só
pes <- merge(pes, REG[, .(munic_6, geres)], by = "munic_6", all.x = TRUE)
recente <- pes[, .(recente = any(ano %in% RECENTES)), by = id]
pes <- merge(pes, recente, by = "id")
message(sprintf("PE: %d pessoas com CNS; %.1f%% sem município confiável; %d chaves do SIH sem CNS",
                uniqueN(pes$id), 100 * uniqueN(pes$id[is.na(pes$munic_6)]) / uniqueN(pes$id),
                uniqueN(sih_sem$id)))

# ---- Agregados ------------------------------------------------------------------
conta <- function(d, s, by) {
  f <- function(k) d[, .(pessoas = uniqueN(id), pessoas_recentes = uniqueN(id[recente])), by = k]
  g <- function(k) s[, .(pessoas_sih_sem_cns = uniqueN(id)), by = k]
  junta <- function(k) {                                   # 0 explícito: NA fica só para N<5
    r <- if (length(k)) merge(f(k), g(k), by = k, all = TRUE) else cbind(f(k), g(k))
    for (c in c("pessoas", "pessoas_recentes", "pessoas_sih_sem_cns")) set(r, which(is.na(r[[c]])), c, 0L)
    r
  }
  rbind(junta(c(by, "subgrupo")), junta(by)[, subgrupo := "TOTAL"], use.names = TRUE)
}
mun <- conta(pes[!is.na(munic_6)], sih_sem, "munic_6")[, `:=`(nivel = "municipio", codigo = munic_6)]
mun <- merge(mun, REG[, .(munic_6, nome = municipio, geres, regiao_saude, pop = pop_2022)], by = "munic_6")
pop_reg <- REG[, .(pop = sum(pop_2022)), by = .(geres, regiao_saude)]
rgs <- merge(conta(pes[!is.na(geres)], sih_sem, "geres"), pop_reg, by = "geres")[
  , `:=`(nivel = "regiao", codigo = geres, nome = regiao_saude)]
est <- conta(pes, sih_sem, character())[, `:=`(nivel = "estado", codigo = "PE", nome = "Pernambuco",
                                      pop = sum(REG$pop_2022))]
sem <- conta(pes[is.na(munic_6)], sih_sem[0], character())[, `:=`(nivel = "sem_municipio", codigo = NA_character_,
                                                     nome = "Sem município confiável")]
out <- rbind(mun[, munic_6 := NULL], rgs, est, sem, fill = TRUE)
out[, `:=`(periodo = sprintf("%d–%d", min(ANOS), max(ANOS)),
           recentes = sprintf("%d–%d", min(RECENTES), max(RECENTES)))]

sup <- function(x) ifelse(x > 0 & x < N_SUPRESSAO, NA, x)
for (c in c("pessoas", "pessoas_recentes", "pessoas_sih_sem_cns")) set(out, j = c, value = sup(out[[c]]))
setcolorder(out, c("nivel", "codigo", "nome", "geres", "regiao_saude", "pop", "subgrupo",
                   "pessoas", "pessoas_recentes", "pessoas_sih_sem_cns", "periodo", "recentes"))
readr::write_csv(out[order(nivel, codigo, -pessoas)], here::here("manifest/pe_hotspots.csv"))
print(out[subgrupo == "TOTAL" & nivel != "municipio", .(nivel, nome, pessoas, pessoas_recentes, pessoas_sih_sem_cns)])
print(out[subgrupo == "TOTAL" & nivel == "municipio"][order(-pessoas)][1:15, .(nome, regiao_saude, pessoas, pessoas_recentes)])
message("✓ hotspots_pe.R", if (TESTE) " (TESTE: só arquivos de PE)")
