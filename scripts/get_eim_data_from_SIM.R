# =============================================================================
# get_eim_data_from_SIM.R — Consolidação do SIM-DO filtrado por EIM
# Entrada: <DIR_FILTRADO>/SIM-DO/filtrado/DO{UF}{AAAA}.parquet (scripts/r550/
#          filtrar_um.R: DBC CRU do DATASUS 2010+, colunas MAIÚSCULAS como texto,
#          flags hit_*; status_dado = DEFINITIVO | PRELIM). Antes: RData do SIM já
#          processado pelo microdatasus no Lika (idade_decode etc.), só 2021–2023.
# ⚠️ A filtragem antiga lia só os 4 primeiros caracteres das LINHAS A–D/II, que no SIM
#    trazem vários CIDs concatenados com "*" ("*A419*J960") — perdia todo óbito com EIM
#    só nas causas múltiplas. A filtragem nova casa em qualquer posição.
# CID no SIM: causabas + causabas_o + linhaa..d + linhaii (multi-código, †/*).
# EIXO CENTRAL: distinguir EIM como (i) CAUSA BÁSICA vs (ii) qualquer linha.
# ANOS_SIM (definitivos) → data/consolidated/sim_eim_nacional.rds
# Ano PRELIMINAR      → data/consolidated/sim_eim_preliminar.rds (fora das taxas)
# =============================================================================

source(here::here("scripts", "00_setup.R"))

DIR_SIM <- file.path(DIR_FILTRADO, "SIM-DO", "filtrado")
arqs <- list.files(DIR_SIM, pattern = "\\.parquet$", full.names = TRUE)
if (!length(arqs)) stop("Nenhum filtrado SIM em ", DIR_SIM, " — rodar a filtragem no R550-2 primeiro.")

COLS_CAUSA <- c("causabas","causabas_o","linhaa","linhab","linhac","linhad","linhaii")

message("== SIM-EIM: consolidando ", length(arqs), " arquivos ==")
# (sem corrigir_encoding: filtrar_um.R já gravou o texto em UTF-8; reconverter de
#  latin1 corromperia os acentos)
sim <- purrr::map_dfr(arqs, function(fp) {
  x <- arrow::read_parquet(fp)
  x <- x[x$hit_eim %in% TRUE, , drop = FALSE] |> as.data.frame() |> janitor::clean_names()
  if (!nrow(x)) return(NULL)
  x |> dplyr::mutate(uf_arquivo = arq_uf, ano = as.integer(arq_ano))
})

# Classificação: EIM como CAUSA BÁSICA vs em QUALQUER campo de causa (multi-código)
#
# CAMADA (corrigido — ver ref/avaliacao_critica_externa.md §1): `eim_causa_basica`
# usava modo "ampliado" (core+limítrofe+ENVELOPE) enquanto SIA e SIH usavam a
# camada restrita. O KPI de mortalidade herdava, assim, E78 (dislipidemia), E79.0
# (gota), E83.1 (hemocromatose), E85 adquirida, E88.x e E90 — exatamente os códigos
# que a lookup declara "NUNCA caso confirmado" — e produzia idade mediana ao óbito
# de 71 anos num grupo de doenças cuja letalidade é neonatal/lactente.
#
# Agora são TRÊS colunas explícitas, e a definição primária é a mesma das outras bases:
#   eim_causa_basica  = camada CORE          → análise primária (comparável a SIH)
#   eim_cb_ampliado   = core+limítrofe+env.  → TETO de subcodificação (bracketing)
#   eim_qualquer      = ampliado, qualquer linha → teto multi-código
# Quem precisar do teto (traçadora Biotinidase em E88.9, KPI em intervalo) deve usar
# `eim_cb_ampliado` EXPLICITAMENTE — nunca reintroduzir o envelope no número primário.
sim <- sim |>
  dplyr::mutate(
    eim_causa_basica = eh_eim(causabas, "restrito", "todos"),
    eim_cb_ampliado  = eh_eim(causabas, "ampliado", "todos"),
    eim_qualquer     = detecta_eim_sim(dplyr::pick(dplyr::everything()),
                                       cols = COLS_CAUSA, modo = "ampliado", escopo = "todos")
  )
# SIM processado (legado) trazia idade_decode (UNIDADE da idade); o cru não tem →
# coluna vazia faz idade_anos cair em decode_idade_sim(idade) (código de 3 dígitos).
if (!"idade_decode" %in% names(sim)) sim$idade_decode <- NA_character_

# subgrupo/classe do EIM (prioriza causa básica; se ausente, 1º da lista de causas)
cls_cb <- classificar_eim(sim$causabas)
cls_ql <- classe_eim_sim(sim[, intersect(COLS_CAUSA, names(sim)), drop = FALSE], modo = "ampliado")
sim <- sim |>
  dplyr::mutate(
    # CID de 4 caracteres e camada DA CAUSA BÁSICA — necessários para auditar a
    # composição do numerador (distribuição por código na página do SIM).
    cid_cb    = cls_cb$cid,
    camada_cb = cls_cb$camada,
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
      TRUE                               ~ decode_idade_sim(idade)   # SIM cru: código de 3 dígitos
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

cat("\n• causa básica (core) vs teto ampliado vs qualquer campo:\n")
print(sim |> dplyr::summarise(cb_core      = sum(eim_causa_basica, na.rm=TRUE),
                              cb_ampliado  = sum(eim_cb_ampliado, na.rm=TRUE),
                              qualquer     = sum(eim_qualquer, na.rm=TRUE),
                              total = dplyr::n()))
cat("• causa básica por CAMADA (auditoria do numerador):\n")
print(as.data.frame(dplyr::count(sim, camada_cb, sort = TRUE)))
cat("• top 25 CID de 4 dígitos na causa básica (auditoria de garbage codes):\n")
print(head(as.data.frame(dplyr::count(sim, cid_cb, camada_cb, sort = TRUE)), 25))
cat("• óbitos por subgrupo (top):\n"); print(head(as.data.frame(dplyr::count(sim, subgrupo, sort=TRUE)), 20))
cat("• óbitos infantis (<1 ano) por ano:\n")
print(sim |> dplyr::group_by(ano) |> dplyr::summarise(obitos = dplyr::n(),
      infantis = sum(obito_infantil, na.rm=TRUE)))

# Só o escopo analítico (sai quem foi capturado só por CID do painel do pezinho)
n0 <- nrow(sim); sim <- dplyr::filter(sim, eim_causa_basica | eim_cb_ampliado | eim_qualquer)
cat(sprintf("\n• descartados (só painel do pezinho não-EIM): %d\n", n0 - nrow(sim)))

prelim <- dplyr::filter(sim, status_dado != "DEFINITIVO" | !ano %in% ANOS_SIM)
sim    <- dplyr::filter(sim, status_dado == "DEFINITIVO", ano %in% ANOS_SIM)
saveRDS(prelim, here::here("data/consolidated/sim_eim_preliminar.rds"))
saveRDS(sim, here::here("data/consolidated/sim_eim_nacional.rds"))
message(sprintf("\n✓ SIM-EIM consolidado: %d óbitos com EIM (causa básica ou linha), %d–%d; %d no ano preliminar à parte.",
                nrow(sim), min(ANOS_SIM), max(ANOS_SIM), nrow(prelim)))
