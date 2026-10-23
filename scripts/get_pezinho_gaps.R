# =============================================================================
# get_pezinho_gaps.R — Consolida os 4 CIDs do PAINEL DO PEZINHO não-EIM
# (D57 falciforme, D56 talassemias, D81 IDP/SCID, P371 toxoplasmose congênita).
# Entrada: <DIR_FILTRADO>/{SIA-PA,SIH-RD,SIM-DO}/filtrado/*.parquet (filtragem 2010+ —
#          esses prefixos estão em eim_lookup.R e portanto em hit_eim). Mantém a linha
#          se QUALQUER campo de CID tem um dos 4 prefixos (mesma regra da extração
#          antiga, que era um diretório à parte no Lika).
# Escopo isolado: NUNCA entram nas taxas de EIM (escopo=="painel_pezinho").
# Ano: SIA = competência de atendimento (PA_CMP); SIH = arquivo (ANO_CMPT); SIM = arquivo
#      (só definitivos, ANOS_SIM).
# Saídas: data/consolidated/pezinho_{sia,sih,sim}.rds
# =============================================================================

source(here::here("scripts", "00_setup.R"))

GAPS <- EIM_LOOKUP$prefixo[EIM_LOOKUP$escopo == "painel_pezinho"]
tem_gap <- function(v) {
  v <- toupper(substr(trimws(as.character(v)), 1, 4))
  !is.na(v) & Reduce(`|`, lapply(GAPS, function(p) startsWith(v, p)))
}
tem_gap_multi <- function(v)   # SIM: vários CIDs por campo ("*D570*J189")
  !is.na(v) & grepl(paste0("(^|\\*)(", paste(GAPS, collapse = "|"), ")"), toupper(v))
ler <- function(base, cols, multi = character()) {
  fs <- list.files(file.path(DIR_FILTRADO, base, "filtrado"), pattern = "\\.parquet$", full.names = TRUE)
  purrr::map_dfr(fs, function(fp) {
    x <- arrow::read_parquet(fp)
    x <- x[x$hit_eim %in% TRUE, , drop = FALSE]
    if (!nrow(x)) return(NULL)
    names(x) <- tolower(names(x))
    h <- Reduce(`|`, c(lapply(intersect(cols, names(x)), function(c) tem_gap(x[[c]])),
                       lapply(intersect(multi, names(x)), function(c) tem_gap_multi(x[[c]]))))
    x[h, , drop = FALSE]
  })
}

# ---- SIA ----
message("== pezinho SIA ==")
sia <- ler("SIA-PA", c("pa_cidpri", "pa_cidsec", "pa_cidcas"))
cls <- classificar_eim(sia$pa_cidpri)
sia <- sia |>
  coagir_tipos(monetarias = c("pa_valapr")) |>
  dplyr::mutate(uf_arquivo = arq_uf,
    ano = suppressWarnings(as.integer(substr(pa_cmp, 1, 4))),
    trimestre = (suppressWarnings(as.integer(substr(pa_cmp, 5, 6))) - 1L) %/% 3L + 1L,
    cid_principal = stringr::str_sub(toupper(pa_cidpri), 1, 4),
    subgrupo = cls$subgrupo, tracadora = cls$tracadora, escopo = cls$escopo,
    sexo = dplyr::recode(toupper(stringr::str_trim(pa_sexo)), F = "Feminino", M = "Masculino", .default = NA_character_),
    idade_anos = suppressWarnings(as.integer(pa_idade)),
    idade_anos = dplyr::if_else(idade_anos >= 0 & idade_anos <= 110, idade_anos, NA_integer_),
    faixa = harmonizar_faixa(idade_anos), uf_pcn = uf_from_mun(pa_munpcn),
    regiao = mapear_uf_regiao(uf_pcn), pa_qtdapr = suppressWarnings(as.numeric(pa_qtdapr)),
    fonte = "datasus_sia_pa") |>
  dplyr::filter(ano %in% ANOS) |>
  dplyr::select(dplyr::any_of(c("pa_cidpri", "pa_cidsec", "pa_cidcas", "cid_principal", "subgrupo",
    "tracadora", "escopo", "sexo", "idade_anos", "faixa", "uf_pcn", "regiao", "ano", "trimestre",
    "pa_valapr", "pa_qtdapr", "pa_proc_id", "fonte")))
saveRDS(sia, here::here("data/consolidated/pezinho_sia.rds"))
cat("SIA gaps:", nrow(sia), "registros. Por doença:\n"); print(janitor::tabyl(sia, subgrupo))

# ---- SIH ----
message("== pezinho SIH ==")
sih <- ler("SIH-RD", c("diag_princ", "diag_secun", paste0("diagsec", 1:9)))
cls <- classificar_eim(sih$diag_princ)
sih <- sih |>
  coagir_tipos(monetarias = c("val_tot"), datas = c("dt_inter")) |>
  dplyr::mutate(uf_arquivo = arq_uf, ano = as.integer(arq_ano),
    trimestre = (as.integer(arq_mes) - 1L) %/% 3L + 1L,
    diag_principal = stringr::str_sub(toupper(diag_princ), 1, 4),
    subgrupo = cls$subgrupo, tracadora = cls$tracadora, escopo = cls$escopo,
    gap_principal = escopo %in% "painel_pezinho",
    sexo = dplyr::recode(as.character(sexo), "1" = "Masculino", "3" = "Feminino", .default = NA_character_),
    idade_anos = idade_em_anos(idade, cod_idade), faixa = harmonizar_faixa(idade_anos),
    uf_res = uf_from_mun(munic_res), regiao = mapear_uf_regiao(uf_res),
    morte = suppressWarnings(as.integer(morte)), fonte = "datasus_sih_rd") |>
  dplyr::filter(ano %in% ANOS) |>
  dplyr::select(dplyr::any_of(c("n_aih", "diag_princ", "diag_principal", "subgrupo", "tracadora",
    "escopo", "gap_principal", "sexo", "idade_anos", "faixa", "uf_res", "regiao", "ano", "trimestre",
    "val_tot", "morte", "fonte")))
saveRDS(sih, here::here("data/consolidated/pezinho_sih.rds"))
cat("SIH gaps:", nrow(sih), "AIH. Por doença (principal):\n")
print(janitor::tabyl(dplyr::filter(sih, gap_principal), subgrupo))

# ---- SIM ----
message("== pezinho SIM ==")
sim <- ler("SIM-DO", c("causabas", "causabas_o"), c("linhaa", "linhab", "linhac", "linhad", "linhaii"))
clc <- classificar_eim(sim$causabas)
sim <- sim |>
  dplyr::mutate(uf_arquivo = arq_uf, ano = as.integer(arq_ano),
    gap_causa_basica = clc$escopo %in% "painel_pezinho",
    subgrupo = clc$subgrupo, tracadora = clc$tracadora,
    idade_anos = decode_idade_sim(idade),                      # SIM cru: código de 3 dígitos
    faixa = harmonizar_faixa(idade_anos), obito_infantil = menor_1_ano(idade_anos),
    sexo = dplyr::case_when(toupper(as.character(sexo)) %in% c("1", "M") ~ "Masculino",
                            toupper(as.character(sexo)) %in% c("2", "F") ~ "Feminino", TRUE ~ NA_character_),
    uf_res = uf_from_mun(codmunres), regiao = mapear_uf_regiao(uf_res), fonte = "datasus_sim_do") |>
  dplyr::filter(status_dado == "DEFINITIVO", ano %in% ANOS_SIM) |>
  dplyr::select(dplyr::any_of(c("causabas", "subgrupo", "tracadora", "gap_causa_basica", "sexo",
    "idade_anos", "faixa", "obito_infantil", "uf_res", "regiao", "ano", "fonte")))
saveRDS(sim, here::here("data/consolidated/pezinho_sim.rds"))
cat("SIM gaps:", nrow(sim), "óbitos. Por doença (causa básica):\n")
print(janitor::tabyl(dplyr::filter(sim, gap_causa_basica), subgrupo))
message("\n✓ Gaps do pezinho consolidados (SIA/SIH/SIM).")
