# =============================================================================
# filtrar_um.R — Filtra UM arquivo DBC do DATASUS e grava filtrado + denominador
#
# Um processo por arquivo (o orquestrador roda N em paralelo): isola memória e
# tolera falha do código C do read.dbc. Pico ≈ 2–3× o tamanho do arquivo lido
# (maior SIA-PA, 235 MB de DBC ≈ 2 GB lido).
#
# Passos: read.dbc (as.is) → nomes MAIÚSCULOS → DENOMINADOR agregado sobre TODAS as
# linhas → flags hit_* por escopo (config_filtro.R) → mantém linhas com algum hit →
# todas as colunas como texto (elimina drift de tipo/colunas entre anos) → grava
# .tmp e renomeia (atômico) → marcador .ok com o tamanho do DBC (checkpoint).
#
# Saídas em <out>/<BASE>/:
#   filtrado/<ARQ>.parquet     linhas com algum hit + colunas meta (arq_*) + hit_*
#   denominador/<ARQ>.parquet  contagens agregadas (ver denominador_*)
#   ok/<ARQ>.ok                tamanho do DBC processado (pular se igual)
# Status: <out>/status_filtro.tsv (append com flock pelo orquestrador; aqui via lockfile)
#
# Uso: Rscript filtrar_um.R --base=SIA-PA --dbc=/caminho/PAPE2101.dbc --out=~/Documentos/ronald/datasus_filtrado
#      [--status=PRELIM|DEFINITIVO]
# =============================================================================
suppressPackageStartupMessages({ library(data.table); library(arrow) })

args <- commandArgs(trailingOnly = TRUE)
arg  <- function(k, d = NULL) { m <- grep(paste0("^--", k, "="), args, value = TRUE); if (length(m)) sub(paste0("^--", k, "="), "", m[1]) else d }
BASE <- arg("base"); DBC <- arg("dbc"); OUT <- path.expand(arg("out", "~/Documentos/ronald/datasus_filtrado"))
STATUS_DADO <- arg("status", if (grepl("/PRELIM/", DBC %||% "")) "PRELIM" else "DEFINITIVO")
stopifnot(!is.null(BASE), !is.null(DBC), file.exists(DBC))

.self <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1])
source(file.path(dirname(normalizePath(.self)), "config_filtro.R"))

ARQ  <- sub("\\.dbc$", "", basename(DBC), ignore.case = TRUE)
TAM  <- file.size(DBC)
DIRS <- file.path(OUT, BASE, c("filtrado", "denominador", "ok")); for (d in DIRS) dir.create(d, recursive = TRUE, showWarnings = FALSE)
f_filt <- file.path(DIRS[1], paste0(ARQ, ".parquet"))
f_den  <- file.path(DIRS[2], paste0(ARQ, ".parquet"))
f_ok   <- file.path(DIRS[3], paste0(ARQ, ".ok"))
f_stat <- file.path(OUT, "status_filtro.tsv")

registrar <- function(st, n_in = NA, n_out = NA, ncol = NA, seg = NA, msg = "") {
  linha <- paste(format(Sys.time(), "%F %T"), st, BASE, ARQ, TAM, n_in, n_out, ncol, seg, gsub("[\t\n]", " ", msg), sep = "\t")
  lk <- paste0(f_stat, ".lock")
  for (i in 1:50) { if (dir.create(lk, showWarnings = FALSE)) break; Sys.sleep(0.1) }   # lock atômico por mkdir
  if (!file.exists(f_stat)) cat("quando\tstatus\tbase\tarquivo\ttamanho_dbc\tn_in\tn_out\tncol\tsegundos\tmsg\n", file = f_stat)
  cat(linha, "\n", sep = "", file = f_stat, append = TRUE); unlink(lk, recursive = TRUE)
}

# Checkpoint: já processado com este mesmo tamanho de DBC
if (file.exists(f_ok) && file.exists(f_filt) && file.exists(f_den) &&
    identical(as.numeric(readLines(f_ok, warn = FALSE)[1]), as.numeric(TAM))) quit(status = 0)

# -----------------------------------------------------------------------------
# Metadados do nome do arquivo
# -----------------------------------------------------------------------------
meta_arquivo <- function(arq) {   # PA/RD: {UF}{AA}{MM}[parte] (mensal) · DO/DN: {UF}{AAAA} (anual)
  m <- regmatches(arq, regexec("^(PA|RD)([A-Z]{2})(\\d{2})(\\d{2})([a-z]?)$", arq, ignore.case = TRUE))[[1]]
  if (length(m)) return(list(uf = toupper(m[3]), ano = 2000L + as.integer(m[4]), mes = as.integer(m[5]), parte = tolower(m[6])))
  m <- regmatches(arq, regexec("^(DO|DN)([A-Z]{2})(\\d{4})$", arq, ignore.case = TRUE))[[1]]
  if (length(m)) return(list(uf = toupper(m[3]), ano = as.integer(m[4]), mes = NA_integer_, parte = ""))
  list(uf = NA_character_, ano = NA_integer_, mes = NA_integer_, parte = "")
}
MT <- meta_arquivo(ARQ)
uf_cod <- c("11"="RO","12"="AC","13"="AM","14"="RR","15"="PA","16"="AP","17"="TO","21"="MA","22"="PI","23"="CE",
            "24"="RN","25"="PB","26"="PE","27"="AL","28"="SE","29"="BA","31"="MG","32"="ES","33"="RJ","35"="SP",
            "41"="PR","42"="SC","43"="RS","50"="MS","51"="MT","52"="GO","53"="DF")
uf_de <- function(mun) unname(uf_cod[substr(as.character(mun), 1, 2)])

# Faixa etária quinquenal (anos) — mesma grade do denominador IBGE
faixa5 <- function(idade) {
  br <- c(0, 1, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80, Inf)
  lb <- c("<1", "1-4", "5-9", "10-14", "15-19", "20-24", "25-29", "30-34", "35-39", "40-44",
          "45-49", "50-54", "55-59", "60-64", "65-69", "70-74", "75-79", "80+")
  as.character(cut(idade, br, lb, right = FALSE))
}
# SIM: IDADE = 1º dígito unidade (0 min,1 h,2 d,3 m,4 a,5 a+100) + 2 dígitos valor
idade_sim <- function(x) { x <- suppressWarnings(as.integer(x)); u <- x %/% 100; v <- x %% 100
  data.table::fcase(u == 4, as.numeric(v), u == 5, 100 + v, u %in% 0:3, 0, default = NA_real_) }

texto <- function(v) {   # numérico → texto sem notação científica; texto latin1 → UTF-8 (exigido pelo parquet)
  if (is.numeric(v)) { s <- format(v, scientific = FALSE, trim = TRUE, drop0trailing = TRUE); s[is.na(v)] <- NA_character_; return(s) }
  s <- as.character(v); ruim <- !is.na(s) & !validUTF8(s)
  if (any(ruim)) s[ruim] <- iconv(s[ruim], from = "latin1", to = "UTF-8", sub = "?")
  s
}

# -----------------------------------------------------------------------------
# Denominadores (sobre TODAS as linhas, antes do filtro)
# -----------------------------------------------------------------------------
denominador <- function(x) {
  g <- function(c) if (c %in% names(x)) x[[c]] else NA
  switch(BASE,
    "SIA-PA" = x[, .(linhas = .N, qtd_apr = sum(as.numeric(g("PA_QTDAPR")), na.rm = TRUE),
                     val_apr = sum(as.numeric(g("PA_VALAPR")), na.rm = TRUE)),
                 by = .(cmp = g("PA_CMP"), docorig = g("PA_DOCORIG"), grupo_proc = substr(g("PA_PROC_ID"), 1, 4),
                        uf_res = uf_de(g("PA_MUNPCN")))],
    "SIH-RD" = x[, .(aih = uniqueN(N_AIH), obitos = sum(as.integer(g("MORTE")) == 1L, na.rm = TRUE),
                     diarias = sum(as.numeric(g("DIAS_PERM")), na.rm = TRUE)),
                 by = .(ano_cmpt = g("ANO_CMPT"), mes_cmpt = g("MES_CMPT"), ident = g("IDENT"),
                        uf_res = uf_de(g("MUNIC_RES")), uf_mov = uf_de(g("MUNIC_MOV")), sexo = g("SEXO"))],
    "SIM-DO" = x[, .(obitos = .N),
                 by = .(ano = substr(g("DTOBITO"), 5, 8), uf_res = uf_de(g("CODMUNRES")), sexo = g("SEXO"),
                        faixa = faixa5(idade_sim(g("IDADE"))), causabas3 = substr(g("CAUSABAS"), 1, 3))],
    "SINASC" = x[, .(nascidos = .N),
                 by = .(ano = substr(g("DTNASC"), 5, 8), uf_res = uf_de(g("CODMUNRES")), sexo = g("SEXO"),
                        idanomal = g("IDANOMAL"))])
}

# -----------------------------------------------------------------------------
# Flags por escopo
# -----------------------------------------------------------------------------
casa_prefixo <- function(v, prefs) {          # v = vetor de códigos; prefixos de tamanhos variados
  v <- toupper(gsub("^\\s+|\\s+$", "", as.character(v), useBytes = TRUE)); hit <- rep(FALSE, length(v))
  for (n in sort(unique(nchar(prefs)))) hit <- hit | (substr(v, 1, n) %chin% prefs[nchar(prefs) == n])
  hit & !is.na(v)
}
flags <- function(x) {
  cc <- intersect(COLS_CID[[BASE]], names(x)); cm <- intersect(COLS_CID_MULTI[[BASE]] %||% character(), names(x))
  cp <- intersect(COLS_PROC[[BASE]], names(x))
  out <- list()
  for (e in names(ESCOPO_CID)) {
    h <- rep(FALSE, nrow(x))
    for (c in cc) h <- h | casa_prefixo(x[[c]], ESCOPO_CID[[e]])
    if (length(cm)) { rx <- regex_multi(ESCOPO_CID[[e]], BASE)
      for (c in cm) h <- h | (grepl(rx, x[[c]], perl = TRUE, useBytes = TRUE, ignore.case = TRUE) & !is.na(x[[c]])) }
    out[[paste0("hit_", e)]] <- h
  }
  for (e in names(ESCOPO_PROC)) {
    h <- rep(FALSE, nrow(x)); for (c in cp) h <- h | casa_prefixo(x[[c]], ESCOPO_PROC[[e]])
    out[[paste0("hit_", e)]] <- h
  }
  as.data.table(out)
}

# -----------------------------------------------------------------------------
# Execução
# -----------------------------------------------------------------------------
t0 <- Sys.time()
res <- tryCatch({
  x <- data.table::setDT(read.dbc::read.dbc(DBC, as.is = TRUE))
  data.table::setnames(x, toupper(names(x)))
  n_in <- nrow(x); nc <- ncol(x)

  den <- denominador(x)
  den[, `:=`(arq = ARQ, arq_uf = MT$uf, arq_ano = MT$ano, arq_mes = MT$mes, arq_parte = MT$parte, status_dado = STATUS_DADO)]

  fl  <- flags(x)
  keep <- Reduce(`|`, fl)
  y <- x[keep]; fl <- fl[keep]; rm(x); invisible(gc(verbose = FALSE))
  for (c in names(y)) data.table::set(y, j = c, value = texto(y[[c]]))
  y[, `:=`(arq = ARQ, arq_uf = MT$uf, arq_ano = MT$ano, arq_mes = MT$mes, arq_parte = MT$parte, status_dado = STATUS_DADO)]
  y <- cbind(y, fl)

  arrow::write_parquet(y,   paste0(f_filt, ".tmp"), compression = "zstd")
  arrow::write_parquet(den, paste0(f_den,  ".tmp"), compression = "zstd")
  file.rename(paste0(f_filt, ".tmp"), f_filt); file.rename(paste0(f_den, ".tmp"), f_den)
  writeLines(as.character(TAM), f_ok)
  list(st = "OK", n_in = n_in, n_out = nrow(y), nc = nc, msg = "")
}, error = function(e) list(st = "ERRO", n_in = NA, n_out = NA, nc = NA, msg = conditionMessage(e)))

registrar(res$st, res$n_in, res$n_out, res$nc, round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1), res$msg)
quit(status = if (res$st == "OK") 0 else 1)
