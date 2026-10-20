# =============================================================================
# separacao_medicamento_apac.R — Tipa EIM pelo medicamento dispensado na APAC (CEAF)
#
# Dois eixos:
#
# A. DESAMBIGUAÇÃO — o CID-10 agrega doenças distintas e o medicamento separa:
#   E76.x  MPS:   laronidase → MPS I · idursulfase → MPS II · alfaelosulfase → MPS IVA ·
#                 galsulfase → MPS VI · alfavestronidase → MPS VII
#   E74.0  Glicogenoses: alfa-alglicosidase → Pompe (GSD II)
#   E75.2  Outras esfingolipidoses: imiglucerase/alfataliglicerase/alfavelaglicerase →
#                 Gaucher · TRE de Fabry → Fabry · miglustate → Gaucher tipo 1 OU NP-C
#   E83.0  Metabolismo do cobre: penicilamina/trientina → Wilson
#   1. SIA — APAC com medicamento: tipo direto. Se a mesma APAC tem mais de um
#      medicamento (ex.: miglustate + imiglucerase), o tipo é a INTERSEÇÃO dos conjuntos
#      de doença ({Gaucher, NP-C} ∩ {Gaucher} = Gaucher); interseção vazia → ambíguo.
#   2. SIA — demais registros (consulta, órtese, transporte…) e
#   3. SIH — a AIH não registra medicamento, mas tem NASC (data completa), sexo e
#      MUNIC_RES — são VINCULADOS às APAC com medicamento pela chave sexo × ano de
#      nascimento, em dois níveis: (a) mesmo município de residência; se não houver
#      candidato, (b) mesma UF. O nível (b) existe porque o município do paciente nas
#      APAC do CEAF NÃO é confiável: em PE quase todas saem com Recife (261160), e um
#      lote de 2024-03 da farmácia estadual (CNES 6471188) saiu com municípios trocados.
#      A idade no SIA é truncada em anos, então ano_nasc_proxy (= ano − idade) ∈
#      {B, B+1} para nascidos no ano B (SIH); entre dois registros SIA, ±1.
#   O vínculo só aceita tipos COMPATÍVEIS com o CID do registro (E76.0 só MPS I,
#   E76.2 só IVA/VI/VII, E74.0 só Pompe…) e resolve vários candidatos pela mesma
#   interseção de conjuntos. Sem vínculo → fica pelo CID (E76.0/E76.1 já são
#   específicos) ou "sem medicamento".
#
# B. ESTRATIFICAÇÃO — o CID já é específico e o medicamento indica fenótipo/genótipo:
#   E84.x  FC:  elexacaftor/tezacaftor/ivacaftor (ETI) → ≥1 F508del (critério de
#               incorporação, Portaria SECTICS/MS 47/2023) · ivacaftor isolado →
#               variante de gating [VERIFICAR PCDT]
#   E70.0/E70.1 PKU/HPA: sapropterina → responsiva a BH4
#   E25.0  HAC: fludrocortisona → com mineralocorticoide (perdedora de sal provável)
#   E85.1  ATTRv: tafamidis → em tratamento modificador
#   Só contagem de pacientes/mês (sem vínculo de registros): numerador = APAC com o
#   medicamento; denominador (FC, PKU) = APAC com qualquer medicamento do grupo.
#
# PACIENTES: nº de APAC distintas por competência — uma APAC do CEAF agrupa os
# medicamentos do paciente (em 2024-06, só 3 de 711 APAC de E75.2 tinham >1
# medicamento). Reporta a MEDIANA MENSAL de ANO_REF, a mediana do 4º trimestre de
# ANO_REF (capta a rampa de incorporação, ex.: ETI a partir de 2024-04) e o máximo.
#
# CÓDIGOS SEM NOME no SIGTAP embutido (microdatasus::sigtab), inferidos do perfil:
#   0604240120 — só E75.2, início 2025-03, adultos (mediana 41 a), mais mulheres,
#                8 frascos/mês → TRE de Fabry (provável alfagalsidase 3,5 mg).
#   0604860030 — FC, início 2024-04 com o ETI adulto, idade 6–11 a → ETI pediátrico.
#   0604860021 — ETI adulto (nome já em sia_procedimentos_sigtap.R §1b).
#
# LIMITES: chave sem identificador direto (LGPD) — colisão possível no nível UF;
# quem não tem APAC com medicamento (MPS III, glicogenoses hepáticas/musculares,
# NP-A/B, Krabbe, LDM, tratamento por via judicial fora do CEAF, falha de vínculo)
# cai em "sem medicamento" e NÃO é tipado.
#
# Saídas (supressão N<5 nas células de contagem):
#   manifest/med_apac_sia.csv      — A: escopo (Brasil/PE) × grupo × tipo × via
#   manifest/med_apac_sih.csv      — A: idem, AIH com EIM principal
#   manifest/med_apac_uf.csv       — A+B: pacientes/mês por UF × tipo (+ taxa/milhão)
#   manifest/med_apac_estratos.csv — B: pacientes/mês por escopo × grupo × estrato
#   manifest/med_apac_vinculo.csv  — QC: vínculo SIH→APAC por escopo × CID × nível
# Rodar: source("scripts/00_setup.R"); source("scripts/separacao_medicamento_apac.R")
# =============================================================================

if (!exists("EIM_LOOKUP"))   source(here::here("scripts", "00_setup.R"))
if (!exists("carregar_pop")) source(here::here("scripts", "calcular_taxas.R"))

ANO_REF <- 2024L   # último ano completo no SIA (2025 com competências faltantes)
AMBIGUO <- "Não separável (vínculo ambíguo)"

# -----------------------------------------------------------------------------
# 1. Mapa medicamento SIGTAP → tipo  ·  tipo → conjunto de doenças  ·  CID → tipos
# -----------------------------------------------------------------------------
MED_APAC <- tibble::tribble(
  ~pa_proc_id,   ~medicamento,                         ~tipo,                     ~grupo,                   ~eixo,
  "0604240066",  "Laronidase",                         "MPS I",                   "mucopolissacaridose",    "A",
  "0604240074",  "Idursulfase alfa",                   "MPS II",                  "mucopolissacaridose",    "A",
  "0604240090",  "Alfaelosulfase",                     "MPS IVA",                 "mucopolissacaridose",    "A",
  "0604240082",  "Galsulfase",                         "MPS VI",                  "mucopolissacaridose",    "A",
  "0604240112",  "Alfavestronidase",                   "MPS VII",                 "mucopolissacaridose",    "A",
  "0604240104",  "Alfa-alglicosidase",                 "Pompe (GSD II)",          "glicogenose",            "A",
  "0604240031",  "Imiglucerase",                       "Gaucher",                 "esfingolipidose_outras", "A",
  "0604240023",  "Alfataliglicerase",                  "Gaucher",                 "esfingolipidose_outras", "A",
  "0604240058",  "Alfavelaglicerase",                  "Gaucher",                 "esfingolipidose_outras", "A",
  "0604240120",  "TRE de Fabry (provável alfagalsidase) [VERIFICAR nome SIGTAP]",
                                                       "Fabry",                   "esfingolipidose_outras", "A",
  "0604630018",  "Miglustate",                         "Gaucher tipo 1 ou NP-C",  "esfingolipidose_outras", "A",
  "0604560010",  "Penicilamina",                       "Wilson",                  "metab_cobre",            "A",
  "0604630077",  "Trientina",                          "Wilson",                  "metab_cobre",            "A",
  # ---- B. estratificação --------------------------------------------------
  "0604860021",  "Elexacaftor/tezacaftor/ivacaftor (adulto)",     "ETI — ≥1 F508del",          "fibrose_cistica",     "B",
  "0604860030",  "Elexacaftor/tezacaftor/ivacaftor (6–11 anos) [VERIFICAR nome SIGTAP]",
                                                                  "ETI — ≥1 F508del",          "fibrose_cistica",     "B",
  "0604860013",  "Ivacaftor",                                     "Ivacaftor — variante de gating", "fibrose_cistica", "B",
  "0604630069",  "Sapropterina",                                  "Sapropterina — responsiva a BH4", "aminoacidopatia_PKU", "B",
  "0604420013",  "Fludrocortisona",                               "Fludrocortisona — perdedora de sal provável", "hiperplasia_adrenal_cong", "B",
  "0604540060",  "Tafamidis",                                     "Tafamidis — ATTRv em tratamento", "amiloidose_familiar", "B"
)
GRUPOS_A <- unique(MED_APAC$grupo[MED_APAC$eixo == "A"])
GRUPOS_B <- unique(MED_APAC$grupo[MED_APAC$eixo == "B"])
# Denominador de B: grupos cujo CEAF tem outros medicamentos (APAC com qualquer 06.04)
GRUPOS_B_DENOM <- c("fibrose_cistica", "aminoacidopatia_PKU")

# Conjunto de doenças por tipo (só o miglustate é guarda-chuva)
TIPO_DOENCAS <- list("Gaucher tipo 1 ou NP-C" = c("Gaucher", "NP-C"))
doencas_de <- function(t) TIPO_DOENCAS[[t]] %||% t

#' Resolve um conjunto de tipos candidatos pela interseção das doenças.
resolver_tipos <- function(tipos) {
  tipos <- unique(tipos)
  if (length(tipos) == 1L) return(tipos)
  inter <- Reduce(intersect, lapply(tipos, doencas_de))
  if (length(inter) == 0L) return(AMBIGUO)
  # rótulo cujo conjunto de doenças coincide com a interseção
  alvo <- tipos[vapply(tipos, function(t) setequal(doencas_de(t), inter), logical(1))]
  if (length(alvo)) alvo[1] else AMBIGUO
}

# Tipos aceitos por CID de 4 caracteres (E76.3/E76.8/E76.9 = MPS NE: qualquer MPS)
CID_TIPOS <- tibble::tribble(
  ~cid4,   ~tipo,
  "E760",  "MPS I",
  "E761",  "MPS II",
  "E762",  "MPS IVA",
  "E762",  "MPS VI",
  "E762",  "MPS VII",
  "E740",  "Pompe (GSD II)",
  "E752",  "Gaucher",
  "E752",  "Fabry",
  "E752",  "Gaucher tipo 1 ou NP-C",
  "E830",  "Wilson"
) |>
  dplyr::bind_rows(tidyr::expand_grid(
    cid4 = c("E763", "E768", "E769"),
    tipo = MED_APAC$tipo[MED_APAC$grupo == "mucopolissacaridose"]))

# Rótulo quando NÃO há vínculo a APAC com medicamento
rotulo_sem_med <- function(cid4) dplyr::case_when(
  cid4 == "E760" ~ "MPS I",
  cid4 == "E761" ~ "MPS II",
  cid4 == "E762" ~ "MPS III/IV/VI/VII — sem medicamento vinculado",
  substr(cid4, 1, 3) == "E76" ~ "MPS não especificada — sem medicamento vinculado",
  cid4 == "E740" ~ "Glicogenose sem TRE (não-Pompe ou Pompe sem TRE)",
  cid4 == "E752" ~ "E75.2 sem medicamento (NP-A/B, Krabbe, LDM, Farber… ou sem tratamento)",
  cid4 == "E830" ~ "E83.0 sem quelante (Menkes, outros, ou Wilson em zinco)",
  TRUE ~ "Outro")

ORDEM_TIPOS <- c("MPS I", "MPS II", "MPS IVA", "MPS VI", "MPS VII",
                 "MPS III/IV/VI/VII — sem medicamento vinculado",
                 "MPS não especificada — sem medicamento vinculado",
                 "Pompe (GSD II)", "Glicogenose sem TRE (não-Pompe ou Pompe sem TRE)",
                 "Gaucher", "Fabry", "Gaucher tipo 1 ou NP-C",
                 "E75.2 sem medicamento (NP-A/B, Krabbe, LDM, Farber… ou sem tratamento)",
                 "Wilson", "E83.0 sem quelante (Menkes, outros, ou Wilson em zinco)",
                 AMBIGUO)

norm_sexo <- function(x) dplyr::case_when(x == "Masculino" ~ "M", x == "Feminino" ~ "F",
                                          TRUE ~ NA_character_)
norm_mun  <- function(x) {
  m <- stringr::str_pad(stringr::str_trim(as.character(x)), 6, pad = "0")
  dplyr::if_else(stringr::str_detect(m, "^0+$") | m == "999999", NA_character_, m)
}

# -----------------------------------------------------------------------------
# 2. SIA — registros core dos grupos + tipo por APAC
# -----------------------------------------------------------------------------
sia_all <- readRDS(here::here("data/consolidated/sia_eim_core_limitrofe.rds")) |>
  dplyr::filter(camada == "core", subgrupo %in% c(GRUPOS_A, GRUPOS_B)) |>
  dplyr::transmute(
    grupo = subgrupo, cid4 = substr(cid_capturado, 1, 4), pa_proc_id, pa_autoriz,
    qtd_apr, competencia, uf = uf_pcn,
    sexo_n = norm_sexo(sexo), mun_n = norm_mun(pa_munpcn),
    idade_i = suppressWarnings(as.integer(idade_anos)),
    idade_i = dplyr::if_else(idade_i >= 0 & idade_i <= 110, idade_i, NA_integer_),
    ano_nasc_proxy = as.integer(format(competencia, "%Y")) - idade_i) |>
  dplyr::left_join(dplyr::select(MED_APAC, pa_proc_id, tipo_med = tipo, eixo),
                   by = "pa_proc_id")

sia <- sia_all |>
  dplyr::filter(grupo %in% GRUPOS_A) |>
  dplyr::mutate(rid = dplyr::row_number(),
                tipo_med = dplyr::if_else(eixo %in% "A", tipo_med, NA_character_))

# Tipo por APAC (interseção quando a APAC tem mais de um medicamento)
tipo_apac <- sia |>
  dplyr::filter(!is.na(tipo_med)) |>
  dplyr::group_by(pa_autoriz) |>
  dplyr::summarise(tipo_apac = resolver_tipos(tipo_med), .groups = "drop")
sia <- sia |>
  dplyr::left_join(tipo_apac, by = "pa_autoriz") |>
  dplyr::mutate(tipo_med = dplyr::if_else(!is.na(tipo_med), tipo_apac, NA_character_)) |>
  dplyr::select(-tipo_apac)

# Chaves de paciente com medicamento (nacional: o vínculo não depende do escopo)
chaves_med <- sia |>
  dplyr::filter(!is.na(tipo_med), tipo_med != AMBIGUO, !is.na(sexo_n), !is.na(ano_nasc_proxy)) |>
  dplyr::distinct(tipo = tipo_med, sexo_n, uf, mun_n, ano_nasc_proxy)

#' Vincula unidades (registro SIA ou paciente SIH) às chaves com medicamento, em dois níveis.
#' @param u  tibble com `uid`, `cid4`, `sexo_n`, `uf`, `mun_n` e lista de anos aceitos em `anos`
#' @return  tibble uid → tipo_vinc (tipo resolvido ou AMBIGUO) + nivel ("município"/"UF")
vincular_med <- function(u) {
  u <- u |>
    dplyr::filter(!is.na(sexo_n)) |>
    tidyr::unnest_longer(anos, values_to = "ano_nasc_proxy") |>
    dplyr::filter(!is.na(ano_nasc_proxy))
  casar <- function(uu, por, nivel) {
    uu |>
      dplyr::inner_join(dplyr::distinct(chaves_med, dplyr::across(dplyr::all_of(c(por, "tipo")))),
                        by = por, relationship = "many-to-many") |>
      dplyr::semi_join(CID_TIPOS, by = c("cid4", "tipo")) |>
      dplyr::group_by(uid) |>
      dplyr::summarise(tipo_vinc = resolver_tipos(tipo), .groups = "drop") |>
      dplyr::mutate(nivel = nivel)
  }
  v_mun <- casar(dplyr::filter(u, !is.na(mun_n)),
                 c("sexo_n", "mun_n", "ano_nasc_proxy"), "município")
  v_uf  <- casar(dplyr::filter(u, !is.na(uf), !uid %in% v_mun$uid),
                 c("sexo_n", "uf", "ano_nasc_proxy"), "UF")
  dplyr::bind_rows(v_mun, v_uf)
}

via_de <- function(tipo_med, tipo_vinc, nivel, cid4) dplyr::case_when(
  !is.na(tipo_med)  ~ "APAC com medicamento",
  !is.na(tipo_vinc) ~ paste0("vínculo à APAC (", nivel, ")"),
  cid4 %in% c("E760", "E761") ~ "CID específico",
  TRUE ~ "sem medicamento")

# Registros SIA sem medicamento: proxy próprio ±1 (as duas pontas têm ruído de 1 ano)
vinc_sia <- sia |>
  dplyr::filter(is.na(tipo_med)) |>
  dplyr::transmute(uid = rid, cid4, sexo_n, uf, mun_n,
                   anos = purrr::map(ano_nasc_proxy, ~ .x + (-1:1))) |>
  vincular_med()

sia <- sia |>
  dplyr::left_join(dplyr::rename(vinc_sia, rid = uid), by = "rid") |>
  dplyr::mutate(tipo = dplyr::coalesce(tipo_med, tipo_vinc, rotulo_sem_med(cid4)),
                via  = via_de(tipo_med, tipo_vinc, nivel, cid4))

#' Pacientes/mês: APAC distintas por competência → mediana de ANO_REF, do 4º tri e máximo
pacientes_mes <- function(df, col = "tipo") {
  df |>
    dplyr::group_by(.data[[col]], competencia) |>
    dplyr::summarise(apac_mes = dplyr::n_distinct(pa_autoriz), .groups = "drop") |>
    dplyr::mutate(ano_c = as.integer(format(competencia, "%Y")),
                  mes_c = as.integer(format(competencia, "%m"))) |>
    dplyr::group_by(.data[[col]]) |>
    dplyr::summarise(
      pac_mes_ref  = stats::median(apac_mes[ano_c == ANO_REF]),
      pac_mes_4tri = stats::median(apac_mes[ano_c == ANO_REF & mes_c >= 10]),
      pac_mes_max  = max(apac_mes), .groups = "drop") |>
    dplyr::mutate(dplyr::across(c(pac_mes_ref, pac_mes_4tri), ~ dplyr::coalesce(.x, 0)))
}

resumir_sia <- function(df, escopo) {
  df |>
    dplyr::group_by(grupo, tipo, via) |>
    dplyr::summarise(registros = dplyr::n(),
                     apac      = dplyr::n_distinct(pa_autoriz),
                     unidades  = sum(qtd_apr[via == "APAC com medicamento"], na.rm = TRUE),
                     .groups = "drop") |>
    dplyr::left_join(df |> dplyr::filter(via == "APAC com medicamento") |> pacientes_mes() |>
                       dplyr::mutate(via = "APAC com medicamento"),
                     by = c("tipo", "via")) |>
    dplyr::mutate(escopo = escopo, .before = 1)
}

res_sia <- dplyr::bind_rows(resumir_sia(sia, "Brasil"),
                            resumir_sia(dplyr::filter(sia, uf == "PE"), "PE"))

# -----------------------------------------------------------------------------
# 3. B — estratos por medicamento (pacientes/mês; denominador = APAC com qualquer 06.04)
# -----------------------------------------------------------------------------
estratos <- function(df, escopo) {
  b <- df |> dplyr::filter(grupo %in% GRUPOS_B)
  num <- b |>
    dplyr::filter(eixo %in% "B") |>
    dplyr::mutate(estrato = tipo_med) |>
    dplyr::group_by(grupo) |>
    dplyr::group_modify(~ pacientes_mes(.x, "estrato")) |>
    dplyr::ungroup()
  den <- b |>
    dplyr::filter(grupo %in% GRUPOS_B_DENOM, substr(pa_proc_id, 1, 4) == "0604") |>
    dplyr::mutate(estrato = "Total do grupo no CEAF") |>
    dplyr::group_by(grupo) |>
    dplyr::group_modify(~ pacientes_mes(.x, "estrato")) |>
    dplyr::ungroup()
  dplyr::bind_rows(den, num) |>
    dplyr::group_by(grupo) |>
    dplyr::mutate(
      pct_4tri = dplyr::if_else(estrato != "Total do grupo no CEAF" & any(estrato == "Total do grupo no CEAF"),
                                100 * pac_mes_4tri / pac_mes_4tri[estrato == "Total do grupo no CEAF"][1],
                                NA_real_)) |>
    dplyr::ungroup() |>
    dplyr::mutate(escopo = escopo, .before = 1)
}
res_estr <- dplyr::bind_rows(estratos(sia_all, "Brasil"),
                             estratos(dplyr::filter(sia_all, uf == "PE"), "PE"))

# Pacientes/mês por UF (A e B; taxa por milhão, população de ANO_REF)
pop_uf <- carregar_pop() |>
  dplyr::filter(ano == ANO_REF) |>
  dplyr::group_by(uf) |>
  dplyr::summarise(pop = sum(pop), .groups = "drop")
med_uf <- dplyr::bind_rows(
  dplyr::filter(sia, !is.na(tipo_med), tipo_med != AMBIGUO) |> dplyr::mutate(tipo = tipo_med),
  dplyr::filter(sia_all, eixo %in% "B") |> dplyr::mutate(tipo = tipo_med)) |>
  dplyr::filter(!is.na(uf))
res_uf <- med_uf |>
  dplyr::group_split(uf) |>
  purrr::map_dfr(~ pacientes_mes(.x) |> dplyr::mutate(uf = .x$uf[1], .before = 1)) |>
  dplyr::left_join(pop_uf, by = "uf") |>
  dplyr::mutate(por_milhao = 1e6 * pac_mes_ref / pop, por_milhao_4tri = 1e6 * pac_mes_4tri / pop) |>
  dplyr::select(uf, tipo, pac_mes_ref, pac_mes_4tri, pac_mes_max, pop, por_milhao, por_milhao_4tri)

# -----------------------------------------------------------------------------
# 4. SIH — paciente (NASC × sexo × MUNIC_RES) vinculado às APAC com medicamento
# -----------------------------------------------------------------------------
sih <- readRDS(here::here("data/consolidated/sih_eim_nacional.rds")) |>
  dplyr::filter(eim_principal, subgrupo %in% GRUPOS_A) |>
  dplyr::transmute(grupo = subgrupo, cid4 = substr(diag_princ, 1, 4), n_aih, uf = uf_res,
                   dias_perm = suppressWarnings(as.numeric(dias_perm)),
                   sexo_n = norm_sexo(sexo), mun_n = norm_mun(munic_res),
                   ano_nasc = suppressWarnings(as.integer(substr(as.character(nasc), 1, 4))),
                   pid = paste(nasc, sexo_n, mun_n, cid4, sep = "|"))

vinc_sih <- sih |>
  dplyr::distinct(uid = pid, cid4, sexo_n, uf, mun_n, ano_nasc) |>
  dplyr::mutate(anos = purrr::map(ano_nasc, ~ .x + 0:1)) |>
  vincular_med()

sih <- sih |>
  dplyr::left_join(dplyr::rename(vinc_sih, pid = uid), by = "pid") |>
  dplyr::mutate(tipo = dplyr::coalesce(tipo_vinc, rotulo_sem_med(cid4)),
                via  = via_de(NA_character_, tipo_vinc, nivel, cid4))

resumir_sih <- function(df, escopo) {
  df |>
    dplyr::group_by(grupo, tipo, via) |>
    dplyr::summarise(aih = dplyr::n_distinct(n_aih), pacientes = dplyr::n_distinct(pid),
                     perm_mediana = stats::median(dias_perm, na.rm = TRUE),
                     .groups = "drop") |>
    dplyr::mutate(escopo = escopo, .before = 1)
}
res_sih <- dplyr::bind_rows(resumir_sih(sih, "Brasil"),
                            resumir_sih(dplyr::filter(sih, uf == "PE"), "PE"))

# QC: quanto do SIH foi vinculado, por escopo × CID × nível
qc <- dplyr::bind_rows(dplyr::mutate(sih, escopo = "Brasil"),
                       dplyr::filter(sih, uf == "PE") |> dplyr::mutate(escopo = "PE")) |>
  dplyr::filter(cid4 %in% CID_TIPOS$cid4) |>
  dplyr::mutate(status = dplyr::case_when(is.na(tipo_vinc) ~ "sem vínculo",
                                          tipo_vinc == AMBIGUO ~ "ambíguo",
                                          TRUE ~ paste0("vinculado (", nivel, ")"))) |>
  dplyr::group_by(escopo, cid4, status) |>
  dplyr::summarise(pacientes = dplyr::n_distinct(pid), aih = dplyr::n_distinct(n_aih),
                   # perfil do paciente (1 linha por pid): ajuda a ler quem fica sem vínculo
                   pct_fem = 100 * mean(sexo_n[!duplicated(pid)] == "F", na.rm = TRUE),
                   idade_mediana = stats::median(ANO_REF - ano_nasc[!duplicated(pid)], na.rm = TRUE),
                   # mesmo perfil ponderado por AIH (quem concentra o volume)
                   pct_fem_aih = 100 * mean(sexo_n[!duplicated(n_aih)] == "F", na.rm = TRUE),
                   idade_mediana_aih = stats::median(ANO_REF - ano_nasc[!duplicated(n_aih)], na.rm = TRUE),
                   .groups = "drop") |>
  dplyr::group_by(escopo, cid4) |>
  dplyr::mutate(pct_aih = round(100 * aih / sum(aih), 1)) |>
  dplyr::ungroup() |>
  dplyr::mutate(dplyr::across(c(pct_fem, idade_mediana, pct_fem_aih, idade_mediana_aih),
                              ~ dplyr::if_else(pacientes < N_SUPRESSAO, NA_real_, .x)))

# -----------------------------------------------------------------------------
# 5. Supressão N<5 e escrita
# -----------------------------------------------------------------------------
sup <- function(df, cols) df |>
  dplyr::mutate(dplyr::across(dplyr::any_of(cols),
                              ~ dplyr::if_else(.x < N_SUPRESSAO, NA_real_, as.numeric(.x))))
ordenar <- function(df) df |>
  dplyr::mutate(tipo = factor(tipo, levels = ORDEM_TIPOS)) |>
  dplyr::arrange(escopo, grupo, tipo, via) |>
  dplyr::mutate(tipo = as.character(tipo))
COLS_PAC <- c("pac_mes_ref", "pac_mes_4tri", "pac_mes_max")

res_sia  <- res_sia |> ordenar() |> sup(c("registros", "apac", "unidades", COLS_PAC))
res_sih  <- res_sih |> ordenar() |> sup(c("aih", "pacientes"))
res_estr <- res_estr |>
  dplyr::mutate(pct_4tri = dplyr::if_else(pac_mes_4tri < N_SUPRESSAO, NA_real_, pct_4tri)) |>
  sup(COLS_PAC)
res_uf   <- res_uf |>
  dplyr::mutate(por_milhao      = dplyr::if_else(pac_mes_ref  < N_SUPRESSAO, NA_real_, por_milhao),
                por_milhao_4tri = dplyr::if_else(pac_mes_4tri < N_SUPRESSAO, NA_real_, por_milhao_4tri)) |>
  sup(COLS_PAC)
qc       <- qc |> sup(c("pacientes", "aih"))

readr::write_csv(res_sia,  here::here("manifest", "med_apac_sia.csv"))
readr::write_csv(res_sih,  here::here("manifest", "med_apac_sih.csv"))
readr::write_csv(res_uf,   here::here("manifest", "med_apac_uf.csv"))
readr::write_csv(res_estr, here::here("manifest", "med_apac_estratos.csv"))
readr::write_csv(qc,       here::here("manifest", "med_apac_vinculo.csv"))

cat("\n== A · SIA ==\n");          print(as.data.frame(res_sia))
cat("\n== A · SIH ==\n");          print(as.data.frame(res_sih))
cat("\n== B · estratos ==\n");     print(as.data.frame(res_estr))
cat("\n== Vínculo SIH→APAC ==\n"); print(as.data.frame(qc))
message("\n✓ Separação por medicamento (APAC) → manifest/med_apac_{sia,sih,uf,estratos,vinculo}.csv")
