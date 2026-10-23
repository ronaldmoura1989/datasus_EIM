#!/usr/bin/env bash
# =============================================================================
# setup_painel.sh — Completa o env `datasus` do R550-2 para rodar o PROJETO INTEIRO
# (consolidação, análises e render do painel Quarto), não só a filtragem.
# conda-forge para o que existir lá (binários, rápido); o resto via CRAN no R do env.
# Rodar NO R550-2:  nohup bash setup_painel.sh > ~/Documentos/ronald/datasus_raw/logs/setup_painel.log 2>&1 &
# =============================================================================
set -uo pipefail
ENV=datasus
export PATH="$HOME/miniconda3/envs/$ENV/bin:$PATH"
CONDA=~/miniconda3/bin/conda
echo "[$(date +%T)] conda-forge"
# (r-geobr e r-sidrar NÃO existem no conda-forge — e o conda é tudo-ou-nada: um pacote ausente
#  derruba a instalação inteira. geobr vai pelo CRAN, sobre sf/duckdb já binários.)
$CONDA install -y -n "$ENV" --override-channels -c conda-forge \
  r-tidyverse r-lubridate r-naniar r-rstatix r-broom r-epitools r-patchwork r-cowplot \
  r-ggpubr r-flextable r-officer r-gt r-sf r-s2 r-units r-renv r-yaml r-forcats r-biocmanager \
  r-xml2 r-fs r-systemfonts r-textshaping r-ragg r-gdtools r-sass r-bslib r-htmlwidgets \
  r-rmarkdown r-knitr r-lme4 r-nloptr r-car r-pbkrtest r-doby r-rvest r-reprex r-reactable \
  r-duckdb quarto git || { echo "[ERRO] conda falhou"; exit 1; }
echo "[$(date +%T)] CRAN (o que faltar)"
Rscript -e '
  options(repos = c(CRAN = "https://cloud.r-project.org"), Ncpus = 16)
  pk <- c("tidyverse","data.table","arrow","janitor","naniar","rstatix","broom","epitools",
          "ggplot2","scales","patchwork","cowplot","ggpubr","flextable","officer","gt","geobr",
          "sidrar","igraph","renv","yaml","digest","here","lubridate","sf","forcats","knitr","rmarkdown")
  falta <- pk[!vapply(pk, requireNamespace, logical(1), quietly = TRUE)]
  if (length(falta)) install.packages(falta)
  ok <- vapply(pk, requireNamespace, logical(1), quietly = TRUE)
  print(ok[!ok]); if (!all(ok)) quit(status = 1)
'
quarto --version && git --version
echo "[$(date +%T)] painel OK"
