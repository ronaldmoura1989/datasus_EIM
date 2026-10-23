# =============================================================================
# genetica_sus_procedimentos.R — Oferta de testes genéticos e de diagnóstico de
# doenças raras no SUS (SIA-PA), TODOS os CIDs — não só EIM
#
# FONTE: SIA-PA 2010+ filtrado por PROCEDIMENTO (scripts/r550/filtrar_um.R, flag
# hit_genetica — config_filtro.R), em <DIR_FILTRADO>/SIA-PA/filtrado/*.parquet. O filtro
# por procedimento independe do CID, então a base inclui oncologia, citogenética,
# anomalias congênitas etc.
#
# CATÁLOGO (GEN_PROC abaixo): grupo 02.02.10 inteiro (citogenética, genética
# molecular, exoma, oncologia molecular, bioquímica especializada de EIM),
# confirmatórios moleculares e diagnóstico tardio do 02.02.11 (fora os componentes
# de rotina do pezinho), atendimento de doenças raras/aconselhamento genético e a
# coleta para HLA-B (farmacogenética).
#
# CUIDADOS DE LEITURA
#   - BPA consolidado (pa_docorig "C") não tem CID, idade, sexo nem residência:
#     volume = soma de PA_QTDAPR (exames aprovados), não nº de linhas; o recorte por
#     CID/residência usa só BPA-I e APAC (pa_docorig I/P/S) e é reportado com a
#     fração do volume que ele cobre.
#   - UF de residência (pa_munpcn) × UF do estabelecimento (pa_ufmun) mede fluxo
#     (quem faz o exame fora do estado), não só oferta.
#   - Códigos novos dentro de 02.02.10 sem nome no SIGTAP embutido saem como
#     "[VERIFICAR nome SIGTAP]" e categoria "outro 02.02.10".
#
# Saídas (supressão N<5):
#   manifest/genetica_sus_proc_uf_ano.csv   — proc × UF executora × ano: exames, valor, estabelecimentos
#   manifest/genetica_sus_categoria_uf.csv  — categoria × UF (residência e executora) × taxa/milhão
#   manifest/genetica_sus_cid.csv           — categoria × capítulo/CID (só BPA-I/APAC)
#   manifest/genetica_sus_fluxo_pe.csv      — residentes de PE: onde fizeram cada categoria
#   manifest/genetica_sus_serie.csv         — categoria × ano: Brasil (executora) e PE (residência)
# Rodar: Rscript scripts/genetica_sus_procedimentos.R [--in=<dir com PA*.parquet>]
# =============================================================================

if (!exists("EIM_LOOKUP"))   source(here::here("scripts", "00_setup.R"))
if (!exists("carregar_pop")) source(here::here("scripts", "calcular_taxas.R"))
suppressPackageStartupMessages(library(data.table))

args   <- commandArgs(trailingOnly = TRUE)
a_in   <- grep("^--in=", args, value = TRUE)
DIR_IN <- if (length(a_in)) sub("^--in=", "", a_in[1]) else file.path(DIR_FILTRADO, "SIA-PA", "filtrado")
ANO_REF <- 2024L

# -----------------------------------------------------------------------------
# 1. Catálogo de procedimentos e categorias
# -----------------------------------------------------------------------------
GEN_PROC <- tibble::tribble(
  ~pa_proc_id,   ~proc_curto,                                   ~categoria,
  "0202100014",  "Cariótipo — cultura de longa duração",        "Citogenética",
  "0202100022",  "Cariótipo — medula óssea / vilo corial",      "Citogenética",
  "0202100030",  "Cariótipo — sangue periférico",               "Citogenética",
  "0202100090",  "FISH",                                        "Citogenética",
  "0202100103",  "Array-CGH",                                   "Citogenômica (array)",
  "0202100065",  "Southern blot",                               "Genética molecular dirigida",
  "0202100073",  "MLPA",                                        "Genética molecular dirigida",
  "0202100081",  "PCR / qPCR / metilação",                      "Genética molecular dirigida",
  "0202100111",  "Sequenciamento por amplicon (≤500 pb)",       "Genética molecular dirigida",
  "0202100235",  "Mutação do gene da protrombina",              "Genética molecular dirigida",
  "0202100200",  "Sequenciamento completo do exoma",            "Exoma",
  "0202100049",  "HER-2 (quantificação/amplificação)",          "Oncologia molecular",
  "0202100219",  "Leucemia Ph+ — diagnóstico molecular",        "Oncologia molecular",
  "0202100227",  "Leucemia Ph+ — reavaliação molecular",        "Oncologia molecular",
  "0202100057",  "Focalização isoelétrica da transferrina",     "Bioquímica especializada de EIM",
  "0202100120",  "Glicosaminoglicanos urinários",               "Bioquímica especializada de EIM",
  "0202100138",  "Oligossacarídeos e sialossacarídeos",         "Bioquímica especializada de EIM",
  "0202100146",  "Carnitina e perfil de acilcarnitinas",        "Bioquímica especializada de EIM",
  "0202100154",  "Aminoácidos (quantitativo)",                  "Bioquímica especializada de EIM",
  "0202100162",  "Ácidos orgânicos (quantitativo)",             "Bioquímica especializada de EIM",
  "0202100170",  "Ensaios enzimáticos — plasma e leucócitos",   "Bioquímica especializada de EIM",
  "0202100189",  "Ensaios enzimáticos — eritrócitos",           "Bioquímica especializada de EIM",
  "0202100197",  "Ensaios enzimáticos — tecido cultivado",      "Bioquímica especializada de EIM",
  "0202110010",  "Variantes da hemoglobina (diagnóstico tardio)", "Confirmatório / diagnóstico tardio (pezinho)",
  "0202110028",  "Molecular — hemoglobinopatias",               "Confirmatório / diagnóstico tardio (pezinho)",
  "0202110036",  "Molecular — fibrose cística",                 "Confirmatório / diagnóstico tardio (pezinho)",
  "0202110117",  "Biotinidase quantitativa (soro)",             "Confirmatório / diagnóstico tardio (pezinho)",
  "0202110125",  "Molecular — hiperplasia adrenal congênita",   "Confirmatório / diagnóstico tardio (pezinho)",
  "0202110133",  "Molecular — deficiência de biotinidase",      "Confirmatório / diagnóstico tardio (pezinho)",
  "0202110141",  "Cloreto no suor",                             "Confirmatório / diagnóstico tardio (pezinho)",
  "0301010196",  "Avaliação doenças raras — anomalias congênitas", "Atendimento de doenças raras",
  "0301010200",  "Avaliação doenças raras — deficiência intelectual", "Atendimento de doenças raras",
  "0301010218",  "Avaliação doenças raras — EIM",               "Atendimento de doenças raras",
  "0301010226",  "Aconselhamento genético",                     "Atendimento de doenças raras",
  "0201020068",  "Coleta para tipificação HLA-B",               "Farmacogenética"
)
# Filtro remoto equivalente (prefixos): 0202100, os 02.02.11 acima, 03010101/2 acima, 0201020068
PROCS_REMOTO <- c("0202100", setdiff(GEN_PROC$pa_proc_id, GEN_PROC$pa_proc_id[startsWith(GEN_PROC$pa_proc_id, "0202100")]))

#' Capítulo CID-10 a partir do código (3 primeiros caracteres)
cap_cid10 <- function(cid) {
  l <- substr(cid, 1, 1); n <- suppressWarnings(as.integer(substr(cid, 2, 3)))
  dplyr::case_when(
    l %in% c("A", "B") ~ "I Infecciosas", l == "C" | (l == "D" & n <= 48) ~ "II Neoplasias",
    l == "D" ~ "III Sangue e imunidade", l == "E" ~ "IV Endócrinas e metabólicas",
    l == "F" ~ "V Mentais", l == "G" ~ "VI Sistema nervoso", l == "H" & n <= 59 ~ "VII Olho",
    l == "H" ~ "VIII Ouvido", l == "I" ~ "IX Circulatório", l == "J" ~ "X Respiratório",
    l == "K" ~ "XI Digestivo", l == "L" ~ "XII Pele", l == "M" ~ "XIII Osteomuscular",
    l == "N" ~ "XIV Geniturinário", l == "O" ~ "XV Gravidez", l == "P" ~ "XVI Perinatal",
    l == "Q" ~ "XVII Malformações congênitas e cromossômicas", l == "R" ~ "XVIII Sintomas",
    l %in% c("S", "T") ~ "XIX Lesões", l == "Z" ~ "XXI Contatos com serviços", TRUE ~ "sem CID")
}

# -----------------------------------------------------------------------------
# 2. Leitura (arquivos filtrados, colunas MAIÚSCULAS do SIA bruto)
# -----------------------------------------------------------------------------
arqs <- list.files(DIR_IN, pattern = "\\.parquet$", full.names = TRUE)
if (!length(arqs)) stop("Nenhum arquivo em ", DIR_IN, " — rode a filtragem no R550-2 primeiro.")
message(sprintf("Lendo %d arquivos de %s", length(arqs), DIR_IN))

ler <- function(fp) {
  x <- data.table::as.data.table(arrow::read_parquet(fp))
  x <- x[hit_genetica %in% TRUE]
  if (!nrow(x)) return(NULL)
  data.table::setnames(x, tolower(names(x)))
  x <- x[pa_proc_id %in% GEN_PROC$pa_proc_id | startsWith(as.character(pa_proc_id), "0202100")]
  if (!nrow(x)) return(NULL)
  x[, .(pa_proc_id = as.character(pa_proc_id), pa_docorig = as.character(pa_docorig),
        pa_cmp = as.character(pa_cmp), pa_coduni = as.character(pa_coduni),
        pa_ufmun = as.character(pa_ufmun), pa_munpcn = as.character(pa_munpcn),
        pa_cidpri = toupper(substr(as.character(pa_cidpri), 1, 4)),
        pa_idade = suppressWarnings(as.integer(pa_idade)), pa_sexo = as.character(pa_sexo),
        pa_qtdapr = suppressWarnings(as.numeric(pa_qtdapr)),
        pa_valapr = suppressWarnings(as.numeric(pa_valapr)))]
}
g <- data.table::rbindlist(lapply(arqs, ler), fill = TRUE)
g <- merge(g, data.table::as.data.table(GEN_PROC), by = "pa_proc_id", all.x = TRUE)
g[is.na(categoria), `:=`(categoria = "outro 02.02.10", proc_curto = "[VERIFICAR nome SIGTAP]")]
g[, `:=`(ano = as.integer(substr(pa_cmp, 1, 4)),
         uf_exec = uf_from_mun(pa_ufmun),
         individualizado = pa_docorig %in% c("I", "P", "S"))]
g[, uf_res := data.table::fifelse(individualizado, uf_from_mun(pa_munpcn), NA_character_)]
g[, cap := data.table::fifelse(individualizado, cap_cid10(pa_cidpri), NA_character_)]
message(sprintf("%s linhas; %s exames aprovados; %.1f%% do volume individualizado (BPA-I/APAC).",
                format(nrow(g), big.mark = "."), format(sum(g$pa_qtdapr, na.rm = TRUE), big.mark = "."),
                100 * sum(g$pa_qtdapr[g$individualizado], na.rm = TRUE) / sum(g$pa_qtdapr, na.rm = TRUE)))

# -----------------------------------------------------------------------------
# 3. Agregados
# -----------------------------------------------------------------------------
pop_uf <- carregar_pop() |> dplyr::filter(ano == ANO_REF) |>
  dplyr::group_by(uf) |> dplyr::summarise(pop = sum(pop), .groups = "drop") |> data.table::as.data.table()

# 3a. procedimento × UF executora × ano
proc_uf_ano <- g[, .(exames = sum(pa_qtdapr, na.rm = TRUE), valor = sum(pa_valapr, na.rm = TRUE),
                     estabelecimentos = data.table::uniqueN(pa_coduni),
                     pct_individualizado = round(100 * sum(pa_qtdapr[individualizado], na.rm = TRUE) /
                                                   sum(pa_qtdapr, na.rm = TRUE), 1)),
                 by = .(categoria, pa_proc_id, proc_curto, uf_exec, ano)]

# 3b. categoria × UF — executora (todo o volume) e de residência (só individualizado)
cat_exec <- g[ano == ANO_REF, .(exames_exec = sum(pa_qtdapr, na.rm = TRUE)), by = .(categoria, uf = uf_exec)]
cat_res  <- g[ano == ANO_REF & individualizado, .(exames_res = sum(pa_qtdapr, na.rm = TRUE)), by = .(categoria, uf = uf_res)]
cat_uf <- merge(cat_exec, cat_res, by = c("categoria", "uf"), all = TRUE) |>
  merge(pop_uf, by = "uf", all.x = TRUE)
cat_uf[, `:=`(exec_por_milhao = 1e6 * exames_exec / pop, res_por_milhao = 1e6 * exames_res / pop)]

# 3c. categoria × capítulo / CID (só individualizado)
cid <- g[individualizado == TRUE, .(exames = sum(pa_qtdapr, na.rm = TRUE)), by = .(categoria, cap, pa_cidpri)]
cid[, pct_categoria := round(100 * exames / sum(exames), 2), by = categoria]
cid <- cid[order(categoria, -exames)]
cid[, eim := eh_eim(pa_cidpri)]

# 3d. fluxo dos residentes de PE (onde fizeram o exame)
fluxo_pe <- g[uf_res == "PE", .(exames = sum(pa_qtdapr, na.rm = TRUE)), by = .(categoria, uf_exec)]
fluxo_pe[, pct := round(100 * exames / sum(exames), 1), by = categoria]

# 3e. série anual por categoria: Brasil (todo o volume, pela UF executora) e PE
#     (residentes, só individualizado) — antes/depois da Portaria 199/2014
serie <- rbind(
  g[ano %in% ANOS, .(escopo = "Brasil", exames = sum(pa_qtdapr, na.rm = TRUE)), by = .(categoria, ano)],
  g[ano %in% ANOS & uf_res == "PE", .(escopo = "PE (residentes)", exames = sum(pa_qtdapr, na.rm = TRUE)), by = .(categoria, ano)])
serie <- serie[order(escopo, categoria, ano)]

# -----------------------------------------------------------------------------
# 4. Supressão N<5 e escrita
# -----------------------------------------------------------------------------
sup <- function(d, cols) { for (c in cols) d[get(c) < N_SUPRESSAO, (c) := NA]; d }
data.table::fwrite(sup(proc_uf_ano, "exames"),                 here::here("manifest", "genetica_sus_proc_uf_ano.csv"))
data.table::fwrite(sup(cat_uf, c("exames_exec", "exames_res")), here::here("manifest", "genetica_sus_categoria_uf.csv"))
data.table::fwrite(sup(cid, "exames"),                         here::here("manifest", "genetica_sus_cid.csv"))
data.table::fwrite(sup(fluxo_pe, "exames"),                    here::here("manifest", "genetica_sus_fluxo_pe.csv"))
data.table::fwrite(sup(serie, "exames"),                       here::here("manifest", "genetica_sus_serie.csv"))

cat("\n== Exames por categoria (Brasil, todos os anos) ==\n")
print(g[, .(exames = sum(pa_qtdapr, na.rm = TRUE), pct_indiv = round(100 * sum(pa_qtdapr[individualizado], na.rm = TRUE) /
                                                                      sum(pa_qtdapr, na.rm = TRUE), 1)), by = categoria][order(-exames)])
message("\n✓ Genética no SUS → manifest/genetica_sus_{proc_uf_ano,categoria_uf,cid,fluxo_pe,serie}.csv")
