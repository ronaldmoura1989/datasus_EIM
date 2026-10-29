# =============================================================================
# get_regioes_saude_pe.R — Tabela de referência: município de PE → região de saúde (GERES)
#                          + população do Censo 2022
#
# Regiões de saúde: geobr::read_health_region(2013), ligadas ao município pelo ponto interno
# do polígono municipal (geobr 2020). Fernando de Noronha fica fora dos polígonos e é da
# I GERES (Recife). A numeração romana das GERES é a da SES-PE.
# População: Censo 2022, SIDRA tabela 4709 (população residente), nível município.
# Saída versionada: ref/pe_regioes_saude.csv (lida por scripts/hotspots_pe.R e pe_eim.qmd).
# Roda no Mac (precisa de internet); o servidor só lê o CSV.
# =============================================================================
suppressPackageStartupMessages({ library(dplyr); library(sf); library(geobr) })
here::i_am("scripts/get_regioes_saude_pe.R")

GERES <- c("Recife" = "I", "Limoeiro" = "II", "Palmares" = "III", "Caruaru" = "IV",
           "Garanhuns" = "V", "Arcoverde" = "VI", "Salgueiro" = "VII", "Petrolina" = "VIII",
           "Ouricuri" = "IX", "Afogados da Ingazeira" = "X", "Serra Talhada" = "XI",
           "Goiana" = "XII")

sf::sf_use_s2(FALSE)
mun <- geobr::read_municipality(code_muni = "PE", year = 2020, showProgress = FALSE) |> sf::st_make_valid()
reg <- geobr::read_health_region(year = 2013, showProgress = FALSE) |>
  dplyr::filter(abbrev_state == "PE") |> sf::st_make_valid() |> sf::st_transform(sf::st_crs(mun))
j <- sf::st_join(sf::st_point_on_surface(mun), reg[, c("code_health_region", "name_health_region")],
                 join = sf::st_within) |> sf::st_drop_geometry()
j$name_health_region[j$code_muni == 2605459] <- "Recife"             # Fernando de Noronha
j$code_health_region[j$code_muni == 2605459] <- reg$code_health_region[reg$name_health_region == "Recife"]
stopifnot(!anyNA(j$name_health_region), all(j$name_health_region %in% names(GERES)))

pop <- jsonlite::fromJSON("https://apisidra.ibge.gov.br/values/t/4709/n6/in%20n3%2026/v/93/p/2022")[-1, ] |>
  dplyr::transmute(code_muni = as.numeric(D1C), municipio = sub(" - PE$", "", D1N), pop_2022 = as.integer(V))
stopifnot(nrow(pop) == nrow(j))

out <- j |>
  dplyr::left_join(pop, by = "code_muni") |>
  dplyr::transmute(munic_6 = substr(as.character(code_muni), 1, 6), municipio,
                   geres = GERES[name_health_region], regiao_saude = name_health_region,
                   cod_regiao_saude = code_health_region, pop_2022) |>
  dplyr::arrange(munic_6)
stopifnot(!anyNA(out$pop_2022))
readr::write_csv(out, here::here("ref/pe_regioes_saude.csv"))
print(dplyr::count(out, geres, regiao_saude, wt = NULL, name = "municipios"))
message("✓ ref/pe_regioes_saude.csv")
