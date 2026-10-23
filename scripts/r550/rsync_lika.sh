#!/usr/bin/env bash
# =============================================================================
# rsync_lika.sh — Traz do Lika para o R550-2 o que vale preservar (roda NO R550-2)
#
# Origem : prospecmol@Lika:/media/prospecmol/disk2/ronald/   (RData do microdatasus)
# Destino: ~/Documentos/ronald/lika/                          (espelho parcial, mesma árvore)
#
# CAMADAS
#   essencial (padrão, ~2,8 GB): todos os scripts (.R .sh .py .qmd .yaml .md, exceto
#     rnaseq/), SIM/datasets (SIM PROCESSADO 2013–2025 — referência p/ validar a
#     decodificação do SIM cru), SIM/raw_opendatasus (2024–2025), SIM/*.pdf, SIA
#     total_atendimentos_* (denominadores 2020–2025), SIH/datasets/old_files e os
#     filtrados (eim_filtrado, eim_filtrado_pezinho, eii_filtrado, cardio_filtrado)
#   --tudo (+ ~96 GB): RData brutos do SIA (76 GB) e SIH (20 GB) 2020–2025 — duplicam
#     os DBC (mesma fonte), mas são a foto de abr/2025 usada pelos projetos HS/EII/cardio
#
# SSH: o /etc/ssh/ssh_config do R550-2 tem opções inválidas (x11userlocalhost) e faz
# o ssh abortar; usa-se um config próprio com -F (que ignora o do sistema).
# Auth: chave dedicada ~/.ssh/id_ed25519_lika (autorizada no Lika) OU agente
# encaminhado (ssh -A) — este último só para dry-run/teste.
#
# Uso: bash rsync_lika.sh [--tudo] [--dry-run]       (dentro de tmux para o --tudo)
# =============================================================================
set -euo pipefail
SRC=prospecmol@150.161.248.197:/media/prospecmol/disk2/ronald
DST=$HOME/Documentos/ronald/lika
CFG=$HOME/.ssh/config_lika
TUDO=0; DRY=""
for a in "$@"; do case "$a" in --tudo) TUDO=1 ;; --dry-run) DRY="--dry-run" ;; *) echo "opção inválida: $a"; exit 2 ;; esac; done

if [[ ! -f $CFG ]]; then
  cat > "$CFG" <<CFGEOF
Host 150.161.248.197
  User prospecmol
  IdentityFile ~/.ssh/id_ed25519_lika
  StrictHostKeyChecking accept-new
  ServerAliveInterval 30
  ServerAliveCountMax 10
CFGEOF
  chmod 600 "$CFG"
fi
mkdir -p "$DST" "$DST/_logs"
LOG=$DST/_logs/rsync_$(date +%Y%m%d_%H%M).log
RS=(rsync -a --partial --info=progress2,stats2 -e "ssh -F $CFG" $DRY)

# Regras de inclusão (ordem importa: rnaseq e datasets brutos fora, salvo o que for incluído)
FILTRO=$(mktemp)
cat > "$FILTRO" <<'EOF2'
- /rnaseq/
- .Rproj.user/
- /SINASC/nao_upar/
+ /SIM/
+ /SIM/datasets/***
+ /SIM/raw_opendatasus/***
+ /SIA/
+ /SIA/datasets/
+ /SIA/datasets/total_atendimentos_*
+ /SIH/
+ /SIH/datasets/
+ /SIH/datasets/old_files/***
+ /eim_filtrado/***
+ /eim_filtrado_pezinho/***
+ /eii_filtrado/***
+ /cardio_filtrado/***
EOF2
if [[ $TUDO -eq 1 ]]; then
  printf '+ /SIA/datasets/sia_*.RData\n+ /SIH/datasets/sih_*.RData\n' >> "$FILTRO"
fi
cat >> "$FILTRO" <<'EOF3'
- /*/datasets/**
- /*/*/datasets/**
+ */
+ *.R
+ *.sh
+ *.py
+ *.qmd
+ *.yaml
+ *.yml
+ *.md
+ *.csv
+ *.pdf
+ *.txt
+ *.log
- *
EOF3

echo "[$(date '+%F %T')] rsync Lika → $DST (tudo=$TUDO ${DRY:+dry-run})" | tee -a "$LOG"
"${RS[@]}" --prune-empty-dirs --filter="merge $FILTRO" "$SRC/" "$DST/" 2>&1 | tee -a "$LOG"
rm -f "$FILTRO"
echo "[$(date '+%F %T')] fim" | tee -a "$LOG"
du -sh "$DST" 2>/dev/null | tee -a "$LOG"
