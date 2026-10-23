#!/usr/bin/env bash
# =============================================================================
# baixar_brutos.sh — Baixa os DBC do manifesto para <raiz>/<destino>/, retomável
#
# Cada arquivo baixa para <nome>.part (wget -c retoma dentro do .part) e só é
# renomeado quando o tamanho bate EXATAMENTE com o do manifesto. Arquivo já
# completo é pulado; arquivo local com tamanho diferente (DATASUS republicou) é
# apagado e baixado de novo. Rodar de novo é seguro: só baixa o que falta.
#
# Uso (NO R550-2, dentro de tmux):
#   bash baixar_brutos.sh [--base SIA-PA|SIH-RD|SIM-DO|SINASC|todas] [--jobs 4]
#                         [--ano-min 2010] [--ano-max 2026] [--uf PE] [--limite N] [--dry-run]
# Log: <raiz>/logs/download_<data>.log ; status por arquivo: <raiz>/logs/status.tsv
# =============================================================================
set -uo pipefail
RAIZ=${RAIZ:-$HOME/Documentos/ronald/datasus_raw}
MANIFESTO=$RAIZ/manifest/manifesto_atual.tsv
BASE=todas; JOBS=4; ANO_MIN=2010; ANO_MAX=2100; UF=""; LIMITE=0; DRY=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --base) BASE=$2; shift 2 ;;   --jobs) JOBS=$2; shift 2 ;;
    --ano-min) ANO_MIN=$2; shift 2 ;; --ano-max) ANO_MAX=$2; shift 2 ;;
    --uf) UF=$2; shift 2 ;;       --limite) LIMITE=$2; shift 2 ;;
    --dry-run) DRY=1; shift ;;    *) echo "opção inválida: $1"; exit 2 ;;
  esac
done
[[ -f $MANIFESTO ]] || { echo "manifesto ausente: rode gerar_manifesto.py"; exit 1; }
mkdir -p "$RAIZ/logs"
LOG=$RAIZ/logs/download_$(date +%Y%m%d).log
STATUS=$RAIZ/logs/status.tsv
[[ -f $STATUS ]] || printf "quando\tstatus\tbase\tarquivo\ttamanho_esperado\ttamanho_local\n" > "$STATUS"

baixar() {   # args: base destino arquivo url tamanho
  local base=$1 destino=$2 arq=$3 url=$4 tam=$5
  local dir=$RAIZ/$destino dest=$RAIZ/$destino/$arq part=$RAIZ/$destino/$arq.part
  mkdir -p "$dir"
  if [[ -f $dest ]]; then
    local atual; atual=$(stat -c%s "$dest")
    if [[ $atual -eq $tam ]]; then return 0; fi
    rm -f "$dest"                                    # republicado: baixa de novo
  fi
  if [[ -f $part && $(stat -c%s "$part") -gt $tam ]]; then rm -f "$part"; fi
  wget -q -c -t 10 --waitretry=30 -T 180 -O "$part" "$url"
  local obtido; obtido=$(stat -c%s "$part" 2>/dev/null || echo 0)
  local st=FALHA
  if [[ $obtido -eq $tam ]]; then mv "$part" "$dest"; st=OK; fi
  ( flock 9; printf "%s\t%s\t%s\t%s\t%s\t%s\n" "$(date '+%F %T')" "$st" "$base" "$arq" "$tam" "$obtido" >> "$STATUS" ) 9>"$STATUS.lock"
  echo "[$(date +%T)] $st $base $arq ($obtido/$tam)"
}
export -f baixar; export RAIZ STATUS

# Seleção do manifesto (pula cabeçalho; ordem do manifesto = SIM, SINASC, SIH, SIA)
SEL=$(awk -F'\t' -v b="$BASE" -v a0="$ANO_MIN" -v a1="$ANO_MAX" -v uf="$UF" \
  'NR>1 && (b=="todas" || $1==b) && $3>=a0 && $3<=a1 && (uf=="" || $4==uf)' "$MANIFESTO")
[[ $LIMITE -gt 0 ]] && SEL=$(printf "%s\n" "$SEL" | head -n "$LIMITE")
N=$(printf "%s\n" "$SEL" | grep -c . || true)
GB=$(printf "%s\n" "$SEL" | awk -F'\t' '{s+=$8} END {printf "%.1f", s/1e9}')
echo "[$(date '+%F %T')] seleção: base=$BASE anos=$ANO_MIN-$ANO_MAX uf=${UF:-todas} → $N arquivos, $GB GB, jobs=$JOBS" | tee -a "$LOG"
if [[ $DRY -eq 1 ]]; then printf "%s\n" "$SEL" | awk -F'\t' '{print $2"/"$6, $8}' | head -20; echo "(dry-run)"; exit 0; fi

printf "%s\n" "$SEL" | awk -F'\t' 'NF{print $1"\t"$2"\t"$6"\t"$7"\t"$8}' |
  xargs -d '\n' -P "$JOBS" -I{} bash -c 'IFS=$'"'"'\t'"'"' read -r b d a u t <<< "$1"; baixar "$b" "$d" "$a" "$u" "$t"' _ {} >> "$LOG" 2>&1

echo "[$(date '+%F %T')] fim da passada" | tee -a "$LOG"
python3 "$(dirname "$0")/verificar_download.py" --raiz "$RAIZ" | tee -a "$LOG"
