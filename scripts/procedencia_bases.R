# =============================================================================
# procedencia_bases.R — Procedência dos dados por base, a partir do status da filtragem
# (rastreabilidade pedida no parecer 2026-10-25: arquivos, GB, linhas lidas e mantidas
# saem de artefato, nunca digitados no texto). Última execução OK de cada arquivo cujo
# parquet filtrado existe (descarta reexecuções e arquivos fora do manifesto).
# Saída: manifest/procedencia_bases.csv
# Rodar no R550-2: Rscript scripts/procedencia_bases.R
# =============================================================================
source(here::here("scripts", "00_setup.R"))
suppressPackageStartupMessages(library(data.table))
st <- fread(file.path(DIR_FILTRADO, "status_filtro.tsv"), sep = "\t", quote = "")[status == "OK"]
st <- st[order(quando)][, .SD[.N], by = .(base, arquivo)]
existe <- rbindlist(lapply(unique(st$base), function(b)
  data.table(base = b, arquivo = sub("\\.parquet$", "", list.files(file.path(DIR_FILTRADO, b, "filtrado"), pattern = "\\.parquet$")))))
st <- merge(st, existe, by = c("base", "arquivo"))
pr <- st[, .(arquivos = .N, gb_dbc = round(sum(as.numeric(tamanho_dbc)) / 1e9, 1),
             linhas_lidas = sum(as.numeric(n_in)), linhas_mantidas = sum(as.numeric(n_out))), by = base][order(base)]
pr[, pct_mantidas := round(100 * linhas_mantidas / linhas_lidas, 3)]
readr::write_csv(pr, here::here("manifest/procedencia_bases.csv"))
print(pr); message("✓ procedencia_bases.R")
