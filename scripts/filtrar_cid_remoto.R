#!/usr/bin/env Rscript
# =============================================================================
# filtrar_cid_remoto.R — FILTRAGEM POR CID no servidor REMOTO "Lika" (roda via SSH)
# -----------------------------------------------------------------------------
# Os brutos do DATASUS já estão em /media/prospecmol/disk2/ronald/{BASE}/datasets.
# Este script roda LÁ, mantém só as linhas com CID de EIM (E70–E90 + correlatos +
# triagem fora do E + raras da lista MS) e grava .rds FILTRADOS leves, trazidos
# depois por rsync e consolidados localmente.
#
# LAYOUTS CONFIRMADOS (inspeção 2026-07-01):
#   SIA: sia_{uf}_{ano}_{tri}.RData        objeto `x`  (60 cols, MAIÚSCULAS)
#        CID: PA_CIDPRI, PA_CIDSEC, PA_CIDCAS
#        (ignorar os total_atendimentos_*.RData — são denominador agregado)
#   SIH: sih_{uf}_{ano}_{tri}.RData        objeto `x`  (113 cols, MAIÚSCULAS)
#        CID: DIAG_PRINC, DIAG_SECUN, DIAGSEC1..9, CID_ASSO, CID_MORTE
#   SIM: sim_do_{UF}_{ano}.RData           objeto `x`  (97 cols, minúsculas, processado)
#        CID: causabas, causabas_o, linhaa, linhab, linhac, linhad, linhaii
#
# USO (no remoto):
#   Rscript filtrar_cid_remoto.R --base=SIA [--uf=ac] [--out=/dados/eim/SIA]
# =============================================================================

suppressPackageStartupMessages(library(stringr))
has_dt <- requireNamespace("data.table", quietly = TRUE)

# ---- 0. Args ---------------------------------------------------------------
args <- commandArgs(trailingOnly = TRUE)
getarg <- function(k, d = NULL) { m <- grep(paste0("^--",k,"="), args, value=TRUE)
  if (length(m)) sub(paste0("^--",k,"="), "", m[1]) else d }
BASE   <- toupper(getarg("base", "SIA"))
ROOT   <- getarg("root", "/media/prospecmol/disk2/ronald")
DIR_IN <- getarg("in",  file.path(ROOT, BASE, "datasets"))
DIR_OUT<- getarg("out", file.path(ROOT, "eim_filtrado", BASE))
UF_ONLY<- tolower(getarg("uf", ""))           # opcional: só uma UF (teste)
ANO_MIN<- as.integer(getarg("ano_min", "2021"))
ANO_MAX<- as.integer(getarg("ano_max", "2025"))
dir.create(DIR_OUT, recursive = TRUE, showWarnings = FALSE)

# ---- 1. Prefixos EIM (SINCRONIZAR com eim_lookup.R::regex_eim("todos")) -----
# Prefixos padrão (núcleo EIM). Sobrescreva com --prefs="D57,D56,D81,P371" para
# extrações específicas (ex.: gaps do painel do pezinho, em diretório separado).
PREF_DEFAULT <- c("E70","E71","E72","E73","E74","E75","E76","E77","E78","E79","E80",
          "E83","E84","E85","E88","E90",          # núcleo E70–E90
          "E250","E031",                            # triagem fora do E (HAC, hipotireoidismo)
          "G120","D66","D67")                       # raras não-EIM da lista MS (contexto)
prefs_arg <- getarg("prefs", "")
PREF <- if (nzchar(prefs_arg)) toupper(strsplit(prefs_arg, ",")[[1]]) else PREF_DEFAULT
REGEX_EIM <- paste0("^(", paste(sort(unique(PREF)), collapse="|"), ")")

# Colunas de CID por base (comparação por NOME em maiúsculas → case-insensitive)
COLS_CID <- switch(BASE,
  SIA = c("PA_CIDPRI","PA_CIDSEC","PA_CIDCAS"),
  SIH = c("DIAG_PRINC","DIAG_SECUN",paste0("DIAGSEC",1:9),"CID_ASSO","CID_MORTE"),
  SIM = c("CAUSABAS","CAUSABAS_O","LINHAA","LINHAB","LINHAC","LINHAD","LINHAII"),
  stop("BASE inválida"))

# Padrão de arquivo por base (exclui total_atendimentos_ no SIA)
PAT <- switch(BASE,
  SIA = "^sia_[a-z]{2}_[0-9]{4}_[1-4]\\.RData$",
  SIH = "^sih_[a-z]{2}_[0-9]{4}_[1-4]\\.RData$",
  SIM = "^sim_do_[A-Z]{2}_[0-9]{4}\\.RData$")

ano_de <- function(nm) as.integer(str_extract(nm, "[0-9]{4}"))
uf_de  <- function(nm) tolower(str_match(nm, "_([A-Za-z]{2})_[0-9]{4}")[,2])

# ---- 2. Leitura + filtro ---------------------------------------------------
carregar_x <- function(fp){ e<-new.env(); nm<-load(fp, envir=e); get(nm[1], envir=e) }

filtrar_eim <- function(df){
  up <- toupper(names(df))
  cols <- names(df)[up %in% COLS_CID]
  if (!length(cols)) return(df[0, , drop=FALSE])
  hit <- rep(FALSE, nrow(df))
  for (cc in cols) {
    v <- str_sub(str_trim(toupper(as.character(df[[cc]]))), 1, 4)
    hit <- hit | (str_starts(v, REGEX_EIM) %in% TRUE)
  }
  df[which(hit), , drop=FALSE]
}

# ---- 3. Loop ---------------------------------------------------------------
arqs <- list.files(DIR_IN, pattern = PAT, full.names = TRUE)
sel  <- ano_de(basename(arqs)) >= ANO_MIN & ano_de(basename(arqs)) <= ANO_MAX
if (nzchar(UF_ONLY)) sel <- sel & (uf_de(basename(arqs)) == UF_ONLY)
arqs <- arqs[sel]
cat(sprintf("[%s] %d arquivos (%d-%d%s)\n", BASE, length(arqs), ANO_MIN, ANO_MAX,
            if (nzchar(UF_ONLY)) paste0(", uf=",UF_ONLY) else ""))

res <- vector("list", length(arqs))
for (i in seq_along(arqs)) {
  fp <- arqs[i]; nm <- basename(fp)
  out_fp <- file.path(DIR_OUT, sub("\\.RData$", "_eim.rds", nm))
  res[[i]] <- tryCatch({
    df <- carregar_x(fp); n_in <- nrow(df)
    f  <- filtrar_eim(df)
    saveRDS(f, out_fp, compress = "xz")
    cat(sprintf("  %-26s %9d -> %6d\n", nm, n_in, nrow(f)))
    data.frame(arquivo=nm, n_in=n_in, n_eim=nrow(f), status="ok")
  }, error=function(e){
    cat(sprintf("  %-26s ERRO: %s\n", nm, conditionMessage(e)))
    data.frame(arquivo=nm, n_in=NA, n_eim=NA, status=paste("erro:",conditionMessage(e)))
  })
  if (i %% 20 == 0) gc(verbose=FALSE)
}
log_dt <- do.call(rbind, res)
write.csv(log_dt, file.path(DIR_OUT, sprintf("_filtro_log_%s.csv", BASE)), row.names=FALSE)
cat(sprintf("\n[%s] OK. %d->%d linhas EIM. Saída: %s\n", BASE,
            sum(log_dt$n_in, na.rm=TRUE), sum(log_dt$n_eim, na.rm=TRUE), DIR_OUT))
