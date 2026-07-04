# =============================================================================
# get_eim_data_from_SIM.R — Consolidação do SIM-DO filtrado por EIM
# Entrada: data/filtered/sim_eim/sim_do_{UF}_{ano}_eim.rds (filtrado no remoto;
#          objeto = tbl JÁ PROCESSADO minúsculo, 97 cols; idade_decode/faixa_etaria
#          já derivados). Disponível 2021–2023 no remoto (SIM-DO 2024+ pendente).
# CID no SIM: causabas + causabas_o + linhaa..d + linhaii (multi-código, †/*).
# EIXO CENTRAL: distinguir EIM como (i) CAUSA BÁSICA vs (ii) qualquer linha.
# Saídas: data/consolidated/sim_eim_nacional.rds
# =============================================================================

source(here::here("scripts", "00_setup.R"))

DIR_SIM <- here::here("data/filtered/sim_eim")
PAT <- "^sim_do_([A-Z]{2})_(\\d{4})_eim\\.rds$"
arqs <- list.files(DIR_SIM, pattern = PAT, full.names = TRUE)
if (!length(arqs)) stop("Nenhum filtrado SIM em ", DIR_SIM, " — rodar rsync primeiro.")

COLS_CAUSA <- c("causabas","causabas_o","linhaa","linhab","linhac","linhad","linhaii")

message("== SIM-EIM: consolidando ", length(arqs), " arquivos ==")
sim <- purrr::map_dfr(arqs, function(fp) {
  meta <- stringr::str_match(basename(fp), PAT)
  uf <- meta[2]; ano <- as.integer(meta[3])
  x <- readRDS(fp) |> as.data.frame() |> janitor::clean_names() |> corrigir_encoding()
  log_run("sim", uf, ano, "ok", n_lidas = nrow(x), n_eim = nrow(x))
  if (!nrow(x)) return(NULL)
  x |> dplyr::mutate(uf_arquivo = uf, ano = ano)
})

# Classificação: EIM como CAUSA BÁSICA vs em QUALQUER campo de causa (multi-código)
sim <- sim |>
  dplyr::mutate(
    eim_causa_basica = eh_eim(causabas, "ampliado", "todos"),
    eim_qualquer     = detecta_eim_sim(dplyr::pick(dplyr::everything()),
                                       cols = COLS_CAUSA, modo = "ampliado", escopo = "todos")
  )
# subgrupo/classe do EIM (prioriza causa básica; se ausente, 1º da lista de causas)
cls_cb <- classificar_eim(sim$causabas)
cls_ql <- classe_eim_sim(sim[, intersect(COLS_CAUSA, names(sim)), drop = FALSE], modo = "ampliado")
sim <- sim |>
  dplyr::mutate(
    subgrupo  = dplyr::coalesce(cls_cb$subgrupo, cls_ql$subgrupo),
    classe    = dplyr::coalesce(cls_cb$classe,   cls_ql$classe),
    tracadora = dplyr::coalesce(cls_cb$tracadora, cls_ql$tracadora),
    # idade em anos: `idade` = valor, `idade_decode` = UNIDADE ("ano"/"mes"/"dia"/
    # "hora"/"minuto"/">100"). Converter pela unidade (não é o valor decodificado!).
    idade_anos = dplyr::case_when(
      idade_decode %in% c("ano", ">100") ~ suppressWarnings(as.numeric(idade)),
      idade_decode == "mes"              ~ suppressWarnings(as.numeric(idade)) / 12,
      idade_decode == "dia"              ~ suppressWarnings(as.numeric(idade)) / 365.25,
      idade_decode %in% c("hora","minuto") ~ 0,
      is.na(idade_decode)                ~ decode_idade_sim(idade),
      TRUE                               ~ NA_real_
    ),
    faixa      = harmonizar_faixa(idade_anos),
    obito_infantil = menor_1_ano(idade_anos),
    # SIM processado já traz "Masculino"/"Feminino"; brutos usam "1"/"2" ou "M"/"F".
    sexo       = dplyr::case_when(
                   toupper(as.character(sexo)) %in% c("1","M","MASCULINO") ~ "Masculino",
                   toupper(as.character(sexo)) %in% c("2","F","FEMININO")  ~ "Feminino",
                   TRUE ~ NA_character_),
    # UF de residência = sigla via código IBGE do município (mun_res_uf traz o NOME
    # completo do estado, não a sigla → não usar como uf).
    uf_res     = uf_from_mun(codmunres),
    regiao     = mapear_uf_regiao(uf_res),
    fonte      = "datasus_sim_do"
  )

cat("\n• causa básica vs qualquer campo:\n")
print(sim |> dplyr::summarise(causa_basica = sum(eim_causa_basica, na.rm=TRUE),
                              qualquer     = sum(eim_qualquer, na.rm=TRUE),
                              total = dplyr::n()))
cat("• óbitos por subgrupo (top):\n"); print(head(as.data.frame(dplyr::count(sim, subgrupo, sort=TRUE)), 20))
cat("• óbitos infantis (<1 ano) por ano:\n")
print(sim |> dplyr::group_by(ano) |> dplyr::summarise(obitos = dplyr::n(),
      infantis = sum(obito_infantil, na.rm=TRUE)))

saveRDS(sim, here::here("data/consolidated/sim_eim_nacional.rds"))
message(sprintf("\n✓ SIM-EIM consolidado: %d óbitos com EIM (causa básica ou linha).", nrow(sim)))
