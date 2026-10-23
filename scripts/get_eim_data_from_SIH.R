# =============================================================================
# get_eim_data_from_SIH.R — Consolidação do SIH-RD filtrado por EIM
# Entrada: <DIR_FILTRADO>/SIH-RD/filtrado/RD{UF}{AA}{MM}.parquet (scripts/r550/
#          filtrar_um.R: DBC do DATASUS 2010+, todas as colunas como texto, flags hit_*).
#          Só linhas com hit_eim; fica quem tem EIM no escopo analítico (principal ou
#          qualquer campo) — o painel do pezinho tem consolidação própria.
# ANO = ano do arquivo/competência da AIH (ANO_CMPT), como na série anterior.
# CID no SIH: DIAG_PRINC + DIAG_SECUN + DIAGSEC1..9 (+ CID_ASSO, CID_MORTE).
#   ⚠️ O CID secundário MUDA DE CAMPO: DIAG_SECUN até 2014 (7,8%→16,6% preenchido),
#   DIAGSEC1..9 a partir de 2014/15 (17%→29%). "Qualquer campo" cresce por
#   preenchimento — a série longa usa o diagnóstico PRINCIPAL.
# DOIS SABORES: (a) diag_princ = EIM (comparável ao SIA); (b) EIM em QUALQUER campo.
# Deduplicação de AIH: contar N_AIH distinta; IDENT==5 = continuação.
# Saídas: data/parquet/sih_eim/ + consolidated/sih_eim_nacional.rds
# =============================================================================

source(here::here("scripts", "00_setup.R"))

DIR_SIH <- file.path(DIR_FILTRADO, "SIH-RD", "filtrado")
arqs <- list.files(DIR_SIH, pattern = "\\.parquet$", full.names = TRUE)
if (!length(arqs)) stop("Nenhum filtrado SIH em ", DIR_SIH, " — rodar a filtragem no R550-2 primeiro.")

ler_sih <- function(fp) {
  x <- arrow::read_parquet(fp)
  x <- x[x$hit_eim %in% TRUE, , drop = FALSE] |> as.data.frame() |> janitor::clean_names()
  if (!nrow(x)) return(NULL)
  x |> dplyr::mutate(uf_arquivo = arq_uf, ano = as.integer(arq_ano),
                     trimestre = (as.integer(arq_mes) - 1L) %/% 3L + 1L) |>
    dplyr::filter(ano %in% ANOS)
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

# Só o escopo analítico do EIM (sai quem foi capturado só por CID do painel do pezinho)
n0 <- nrow(sih); sih <- dplyr::filter(sih, eim_principal | eim_qualquer)
cat(sprintf("\n• descartados (só painel do pezinho não-EIM): %d\n", n0 - nrow(sih)))

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
