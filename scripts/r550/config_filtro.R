# =============================================================================
# config_filtro.R — FONTE ÚNICA dos escopos da filtragem dos DBC (2010+, R550-2)
#
# Uma passada por arquivo marca cada linha com flags por escopo (hit_*), para que o
# mesmo filtrado sirva a EIM, hematologia, nefro, genética e medicamentos. Antes os
# prefixos eram copiados à mão em filtrar_cid_remoto.R (PREF_DEFAULT) e em
# disparar_extracao_extra.sh — e já divergiam da lookup.
#
#   CID  (prefixos de 3 ou 4 caracteres, casados no início de cada CID):
#     eim    ← TODOS os prefixos de eim_lookup.R (núcleo, fora do cap. E, contexto
#              raras e painel do pezinho); a camada/escopo é decidida na consolidação
#     hemato ← hemoglobinopatias, enzimo/membranopatias, coagulopatias hereditárias,
#              falência medular constitucional, metemoglobinemia, sobrecarga de ferro
#     nefro  ← tubulopatias e nefropatias hereditárias fora do cap. E
#   PROCEDIMENTO SIGTAP (prefixos de qualquer tamanho, casados no início):
#     genetica    ← 02.02.10 inteiro + confirmatórios 02.02.11 + doenças raras/aconselhamento + HLA-B
#     medicamento ← os 19 de separacao_medicamento_apac.R (MED_APAC) + quelantes, burosumabe,
#                   hidroxiureia
#     lab         ← laboratório hematológico e renal especializado
#
# Sincronizar: GEN_PROC (genetica_sus_procedimentos.R) e MED_APAC
# (separacao_medicamento_apac.R) são os catálogos com RÓTULOS; aqui ficam só os códigos.
# =============================================================================

.dir_cfg <- local({
  a <- commandArgs(trailingOnly = FALSE); f <- sub("^--file=", "", grep("^--file=", a, value = TRUE))
  if (length(f)) dirname(normalizePath(f[1])) else getwd()
})
if (!exists("EIM_LOOKUP")) {
  lk <- c(file.path(.dir_cfg, "eim_lookup.R"), file.path(.dir_cfg, "..", "eim_lookup.R"))
  source(lk[file.exists(lk)][1])
}

ESCOPO_CID <- list(
  eim    = unique(EIM_LOOKUP$prefixo),
  hemato = c("D55", "D56", "D57", "D58", "D610", "D640", "D66", "D67", "D680", "D681",
             "D682", "D685", "D691", "D740", "D750", "T454"),
  nefro  = c("E268", "N251", "N258", "N07", "Q612", "Q613", "Q615")
)

ESCOPO_PROC <- list(
  genetica = c("0202100",                                   # citogenética, molecular, exoma, bioquímica EIM
               "0202110010", "0202110028", "0202110036",      # Hb variantes/molecular, FC molecular
               "0202110117", "0202110125", "0202110133",      # biotinidase sérica, HAC e biotinidase moleculares
               "0202110141",                                  # cloreto no suor
               "0301010196", "0301010200", "0301010218",      # avaliação doenças raras (eixos)
               "0301010226",                                  # aconselhamento genético
               "0201020068"),                                 # coleta HLA-B
  medicamento = c("0604240066", "0604240074", "0604240090", "0604240082", "0604240112",  # TRE MPS
                  "0604240104",                                                        # Pompe
                  "0604240031", "0604240023", "0604240058", "0604240120",              # Gaucher, Fabry
                  "0604630018",                                                        # miglustate
                  "0604560010", "0604630077",                                          # Wilson
                  "0604860021", "0604860030", "0604860013",                            # moduladores CFTR
                  "0604630069", "0604420013", "0604540060",                            # sapropterina, fludrocortisona, tafamidis
                  "0604020",                                                           # quelantes de ferro
                  "0604870",                                                           # burosumabe
                  "0604480"),                                                          # hidroxiureia
  lab = c("0202010481", "0202020177", "0202020240", "0202020320", "0202020355",
          "0202020550", "0202020568", "0202070271",                # G6PD, AT-III, vWF, Hb instável/fetal, PC/PS, meta-Hb
          "0306020165", "0306020211",                              # fator VIII p/ vW, fibrinogênio
          "0202050106", "0202050190")                              # oxalato, cistina urinária
)

# Colunas por base (comparação por nome MAIÚSCULO; colunas ausentes no ano são ignoradas)
COLS_CID <- list(
  "SIA-PA" = c("PA_CIDPRI", "PA_CIDSEC", "PA_CIDCAS"),
  "SIH-RD" = c("DIAG_PRINC", "DIAG_SECUN", paste0("DIAGSEC", 1:9), "CID_ASSO", "CID_MORTE"),
  "SIM-DO" = c("CAUSABAS", "CAUSABAS_O"),                     # 1 CID por campo
  "SINASC" = character(),
  # APAC de medicamentos (AM) e de laudos diversos (AD): mesmas colunas de CID com prefixo AP_
  "SIA-AM" = c("AP_CIDPRI", "AP_CIDSEC", "AP_CIDCAS"),
  "SIA-AD" = c("AP_CIDPRI", "AP_CIDSEC", "AP_CIDCAS"),
  "SIA-BI" = "CIDPRI")                                          # BPA individualizado: um CID
# SIM: campos de CAUSAS MÚLTIPLAS trazem vários CIDs concatenados com "*" (ex. "*A419*J960");
# casar em QUALQUER posição — o filtro antigo (4 primeiros caracteres) perdia todos.
COLS_CID_MULTI <- list("SIM-DO" = c("LINHAA", "LINHAB", "LINHAC", "LINHAD", "LINHAII"),
                       "SINASC" = c("CODANOMAL"))
COLS_PROC <- list("SIA-PA" = "PA_PROC_ID", "SIH-RD" = c("PROC_REA", "PROC_SOLIC"),
                  "SIM-DO" = character(), "SINASC" = character(),
                  "SIA-AM" = "AP_PRIPAL", "SIA-AD" = "AP_PRIPAL", "SIA-BI" = "PROC_ID")
# Identificador do paciente criptografado (CNS) em BI e APAC: bytes binários → gravado em
# hexadecimal (determinístico, ASCII). Pseudonimização: só para contar/ligar, nunca exportar.
COLS_CNS <- c("AP_CNSPCN", "CNS_PAC")

# Regex para campos multi-CID. SIM: códigos separados por "*" ("*A419*J960");
# SINASC: blocos de 4 caracteres SEM separador ("Q059Q669") → casar só em posição múltipla de 4.
regex_multi <- function(prefs, base) {
  alt <- paste(sort(unique(prefs)), collapse = "|")
  if (base == "SINASC") paste0("^(.{4})*(", alt, ")") else paste0("(^|\\*)(", alt, ")")
}
