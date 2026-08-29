# =============================================================================
# get_eim_data_from_SIH.R — Consolidação do SIH-RD filtrado por EIM
# Entrada: data/filtered/sih_eim/sih_{uf}_{ano}_{tri}_eim.rds (filtrado no remoto;
#          objeto = data.frame bruto MAIÚSCULO, 113 cols).
# CID no SIH: DIAG_PRINC + DIAG_SECUN + DIAGSEC1..9 (+ CID_ASSO, CID_MORTE).
# DOIS SABORES: (a) diag_princ = EIM (comparável ao SIA); (b) EIM em QUALQUER campo.
# Deduplicação de AIH: contar N_AIH distinta; IDENT==5 = continuação.
# Saídas: data/parquet/sih_eim/ + consolidated/sih_eim_nacional.rds
# =============================================================================

source(here::here("scripts", "00_setup.R"))

DIR_SIH <- here::here("data/filtered/sih_eim")
PAT <- "^sih_([a-z]{2})_(\\d{4})_(\\d)_eim\\.rds$"
arqs <- list.files(DIR_SIH, pattern = PAT, full.names = TRUE)
if (!length(arqs)) stop("Nenhum filtrado SIH em ", DIR_SIH, " — rodar rsync primeiro.")

ler_sih <- function(fp) {
  meta <- stringr::str_match(basename(fp), PAT)
  uf <- toupper(meta[2]); ano <- as.integer(meta[3]); tri <- as.integer(meta[4])
  x <- readRDS(fp) |> as.data.frame() |> janitor::clean_names()
  log_run("sih", uf, sprintf("%d_T%d", ano, tri), "ok", n_lidas = nrow(x), n_eim = nrow(x))
  if (!nrow(x)) return(NULL)
  x |> dplyr::mutate(uf_arquivo = uf, ano = ano, trimestre = tri)
}

message("== SIH-EIM: consolidando ", length(arqs), " arquivos ==")
lst <- purrr::map(arqs, ler_sih) |> purrr::compact()
ref <- lst[[which.max(purrr::map_int(lst, nrow))]]
lst <- purrr::map(lst, ~ casar_tipos(.x, ref))
sih <- dplyr::bind_rows(lst); rm(lst); gc(verbose = FALSE)

cols_diag <- detectar_cols_diag(sih)                 # diag_princ + diag_secun + diagsec1..9
message("Colunas de diagnóstico detectadas: ", paste(cols_diag, collapse = ", "))

cls <- classificar_eim_analitico(sih$diag_princ)      # classe pelo diagnóstico PRINCIPAL, escopo restrito
sih <- sih |>
  coagir_tipos(monetarias = c("val_tot","val_sh","val_sp","val_uti"),
               datas = c("dt_inter","dt_saida")) |>
  dplyr::mutate(
    diag_principal = stringr::str_sub(toupper(diag_princ), 1, 4),
    subgrupo   = cls$subgrupo, classe = cls$classe, camada = cls$camada,
    tracadora  = cls$tracadora, heranca = cls$heranca, escopo = cls$escopo,
    # SABOR (a): EIM é o diagnóstico principal (comparável ao SIA)
    eim_principal = eh_eim(diag_princ, MODO_CAPTURA, "todos"),
    # SABOR (b): EIM em QUALQUER campo de diagnóstico (principal ou secundários)
    eim_qualquer  = dplyr::if_any(dplyr::any_of(cols_diag),
                                  ~ eh_eim(.x, "ampliado", "todos")),
    sexo       = dplyr::recode(as.character(sexo),
                               "1"="Masculino","3"="Feminino",
                               "M"="Masculino","F"="Feminino", .default = NA_character_),
    raca_cor   = dplyr::recode(stringr::str_pad(stringr::str_trim(as.character(raca_cor)), 2, pad="0"),
                               "01"="Branca","02"="Preta","03"="Parda","04"="Amarela",
                               "05"="Indígena", .default = NA_character_),
    idade_anos = idade_em_anos(idade, cod_idade),
    faixa      = harmonizar_faixa(idade_anos),
    uf_res     = uf_from_mun(munic_res),
    regiao     = mapear_uf_regiao(uf_res),
    dias_perm  = suppressWarnings(as.integer(dias_perm)),
    morte      = suppressWarnings(as.integer(morte)),
    uti        = suppressWarnings(as.integer(uti_mes_to)) > 0,
    aih_continuacao = as.character(ident) == "5",     # 5 = AIH de continuação
    fonte      = "datasus_sih_rd"
  )

# Camada mais específica (core > limítrofe > envelope) encontrada em QUALQUER
# campo de diagnóstico — o KPI "AIH com EIM em qualquer campo" (sabor b) não
# distingue core de envelope/fora-do-capítulo-E; sem essa coluna, a home só
# pode publicar o tamanho do recorte bruto, não um achado (ref. N3/E4 auditoria).
.PRIORIDADE_CAMADA <- c(core = 1L, limitrofe = 2L, envelope = 3L)
camadas_por_campo <- purrr::map(cols_diag, ~ classificar_eim_analitico(sih[[.x]])$camada)
sih$camada_qualquer <- purrr::pmap_chr(camadas_por_campo, function(...) {
  v <- unlist(list(...)); v <- v[!is.na(v)]
  if (!length(v)) return(NA_character_)
  v[which.min(.PRIORIDADE_CAMADA[v])]   # a camada de MENOR prioridade numérica (core=1) vence
})

cat("\n• sabor principal vs qualquer campo:\n")
print(sih |> dplyr::summarise(principal = sum(eim_principal, na.rm=TRUE),
                              qualquer  = sum(eim_qualquer,  na.rm=TRUE),
                              aih_distintas = dplyr::n_distinct(n_aih)))
cat("• KPI 'qualquer campo' por CAMADA mais específica encontrada (honestidade do\n")
cat("  rótulo — só 'core' é achado; o resto é teto de subcodificação/fora do núcleo):\n")
print(janitor::tabyl(sih, camada_qualquer))
cat("• subgrupos (principal, top):\n"); print(head(as.data.frame(dplyr::count(sih, subgrupo, sort=TRUE)), 20))
cat("• internações por ano:\n"); print(dplyr::count(sih, ano, name = "aih"))

sih |> dplyr::mutate(uf = uf_arquivo) |>
  arrow::write_dataset(here::here("data/parquet/sih_eim"),
                       partitioning = c("ano","uf"), format = "parquet")
saveRDS(sih, here::here("data/consolidated/sih_eim_nacional.rds"))
message(sprintf("\n✓ SIH-EIM consolidado: %d AIH-registros (2 sabores) → Parquet + consolidated.", nrow(sih)))
