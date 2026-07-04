# =============================================================================
# get_eim_data_from_SIA.R — Consolidação do SIA-PA filtrado por EIM (STREAMING)
# Entrada: data/filtered/sia_eim/sia_{uf}_{ano}_{tri}_eim.rds (filtrado no remoto;
#          data.frame bruto MAIÚSCULO; CID: PA_CIDPRI/PA_CIDSEC/PA_CIDCAS).
#
# ⚠️ VOLUME: a captura nacional tem ~22 M registros, DOMINADA pelo ENVELOPE (E78
#    dislipidemia etc. — SP sozinho ~14 M). Carregar tudo em RAM é inviável.
# ESTRATÉGIA (memória-consciente, plano §9.4):
#   - processa arquivo a arquivo (gc por arquivo);
#   - mantém REGISTROS COMPLETOS só de camada core+limítrofe (raros → cabem em RAM);
#   - agrega o ENVELOPE a CONTAGENS (uf×ano×tri×subgrupo×sexo×faixa + volume/valor):
#     o envelope é teto de subcodificação (bracketing), não precisa de microdados.
# Saídas: data/consolidated/sia_eim_core.rds (core+limítrofe, completo)
#         data/parquet/sia_eim/ (core+limítrofe particionado ano+uf)
#         data/consolidated/sia_eim_envelope_agg.rds (envelope agregado)
#         data/consolidated/sia_eim_volume_agg.rds (volume/valor por estrato, TODAS camadas)
# =============================================================================

source(here::here("scripts", "00_setup.R"))

DIR_SIA <- here::here("data/filtered/sia_eim")
PAT <- "^sia_([a-z]{2})_(\\d{4})_(\\d)_eim\\.rds$"
arqs <- list.files(DIR_SIA, pattern = PAT, full.names = TRUE)
if (!length(arqs)) stop("Nenhum filtrado SIA em ", DIR_SIA, " — rodar rsync primeiro.")

MON <- c("pa_valpro","pa_valapr","pa_vl_cf","pa_vl_cl","pa_vl_inc")

enriquecer <- function(x, uf, ano, tri) {
  cls <- classificar_eim(x$pa_cidpri)
  x |>
    coagir_tipos(monetarias = MON) |>
    dplyr::mutate(
      uf_arquivo = uf, ano = ano, trimestre = tri,
      cid_principal = stringr::str_sub(toupper(pa_cidpri), 1, 4),
      subgrupo = cls$subgrupo, classe = cls$classe, camada = cls$camada,
      tracadora = cls$tracadora, heranca = cls$heranca, escopo = cls$escopo,
      eim_qualquer = eh_eim(pa_cidpri,"ampliado","todos") |
                     eh_eim(pa_cidsec,"ampliado","todos") |
                     eh_eim(pa_cidcas,"ampliado","todos"),
      sexo = dplyr::recode(toupper(stringr::str_trim(pa_sexo)),
                           F="Feminino", M="Masculino", .default=NA_character_),
      raca_cor = dplyr::recode(stringr::str_pad(stringr::str_trim(pa_racacor),2,pad="0"),
                               "01"="Branca","02"="Preta","03"="Parda","04"="Amarela",
                               "05"="Indígena", .default=NA_character_),
      idade_anos = suppressWarnings(as.integer(pa_idade)),
      idade_anos = dplyr::if_else(idade_anos>=0 & idade_anos<=110, idade_anos, NA_integer_),
      faixa = harmonizar_faixa(idade_anos),
      uf_pcn = uf_from_mun(pa_munpcn), regiao = mapear_uf_regiao(uf_pcn),
      competencia = lubridate::ym(pa_cmp),
      qtd_apr = suppressWarnings(as.numeric(pa_qtdapr)),
      fonte = "datasus_sia_pa")
}

message("== SIA-EIM (streaming): processando ", length(arqs), " arquivos ==")
core_lst <- list(); env_lst <- list(); vol_lst <- list()
for (i in seq_along(arqs)) {
  fp <- arqs[i]; meta <- stringr::str_match(basename(fp), PAT)
  uf <- toupper(meta[2]); ano <- as.integer(meta[3]); tri <- as.integer(meta[4])
  x <- readRDS(fp) |> as.data.frame() |> janitor::clean_names()
  log_run("sia", uf, sprintf("%d_T%d", ano, tri), "ok", n_lidas = nrow(x), n_eim = nrow(x))
  if (!nrow(x)) next
  x <- enriquecer(x, uf, ano, tri)
  # (a) core+limítrofe: registros completos
  core_lst[[length(core_lst)+1]] <- dplyr::filter(x, camada %in% c("core","limitrofe"))
  # (b) envelope: só contagens + volume/valor
  env_lst[[length(env_lst)+1]] <- x |> dplyr::filter(camada == "envelope") |>
    dplyr::group_by(uf_pcn, ano, trimestre, subgrupo, sexo, faixa) |>
    dplyr::summarise(n = dplyr::n(), qtd = sum(qtd_apr, na.rm=TRUE),
                     valor = sum(pa_valapr, na.rm=TRUE), .groups="drop")
  # (c) volume/valor por estrato (TODAS as camadas) — intensidade de uso
  vol_lst[[length(vol_lst)+1]] <- x |>
    dplyr::group_by(uf_pcn, ano, camada, subgrupo) |>
    dplyr::summarise(registros = dplyr::n(), qtd = sum(qtd_apr, na.rm=TRUE),
                     valor = sum(pa_valapr, na.rm=TRUE), .groups="drop")
  rm(x); if (i %% 20 == 0) { gc(verbose=FALSE); message("  ...", i, "/", length(arqs)) }
}

# Bind + harmonizar tipos do core
ref <- core_lst[[which.max(purrr::map_int(core_lst, nrow))]]
core <- purrr::map(core_lst, ~ casar_tipos(.x, ref)) |> dplyr::bind_rows()
env  <- dplyr::bind_rows(env_lst) |>
  dplyr::group_by(uf_pcn, ano, trimestre, subgrupo, sexo, faixa) |>
  dplyr::summarise(dplyr::across(c(n,qtd,valor), sum), .groups="drop")
vol  <- dplyr::bind_rows(vol_lst) |>
  dplyr::group_by(uf_pcn, ano, camada, subgrupo) |>
  dplyr::summarise(dplyr::across(c(registros,qtd,valor), sum), .groups="drop")
rm(core_lst, env_lst, vol_lst); gc(verbose=FALSE)

cat(sprintf("\n• core+limítrofe: %d registros | envelope: %d (agregado) registros\n",
            nrow(core), sum(env$n)))
cat("• camada (core+limítrofe):\n"); print(janitor::tabyl(core, camada))
cat("• subgrupos core+limítrofe (top):\n")
print(head(as.data.frame(dplyr::count(core, subgrupo, sort=TRUE)), 20))
cat("• registros por ano (core+limítrofe):\n"); print(dplyr::count(core, ano, name="registros"))

# Persistir
core |> dplyr::mutate(uf = uf_arquivo) |>
  arrow::write_dataset(here::here("data/parquet/sia_eim"),
                       partitioning = c("ano","uf"), format="parquet")
saveRDS(core, here::here("data/consolidated/sia_eim_core.rds"))
saveRDS(env,  here::here("data/consolidated/sia_eim_envelope_agg.rds"))
saveRDS(vol,  here::here("data/consolidated/sia_eim_volume_agg.rds"))
message(sprintf("\n✓ SIA-EIM: %d core+limítrofe (Parquet+rds) + envelope/volume agregados.",
                nrow(core)))
