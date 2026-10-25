# =============================================================================
# listas_prioridade.R — Listas de prioridade para testes genéticos (PE), série 2010+
#   1. ranking_doencas_alvo_testes_geneticos_PE.tsv  — EIM
#   2. lista_nefropatias_hereditarias_PE.tsv         — EIM renais + tubulopatias/nefropatias
#   3. lista_hemoglobinopatias_sangue_PE.tsv          — hemoglobinopatias, enzimo/membranopatias,
#                                                       coagulopatias e correlatos
# Números: data/consolidated/listas_base_numeros.rds (scripts/listas_base_numeros.R) +
#   manifest/med_apac_{sia,estratos}.csv + manifest/sia_pseudo_pacientes_PE.csv.
#   SIA = registros com o CID PRINCIPAL (2010–2025); SIH = AIH distintas com o diagnóstico
#   principal (2010–2025); SIM = óbitos por causa básica (definitivos 2010–2024);
#   razão PE/BR = (casos PE / pop PE) ÷ (casos BR / pop BR), população 2010–2025 somada;
#   pacientes/mês = mediana mensal de APAC distintas do medicamento em 2024;
#   testes = exames individualizados (BPA-I/APAC) de residentes, 2010–2025.
# Contagens < 5 viram "<5" (LGPD). Saída: ../misc/ (fora do repositório), ou EIM_DIR_LISTAS.
# No Mac, as listas publicadas ficam em projetos/PROFIX_FACEPE/misc/ (o projeto mudou de pasta).
# Critérios de prioridade: misc/listas_prioridade_LEIAME.md
# =============================================================================

source(here::here("scripts", "00_setup.R"))
source(here::here("scripts", "calcular_taxas.R"))
b <- lapply(readRDS(here::here("data/consolidated/listas_base_numeros.rds")), dplyr::ungroup)
pop <- carregar_pop() |> dplyr::filter(ano %in% ANOS)
POP_PE <- sum(pop$pop[pop$uf == "PE"]); POP_BR <- sum(pop$pop)
POP24  <- carregar_pop() |> dplyr::filter(ano == 2024L)
POP24_PE <- sum(POP24$pop[POP24$uf == "PE"]); POP24_BR <- sum(POP24$pop)

MOLEC <- c("0202100065", "0202100073", "0202100081", "0202100090", "0202100103", "0202100111",
           "0202100200", "0202100235", "0202110028", "0202110036", "0202110125", "0202110133")
BIOQ  <- c("0202100057", "0202100120", "0202100138", "0202100146", "0202100154", "0202100162",
           "0202100170", "0202100189", "0202100197")

casa <- function(cid4, cids) {          # cids = prefixos de 3 ou 4 caracteres
  cids <- gsub("\\.", "", cids); out <- rep(FALSE, length(cid4))
  for (p in cids) out <- out | startsWith(cid4, p)
  out & !is.na(cid4)
}
soma <- function(d, cids, col = "n", uf = NULL) {
  h <- casa(d$cid4, cids); if (!is.null(uf)) h <- h & d$uf %in% uf
  sum(d[[col]][h], na.rm = TRUE)
}
fmt <- function(x) ifelse(is.na(x), "", ifelse(x > 0 & x < N_SUPRESSAO, "<5", format(round(x), big.mark = ".", decimal.mark = ",", trim = TRUE)))
fmt1 <- function(x) ifelse(is.na(x) | !is.finite(x), "", formatC(x, format = "f", digits = 1, decimal.mark = ","))
razao <- function(pe, br, ppe = POP_PE, pbr = POP_BR) ifelse(is.na(pe) | pe < N_SUPRESSAO | br == 0, NA, (pe / ppe) / (br / pbr))

# pacientes/mês por medicamento marcador (2024), PE e BR
pac_marc <- function(m) {
  x <- b$med_mes |> dplyr::filter(marcador == m, substr(PA_CMP, 1, 4) == "2024") |>
    dplyr::group_by(PA_CMP) |> dplyr::summarise(BR = sum(apac), PE = sum(apac[uf %in% "PE"]), .groups = "drop")
  c(pe = stats::median(x$PE), br = stats::median(x$BR))
}
med_sia  <- readr::read_csv(here::here("manifest/med_apac_sia.csv"), show_col_types = FALSE)
med_estr <- readr::read_csv(here::here("manifest/med_apac_estratos.csv"), show_col_types = FALSE)
pac_tipo <- function(tipos) {           # eixo A (separação por APAC)
  x <- med_sia |> dplyr::filter(via == "APAC com medicamento", tipo %in% tipos)
  c(pe = sum(x$pac_mes_ref[x$escopo == "PE"], na.rm = TRUE), br = sum(x$pac_mes_ref[x$escopo == "Brasil"], na.rm = TRUE))
}
pac_estr <- function(e) {               # eixo B (estratos), 4º tri 2024
  x <- med_estr |> dplyr::filter(estrato %in% e)
  c(pe = sum(x$pac_mes_4tri[x$escopo == "PE"], na.rm = TRUE), br = sum(x$pac_mes_4tri[x$escopo == "Brasil"], na.rm = TRUE))
}
ps <- readr::read_csv(here::here("manifest/sia_pseudo_pacientes_PE.csv"), show_col_types = FALSE)
pseudo <- function(sg) { x <- ps[ps$subgrupo %in% sg, ]; if (!nrow(x)) "" else
  paste0(fmt(sum(x$pseudo_frouxa, na.rm = TRUE)), "–", fmt(sum(x$pseudo_estrita, na.rm = TRUE))) }

#' Uma linha: números a partir dos CIDs + medicamento (opcional) + campos clínicos
linha <- function(rank, doenca, cids, ..., pac = NULL, subgrupos = NULL, renal = FALSE, contar = TRUE) {
  # contar = FALSE: o CID é dominado por outra condição (ex.: E83.3 = DRC) → só medicamento
  sia_pe <- soma(b$sia_cid, cids, uf = "PE"); sia_br <- soma(b$sia_cid, cids)
  sih_pe <- soma(b$sih_cid, cids, uf = "PE"); sih_br <- soma(b$sih_cid, cids)
  sim_pe <- soma(b$sim_cid, cids, uf = "PE"); sim_br <- soma(b$sim_cid, cids)
  if (!contar) sia_pe <- sia_br <- sih_pe <- sih_br <- sim_pe <- sim_br <- NA
  gen_m  <- b$gen[b$gen$PA_PROC_ID %in% MOLEC, ]; gen_b <- b$gen[b$gen$PA_PROC_ID %in% BIOQ, ]
  out <- tibble::tibble(
    rank, doenca, cid10 = paste(cids, collapse = "; "),
    SIA_registros_PE = fmt(sia_pe), SIA_registros_BR = fmt(sia_br),
    razao_PE_BR_SIA = fmt1(razao(sia_pe, sia_br)),
    SIH_AIH_PE = fmt(sih_pe), SIH_AIH_BR = fmt(sih_br),
    razao_PE_BR_SIH = fmt1(razao(sih_pe, sih_br)),
    SIM_obitos_PE = fmt(sim_pe), SIM_obitos_BR = fmt(sim_br),
    pacientes_mes_2024_PE = if (is.null(pac)) "" else fmt(pac[["pe"]]),
    razao_PE_BR_pacientes = if (is.null(pac)) "" else fmt1(razao(pac[["pe"]], pac[["br"]], POP24_PE, POP24_BR)),
    pseudo_pacientes_PE = if (is.null(subgrupos)) "" else pseudo(subgrupos),
    testes_moleculares_resid_PE = fmt(soma(gen_m, cids, "exames", "PE")),
    testes_moleculares_BR = fmt(soma(gen_m, cids, "exames")),
    testes_bioq_EIM_resid_PE = fmt(soma(gen_b, cids, "exames", "PE")))
  if (renal) {
    d <- b$sim_cid[casa(b$sim_cid$cid4, cids), ]
    out$pct_obitos_DRC_IRA_BR <- if (sum(d$n) >= N_SUPRESSAO) fmt1(100 * sum(d$renal) / sum(d$n)) else ""
  }
  dplyr::bind_cols(out, tibble::as_tibble(list(...)))
}
OUT <- Sys.getenv("EIM_DIR_LISTAS", here::here("..", "misc"))
grava <- function(d, nome) { readr::write_tsv(d, file.path(OUT, nome), na = ""); message("✓ ", nome, " (", nrow(d), " linhas)") }

# =============================================================================
# 1. EIM
# =============================================================================
eim <- dplyr::bind_rows(
  linha(1, "MPS VI (Maroteaux-Lamy) e MPS IVA (Morquio A)", c("E76.2"), pac = pac_tipo(c("MPS VI", "MPS IVA")), subgrupos = "mucopolissacaridose",
    genes = "ARSB; GALNS", papel_teste_genetico = "confirmação; aconselhamento; cascata familiar e de portadores",
    obrigatoriedade = "recomendado (enzima é padrão-ouro)",
    acao_que_depende_do_genotipo = "painel dirigido às variantes fundadoras; triagem neonatal lisossômica (Lei 14.154/2021, etapa 3)",
    justificativa = "maior excesso de PE entre as doenças com TRE (MPS VI e IVA muito acima da taxa nacional); diagnóstico precoce melhora a resposta à TRE",
    ressalvas = "SIA/SIH/SIM = E76.2 inteiro (inclui MPS III e VII); pacientes/mês = VI + IVA em TRE no CEAF; efeito fundador é hipótese"),
  linha(2, "Fibrose cística", c("E84"), pac = pac_estr(c("ETI — ≥1 F508del", "Ivacaftor — variante de gating")), subgrupos = "fibrose_cistica",
    genes = "CFTR", papel_teste_genetico = "elegibilidade a moduladores; diagnóstico com suor limítrofe",
    obrigatoriedade = "necessário para tratamento (diagnóstico = cloreto no suor)",
    acao_que_depende_do_genotipo = "ETI (≥1 F508del, Portaria SECTICS/MS 47/2023); ivacaftor isolado (gating)",
    justificativa = "maior carga do SIA; excesso de ivacaftor isolado em PE sugere variantes de gating — sinal genético",
    ressalvas = "pacientes/mês = em modulador (ETI + ivacaftor), não o total de FC; testes moleculares incluem o confirmatório 02.02.11.003-6"),
  linha(4, "Amiloidose hereditária por transtirretina (ATTRv/PAF-TTR)", c("E85.1"), pac = pac_estr("Tafamidis — ATTRv em tratamento"), subgrupos = "amiloidose_familiar",
    genes = "TTR", papel_teste_genetico = "diagnóstico (distingue ATTRv de selvagem e AL); elegibilidade ao tafamidis; cascata pré-sintomática",
    obrigatoriedade = "obrigatório", acao_que_depende_do_genotipo = "tafamidis; seguimento de portadores adultos",
    justificativa = "o teste define o diagnóstico; início adulto permite detecção pré-sintomática em familiares",
    ressalvas = "pacientes/mês = em tafamidis"),
  linha(5, "Esfingolipidoses E75.2 (Gaucher, Fabry, Niemann-Pick C)", c("E75.2"), pac = pac_tipo(c("Gaucher", "Fabry", "Gaucher tipo 1 ou NP-C")), subgrupos = "esfingolipidose_outras",
    genes = "GBA1; GLA; NPC1; NPC2; SMPD1", papel_teste_genetico = "Fabry em mulheres e p/ migalastate; confirmação de NP-C; prognóstico em Gaucher",
    obrigatoriedade = "obrigatório em NP-C e Fabry feminina; recomendado em Gaucher",
    acao_que_depende_do_genotipo = "migalastate (variante amenable); cascata familiar em Fabry (ligada ao X)",
    justificativa = "2ª causa de AIH-EIM em PE (quase toda Gaucher); AIH sem medicamento em mulheres adultas sugerem Fabry fora do CEAF",
    ressalvas = "CID não separa as doenças; TRE de Fabry no CEAF só desde 2025-03; GBA1 tem pseudogene"),
  linha(6, "Glicogenoses (Pompe e não-Pompe)", c("E74.0"), pac = pac_tipo("Pompe (GSD II)"), subgrupos = "glicogenose",
    genes = "GAA; G6PC1; SLC37A4; AGL; GBE1; PYGL; PYGM; PHKA2", papel_teste_genetico = "diagnóstico (painel substitui biópsia nas não-Pompe); confirmação em Pompe",
    obrigatoriedade = "na prática obrigatório nas não-Pompe; recomendado em Pompe",
    acao_que_depende_do_genotipo = "TRE (Pompe); manejo dietético por tipo",
    justificativa = "não-Pompe invisíveis no dado (sem medicamento que as identifique)", ressalvas = "Pompe <5 pacientes/mês em PE"),
  linha(8, "MPS I e MPS II", c("E76.0", "E76.1"), pac = pac_tipo(c("MPS I", "MPS II")),
    genes = "IDUA; IDS", papel_teste_genetico = "confirmação; portadoras (MPS II, ligada ao X); aconselhamento", obrigatoriedade = "recomendado",
    acao_que_depende_do_genotipo = "TRE; TCTH em MPS I grave (decisão depende do genótipo)",
    justificativa = "aconselhamento de mães e irmãs em MPS II", ressalvas = "pseudo-pacientes estão na linha 1 (subgrupo MPS inteiro)"),
  linha(7, "Distúrbios do ciclo da ureia e acidúrias orgânicas", c("E72.2", "E71.1"), subgrupos = c("ciclo_ureia", "acuduria_organica"),
    genes = "OTC; CPS1; ASS1; ASL; ARG1; NAGS; MMUT; PCCA; PCCB", papel_teste_genetico = "confirmação; diagnóstico pré-natal; transplante hepático",
    obrigatoriedade = "recomendado (bioquímica de urgência primeiro)",
    acao_que_depende_do_genotipo = "aconselhamento (OTC ligada ao X); indicação de transplante",
    justificativa = "letais precoces: alta proporção de óbito entre os casos; IRA terminal na descompensação",
    ressalvas = "E71.1 inclui outras acidúrias de cadeia ramificada"),
  linha(3, "Lipofuscinose ceroide neuronal (CLN)", c("E75.4"), subgrupos = "lipofuscinose_NCL",
    genes = "TPP1/CLN2; CLN3; CLN5; CLN6; MFSD8; CLN8", papel_teste_genetico = "diagnóstico (só CLN2 tem enzima)",
    obrigatoriedade = "na prática obrigatório", acao_que_depende_do_genotipo = "cerliponase alfa (CLN2)",
    justificativa = "excesso marcado em PE (razão PE/BR no SIA) + teste obrigatório + terapia específica em CLN2 — possível agrupamento regional a investigar", ressalvas = "N pequeno: poucos pacientes, razão instável"),
  linha(9, "Distúrbios do piruvato e beta-oxidação (FAOD)", c("E74.4", "E71.3"), subgrupos = c("metab_piruvato", "faod"),
    genes = "PDHA1; PDHB; PC; ACADM; ACADVL; HADHA; CPT2", papel_teste_genetico = "diagnóstico confirmatório",
    obrigatoriedade = "na prática obrigatório (piruvato); recomendado (FAOD)",
    acao_que_depende_do_genotipo = "dieta cetogênica (PDH); manejo dietético (FAOD)",
    justificativa = "enzima raramente disponível (piruvato); acilcarnitinas pedem confirmação (FAOD)", ressalvas = "N pequeno"),
  linha(10, "Fenilcetonúria / hiperfenilalaninemias", c("E70.0", "E70.1"), pac = pac_estr("Sapropterina — responsiva a BH4"), subgrupos = "aminoacidopatia_PKU",
    genes = "PAH; PTS; QDPR; GCH1", papel_teste_genetico = "prognóstico de resposta a BH4; excluir deficiência de BH4", obrigatoriedade = "opcional",
    acao_que_depende_do_genotipo = "sapropterina", justificativa = "sapropterina proporcionalmente mais usada em PE que no Brasil — genótipo ou prática",
    ressalvas = "diagnóstico bioquímico (pezinho); pacientes/mês = em sapropterina"),
  linha(11, "Hiperplasia adrenal congênita", c("E25.0"), pac = pac_estr("Fludrocortisona — perdedora de sal provável"), subgrupos = "hiperplasia_adrenal_cong",
    genes = "CYP21A2", papel_teste_genetico = "forma não clássica; aconselhamento", obrigatoriedade = "opcional",
    acao_que_depende_do_genotipo = "aconselhamento; diagnóstico pré-natal", justificativa = "diagnóstico por 17-OHP; existe confirmatório molecular no SUS (02.02.11.012-5)",
    ressalvas = "pacientes/mês = em fludrocortisona"),
  linha(12, "Doença de Wilson", c("E83.0"), pac = pac_tipo("Wilson"), subgrupos = "metab_cobre",
    genes = "ATP7B", papel_teste_genetico = "casos duvidosos no escore de Leipzig; rastreio de irmãos", obrigatoriedade = "opcional",
    acao_que_depende_do_genotipo = "rastreio de irmãos pré-sintomáticos", justificativa = "diagnóstico bioquímico na maioria", ressalvas = "pacientes/mês = penicilamina ou trientina"),
  linha(13, "Outros EIM de diagnóstico bioquímico (HC, tirosinemia, MSUD, galactosemia)", c("E03.1", "E70.2", "E71.0", "E74.2"),
    subgrupos = c("hipotireoidismo_congenito", "aminoacidopatia_tirosina", "aminoacidopatia_MSUD", "galactosemia"),
    genes = "TSHR/TPO/DUOX2…; FAH; BCKDHA/BCKDHB/DBT; GALT", papel_teste_genetico = "aconselhamento", obrigatoriedade = "opcional",
    acao_que_depende_do_genotipo = "", justificativa = "diagnóstico bioquímico (TSH/T4, succinilacetona, aloisoleucina, GALT)", ressalvas = "")
)

# =============================================================================
# 2. Nefropatias hereditárias (EIM renais + tubulopatias + nefropatias não-EIM)
# =============================================================================
nefro <- dplyr::bind_rows(
  linha(4, "Doença renal policística autossômica dominante e recessiva", c("Q61.2", "Q61.3"), renal = TRUE,
    nivel = "nefropatia hereditária não-EIM", genes = "PKD1; PKD2; PKHD1; GANAB; DNAJB11", heranca = "AD/AR",
    acometimento_renal = "cistos renais progressivos, DRC terminal na vida adulta (AD) ou infância (AR)",
    papel_teste_genetico = "diagnóstico em jovens/atípicos e de doador vivo aparentado; prognóstico (PKD1 truncante)", obrigatoriedade = "recomendado",
    marcador_SUS = "nenhum (tolvaptano sem código SIGTAP)", justificativa = "maior carga entre as nefropatias hereditárias, com mortalidade relevante; decisão de doador vivo depende do genótipo",
    ressalvas = "Q61.3 = rim policístico NE (inclui formas não genotipadas)"),
  linha(1, "Hiperoxalúria primária (tipos 1–3)", c("E74.8"), renal = TRUE,
    nivel = "EIM renal predominante", genes = "AGXT; GRHPR; HOGA1", heranca = "AR",
    acometimento_renal = "nefrocalcinose, litíase de oxalato, oxalose sistêmica, DRC terminal",
    papel_teste_genetico = "diagnóstico; define tipo e estratégia de transplante (rim ou fígado-rim) e elegibilidade a lumasirana", obrigatoriedade = "obrigatório",
    marcador_SUS = "dosagem de oxalato (02.02.05.010-6)", justificativa = "o genótipo decide o transplante; recorrência no enxerto se não diagnosticada; excesso em PE",
    ressalvas = "E74.8 compartilhado com glicosúria renal e pentosúria"),
  linha(2, "Cistinose nefropática", c("E72.0"), renal = TRUE,
    nivel = "EIM renal predominante", genes = "CTNS", heranca = "AR",
    acometimento_renal = "Fanconi proximal no 1º ano; DRC terminal ~10 anos sem cisteamina",
    papel_teste_genetico = "confirmação (dosagem de cistina leucocitária pouco disponível)", obrigatoriedade = "na prática obrigatório",
    marcador_SUS = "nenhum (cisteamina sem código SIGTAP)", justificativa = "tratamento precoce adia a DRC terminal; excesso em PE (E72.0)",
    ressalvas = "E72.0 compartilhado com cistinúria, Hartnup, Lowe e Fanconi"),
  linha(5, "Síndrome de Alport e nefropatia túbulo-intersticial AD (ADTKD)", c("N07"), renal = TRUE,
    nivel = "nefropatia hereditária não-EIM", genes = "COL4A3; COL4A4; COL4A5; UMOD; MUC1; REN; HNF1B", heranca = "XL/AR/AD",
    acometimento_renal = "hematúria, proteinúria, DRC; surdez e alterações oculares (Alport)",
    papel_teste_genetico = "diagnóstico sem biópsia; prognóstico; seleção de doador aparentado", obrigatoriedade = "recomendado",
    marcador_SUS = "nenhum", justificativa = "IECA precoce retarda a DRC; cascata familiar (Alport ligado ao X)",
    ressalvas = "N07.9 (NE) domina o código"),
  linha(8, "Doença de Fabry (nefropatia)", c("E75.2"), contar = FALSE, renal = FALSE, pac = pac_tipo("Fabry"),
    nivel = "EIM renal predominante", genes = "GLA", heranca = "XL",
    acometimento_renal = "proteinúria, DRC (principal causa de morte com a cardiopatia)",
    papel_teste_genetico = "obrigatório em mulheres; migalastate", obrigatoriedade = "obrigatório em mulheres",
    marcador_SUS = "TRE de Fabry (06.04.24.012-0, desde 2025-03)", justificativa = "terapia disponível; cascata familiar ligada ao X",
    ressalvas = "contagens por CID omitidas (E75.2 é quase todo Gaucher); pacientes/mês = TRE de Fabry em 2024 (ainda ~0)"),
  linha(7, "Raquitismo hipofosfatêmico ligado ao X (XLH)", c("E83.3"), contar = FALSE, pac = pac_marc("burosumabe"),
    nivel = "EIM renal predominante", genes = "PHEX; FGF23; DMP1; ENPP1; SLC34A3", heranca = "XL; AD/AR",
    acometimento_renal = "perda renal de fosfato; nefrocalcinose sob tratamento convencional",
    papel_teste_genetico = "diagnóstico diferencial das hipofosfatemias; elegibilidade ao burosumabe", obrigatoriedade = "recomendado",
    marcador_SUS = "burosumabe (06.04.87.001-9/002-7/003-5)", justificativa = "terapia de alto custo no SUS; genótipo separa XLH de outras causas",
    ressalvas = "contagens por CID omitidas: E83.3 é 99% distúrbio mineral ósseo da DRC; pacientes/mês = burosumabe"),
  linha(3, "Amiloidose hereditária renal (fibrinogênio Aα, ApoA-I, ApoA-II, lisozima)", c("E85.0"), renal = TRUE,
    nivel = "EIM renal predominante", genes = "FGA; APOA1; APOA2; LYZ", heranca = "AD",
    acometimento_renal = "síndrome nefrótica, DRC", papel_teste_genetico = "tipagem (distingue de AL e AA)", obrigatoriedade = "obrigatório",
    marcador_SUS = "nenhum", justificativa = "excesso em PE; alta proporção de óbitos com DRC/IRA; tratamento da AL é oposto",
    ressalvas = ""),
  linha(6, "Tubulopatias hereditárias (Bartter, Gitelman, ATR, Dent, DI nefrogênico, PHA1)", c("E26.8", "N25.8", "N25.1"), renal = TRUE,
    nivel = "tubulopatia hereditária", genes = "SLC12A1; KCNJ1; CLCNKB; BSND; SLC12A3; SLC4A1; ATP6V1B1; ATP6V0A4; CLCN5; OCRL; AVPR2; AQP2; NR3C2; SCNN1A/B/G",
    heranca = "AR/AD/XL", acometimento_renal = "distúrbios de sal, potássio, ácido-base e água; nefrocalcinose",
    papel_teste_genetico = "diagnóstico definitivo (fenótipos se sobrepõem)", obrigatoriedade = "na prática obrigatório",
    marcador_SUS = "nenhum", justificativa = "painel resolve o diagnóstico diferencial; tratamento por mecanismo",
    ressalvas = "N25.8 inclui formas adquiridas (fármacos, autoimunes)"),
  linha(10, "Hipomagnesemia familiar com hipercalciúria e nefrocalcinose", c("E83.4"), renal = TRUE,
    nivel = "EIM renal predominante", genes = "CLDN16; CLDN19", heranca = "AR",
    acometimento_renal = "nefrocalcinose, DRC progressiva", papel_teste_genetico = "diagnóstico", obrigatoriedade = "na prática obrigatório",
    marcador_SUS = "nenhum", justificativa = "progride para DRC na infância/adolescência",
    ressalvas = "E83.4 inclui hipomagnesemia adquirida (fármacos, perdas GI)"),
  linha(11, "Deficiência de APRT, xantinúria e hipouricemia renal", c("E79.8"), renal = TRUE,
    nivel = "EIM renal predominante", genes = "APRT; XDH; MOCOS; SLC22A12; SLC2A9", heranca = "AR",
    acometimento_renal = "litíase radiotransparente, nefropatia cristalina, IRA por exercício",
    papel_teste_genetico = "diagnóstico", obrigatoriedade = "na prática obrigatório", marcador_SUS = "nenhum",
    justificativa = "deficiência de APRT é tratável com alopurinol; DRC evitável", ressalvas = "E79.8 compartilhado"),
  linha(9, "Nefronoftise e ciliopatias renais", c("Q61.5"), renal = TRUE,
    nivel = "nefropatia hereditária não-EIM", genes = "NPHP1…NPHP20; CEP290; IFT140", heranca = "AR",
    acometimento_renal = "DRC terminal na infância/adolescência", papel_teste_genetico = "diagnóstico (biópsia inespecífica)",
    obrigatoriedade = "na prática obrigatório", marcador_SUS = "nenhum", justificativa = "causa genética mais comum de DRC terminal pediátrica",
    ressalvas = ""),
  linha(12, "Hipercalcemia infantil idiopática", c("E83.5"), renal = TRUE,
    nivel = "EIM renal predominante", genes = "CYP24A1; SLC34A1", heranca = "AR",
    acometimento_renal = "nefrocalcinose, litíase", papel_teste_genetico = "diagnóstico", obrigatoriedade = "recomendado", marcador_SUS = "nenhum",
    justificativa = "evitar vitamina D; nefrocalcinose", ressalvas = "contagens de E83.5 dominadas por hipercalcemia SECUNDÁRIA (neoplasia, DRC)"),
  linha(13, "Acidemia metilmalônica (nefropatia)", c("E71.1"), renal = TRUE,
    nivel = "EIM renal relevante", genes = "MMUT; MMAA; MMAB; MMACHC", heranca = "AR",
    acometimento_renal = "DRC tubulointersticial; transplante renal/hepatorrenal", papel_teste_genetico = "confirmação; prognóstico (responsivo a B12)",
    obrigatoriedade = "recomendado", marcador_SUS = "nenhum", justificativa = "DRC é complicação tardia frequente", ressalvas = "E71.1 inclui outras acidúrias"),
  linha(14, "Glicogenose tipo I e Fanconi-Bickel", c("E74.0"), renal = TRUE,
    nivel = "EIM renal relevante", genes = "G6PC1; SLC37A4; SLC2A2", heranca = "AR",
    acometimento_renal = "nefromegalia, hiperfiltração, DRC; Fanconi (Fanconi-Bickel)", papel_teste_genetico = "diagnóstico",
    obrigatoriedade = "na prática obrigatório", marcador_SUS = "nenhum", justificativa = "", ressalvas = "E74.0 inclui Pompe e demais glicogenoses"),
  linha(15, "Tirosinemia tipo 1 (tubulopatia)", c("E70.2"), renal = TRUE,
    nivel = "EIM renal relevante", genes = "FAH", heranca = "AR", acometimento_renal = "Fanconi proximal, nefrocalcinose",
    papel_teste_genetico = "aconselhamento", obrigatoriedade = "opcional", marcador_SUS = "nenhum (nitisinona sem código SIGTAP)",
    justificativa = "diagnóstico por succinilacetona", ressalvas = ""),
  linha(16, "Doença de Wilson (tubulopatia)", c("E83.0"), renal = TRUE, pac = pac_tipo("Wilson"),
    nivel = "EIM renal relevante", genes = "ATP7B", heranca = "AR", acometimento_renal = "tubulopatia proximal, nefrocalcinose",
    papel_teste_genetico = "casos duvidosos; irmãos", obrigatoriedade = "opcional", marcador_SUS = "penicilamina/trientina",
    justificativa = "", ressalvas = "")
)

# =============================================================================
# 3. Hemoglobinopatias e outras doenças hereditárias do sangue
# =============================================================================
hemo <- dplyr::bind_rows(
  linha(1, "Doença falciforme (SS, SC, S/β-talassemia)", c("D57.0", "D57.1", "D57.2", "D57.8"), pac = pac_marc("hidroxiureia"),
    grupo = "hemoglobinopatia", genes = "HBB (+ HBA1/HBA2, BCL11A, HBG — moduladores)", heranca = "AR",
    diagnostico_padrao = "HPLC/eletroforese no pezinho", papel_teste_genetico = "genótipo (SS vs Sβ0 vs Sβ+ vs SC) para prognóstico; pré-natal; aconselhamento; doador de TCTH",
    obrigatoriedade = "recomendado", marcador_SUS = "hidroxiureia; molecular confirmatório (02.02.11.002-8)",
    justificativa = "maior carga hematológica de PE; quase nenhum teste molecular registrado em PE, contra milhares em MG, SP e BA",
    ressalvas = "traço (D57.3) fora; pacientes/mês = hidroxiureia"),
  linha(2, "Beta-talassemia (maior/intermédia)", c("D56.1"), grupo = "hemoglobinopatia", genes = "HBB", heranca = "AR",
    diagnostico_padrao = "HPLC (HbA2/HbF)", papel_teste_genetico = "β0 vs β+ (gravidade, dependência transfusional); pré-natal; casais portadores",
    obrigatoriedade = "recomendado", marcador_SUS = "quelantes de ferro (T45.4); molecular confirmatório (02.02.11.002-8)",
    justificativa = "transfusão crônica e quelação; aconselhamento reprodutivo depende do genótipo",
    ressalvas = "quelantes saem com CID T45.4, não D56 — pacientes/mês na linha 'sobrecarga de ferro'"),
  linha(3, "Alfa-talassemia e doença da HbH", c("D56.0"), grupo = "hemoglobinopatia", genes = "HBA1; HBA2 (deleções −α3.7, −α4.2, −−SEA…)", heranca = "AR",
    diagnostico_padrao = "HPLC não detecta o traço", papel_teste_genetico = "diagnóstico (GAP-PCR/MLPA); aconselhamento; hidropsia fetal (Hb Bart)",
    obrigatoriedade = "obrigatório", marcador_SUS = "molecular (02.02.11.002-8, MLPA 02.02.10.007-3)",
    justificativa = "só o teste molecular confirma; frequente em ascendência africana", ressalvas = ""),
  linha(4, "Deficiência de G6PD", c("D55.0"), grupo = "enzimopatia", genes = "G6PD", heranca = "XL",
    diagnostico_padrao = "dosagem enzimática (02.02.01.048-1)", papel_teste_genetico = "heterozigotas (enzima pode ser normal); primaquina/tafenoquina",
    obrigatoriedade = "recomendado em mulheres", marcador_SUS = "dosagem de G6PD",
    justificativa = "PE concentra parcela desproporcional das internações do país por D55.0 (crises hemolíticas; ver razão PE/BR no SIH)",
    ressalvas = ""),
  linha(5, "Hemofilia A", c("D66"), grupo = "coagulopatia", genes = "F8 (inversão do íntron 22)", heranca = "XL",
    diagnostico_padrao = "dosagem de fator VIII", papel_teste_genetico = "portadoras; risco de inibidor; pré-natal", obrigatoriedade = "recomendado",
    marcador_SUS = "aplicação de fator VIII (03.06.02.003-3)", justificativa = "detecção de portadoras muda o cuidado obstétrico", ressalvas = ""),
  linha(7, "Hemofilia B", c("D67"), grupo = "coagulopatia", genes = "F9", heranca = "XL",
    diagnostico_padrao = "dosagem de fator IX", papel_teste_genetico = "portadoras; pré-natal", obrigatoriedade = "recomendado",
    marcador_SUS = "aplicação de fator IX (03.06.02.002-5)", justificativa = "idem hemofilia A", ressalvas = ""),
  linha(6, "Doença de von Willebrand", c("D68.0"), grupo = "coagulopatia", genes = "VWF", heranca = "AD/AR",
    diagnostico_padrao = "vWF:Ag, atividade, multímeros (02.02.02.024-0)", papel_teste_genetico = "subtipos 2 (2B, 2N) e 3; pré-natal no tipo 3",
    obrigatoriedade = "recomendado nos tipos 2/3", marcador_SUS = "fator VIII para vW (03.06.02.016-5)",
    justificativa = "subtipo define o tratamento (DDAVP contraindicado no 2B)", ressalvas = ""),
  linha(9, "Esferocitose e eliptocitose hereditárias", c("D58.0", "D58.1"), grupo = "membranopatia", genes = "ANK1; SPTB; SPTA1; SLC4A1; EPB42",
    heranca = "AD/AR", diagnostico_padrao = "EMA/fragilidade osmótica", papel_teste_genetico = "casos atípicos e recessivos; decisão de esplenectomia",
    obrigatoriedade = "opcional", marcador_SUS = "nenhum", justificativa = "", ressalvas = ""),
  linha(10, "Outras hemoglobinopatias (HbC, HbE, instáveis, alta afinidade)", c("D58.2", "D75.0"), grupo = "hemoglobinopatia",
    genes = "HBB; HBA1/HBA2; EPOR; VHL; EGLN1", heranca = "AD/AR", diagnostico_padrao = "HPLC; teste de instabilidade (02.02.02.032-0)",
    papel_teste_genetico = "identificação da variante; eritrocitose familiar", obrigatoriedade = "recomendado", marcador_SUS = "nenhum",
    justificativa = "", ressalvas = "D75.0 inclui eritrocitose familiar"),
  linha(8, "Falência medular constitucional (Fanconi, Diamond-Blackfan)", c("D61.0"), grupo = "falência medular", genes = "FANCA…FANCW; RPS19; RPL5…",
    heranca = "AR/XL/AD", diagnostico_padrao = "quebras cromossômicas (DEB)", papel_teste_genetico = "diagnóstico; escolha do doador de TCTH; vigilância de câncer",
    obrigatoriedade = "obrigatório", marcador_SUS = "cariótipo/quebras (02.02.10.001-4)", justificativa = "o doador aparentado precisa ser excluído geneticamente",
    ressalvas = "volume de D61.0 alto demais para doença rara — provável uso para aplasia adquirida"),
  linha(12, "Outras deficiências hereditárias de fatores (FVII, FX, FXIII, fibrinogênio, FXI)", c("D68.1", "D68.2"), grupo = "coagulopatia",
    genes = "F7; F10; F13A1; FGA/FGB/FGG; F11", heranca = "AR", diagnostico_padrao = "dosagem do fator", papel_teste_genetico = "confirmação; pré-natal",
    obrigatoriedade = "opcional", marcador_SUS = "concentrado de fibrinogênio (03.06.02.021-1)", justificativa = "", ressalvas = ""),
  linha(13, "Defeitos qualitativos de plaquetas (Glanzmann, Bernard-Soulier)", c("D69.1"), grupo = "plaquetopatia", genes = "ITGA2B; ITGB3; GP1BA; GP1BB; GP9",
    heranca = "AR", diagnostico_padrao = "agregação plaquetária/citometria", papel_teste_genetico = "confirmação; pré-natal", obrigatoriedade = "opcional",
    marcador_SUS = "nenhum", justificativa = "", ressalvas = "D69.1 inclui defeitos adquiridos"),
  linha(14, "Hemocromatose hereditária", c("E83.1"), grupo = "metabolismo do ferro", genes = "HFE (C282Y, H63D); HJV; HAMP; TFR2; SLC40A1",
    heranca = "AR/AD", diagnostico_padrao = "ferritina e saturação de transferrina", papel_teste_genetico = "diagnóstico (C282Y homozigoto); rastreio de irmãos",
    obrigatoriedade = "recomendado", marcador_SUS = "quelantes de ferro; flebotomia", justificativa = "genotipagem HFE define o diagnóstico sem biópsia",
    ressalvas = "E83.1 inclui sobrecarga secundária; C282Y é rara em populações de ascendência não europeia"),
  linha(11, "Enzimopatias eritrocitárias raras (piruvato quinase e outras)", c("D55.1", "D55.2", "D55.3", "D55.8", "D55.9"), grupo = "enzimopatia",
    genes = "PKLR; GPI; TPI1; NT5C3A; GSR", heranca = "AR", diagnostico_padrao = "ensaios enzimáticos (02.02.10.018-9)",
    papel_teste_genetico = "diagnóstico (ensaios pouco disponíveis)", obrigatoriedade = "na prática obrigatório", marcador_SUS = "nenhum",
    justificativa = "", ressalvas = ""),
  linha(15, "Anemia sideroblástica hereditária, metemoglobinemia congênita", c("D64.0", "D74.0"), grupo = "outros", genes = "ALAS2; SLC25A38; CYB5R3; HBA/HBB (HbM)",
    heranca = "XL/AR", diagnostico_padrao = "mielograma; dosagem de meta-Hb (02.02.07.027-1)", papel_teste_genetico = "diagnóstico", obrigatoriedade = "recomendado",
    marcador_SUS = "nenhum", justificativa = "", ressalvas = "D64.0 provavelmente inclui formas adquiridas"),
  linha(16, "Sobrecarga de ferro em tratamento (contexto)", c("T45.4"), pac = pac_marc("quelante de ferro"), grupo = "marcador terapêutico",
    genes = "—", heranca = "—", diagnostico_padrao = "—", papel_teste_genetico = "—", obrigatoriedade = "—",
    marcador_SUS = "deferasirox, deferiprona, desferroxamina (06.04.02)", justificativa = "dimensiona talassemia/falciforme transfusionais e hemocromatose",
    ressalvas = "causa diversa (talassemia, falciforme, mielodisplasia, hemocromatose); APAC raramente traz o CID de base")
)

ordena <- function(d) dplyr::arrange(d, rank)
eim <- ordena(eim); nefro <- ordena(nefro); hemo <- ordena(hemo)
grava(eim,   "ranking_doencas_alvo_testes_geneticos_PE.tsv")
grava(nefro, "lista_nefropatias_hereditarias_PE.tsv")
grava(hemo,  "lista_hemoglobinopatias_sangue_PE.tsv")
