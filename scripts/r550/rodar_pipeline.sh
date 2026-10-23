#!/usr/bin/env bash
# =============================================================================
# rodar_pipeline.sh — Consolidação + análises + render do painel, série 2010+ (R550-2)
#
# Roda NA CÓPIA do projeto no R550-2 (~/Documentos/ronald/datasus_EIM, sincronizada do
# Mac por rsync, sem .git; data/filtered_2010 → ~/Documentos/ronald/datasus_filtrado).
# Etapas em ordem de dependência; para na 1ª falha; log por etapa em logs/pipeline/.
#
# Uso (dentro de tmux):
#   bash scripts/r550/rodar_pipeline.sh                 # tudo
#   bash scripts/r550/rodar_pipeline.sh --de 06         # retoma a partir da etapa 06
#   bash scripts/r550/rodar_pipeline.sh --ate 05        # só consolidação
#   bash scripts/r550/rodar_pipeline.sh --so-render     # só o Quarto
# =============================================================================
set -uo pipefail
cd "$(dirname "$0")/../.."
# Quarto oficial em ~/opt (o do conda-forge vem quebrado: não acha o deno) + R do env
export PATH="$HOME/opt/quarto-1.9.37/bin:$HOME/miniconda3/envs/datasus/bin:$PATH"
export QUARTO_R="$HOME/miniconda3/envs/datasus/bin/R"
# sf/GDAL precisam achar o banco de projeções do env (sem `conda activate` o PROJ falha
# e st_transform devolve CRS inválido → os mapas quebram no render)
export PROJ_DATA="$HOME/miniconda3/envs/datasus/share/proj" PROJ_LIB="$HOME/miniconda3/envs/datasus/share/proj"
export GDAL_DATA="$HOME/miniconda3/envs/datasus/share/gdal"
DE=00; ATE=99; SO_RENDER=0
while [[ $# -gt 0 ]]; do
  case "$1" in --de) DE=$2; shift 2 ;; --ate) ATE=$2; shift 2 ;; --so-render) SO_RENDER=1; shift ;;
    *) echo "opção inválida: $1"; exit 2 ;; esac
done
LOGD=logs/pipeline; mkdir -p "$LOGD"

ETAPAS=(
  "01 scripts/get_nascidos_vivos_SINASC.R"
  "02 scripts/get_eim_data_from_SIA.R"
  "03 scripts/get_eim_data_from_SIH.R"
  "04 scripts/get_eim_data_from_SIM.R"
  "05 scripts/get_pezinho_gaps.R"
  "06 scripts/descritivo_cross_base.R"
  "07 scripts/incidencia_nascimento_tracadoras.R"
  "08 scripts/pezinho_panel.R"
  "09 scripts/sih_uti.R"
  "10 scripts/sia_procedimentos_sigtap.R"
  "11 scripts/separacao_medicamento_apac.R"
  "12 scripts/feature_eng_pacientes_SIA.R"
  "13 scripts/pseudo_id_PE_recife.R"
  "14 scripts/genetica_sus_procedimentos.R"
)
PAGINAS=(index sia_eim sih_eim sim_eim pezinho pe_eim discussao glossario notas_lancamento)

if [[ $SO_RENDER -eq 0 ]]; then
  for e in "${ETAPAS[@]}"; do
    n=${e%% *}; s=${e#* }
    [[ 10#$n -lt 10#$DE || 10#$n -gt 10#$ATE ]] && continue
    echo "[$(date '+%F %T')] etapa $n: $s"
    t0=$(date +%s)
    if ! Rscript "$s" > "$LOGD/${n}_$(basename "$s" .R).log" 2>&1; then
      echo "[$(date '+%F %T')] FALHA na etapa $n — ver $LOGD/${n}_$(basename "$s" .R).log"
      tail -15 "$LOGD/${n}_$(basename "$s" .R).log"; exit 1
    fi
    echo "    ok em $(( $(date +%s) - t0 ))s"
  done
fi

if [[ 10#$ATE -ge 15 || $SO_RENDER -eq 1 ]]; then
  # Uma página por comando: render em lote funde os .qmd num só .knit.md (ver notas de lançamento)
  for p in "${PAGINAS[@]}"; do
    echo "[$(date '+%F %T')] render $p"
    (cd qmd && quarto render "$p.qmd" > "../$LOGD/render_$p.log" 2>&1) || { echo "FALHA render $p"; tail -20 "$LOGD/render_$p.log"; exit 1; }
  done
fi
echo "[$(date '+%F %T')] pipeline concluído"
