# =============================================================================
# utils.R — Funções utilitárias do pipeline DATASUS-EIM
# Carregado por 00_setup.R. Herda o núcleo do projeto HS (datasus_HS/scripts/utils.R)
# e ADICIONA as funções específicas de EIM (classificação multi-CID via lookup,
# detecção no SIM multi-código, incidência ao nascimento, supressão de taxa).
# Depende de: tidyverse/stringr/janitor já anexados + EIM_LOOKUP (eim_lookup.R).
# =============================================================================

# -----------------------------------------------------------------------------
# 1. Classificação de CID via lookup (SUBSTITUI o camada_cid() booleano do HS)
# -----------------------------------------------------------------------------

#' Classifica um vetor de códigos CID contra EIM_LOOKUP (match por prefixo,
#' mais específico primeiro). Passada única. Vetorizado.
#' @return tibble alinhada a `cids`: cid(4) + subgrupo + classe + camada +
#'   tracadora + heranca + triagem + escopo + eh_eim(lógico)
classificar_eim <- function(cids, lookup = EIM_LOOKUP) {
  x <- stringr::str_sub(stringr::str_trim(toupper(as.character(cids))), 1, 4)
  # match por prefixo: 1º prefixo (lookup já ordenada desc(nchar)) que o cid começa
  idx <- vapply(x, function(c) {
    if (is.na(c) || c == "") return(NA_integer_)
    hit <- which(stringr::str_starts(c, lookup$prefixo))
    if (length(hit)) hit[1] else NA_integer_
  }, integer(1), USE.NAMES = FALSE)
  tibble::tibble(
    cid       = x,
    subgrupo  = lookup$subgrupo[idx],
    classe    = lookup$classe[idx],
    camada    = lookup$camada[idx],
    tracadora = lookup$tracadora[idx],
    heranca   = lookup$heranca[idx],
    triagem   = lookup$triagem[idx],
    escopo    = lookup$escopo[idx],
    eh_eim    = !is.na(idx)
  )
}

#' Conveniência lógica: "é EIM no modo escolhido".
#' @param modo "restrito" (só camada core) | "ampliado" (core+limitrofe+envelope)
#' @param escopo "nucleo" (só E70–E90 stricto sensu) | "todos"
eh_eim <- function(cids, modo = MODO_CAPTURA, escopo = "nucleo", lookup = EIM_LOOKUP) {
  cl <- classificar_eim(cids, lookup)
  # "todos" = EIM-relevante (núcleo + triagem endócrina + contexto raras), MAS
  # NUNCA o painel_pezinho não-EIM (D57/D56/D81/P371), que tem pipeline próprio.
  ok_escopo <- if (escopo == "nucleo") cl$escopo == "nucleo_eim"
               else cl$escopo %in% c("nucleo_eim","fora_capitulo_E","contexto_raras")
  base <- cl$eh_eim & ok_escopo
  if (modo == "restrito")      base & cl$camada == "core"
  else if (modo == "ampliado") base
  else stop("modo inválido: use 'restrito' ou 'ampliado'")
}

#' CID sintaticamente válido (1 letra + >=2 dígitos) — indicador de qualidade.
cid_valido <- function(campo) {
  stringr::str_detect(stringr::str_trim(toupper(as.character(campo))), "^[A-Z][0-9]{2}")
}

#' Normaliza uma célula de CID do SIM (causabas/linhas): remove daga/asterisco (†/*)
#' e extrai TODOS os códigos. Aplicar APÓS corrigir encoding.
#' @return lista de vetores de códigos por elemento de `x`
normalizar_cid_sim <- function(x) {
  x |>
    toupper() |>
    stringr::str_remove_all("[†*+]") |>            # daga (†), asterisco, '+'
    stringr::str_extract_all("[A-Z][0-9]{2,3}")
}

#' Detecta EIM em QUALQUER campo de causa do SIM (causabas + linhas), multi-código.
#' @param df data.frame; cols = colunas de causa presentes
#' @return lógico por linha
detecta_eim_sim <- function(df,
                            cols = c("causabas","linhaa","linhab","linhac","linhad","linhaii"),
                            modo = MODO_CAPTURA, escopo = "nucleo") {
  cols <- intersect(cols, names(df))
  cods_por_linha <- purrr::pmap(df[cols], function(...) {
    unlist(purrr::map(list(...), ~ unlist(normalizar_cid_sim(.x))))
  })
  purrr::map_lgl(cods_por_linha, ~ length(.x) > 0 && any(eh_eim(.x, modo = modo, escopo = escopo)))
}

#' Extrai a CLASSE/subgrupo do 1º código EIM encontrado numa lista de campos do SIM
#' (para estratificar óbitos por subgrupo). Retorna tibble subgrupo/classe/tracadora.
classe_eim_sim <- function(df,
                           cols = c("causabas","linhaa","linhab","linhac","linhad","linhaii"),
                           modo = MODO_CAPTURA) {
  cols <- intersect(cols, names(df))
  purrr::pmap_dfr(df[cols], function(...) {
    cods <- unlist(purrr::map(list(...), ~ unlist(normalizar_cid_sim(.x))))
    cl <- classificar_eim(cods)
    hit <- which(cl$eh_eim & (modo == "ampliado" | cl$camada == "core"))
    if (length(hit)) cl[hit[1], c("subgrupo","classe","tracadora")]
    else tibble::tibble(subgrupo = NA_character_, classe = NA_character_, tracadora = NA_character_)
  })
}

#' Detecta dinamicamente as colunas de diagnóstico do SIH (varia entre anos).
detectar_cols_diag <- function(df) {
  cols <- names(df) |> stringr::str_subset("^diag(_?princ|_?secun|sec)")
  union("diag_princ", cols) |> intersect(names(df))
}

# -----------------------------------------------------------------------------
# 2. Encoding e tipos (DATASUS é ISO-8859-1 / latin1) — herdado do HS
# -----------------------------------------------------------------------------
corrigir_encoding <- function(df) {
  dplyr::mutate(df, dplyr::across(where(is.character),
                                  ~ iconv(.x, from = "latin1", to = "UTF-8")))
}

coagir_tipos <- function(df, monetarias = character(), datas = character()) {
  monetarias <- intersect(monetarias, names(df))
  datas      <- intersect(datas, names(df))
  df |>
    dplyr::mutate(dplyr::across(dplyr::all_of(monetarias),
                                ~ readr::parse_number(as.character(.x)))) |>
    dplyr::mutate(dplyr::across(dplyr::all_of(datas),
                                ~ lubridate::ymd(.x, quiet = TRUE)))
}

# -----------------------------------------------------------------------------
# 3. Idade e faixas etárias — GRADE PEDIÁTRICA FINA (diferente do HS)
#    EIM concentra-se em <1 ano; a grade quinquenal do HS é grossa demais.
# -----------------------------------------------------------------------------

#' Converte idade para ANOS respeitando a unidade (SIH: idade + cod_idade).
#' [VERIFICAR] mapeamento de cod_idade na competência/versão do microdatasus.
idade_em_anos <- function(idade, cod_idade = NULL) {
  idade <- suppressWarnings(as.numeric(idade))
  if (is.null(cod_idade)) return(idade)
  cod <- as.character(cod_idade)
  dplyr::case_when(
    cod == "4" ~ idade,            # anos
    cod == "3" ~ idade / 12,       # meses
    cod == "2" ~ idade / 365.25,   # dias
    cod == "1" ~ idade / 8766,     # horas
    cod == "0" ~ 0,                # minutos
    TRUE       ~ idade             # [VERIFICAR]
  )
}

#' Decodifica o campo IDADE bruto do SIM (3 díg.: 1º = unidade, 2º-3º = valor) → anos.
decode_idade_sim <- function(idade_cod) {
  s <- stringr::str_pad(as.character(idade_cod), 3, pad = "0")
  u <- stringr::str_sub(s, 1, 1)
  v <- suppressWarnings(as.numeric(stringr::str_sub(s, 2, 3)))
  dplyr::case_when(
    u == "5" ~ 100 + v, u == "4" ~ v, u == "3" ~ v / 12,
    u == "2" ~ v / 365.25, u %in% c("0","1") ~ 0, TRUE ~ NA_real_
  )
}

# Grade CANÔNICA pediátrica-fina do EIM (mesma no numerador e no denominador IBGE).
# 0=neonatal(<28d aprox.), depois <1 ano, 1-4, 5-9, ... — declarada em 00_setup.R.
#' Aplica a grade FAIXAS_EIM a uma idade em anos.
harmonizar_faixa <- function(idade_anos, breaks = FAIXAS_EIM) {
  lb <- head(breaks, -1); ub <- breaks[-1]
  labs <- ifelse(is.infinite(ub), paste0(lb, "+"),
                 ifelse(ub - lb <= 0.1, sprintf("%.2g", lb), paste0(lb, "-", ub - 1)))
  cut(idade_anos, breaks = breaks, right = FALSE, labels = labs, include.lowest = TRUE)
}

#' Marca óbito/atendimento no 1º ano de vida (coorte de nascimento p/ incidência).
menor_1_ano <- function(idade_anos) !is.na(idade_anos) & idade_anos < 1

# -----------------------------------------------------------------------------
# 4. Geografia — herdado do HS
# -----------------------------------------------------------------------------
.UF_COD <- tibble::tribble(
  ~cod, ~uf,
  "11","RO","12","AC","13","AM","14","RR","15","PA","16","AP","17","TO",
  "21","MA","22","PI","23","CE","24","RN","25","PB","26","PE","27","AL","28","SE","29","BA",
  "31","MG","32","ES","33","RJ","35","SP",
  "41","PR","42","SC","43","RS",
  "50","MS","51","MT","52","GO","53","DF"
)
uf_from_mun <- function(cod_mun) {
  cod2 <- stringr::str_sub(as.character(cod_mun), 1, 2)
  .UF_COD$uf[match(cod2, .UF_COD$cod)]
}
mapear_uf_regiao <- function(uf) {
  regioes <- list(
    Norte = c("RO","AC","AM","RR","PA","AP","TO"),
    Nordeste = c("MA","PI","CE","RN","PB","PE","AL","SE","BA"),
    Sudeste = c("MG","ES","RJ","SP"), Sul = c("PR","SC","RS"),
    `Centro-Oeste` = c("MS","MT","GO","DF"))
  reg <- rep(NA_character_, length(uf))
  for (nm in names(regioes)) reg[uf %in% regioes[[nm]]] <- nm
  reg
}

# -----------------------------------------------------------------------------
# 5. Logging e validação de grade — herdado do HS (n_hs → n_eim)
# -----------------------------------------------------------------------------
log_run <- function(base, uf, competencia, status,
                    n_lidas = NA_integer_, n_eim = NA_integer_, msg = "") {
  fp <- here::here("logs", paste0("run_log_", base, ".csv"))
  linha <- tibble::tibble(
    ts = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    base = base, uf = uf, competencia = as.character(competencia),
    status = status, n_lidas = n_lidas, n_eim = n_eim, msg = msg)
  readr::write_csv(linha, fp, append = file.exists(fp))
  invisible(linha)
}

validar_grade_completa <- function(base, dir, pattern_fun,
                                   anos = ANOS, ufs = UFS, meses = MESES,
                                   stop_se_faltar = TRUE) {
  grade <- if (base %in% c("sia","sih")) tidyr::expand_grid(uf = ufs, ano = anos, mes = meses)
           else tidyr::expand_grid(uf = ufs, ano = anos, mes = NA_integer_)
  grade <- grade |>
    dplyr::mutate(
      arquivo = purrr::pmap_chr(list(uf, ano, mes), pattern_fun),
      caminho = file.path(dir, arquivo),
      tamanho = file.info(caminho)$size,
      presente = !is.na(tamanho) & tamanho > 0)
  n_faltantes <- sum(!grade$presente)
  attr(grade, "n_faltantes") <- n_faltantes
  message(sprintf("[%s] grade: %d esperados, %d presentes, %d faltantes.",
                  toupper(base), nrow(grade), sum(grade$presente), n_faltantes))
  if (stop_se_faltar && n_faltantes > 0)
    stop(sprintf("validar_grade_completa(%s): %d faltantes.", base, n_faltantes))
  grade
}

casar_tipos <- function(df, ref) {
  comuns <- intersect(names(df), names(ref))
  for (cn in comuns) {
    cls_ref <- class(ref[[cn]])[1]
    if (class(df[[cn]])[1] == cls_ref) next
    df[[cn]] <- tryCatch(
      switch(cls_ref, numeric = as.numeric(df[[cn]]), double = as.numeric(df[[cn]]),
             integer = as.integer(df[[cn]]), character = as.character(df[[cn]]),
             factor = factor(df[[cn]]), Date = lubridate::as_date(df[[cn]]),
             logical = as.logical(df[[cn]]), df[[cn]]),
      error = function(e) df[[cn]], warning = function(w) df[[cn]])
  }
  df
}

#' Carrega o 1º objeto (ou `obj` nomeado) de um .RData.
carregar_obj <- function(fp, obj = NULL) {
  e <- new.env(); nm <- load(fp, envir = e)
  get(if (!is.null(obj) && obj %in% nm) obj else nm[1], envir = e)
}

# -----------------------------------------------------------------------------
# 6. QC e supressão LGPD (N<5 é REGRA ESTRUTURAL em doença rara)
# -----------------------------------------------------------------------------
qc_basico <- function(df, cols_cid = character()) {
  cols_cid <- intersect(cols_cid, names(df))
  compl <- df |>
    dplyr::summarise(dplyr::across(dplyr::everything(), ~ mean(!is.na(.x) & .x != ""))) |>
    tidyr::pivot_longer(dplyr::everything(), names_to = "coluna", values_to = "completude")
  cid_ok <- if (length(cols_cid)) {
    df |> dplyr::summarise(dplyr::across(dplyr::all_of(cols_cid),
                                         ~ mean(cid_valido(.x), na.rm = TRUE))) |>
      tidyr::pivot_longer(dplyr::everything(), names_to = "coluna", values_to = "prop_cid_valido")
  } else tibble::tibble(coluna = character(), prop_cid_valido = double())
  list(n_linhas = nrow(df), completude = compl, cid_valido = cid_ok)
}

#' Suprime CONTAGENS de células pequenas.
suprimir_pequenas <- function(df, col_n, limiar = N_SUPRESSAO) {
  df |> dplyr::mutate("{{col_n}}" := ifelse({{ col_n }} < limiar, NA_integer_, {{ col_n }}))
}

#' Suprime a PRÓPRIA TAXA (e IC) quando o nº de eventos < limiar — específico EIM.
#' Zera taxa_bruta/taxa_pad/ic_inf/ic_sup em células com eventos < N_SUPRESSAO.
suprimir_taxa <- function(df, col_ev = "eventos", limiar = N_SUPRESSAO,
                          cols_taxa = c("taxa_bruta","taxa_pad","ic_inf","ic_sup")) {
  cols_taxa <- intersect(cols_taxa, names(df))
  df |> dplyr::mutate(dplyr::across(dplyr::all_of(cols_taxa),
                                    ~ dplyr::if_else(.data[[col_ev]] < limiar, NA_real_, .x)))
}

# -----------------------------------------------------------------------------
# 7. Incidência ao nascimento (por 100 mil NV) — traçadoras de triagem neonatal
# -----------------------------------------------------------------------------
#' casos incidentes (idade <1 ano no ano t) / nascidos vivos (SINASC, ano t) × por.
#' IC de Poisson exato (epitools::pois.exact) — honesto p/ contagens pequenas.
incidencia_nascimento <- function(num_incidente, nv, grupos = c("uf","ano"),
                                  por = 1e5) {
  n <- num_incidente |>
    dplyr::group_by(dplyr::across(dplyr::all_of(grupos))) |>
    dplyr::summarise(casos = sum(n, na.rm = TRUE), .groups = "drop")
  d <- nv |>
    dplyr::group_by(dplyr::across(dplyr::all_of(grupos))) |>
    dplyr::summarise(nv = sum(nv, na.rm = TRUE), .groups = "drop")
  out <- dplyr::left_join(n, d, by = grupos) |>
    dplyr::mutate(inc_nasc = por * casos / nv)
  # IC Poisson exato por linha (quando epitools disponível)
  if (requireNamespace("epitools", quietly = TRUE)) {
    ic <- epitools::pois.exact(out$casos, pt = out$nv / por)
    out$ic_inf <- ic$lower; out$ic_sup <- ic$upper
  }
  suprimir_taxa(out, col_ev = "casos")
}
