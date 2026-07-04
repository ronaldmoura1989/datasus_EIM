# =============================================================================
# sih_uti.R — Uso de UTI e tempo de permanência nas AIH de EIM (SIH-RD)
#
# Dicionário SIH-RD:
#   MARCA_UTI  — código do tipo de UTI usada na AIH; "00" = NÃO usou UTI, demais
#                códigos (74–99, 01…) = usou UTI (por tipo). Derivamos uti = MARCA_UTI != "00".
#   UTI_MES_TO — nº TOTAL de diárias de UTI no mês da AIH.
#   DIAS_PERM  — permanência hospitalar total (dias).
#   QT_DIARIAS — nº total de diárias faturadas (enfermaria + UTI).
#   VAL_UTI    — valor de UTI (consistência: >0 sse usou UTI).
# (Confirmado na base: marca_uti != "00", uti_mes_to>0 e val_uti>0 coincidem em 1.222 AIH principais.)
#
# Reporta, para AIH com EIM PRINCIPAL (core):
#   - proporção de AIH com UTI (global e por traçadora);
#   - permanência total MEDIANA (dias) e diárias de UTI medianas (entre quem usou UTI).
#
# Saída: manifest/sih_uti.csv. Supressão N<5 nas células por traçadora.
# Rodar: source("scripts/00_setup.R"); source("scripts/sih_uti.R")
# =============================================================================

if (!exists("EIM_LOOKUP")) source(here::here("scripts", "00_setup.R"))

sih <- readRDS(here::here("data/consolidated/sih_eim_nacional.rds")) |>
  dplyr::filter(eim_principal) |>
  dplyr::mutate(
    marca_uti = stringr::str_pad(stringr::str_trim(as.character(marca_uti)), 2, pad = "0"),
    usou_uti  = !is.na(marca_uti) & marca_uti != "00",
    diarias_uti = suppressWarnings(as.numeric(uti_mes_to)),
    dias_perm   = suppressWarnings(as.numeric(dias_perm))
  )

# -----------------------------------------------------------------------------
# 1. Global
# -----------------------------------------------------------------------------
resumir <- function(df, rotulo) {
  n_aih <- dplyr::n_distinct(df$n_aih)
  n_uti <- dplyr::n_distinct(df$n_aih[df$usou_uti])
  tibble::tibble(
    grupo          = rotulo,
    aih            = n_aih,
    aih_com_uti    = n_uti,
    pct_uti        = round(100 * n_uti / n_aih, 1),
    perm_mediana   = stats::median(df$dias_perm, na.rm = TRUE),
    # diárias de UTI medianas ENTRE quem usou UTI (0 domina o global, sem informação)
    diarias_uti_mediana_entre_uti =
      if (n_uti >= N_SUPRESSAO)
        stats::median(df$diarias_uti[df$usou_uti & df$diarias_uti > 0], na.rm = TRUE)
      else NA_real_
  )
}

global <- resumir(sih, "TODAS (EIM principal)")

# -----------------------------------------------------------------------------
# 2. Por traçadora (supressão N<5)
# -----------------------------------------------------------------------------
por_trac <- sih |>
  dplyr::filter(!is.na(tracadora)) |>
  dplyr::group_split(tracadora) |>
  purrr::map_dfr(~ resumir(.x, unique(.x$tracadora))) |>
  dplyr::rename(tracadora = grupo) |>
  dplyr::filter(aih >= N_SUPRESSAO) |>
  # suprime pct_uti quando o nº de AIH com UTI é pequeno demais
  dplyr::mutate(
    aih_com_uti = dplyr::if_else(aih_com_uti < N_SUPRESSAO, NA_integer_, as.integer(aih_com_uti)),
    pct_uti     = dplyr::if_else(is.na(aih_com_uti), NA_real_, pct_uti)
  ) |>
  dplyr::arrange(dplyr::desc(aih))

# -----------------------------------------------------------------------------
# 3. Persistir manifest
# -----------------------------------------------------------------------------
manifest <- dplyr::bind_rows(
  dplyr::rename(global, tracadora = grupo),
  por_trac
)
readr::write_csv(manifest, here::here("manifest", "sih_uti.csv"))

cat("\n== UTI nas AIH de EIM principal ==\n")
print(as.data.frame(global))
cat("\n== Por traçadora ==\n")
print(as.data.frame(por_trac))

message(sprintf(
  "\n✓ SIH-UTI: %.1f%% das AIH-EIM (principal) usaram UTI; permanência mediana %.0f dias. → manifest/sih_uti.csv",
  global$pct_uti, global$perm_mediana))
