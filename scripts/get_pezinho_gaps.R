# =============================================================================
# get_pezinho_gaps.R — Consolida os 4 CIDs do PAINEL DO PEZINHO não-EIM
# (D57 falciforme, D56 talassemias, D81 IDP/SCID, P371 toxoplasmose congênita),
# re-extraídos à parte em data/filtered/pezinho_eim/{sia,sih,sim}.
# Escopo isolado: NUNCA entram nas taxas de EIM (escopo=="painel_pezinho").
# Saídas: data/consolidated/pezinho_{sia,sih,sim}.rds
# =============================================================================

source(here::here("scripts", "00_setup.R"))

DIR <- here::here("data/filtered/pezinho_eim")

# ---- SIA ----
sia_arqs <- list.files(file.path(DIR,"sia"), pattern="^sia_([a-z]{2})_(\\d{4})_(\\d)_eim\\.rds$", full.names=TRUE)
message("== pezinho SIA: ", length(sia_arqs), " arquivos ==")
sia <- purrr::map_dfr(sia_arqs, function(fp){
  m <- stringr::str_match(basename(fp), "^sia_([a-z]{2})_(\\d{4})_(\\d)_eim\\.rds$")
  x <- readRDS(fp) |> as.data.frame() |> janitor::clean_names()
  if(!nrow(x)) return(NULL)
  cls <- classificar_eim(x$pa_cidpri)
  x |> coagir_tipos(monetarias=c("pa_valapr")) |>
    dplyr::mutate(uf_arquivo=toupper(m[2]), ano=as.integer(m[3]), trimestre=as.integer(m[4]),
      cid_principal=stringr::str_sub(toupper(pa_cidpri),1,4),
      subgrupo=cls$subgrupo, tracadora=cls$tracadora, escopo=cls$escopo,
      sexo=dplyr::recode(toupper(stringr::str_trim(pa_sexo)),F="Feminino",M="Masculino",.default=NA_character_),
      idade_anos=suppressWarnings(as.integer(pa_idade)),
      idade_anos=dplyr::if_else(idade_anos>=0&idade_anos<=110,idade_anos,NA_integer_),
      faixa=harmonizar_faixa(idade_anos), uf_pcn=uf_from_mun(pa_munpcn),
      regiao=mapear_uf_regiao(uf_pcn), fonte="datasus_sia_pa") |>
    dplyr::select(dplyr::any_of(c("pa_cidpri","pa_cidsec","pa_cidcas","cid_principal","subgrupo",
      "tracadora","escopo","sexo","idade_anos","faixa","uf_pcn","regiao","ano","trimestre",
      "pa_valapr","pa_qtdapr","fonte")))
})
saveRDS(sia, here::here("data/consolidated/pezinho_sia.rds"))
cat("SIA gaps:", nrow(sia), "registros. Por doença:\n"); print(janitor::tabyl(sia, subgrupo))

# ---- SIH ----
sih_arqs <- list.files(file.path(DIR,"sih"), pattern="^sih_([a-z]{2})_(\\d{4})_(\\d)_eim\\.rds$", full.names=TRUE)
message("== pezinho SIH: ", length(sih_arqs), " arquivos ==")
sih <- purrr::map_dfr(sih_arqs, function(fp){
  m <- stringr::str_match(basename(fp), "^sih_([a-z]{2})_(\\d{4})_(\\d)_eim\\.rds$")
  x <- readRDS(fp) |> as.data.frame() |> janitor::clean_names()
  if(!nrow(x)) return(NULL)
  cls <- classificar_eim(x$diag_princ)
  x |> coagir_tipos(monetarias=c("val_tot"), datas=c("dt_inter")) |>
    dplyr::mutate(uf_arquivo=toupper(m[2]), ano=as.integer(m[3]), trimestre=as.integer(m[4]),
      diag_principal=stringr::str_sub(toupper(diag_princ),1,4),
      subgrupo=cls$subgrupo, tracadora=cls$tracadora, escopo=cls$escopo,
      gap_principal = escopo=="painel_pezinho",
      sexo=dplyr::recode(as.character(sexo),"1"="Masculino","3"="Feminino",.default=NA_character_),
      idade_anos=idade_em_anos(idade,cod_idade), faixa=harmonizar_faixa(idade_anos),
      uf_res=uf_from_mun(munic_res), regiao=mapear_uf_regiao(uf_res),
      morte=suppressWarnings(as.integer(morte)), fonte="datasus_sih_rd") |>
    dplyr::select(dplyr::any_of(c("n_aih","diag_princ","diag_principal","subgrupo","tracadora",
      "escopo","gap_principal","sexo","idade_anos","faixa","uf_res","regiao","ano","trimestre",
      "val_tot","morte","fonte")))
})
saveRDS(sih, here::here("data/consolidated/pezinho_sih.rds"))
cat("SIH gaps:", nrow(sih), "AIH. Por doença (principal):\n")
print(janitor::tabyl(dplyr::filter(sih, gap_principal), subgrupo))

# ---- SIM ----
sim_arqs <- list.files(file.path(DIR,"sim"), pattern="^sim_do_([A-Z]{2})_(\\d{4})_eim\\.rds$", full.names=TRUE)
message("== pezinho SIM: ", length(sim_arqs), " arquivos ==")
COLS <- c("causabas","causabas_o","linhaa","linhab","linhac","linhad","linhaii")
sim <- purrr::map_dfr(sim_arqs, function(fp){
  m <- stringr::str_match(basename(fp), "^sim_do_([A-Z]{2})_(\\d{4})_eim\\.rds$")
  x <- readRDS(fp) |> as.data.frame() |> janitor::clean_names() |> corrigir_encoding()
  if(!nrow(x)) return(NULL)
  clc <- classificar_eim(x$causabas)
  x |> dplyr::mutate(uf_arquivo=m[2], ano=as.integer(m[3]),
      gap_causa_basica = clc$escopo=="painel_pezinho",
      subgrupo=clc$subgrupo, tracadora=clc$tracadora,
      idade_anos=dplyr::case_when(
        idade_decode %in% c("ano",">100")~suppressWarnings(as.numeric(idade)),
        idade_decode=="mes"~suppressWarnings(as.numeric(idade))/12,
        idade_decode=="dia"~suppressWarnings(as.numeric(idade))/365.25,
        idade_decode %in% c("hora","minuto")~0, TRUE~NA_real_),
      faixa=harmonizar_faixa(idade_anos), obito_infantil=menor_1_ano(idade_anos),
      sexo=dplyr::case_when(toupper(as.character(sexo)) %in% c("1","M","MASCULINO")~"Masculino",
        toupper(as.character(sexo)) %in% c("2","F","FEMININO")~"Feminino", TRUE~NA_character_),
      uf_res=uf_from_mun(codmunres), regiao=mapear_uf_regiao(uf_res), fonte="datasus_sim_do") |>
    dplyr::select(dplyr::any_of(c("causabas","subgrupo","tracadora","gap_causa_basica","sexo",
      "idade_anos","faixa","obito_infantil","uf_res","regiao","ano","fonte")))
})
saveRDS(sim, here::here("data/consolidated/pezinho_sim.rds"))
cat("SIM gaps:", nrow(sim), "óbitos. Por doença (causa básica):\n")
print(janitor::tabyl(dplyr::filter(sim, gap_causa_basica), subgrupo))
message("\n✓ Gaps do pezinho consolidados (SIA/SIH/SIM).")
