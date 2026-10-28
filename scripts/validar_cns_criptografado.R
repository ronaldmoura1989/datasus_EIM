# =============================================================================
# validar_cns_criptografado.R — O CNS criptografado identifica a mesma pessoa?
#
# Teste nacional de consistência do CNS criptografado nos arquivos que o carregam
# (SIA-AM, SIA-AD: AP_CNSPCN; SIA-BI: CNS_PAC), sobre todas as linhas filtradas
# 2010–2025. Para cada CNS visto em mais de um contexto, verifica se o sexo e o ano de
# nascimento concordam — o que se espera se o código é estável e não colide pessoas:
#   meses       — meses distintos do mesmo ano, mesmo arquivo
#   anos        — anos distintos, mesmo arquivo
#   AM × AD     — os dois arquivos de APAC
#   APAC × BPA-I
# Ano de nascimento: BPA-I = ano de DTNASC; APAC = ano da competência − idade (idade
# truncada em anos → concordância aceita diferença ≤ 1 ano no BPA-I e ≤ 2 entre APAC,
# cujas duas pontas são aproximadas). No BPA-I também se testa a data de nascimento
# exata entre todos os registros do mesmo CNS.
# Unidade = CNS (concordante = um único sexo; amplitude de ano de nascimento dentro da
# tolerância). Rastreabilidade pedida no parecer 2026-10-25 (Methods: teste do CNS).
# PRIVACIDADE: CNS só agrupado; nenhuma saída o contém.
# Saída: manifest/validacao_cns_concordancia.csv
# Rodar no R550-2: Rscript scripts/validar_cns_criptografado.R
# =============================================================================
source(here::here("scripts", "00_setup.R"))
suppressPackageStartupMessages(library(data.table))

ler <- function(base, cols) {
  fs <- list.files(file.path(DIR_FILTRADO, base, "filtrado"), pattern = "\\.parquet$", full.names = TRUE)
  rbindlist(parallel::mclapply(fs, function(f) as.data.table(arrow::read_parquet(f, col_select = dplyr::all_of(cols))), mc.cores = 24))
}
# idade em anos: unidade 4 = anos, 5 = 100 + valor, 2/3 = dias/meses (< 1 ano)
idade_anos <- function(un, v) { v <- suppressWarnings(as.integer(v))
  fifelse(un == "4", v, fifelse(un == "5", 100L + v, fifelse(un %chin% c("2", "3"), 0L, NA_integer_))) }

ap <- rbind(
  ler("SIA-AM", c("AP_CNSPCN", "AP_CMP", "AP_SEXO", "AP_COIDADE", "AP_NUIDADE"))[, fonte := "AM"],
  ler("SIA-AD", c("AP_CNSPCN", "AP_CMP", "AP_SEXO", "AP_COIDADE", "AP_NUIDADE"))[, fonte := "AD"])
ap <- ap[!is.na(AP_CNSPCN) & nchar(AP_CNSPCN) == 30,
         .(cns = AP_CNSPCN, fonte, ano = as.integer(substr(AP_CMP, 1, 4)), mes = AP_CMP, sexo = AP_SEXO,
           ano_nasc = as.integer(substr(AP_CMP, 1, 4)) - idade_anos(AP_COIDADE, AP_NUIDADE), dtnasc = NA_character_)]
bi <- ler("SIA-BI", c("CNS_PAC", "DT_ATEND", "SEXOPAC", "DTNASC"))
bi <- bi[!is.na(CNS_PAC) & nchar(CNS_PAC) == 30,
         .(cns = CNS_PAC, fonte = "BPA-I", ano = as.integer(substr(DT_ATEND, 1, 4)), mes = DT_ATEND, sexo = SEXOPAC,
           ano_nasc = as.integer(substr(DTNASC, 1, 4)), dtnasc = DTNASC)]
x <- unique(rbind(ap, bi)[sexo %chin% c("F", "M") & ano %in% ANOS])
rm(ap, bi); gc()
message(sprintf("registros únicos (CNS × fonte × mês × sexo × nascimento): %s", format(nrow(x), big.mark = ".")))

# resumo por CNS dentro de um contexto: sexo único? amplitude do ano de nascimento?
avaliar <- function(d, teste, tol) {
  r <- d[, .(sexo_ok = uniqueN(sexo) == 1L,
             nasc_ok = { a <- ano_nasc[!is.na(ano_nasc)]; if (length(a) < 2) NA else diff(range(a)) <= tol }), by = cns]
  data.table(teste, cns_testados = nrow(r), sexo_concordante_pct = round(100 * mean(r$sexo_ok), 2),
             cns_com_nascimento = sum(!is.na(r$nasc_ok)), nascimento_concordante_pct = round(100 * mean(r$nasc_ok, na.rm = TRUE), 2),
             tolerancia_anos = tol)
}
# CNS presentes em >1 valor de `chave` (dentro de `por`)
em_varios <- function(d, chave, por = NULL) {
  k <- d[, .(n = uniqueN(get(chave))), by = c("cns", por)][n > 1, c("cns", por), with = FALSE]
  merge(d, unique(k), by = c("cns", por))
}
ap_x <- x[fonte != "BPA-I"]; bi_x <- x[fonte == "BPA-I"]
res <- rbind(
  avaliar(em_varios(ap_x[, .(cns, sexo, ano_nasc, ano, mes = paste(fonte, mes))], "mes", "ano"), "APAC: meses distintos do mesmo ano", 2),
  avaliar(em_varios(ap_x, "ano"), "APAC: anos distintos", 2),
  avaliar(em_varios(ap_x, "fonte"), "APAC: AM × AD", 2),
  avaliar(em_varios(bi_x, "mes", "ano"), "BPA-I: meses distintos do mesmo ano", 1),
  avaliar(em_varios(bi_x, "ano"), "BPA-I: anos distintos", 1),
  avaliar(em_varios(x[, .(cns, sexo, ano_nasc, arq = fifelse(fonte == "BPA-I", "BPA-I", "APAC"))], "arq"), "APAC × BPA-I", 2))
# data de nascimento exata no BPA-I, entre todos os registros do mesmo CNS
dn <- bi_x[!is.na(dtnasc) & nchar(dtnasc) == 8, .(n = uniqueN(dtnasc), reg = .N), by = cns][reg > 1]
res <- rbind(res, data.table(teste = "BPA-I: data de nascimento idêntica em todos os registros do CNS", cns_testados = nrow(dn),
                             sexo_concordante_pct = NA_real_, cns_com_nascimento = nrow(dn),
                             nascimento_concordante_pct = round(100 * mean(dn$n == 1L), 2), tolerancia_anos = 0), fill = TRUE)
readr::write_csv(res, here::here("manifest/validacao_cns_concordancia.csv"))
print(res); message("✓ validar_cns_criptografado.R")
