# =============================================================================
# pseudo_id_PE_recife.R — Pseudo-individualização do SIA para PE e RECIFE
# Reaproveita o motor de feature_eng_pacientes_SIA.R (blocking sexo×município,
# janela ano_nasc±1, componentes conexos igraph, cap span≤1), mas restringe o
# escopo geográfico e, dado o volume menor, roda em TODOS os subgrupos core.
# Reporta o nº ESTIMADO DE INDIVÍDUOS como INTERVALO [registros ; pseudo-pacientes].
#
# ESCOPOS: PE (uf_pcn == "PE") e RECIFE (pa_munpcn == "261160").
# Princípio (LGPD, §5.1): pseudo-ID é AGRUPADOR, não identificador; intervalo, não
# ponto; supressão N<5 por subgrupo (o TOTAL agregado é grande, não suprimido);
# razão registros/paciente = INTENSIDADE DE USO. Cautela <1 ano (idade em anos).
# Saídas: manifest/sia_pseudo_pacientes_PE.csv e _Recife.csv.
# =============================================================================

if (!exists("EIM_LOOKUP")) source(here::here("scripts", "00_setup.R"))
suppressPackageStartupMessages({ library(data.table); library(igraph) })

# -----------------------------------------------------------------------------
# Motor de linkage (idêntico ao feature_eng_pacientes_SIA.R)
# -----------------------------------------------------------------------------
construir_pares <- function(el, usar_raca, janela) {
  bloco <- if (usar_raca) c("sexo_n","mun_n","raca_n") else c("sexo_n","mun_n")
  a <- el[, c("rid", bloco, "ano_nasc_proxy"), with = FALSE]
  b <- el[, c("rid", bloco, "ano_nasc_proxy"), with = FALSE]
  data.table::setnames(b, "rid", "rid_b")
  offs <- if (janela == 0) 0L else seq(-janela, janela)
  b_exp <- data.table::rbindlist(lapply(offs, function(o) {
    bb <- data.table::copy(b); bb[, ano_nasc_proxy := ano_nasc_proxy + o]; bb }))
  on_cols <- c(bloco, "ano_nasc_proxy")
  pr <- a[b_exp, on = on_cols, nomatch = 0L, allow.cartesian = TRUE, .(x = rid, y = rid_b)]
  pr <- pr[x < y]; unique(pr)
}
atribuir_componentes <- function(rids, pares) {
  g <- igraph::graph_from_data_frame(as.data.frame(pares[, .(x, y)]), directed = FALSE,
        vertices = data.frame(name = as.character(rids)))
  igraph::components(g)$membership
}
contar_pacientes <- function(el, usar_raca, janela) {
  if (nrow(el) <= 1L) return(nrow(el))
  pares <- construir_pares(el, usar_raca, janela)
  memb  <- atribuir_componentes(el$rid, pares)
  dt <- data.table::copy(el); dt[, comp := memb[as.character(rid)]]
  dt[, span := max(ano_nasc_proxy) - min(ano_nasc_proxy), by = comp]
  dt[, id_final := data.table::fifelse(span <= 1L, paste0("C", comp),
                                       paste0("C", comp, "_", ano_nasc_proxy))]
  data.table::uniqueN(dt$id_final)
}

# -----------------------------------------------------------------------------
# Carregar core + normalizar quase-identificadores (uma vez)
# -----------------------------------------------------------------------------
sia_core <- readRDS(here::here("data/consolidated/sia_eim_core.rds")) |>
  dplyr::filter(camada == "core") |>
  dplyr::select(subgrupo, tracadora, sexo, idade_anos, pa_munpcn, pa_racacor,
                competencia, ano, uf_pcn) |>
  dplyr::mutate(
    sexo_n = dplyr::case_when(sexo=="Masculino"~"M", sexo=="Feminino"~"F", TRUE~NA_character_),
    raca_n = { r <- stringr::str_pad(stringr::str_trim(as.character(pa_racacor)),2,pad="0")
               dplyr::if_else(r %in% c("01","02","03","04","05"), r, NA_character_) },
    mun_n  = { m <- stringr::str_pad(stringr::str_trim(as.character(pa_munpcn)),6,pad="0")
               dplyr::if_else(stringr::str_detect(m,"^0+$") | m=="999999", NA_character_, m) },
    idade_i = suppressWarnings(as.integer(idade_anos)),
    idade_i = dplyr::if_else(idade_i>=0 & idade_i<=110, idade_i, NA_integer_),
    ano_cmp = as.integer(format(competencia, "%Y")),
    ano_nasc_proxy = ano_cmp - idade_i,
    chave_completa = !is.na(sexo_n) & !is.na(raca_n) & !is.na(mun_n) & !is.na(ano_nasc_proxy))

# -----------------------------------------------------------------------------
# Rotina por escopo: gradiente por subgrupo + TOTAL agregado
# -----------------------------------------------------------------------------
resumo_subgrupo <- function(s) {
  n_total <- nrow(s)
  s <- dplyr::mutate(s, rid = dplyr::row_number())
  elig <- data.table::as.data.table(
    dplyr::filter(s, chave_completa)[, c("rid","sexo_n","mun_n","raca_n","ano_nasc_proxy")])
  n_incompletos <- sum(!s$chave_completa)
  if (nrow(elig) == 0L)
    return(tibble::tibble(registros=n_total, pseudo_estrita=n_total,
                          pseudo_intermediaria=n_total, pseudo_frouxa=n_total))
  tibble::tibble(
    registros = n_total,
    pseudo_estrita       = contar_pacientes(elig, TRUE,  0L) + n_incompletos,
    pseudo_intermediaria = contar_pacientes(elig, TRUE,  1L) + n_incompletos,
    pseudo_frouxa        = contar_pacientes(elig, FALSE, 1L) + n_incompletos)
}

rodar_escopo <- function(df, rotulo) {
  subs <- sort(unique(df$subgrupo))
  por_sub <- purrr::map_dfr(subs, function(sub) {
    r <- resumo_subgrupo(dplyr::filter(df, subgrupo == sub))
    dplyr::mutate(r, subgrupo = sub, .before = 1) })
  por_sub <- por_sub |>
    dplyr::mutate(razao = round(registros / pseudo_intermediaria, 2))
  # TOTAL agregado (soma sobre subgrupos — inclui os pequenos; grande, não suprimido)
  total <- por_sub |>
    dplyr::summarise(subgrupo = "TOTAL (todos os subgrupos core)",
                     registros = sum(registros),
                     pseudo_estrita = sum(pseudo_estrita),
                     pseudo_intermediaria = sum(pseudo_intermediaria),
                     pseudo_frouxa = sum(pseudo_frouxa)) |>
    dplyr::mutate(razao = round(registros / pseudo_intermediaria, 2))
  # Supressão N<5 nas CÉLULAS por subgrupo (o TOTAL fica)
  por_sub_sup <- por_sub |>
    dplyr::mutate(dplyr::across(dplyr::starts_with("pseudo_"),
                   ~ dplyr::if_else(.x < N_SUPRESSAO, NA_integer_, as.integer(.x)))) |>
    dplyr::arrange(dplyr::desc(registros))
  out <- dplyr::bind_rows(por_sub_sup, total)
  cat(sprintf("\n== %s ==\n", rotulo)); print(as.data.frame(out))
  cat(sprintf("→ %s: ~%s registros; indivíduos estimados no INTERVALO [%s (frouxa) ; %s (estrita)]; razão %.1f reg/indivíduo\n",
      rotulo, formatC(total$registros, format="d", big.mark="."),
      formatC(total$pseudo_frouxa, format="d", big.mark="."),
      formatC(total$pseudo_estrita, format="d", big.mark="."), total$razao))
  out
}

pe     <- dplyr::filter(sia_core, uf_pcn == "PE")
recife <- dplyr::filter(sia_core, mun_n == "261160")

res_pe     <- rodar_escopo(pe,     "PERNAMBUCO (SIA core)")
res_recife <- rodar_escopo(recife, "RECIFE (SIA core)")

readr::write_csv(res_pe,     here::here("manifest","sia_pseudo_pacientes_PE.csv"))
readr::write_csv(res_recife, here::here("manifest","sia_pseudo_pacientes_Recife.csv"))
message("\n✓ Pseudo-ID SIA PE/Recife → manifest/sia_pseudo_pacientes_{PE,Recife}.csv")
