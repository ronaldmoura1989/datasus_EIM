# =============================================================================
# catalogo_schema.R — Catálogo de colunas e preenchimento por base × ano (2010+)
#
# Para cada base × ano lê UM DBC de referência (UF --uf, padrão PE; mês 01 nas bases
# mensais; parte "a" quando dividido) e registra, por coluna: classe, % preenchido
# (não NA e não vazio/zeros) e nº de valores distintos. Documenta o drift de schema
# (SIA 54→62 cols, SIH 86→113, SIM 59→87) e a completude de campos-chave ao longo da
# série — ex.: DIAGSEC1..9 no SIH, PA_CIDSEC/PA_CIDCAS no SIA, LINHA* no SIM.
#
# Saídas em <raiz>/logs/: schema_catalogo.tsv (longo) e schema_resumo.tsv (base×ano)
# Uso: Rscript catalogo_schema.R [--raiz ~/Documentos/ronald/datasus_raw] [--uf PE]
# =============================================================================
suppressPackageStartupMessages(library(data.table))
args <- commandArgs(trailingOnly = TRUE)
arg  <- function(k, d) { m <- grep(paste0("^--", k, "="), args, value = TRUE); if (length(m)) sub(".*=", "", m[1]) else d }
RAIZ <- path.expand(arg("raiz", "~/Documentos/ronald/datasus_raw")); UF <- arg("uf", "PE")

man <- fread(file.path(RAIZ, "manifest", "manifesto_atual.tsv"), colClasses = "character")
man[, fp := file.path(RAIZ, destino, arquivo)]
man <- man[uf == UF & file.exists(fp)]
man <- man[file.size(fp) == as.numeric(tamanho)]
man[, mes := fifelse(nchar(periodo) >= 4 & base %in% c("SIA-PA", "SIH-RD"), substr(periodo, 3, 4), "")]
ref <- man[mes %in% c("", "01")][order(base, ano, periodo)][, .SD[1], by = .(base, ano)]

# useBytes: campos de texto do DBC vêm em latin1 e podem não ser UTF-8 válido
vazio <- function(v) is.na(v) | gsub("^\\s+|\\s+$", "", as.character(v), useBytes = TRUE) %chin% c("", "0", "00", "000", "0000", "00000000")
cat_um <- function(i) {
  r <- ref[i]
  x <- tryCatch(setDT(read.dbc::read.dbc(r$fp, as.is = TRUE)), error = function(e) NULL)
  if (is.null(x)) return(data.table(base = r$base, ano = r$ano, arquivo = r$arquivo, coluna = NA, classe = "ERRO_LEITURA",
                                    pct_preenchido = NA, distintos = NA, linhas = NA))
  setnames(x, toupper(names(x)))
  rbindlist(lapply(names(x), function(c) data.table(
    base = r$base, ano = r$ano, arquivo = r$arquivo, coluna = c, classe = class(x[[c]])[1],
    pct_preenchido = round(100 * mean(!vazio(x[[c]])), 1), distintos = uniqueN(x[[c]]), linhas = nrow(x))))
}
cat_ <- rbindlist(lapply(seq_len(nrow(ref)), cat_um))
fwrite(cat_, file.path(RAIZ, "logs", "schema_catalogo.tsv"), sep = "\t")

CHAVE <- c("PA_CIDSEC", "PA_CIDCAS", "PA_AUTORIZ", "PA_RACACOR", "PA_MUNPCN",
           "DIAG_SECUN", "DIAGSEC1", "DIAGSEC2", "NASC", "RACA_COR",
           "LINHAA", "LINHAII", "CAUSABAS_O", "IDANOMAL", "CODANOMAL")
res <- cat_[, .(colunas = .N, linhas = linhas[1]), by = .(base, ano)]
chave <- dcast(cat_[coluna %in% CHAVE], base + ano ~ coluna, value.var = "pct_preenchido")
res <- merge(res, chave, by = c("base", "ano"), all.x = TRUE)
fwrite(res, file.path(RAIZ, "logs", "schema_resumo.tsv"), sep = "\t")
print(res[order(base, ano)], nrows = 200)

# Colunas que entram ou saem ao longo da série (por base)
mud <- cat_[, .(anos = paste(range(ano), collapse = "–"), n_anos = .N), by = .(base, coluna)]
tot <- cat_[, .(n_total = uniqueN(ano)), by = base]
mud <- merge(mud, tot, by = "base")[n_anos < n_total][order(base, anos)]
cat("\nColunas presentes só em parte da série:\n"); print(mud[, .(base, coluna, anos)], nrows = 200)
