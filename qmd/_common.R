# =============================================================================
# qmd/_common.R — Setup compartilhado do painel Quarto (EIM)
# Sourced no chunk de setup de cada .qmd. Carrega params/paleta (00_setup.R),
# motor de taxas (calcular_taxas.R), dados consolidados, tema visual verde-azulado
# e helpers (KPI cards, mapa geobr, tabela flextable, formatação numérica).
# Espelha datasus_HS/qmd/_common.R — paleta e conteúdo adaptados para EIM.
# =============================================================================
suppressPackageStartupMessages({
  library(tidyverse); library(arrow); library(here)
  library(ggpubr); library(scales); library(flextable); library(sf); library(geobr)
})

# Ancora a raiz do projeto independentemente do working dir do Quarto/knitr
here::i_am("qmd/_common.R")

source(here::here("scripts", "00_setup.R"))       # params, PAL_EIM, utils, dirs, lookup
source(here::here("scripts", "calcular_taxas.R")) # taxas_padronizadas(), contar_estrato()...

# Override de funções mascaradas (Bioc/flextable/arrow) — dplyr ganha.
select <- dplyr::select; filter <- dplyr::filter; rename <- dplyr::rename
slice  <- dplyr::slice;  count  <- dplyr::count

# -----------------------------------------------------------------------------
# Dados consolidados (lazy no SIA; RDS em memória nas demais)
# -----------------------------------------------------------------------------
D <- local({
  list(
    sia          = arrow::open_dataset(here::here("data/parquet/sia_eim")),
    sia_env_agg  = readRDS(here::here("data/consolidated/sia_eim_envelope_agg.rds")),
    sia_vol_agg  = readRDS(here::here("data/consolidated/sia_eim_volume_agg.rds")),
    sih          = readRDS(here::here("data/consolidated/sih_eim_nacional.rds")),
    sim          = readRDS(here::here("data/consolidated/sim_eim_nacional.rds")),
    pz_sia       = readRDS(here::here("data/consolidated/pezinho_sia.rds")),
    pz_sih       = readRDS(here::here("data/consolidated/pezinho_sih.rds")),
    pz_sim       = readRDS(here::here("data/consolidated/pezinho_sim.rds")),
    pop          = carregar_pop(),
    nv           = carregar_nv(),
    # Resultados prontos (manifest) — usar direto nas tabelas
    m_tracadora  = readr::read_csv(here::here("manifest/descritivo_tracadoras_cross_base.csv"),
                                   show_col_types = FALSE),
    m_incid      = readr::read_csv(here::here("manifest/incidencia_nascimento_tracadoras.csv"),
                                   show_col_types = FALSE),
    m_pezinho    = readr::read_csv(here::here("manifest/pezinho_panel.csv"),
                                   show_col_types = FALSE)
  )
})

# -----------------------------------------------------------------------------
# Guarda de contrato: as páginas dependem de colunas criadas na consolidação.
# Sem isto, um render feito sobre consolidados ANTIGOS falha com erro obscuro
# ("object 'eim_cb_ampliado' not found") no meio de um chunk.
# -----------------------------------------------------------------------------
local({
  exigir <- function(df, cols, script) {
    faltam <- setdiff(cols, names(df))
    if (length(faltam))
      stop(sprintf(paste0("Consolidado desatualizado: faltam a(s) coluna(s) %s.\n",
                          "  Rode `Rscript %s` antes de renderizar o site.\n",
                          "  (a definição de caso do SIM passou a ser a camada CORE — ",
                          "ver ref/avaliacao_critica_externa.md)"),
                   paste(faltam, collapse = ", "), script), call. = FALSE)
  }
  exigir(D$sim, c("eim_causa_basica", "eim_cb_ampliado", "cid_cb", "camada_cb"),
         "scripts/get_eim_data_from_SIM.R")
  exigir(D$sih, c("eim_principal", "eim_qualquer", "camada_qualquer"),
         "scripts/get_eim_data_from_SIH.R")
  exigir(D$sia_vol_agg, "camada", "scripts/get_eim_data_from_SIA.R")
  exigir(D$sia, c("camada", "escopo", "campo_captura"), "scripts/get_eim_data_from_SIA.R")
})

# -----------------------------------------------------------------------------
# Tema visual e escalas (paleta PAL_EIM — verde-azulado → índigo; 00_setup.R §1)
# -----------------------------------------------------------------------------
theme_eim <- function(base_size = 12) {
  ggpubr::theme_pubr(base_size = base_size, legend = "right") +
    theme(plot.title    = element_text(color = "#0E2F38", face = "bold"),
          plot.subtitle = element_text(color = "#26495C"),
          strip.background = element_rect(fill = "#E1F0EC", color = NA),
          strip.text    = element_text(color = "#0E2F38", face = "bold"),
          panel.grid.major.y = element_line(color = "grey92"))
}
scale_fill_eim  <- function(...) scale_fill_manual(values = PAL_EIM, ...)
scale_color_eim <- function(...) scale_color_manual(values = PAL_EIM, ...)
grad_eim <- function(name = NULL, labels = scales::comma)
  scale_fill_gradient(low = PAL_EIM_GRAD[["low"]], high = PAL_EIM_GRAD[["high"]],
                      name = name, labels = labels)

# -----------------------------------------------------------------------------
# Mapa coroplético por UF (geobr; malha cacheada em data/denominators)
# -----------------------------------------------------------------------------
malha_uf <- function() {
  fp <- here::here("data/denominators/malha_uf.rds")
  if (file.exists(fp)) return(readRDS(fp))
  m <- geobr::read_state(year = 2020, showProgress = FALSE) |>
    sf::st_simplify(dTolerance = 0.01)
  saveRDS(m, fp); m
}

#' Mapa de UF: df precisa de coluna `uf` (sigla) + a coluna de valor.
mapa_uf <- function(df, valor, titulo = NULL, legenda = NULL) {
  m <- malha_uf() |> dplyr::left_join(df, by = c("abbrev_state" = "uf"))
  ggplot(m) +
    geom_sf(aes(fill = .data[[valor]]), color = "white", linewidth = 0.15) +
    grad_eim(name = legenda %||% valor) +
    labs(title = titulo) +
    theme_void(base_size = 12) +
    theme(plot.title = element_text(color = "#0E2F38", face = "bold", hjust = 0.5),
          legend.position = "right")
}

# -----------------------------------------------------------------------------
# Mapa coroplético MUNICIPAL de Pernambuco (geobr; malha cacheada)
# Aditivo — usado apenas pela página pe_eim.qmd. Não altera helpers existentes.
# -----------------------------------------------------------------------------
malha_pe <- function() {
  fp <- here::here("data/denominators/malha_pe.rds")
  if (file.exists(fp)) return(readRDS(fp))
  m <- geobr::read_municipality(code_muni = "PE", year = 2020, showProgress = FALSE) |>
    sf::st_simplify(dTolerance = 0.005) |>
    dplyr::mutate(munic_6 = substr(as.character(code_muni), 1, 6))
  saveRDS(m, fp); m
}

#' Mapa municipal de PE: `df` precisa de `munic_6` (código IBGE 6 díg.) + coluna de valor.
#' O join é por substr(code_muni,1,6) == munic_6 (geobr 7 díg. → DATASUS 6 díg.).
#' @param excluir_munic6 vetor de códigos 6-díg. a remover do POLÍGONO e do JOIN
#'   (ex.: Fernando de Noronha "260545" — arquipélago isolado que distorce o enquadramento).
mapa_municipio_pe <- function(df, valor, titulo = NULL, subtitulo = NULL,
                              legenda = NULL, excluir_munic6 = NULL) {
  malha <- malha_pe()
  if (!is.null(excluir_munic6)) {
    malha <- malha |> dplyr::filter(!munic_6 %in% excluir_munic6)
    df    <- df    |> dplyr::filter(!munic_6 %in% excluir_munic6)
  }
  m <- malha |> dplyr::left_join(df, by = "munic_6")
  ggplot(m) +
    geom_sf(aes(fill = .data[[valor]]), color = "white", linewidth = 0.08) +
    grad_eim(name = legenda %||% valor) +
    labs(title = titulo, subtitle = subtitulo) +
    theme_void(base_size = 12) +
    theme(plot.title    = element_text(color = "#0E2F38", face = "bold", hjust = 0.5),
          plot.subtitle = element_text(color = "#26495C", hjust = 0.5),
          legend.position = "right")
}

# -----------------------------------------------------------------------------
# Pirâmide etária sexo × idade (grade pediátrico-fina FAIXAS_EIM)
# df precisa de colunas `sexo` (Masculino/Feminino), `idade_anos`.
# Masculino à esquerda (negativo), Feminino à direita.
# -----------------------------------------------------------------------------
# Rótulos legíveis para a grade FAIXAS_EIM (o factor bruto tem "0.0833...-0")
.FAIXA_EIM_LABS <- c("<1 mês", "1–11 m", "1–4", "5–9", "10–14", "15–19",
                     "20–29", "30–39", "40–49", "50–59", "60–69", "70–79", "80+")

piramide_etaria <- function(df, titulo = NULL, subtitulo = NULL, unidade = "registros") {
  br <- FAIXAS_EIM
  d <- df |>
    dplyr::filter(!is.na(idade_anos), sexo %in% c("Masculino", "Feminino")) |>
    dplyr::mutate(
      fx_idx = as.integer(cut(idade_anos, breaks = br, right = FALSE,
                              include.lowest = TRUE)),
      faixa  = factor(.FAIXA_EIM_LABS[fx_idx], levels = .FAIXA_EIM_LABS)) |>
    dplyr::filter(!is.na(faixa)) |>
    dplyr::count(sexo, faixa, name = "n") |>
    dplyr::mutate(n_sign = dplyr::if_else(sexo == "Masculino", -n, n))
  lim <- max(abs(d$n_sign))
  ggplot(d, aes(x = faixa, y = n_sign, fill = sexo)) +
    geom_col(width = 0.85) +
    coord_flip() +
    scale_y_continuous(
      labels = function(x) scales::label_number(big.mark = ".",
                             scale_cut = scales::cut_short_scale())(abs(x)),
      limits = c(-lim, lim)) +
    scale_fill_manual(values = c("Masculino" = "#3E5C8A", "Feminino" = "#2E9E96"),
                      name = NULL) +
    labs(x = "Faixa etária", y = paste0("← Masculino  ·  ", unidade, "  ·  Feminino →"),
         title = titulo, subtitle = subtitulo) +
    theme_eim() +
    theme(legend.position = "top")
}

# -----------------------------------------------------------------------------
# Tabela flextable temada (cabeçalho verde EIM)
# -----------------------------------------------------------------------------
tabela_eim <- function(df, titulo = NULL, nota = NULL) {
  ft <- flextable::flextable(df) |>
    flextable::theme_booktabs() |>
    flextable::bg(part = "header", bg = "#1B6F6A") |>
    flextable::color(part = "header", color = "white") |>
    flextable::bold(part = "header") |>
    flextable::fontsize(size = 10, part = "all") |>
    flextable::padding(padding = 4, part = "all") |>
    flextable::autofit()
  if (!is.null(titulo)) ft <- flextable::set_caption(ft, titulo)
  if (!is.null(nota)) ft <- flextable::add_footer_lines(ft, nota) |>
    flextable::fontsize(size = 8, part = "footer") |>
    flextable::color(color = "#26495C", part = "footer")
  ft
}

# -----------------------------------------------------------------------------
# Cartões de KPI (HTML) — uso: cat(kpi_row(list(c(valor,rótulo), ...)))
# -----------------------------------------------------------------------------
kpi_row <- function(cards) {
  itens <- vapply(cards, function(c)
    sprintf('<div class="kpi-card"><div class="v">%s</div><div class="l">%s</div></div>',
            c[[1]], c[[2]]), character(1))
  paste0('<div class="kpi-row">', paste(itens, collapse = ""), "</div>")
}
fmt_n <- function(x) formatC(x, format = "d", big.mark = ".")
fmt_1 <- function(x) formatC(x, format = "f", digits = 1, big.mark = ".", decimal.mark = ",")
fmt_2 <- function(x) formatC(x, format = "f", digits = 2, big.mark = ".", decimal.mark = ",")

`%||%` <- function(a, b) if (is.null(a)) b else a
