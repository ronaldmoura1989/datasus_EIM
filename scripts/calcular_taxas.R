# =============================================================================
# calcular_taxas.R — Biblioteca de taxas (brutas, padronizadas, incidência ao
# nascimento, tendência) para o projeto EIM. Herda o motor do HS + adições EIM:
#   - padronização por idade×sexo na grade QUINQUENAL (FAIXAS_PAD), IC gama;
#   - supressão N<5 estrutural (suprimir_taxa) em toda saída;
#   - estratificação por classe/subgrupo/tracadora;
#   - incidência ao nascimento (SINASC) — em utils.R::incidencia_nascimento();
#   - tendência Poisson/quasi-Poisson com offset log(pop) ou log(NV).
# Princípio: taxas de DETECÇÃO/USO e MORTALIDADE REGISTRADA, não prevalência.
# =============================================================================

if (!exists("UFS")) source(here::here("scripts", "00_setup.R"))
suppressPackageStartupMessages({ library(epitools); library(broom) })

# Estratos de padronização = sexo × faixa QUINQUENAL (FAIXAS_PAD).
.FAIXA_PAD <- levels(harmonizar_faixa(seq(0, 85, by = 5), breaks = FAIXAS_PAD))

carregar_pop <- function() {
  fp <- here::here("data/denominators/pop_ibge.parquet")
  if (!file.exists(fp)) stop("Rode scripts/get_denominadores_ibge.R primeiro.")
  arrow::read_parquet(fp) |>
    dplyr::mutate(faixa = factor(as.character(faixa), levels = .FAIXA_PAD))
}
carregar_nv <- function() {
  fp <- here::here("data/denominators/nascidos_vivos.parquet")
  if (!file.exists(fp)) stop("Rode scripts/get_nascidos_vivos_SINASC.R primeiro.")
  arrow::read_parquet(fp)
}

#' Conta eventos por estrato (uf × ano × sexo × faixa[QUINQUENAL] [× extra]).
#' Re-binna a idade para FAIXAS_PAD (o campo `faixa` do numerador está em FAIXAS_EIM).
#' @param col_uf   coluna de UF de residência ("uf_pcn" SIA, "uf_res" SIH/SIM)
#' @param col_idade coluna de idade em anos
#' @param extra    colunas adicionais de estratificação (ex.: "classe","subgrupo","tracadora")
#' @param distinct_por conta entidades distintas (ex.: "n_aih") em vez de linhas
contar_estrato <- function(df, col_uf, col_idade = "idade_anos", extra = NULL,
                           distinct_por = NULL) {
  d <- df |>
    dplyr::mutate(
      uf    = .data[[col_uf]],
      ano   = as.integer(ano),
      faixa = factor(as.character(harmonizar_faixa(.data[[col_idade]], breaks = FAIXAS_PAD)),
                     levels = .FAIXA_PAD)) |>
    dplyr::filter(!is.na(uf), !is.na(sexo), !is.na(faixa), uf %in% UFS)
  chave <- c("uf","ano","sexo","faixa", extra)
  if (is.null(distinct_por)) dplyr::count(d, dplyr::across(dplyr::all_of(chave)), name = "n")
  else d |> dplyr::group_by(dplyr::across(dplyr::all_of(chave))) |>
    dplyr::summarise(n = dplyr::n_distinct(.data[[distinct_por]]), .groups = "drop")
}

pop_padrao <- function(pop, ano_ref = 2022) {
  pop |> dplyr::filter(ano == ano_ref) |>
    dplyr::group_by(sexo, faixa) |>
    dplyr::summarise(stdpop = sum(pop), .groups = "drop")
}

#' Taxas BRUTAS + PADRONIZADAS (direta idade×sexo, IC gama) por grupo.
#' Aplica supressão N<5 (suprimir_taxa) por padrão.
taxas_padronizadas <- function(num, pop, grupos, ano_ref = 2022, por = 1e5,
                               conf = 0.95, suprimir = TRUE) {
  std <- pop_padrao(pop, ano_ref)
  chave <- c(grupos, "sexo", "faixa")
  d <- pop |> dplyr::group_by(dplyr::across(dplyr::all_of(chave))) |>
    dplyr::summarise(pop = sum(pop), .groups = "drop")
  n <- num |> dplyr::group_by(dplyr::across(dplyr::all_of(chave))) |>
    dplyr::summarise(n = sum(n), .groups = "drop")
  base <- d |> dplyr::left_join(n, by = chave) |>
    dplyr::mutate(n = tidyr::replace_na(n, 0)) |>
    dplyr::left_join(std, by = c("sexo","faixa"))
  out <- base |>
    dplyr::group_by(dplyr::across(dplyr::all_of(grupos))) |>
    dplyr::group_modify(function(.x, .key) {
      a <- epitools::ageadjust.direct(count = .x$n, pop = .x$pop,
                                      stdpop = .x$stdpop, conf.level = conf)
      tibble::tibble(eventos = sum(.x$n), pop = sum(.x$pop),
                     taxa_bruta = por*unname(a["crude.rate"]),
                     taxa_pad   = por*unname(a["adj.rate"]),
                     ic_inf     = por*unname(a["lci"]),
                     ic_sup     = por*unname(a["uci"]))
    }) |> dplyr::ungroup()
  if (suprimir) suprimir_taxa(out) else out
}

#' Taxa BRUTA por grupo (sem padronização), com IC de Poisson exato e supressão N<5.
taxa_bruta <- function(num, pop, grupos, por = 1e5, suprimir = TRUE) {
  n <- num |> dplyr::group_by(dplyr::across(dplyr::all_of(grupos))) |>
    dplyr::summarise(eventos = sum(n), .groups = "drop")
  d <- pop |> dplyr::group_by(dplyr::across(dplyr::all_of(grupos))) |>
    dplyr::summarise(pop = sum(pop), .groups = "drop")
  out <- n |> dplyr::left_join(d, by = grupos) |>
    dplyr::mutate(taxa_bruta = por * eventos / pop)
  if (requireNamespace("epitools", quietly = TRUE)) {
    ic <- epitools::pois.exact(out$eventos, pt = out$pop / por)
    out$ic_inf <- ic$lower; out$ic_sup <- ic$upper
  }
  if (suprimir) suprimir_taxa(out) else out
}

#' Tendência temporal da contagem: quasi-Poisson com offset log(denominador).
#' Retorna razão de taxas por ano (exp do coef) com IC. Ressalva COVID 2020–2021.
#' @param dados data.frame com colunas `ano`, `eventos` e a coluna de offset
#' @param offset_col "pop" (detecção/mortalidade) | "nv" (incidência ao nascimento)
tendencia_poisson <- function(dados, offset_col = "pop", excluir_covid = FALSE) {
  d <- dados
  if (excluir_covid) d <- dplyr::filter(d, !ano %in% ANOS_COVID)
  m <- stats::glm(eventos ~ ano, family = quasipoisson(link = "log"),
                  offset = log(d[[offset_col]]), data = d)
  broom::tidy(m, conf.int = TRUE, exponentiate = TRUE) |>
    dplyr::filter(term == "ano") |>
    dplyr::transmute(razao_taxa_ano = estimate, ic_inf = conf.low, ic_sup = conf.high,
                     p_valor = p.value)
}
