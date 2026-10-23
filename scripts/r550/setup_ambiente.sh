#!/usr/bin/env bash
# =============================================================================
# setup_ambiente.sh — Ambiente R para os brutos do DATASUS no host R550-2 (SEM sudo)
#
# O R550-2 não tem R nem tmux no sistema e o usuário não tem sudo sem senha. Usa o
# miniconda já instalado (~/miniconda3) para criar o env `datasus` (conda-forge):
# R + compiladores + tmux, e instala pelo R os pacotes do GitHub (read.dbc,
# microdatasus) com as mesmas fontes do projeto (00_setup.R).
#
# Rodar NO R550-2 (dura ~15–30 min; usar nohup):
#   nohup bash setup_ambiente.sh > ~/Documentos/ronald/datasus_raw/logs/setup.log 2>&1 &
# Ativar depois:  source ~/miniconda3/bin/activate datasus
# =============================================================================
set -euo pipefail
CONDA=~/miniconda3/bin/conda
ENV=datasus

if ! $CONDA env list | awk '{print $1}' | grep -qx "$ENV"; then
  echo "[$(date +%T)] criando env $ENV (conda-forge)"
  $CONDA create -y -n "$ENV" --override-channels -c conda-forge \
    r-base=4.4 r-remotes r-data.table r-dplyr r-tidyr r-stringr r-purrr r-tibble \
    r-readr r-here r-janitor r-digest r-arrow r-foreign r-curl r-igraph \
    tmux make pkg-config c-compiler cxx-compiler fortran-compiler
else
  echo "[$(date +%T)] env $ENV já existe — pulando criação"
fi

# make/gcc/gfortran do env precisam estar no PATH (Rscript chamado sem `conda activate`)
export PATH="$HOME/miniconda3/envs/$ENV/bin:$PATH"
RSCRIPT=~/miniconda3/envs/$ENV/bin/Rscript
echo "[$(date +%T)] instalando pacotes do GitHub"
$RSCRIPT -e '
  options(repos = c(CRAN = "https://cloud.r-project.org"))
  gh <- c(read.dbc = "danicat/read.dbc", microdatasus = "rfsaldanha/microdatasus")
  for (p in names(gh)) if (!requireNamespace(p, quietly = TRUE))
    remotes::install_github(gh[[p]], upgrade = "never", dependencies = TRUE)
  falt <- names(gh)[!vapply(names(gh), requireNamespace, logical(1), quietly = TRUE)]
  if (length(falt)) stop("não instalou: ", paste(falt, collapse = ", "))
'

echo "[$(date +%T)] verificação"
$RSCRIPT -e '
  pk <- c("read.dbc","microdatasus","data.table","dplyr","stringr","arrow","janitor","digest","igraph")
  ok <- vapply(pk, requireNamespace, logical(1), quietly = TRUE)
  print(data.frame(pacote = pk, ok = ok, versao = vapply(pk, function(p) if (requireNamespace(p, quietly = TRUE)) as.character(packageVersion(p)) else NA_character_, "")))
  cat(R.version.string, "\n")
  if (!all(ok)) quit(status = 1)
'
~/miniconda3/envs/$ENV/bin/tmux -V
echo "[$(date +%T)] ambiente OK"
