# =============================================================================
# validar_amostra.R — Lê DBC baixados e confere as colunas que o pipeline usa
# Para cada base, lê até N arquivos (os primeiros do manifesto já presentes em disco,
# + o mais antigo e o mais recente) e verifica: leitura sem erro, nº de linhas > 0 e
# presença das colunas-chave (CID, procedimento, município, idade, sexo, datas).
# Uso: Rscript validar_amostra.R [--raiz ~/Documentos/ronald/datasus_raw] [--n 3]
# =============================================================================
args <- commandArgs(trailingOnly = TRUE)
arg  <- function(k, d) { m <- grep(paste0("^--", k, "="), args, value = TRUE); if (length(m)) sub(".*=", "", m[1]) else d }
RAIZ <- path.expand(arg("raiz", "~/Documentos/ronald/datasus_raw"))
N    <- as.integer(arg("n", "3"))

CHAVES <- list(
  "SIA-PA" = c("PA_PROC_ID", "PA_CIDPRI", "PA_CIDSEC", "PA_CIDCAS", "PA_MUNPCN", "PA_UFMUN",
               "PA_IDADE", "PA_SEXO", "PA_RACACOR", "PA_AUTORIZ", "PA_DOCORIG", "PA_QTDAPR", "PA_CMP"),
  "SIH-RD" = c("N_AIH", "DIAG_PRINC", "DIAG_SECUN", "PROC_REA", "MUNIC_RES", "NASC", "SEXO",
               "IDADE", "COD_IDADE", "DIAS_PERM", "MORTE", "DT_INTER"),
  "SIM-DO" = c("CAUSABAS", "LINHAA", "LINHAB", "LINHAC", "LINHAD", "LINHAII", "CODMUNRES",
               "DTOBITO", "DTNASC", "IDADE", "SEXO"),
  "SINASC" = c("CODMUNRES", "DTNASC", "SEXO", "PESO", "IDANOMAL", "CODANOMAL"))

man <- read.delim(file.path(RAIZ, "manifest", "manifesto_atual.tsv"), colClasses = "character")
man$fp <- file.path(RAIZ, man$destino, man$arquivo)
man <- man[file.exists(man$fp) & file.size(man$fp) == as.numeric(man$tamanho), ]
if (!nrow(man)) stop("nenhum arquivo completo em disco para validar")

res <- do.call(rbind, lapply(split(man, man$base), function(m) {
  m <- m[order(m$ano, m$periodo), ]
  idx <- unique(c(seq_len(min(N, nrow(m))), 1, nrow(m)))
  do.call(rbind, lapply(idx, function(i) {
    fp <- m$fp[i]; t0 <- Sys.time()
    x <- tryCatch(read.dbc::read.dbc(fp), error = function(e) e)
    if (inherits(x, "error"))
      return(data.frame(base = m$base[i], arquivo = m$arquivo[i], linhas = NA, colunas = NA,
                        faltam = NA, segundos = NA, status = paste("ERRO:", conditionMessage(x))))
    falt <- setdiff(CHAVES[[m$base[i]]], toupper(names(x)))
    data.frame(base = m$base[i], arquivo = m$arquivo[i], linhas = nrow(x), colunas = ncol(x),
               faltam = paste(falt, collapse = ","),
               segundos = round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1),
               status = if (nrow(x) > 0 && !length(falt)) "OK" else "VERIFICAR")
  }))
}))
print(res, row.names = FALSE)
write.table(res, file.path(RAIZ, "logs", paste0("validacao_", format(Sys.Date(), "%Y%m%d"), ".tsv")),
            sep = "\t", row.names = FALSE, quote = FALSE)
if (any(res$status != "OK")) quit(status = 1)
