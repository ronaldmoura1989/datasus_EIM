# datasus_EIM — Erros Inatos do Metabolismo no DATASUS

Análise de microdados do DATASUS (SIA-PA, SIH-RD, SIM-DO + SINASC) sobre o grupo dos
**Erros Inatos do Metabolismo (EIM)**, doenças raras. Fork adaptado da engenharia do
projeto de Hidradenite Supurativa (`../../portfolio/data_sus/datasus_HS/`).

- **Metodologia:** [plano_analise_EIM_datasus.md](plano_analise_EIM_datasus.md)
- **Definição de caso (CID→classe):** [scripts/eim_lookup.R](scripts/eim_lookup.R)
- **Lista oficial de raras (crosswalk):** [ref/crosswalk_lista_raras_MS.md](ref/crosswalk_lista_raras_MS.md)

## ⚠️ Estado atual: pipeline corrigido, site pendente de re-render

Correções aplicadas ao **código** (ver `ref/avaliacao_critica_externa.md`):

| # | Correção | Arquivo |
|---|---|---|
| 1 | `eim_causa_basica` passa de `"ampliado"` (core+limítrofe+**envelope**) para **core**, alinhando o SIM a SIA/SIH; `eim_cb_ampliado` guarda o teto | `scripts/get_eim_data_from_SIM.R` |
| 2 | `sia_eim_core.rds` → `sia_eim_core_limitrofe.rds` (o arquivo sempre conteve core+limítrofe) e a página do SIA passa a filtrar `camada == "core"` | `scripts/get_eim_data_from_SIA.R`, `qmd/sia_eim.qmd` |
| 3 | Home: remove "todas as três bases em alta" (falso p/ SIM) e "eixo mais estável e mais robusto"; taxas passam a ser **calculadas**, nunca escritas à mão | `qmd/index.qmd`, `qmd/sim_eim.qmd`, `qmd/discussao.qmd` |
| 4 | Lookup auditada contra a CID-10: E80.3 é catalase/peroxidase (Gilbert = E80.4 → envelope; Crigler-Najjar = E80.5 → core); E85.0/E85.2 são heredofamiliares → core | `scripts/eim_lookup.R` |
| + | Nova seção "composição do numerador" (por camada e por CID de 4 dígitos) na página do SIM | `qmd/sim_eim.qmd` |

**O site em `docs/` ainda mostra os números antigos.** Para regenerar, na máquina que
tem `data/`:

```bash
Rscript scripts/get_eim_data_from_SIA.R      # regrava o rds com o novo nome
Rscript scripts/get_eim_data_from_SIM.R      # cria eim_cb_ampliado / cid_cb / camada_cb
Rscript scripts/descritivo_cross_base.R      # RESULTADOS_PRELIMINARES.md
Rscript scripts/incidencia_nascimento_tracadoras.R
quarto render qmd --output-dir ../docs
```

`qmd/_common.R` tem uma guarda que **aborta o render com mensagem explícita** se os
consolidados ainda forem os antigos, em vez de falhar no meio de um chunk.


## Diferenças estruturais vs HS
1. Alvo = **grupo de centenas de CIDs** (E70–E90 + correlatos) → captura via **lookup**,
   não CID único.
2. **Dois denominadores:** IBGE (uso/detecção) + **SINASC nascidos vivos** (incidência
   ao nascimento das doenças de triagem).
3. **SIM é eixo central** (não exploratório) — EIM grave costuma ser causa básica.
4. **Supressão N<5 é regra estrutural** (raridade extrema).

## Estado atual (Fase 1 quase completa)
- [x] Estrutura de diretórios + `00_setup.R` (janela 2021–2025; SIM 2021–2023)
- [x] `scripts/eim_lookup.R` — 63 prefixos (35 core / 21 limítrofe / 7 envelope), 22
      traçadoras. **Validado**. CIDs das traçadoras confirmados na lista oficial do MS.
- [x] `scripts/utils.R` — núcleo do HS + `classificar_eim()`, `detecta_eim_sim()`,
      `suprimir_taxa()`, `incidencia_nascimento()`; grades `FAIXAS_EIM` (fina) e `FAIXAS_PAD`.
- [x] `scripts/filtrar_cid_remoto.R` — filtragem por CID no remoto **Lika** (via SSH).
      Layouts confirmados: SIA/SIH `x` MAIÚSCULO trimestral; SIM `x` minúsculo anual.
- [x] **Filtragem SIM** concluída (10.554 óbitos EIM 2021–2023) + **consolidado e
      validado** (`get_eim_data_from_SIM.R`): 96% como causa básica, ~100 óbitos
      infantis/ano.
- [x] **Filtragem SIA/SIH/SIM** concluída no remoto + rsync + consolidada.
      SIA: 1,35M registros core+limítrofe (envelope 21M agregado); SIH: 154.375 AIH
      (26.023 principal core); SIM: 10.554 óbitos.
- [x] `get_eim_data_from_{SIA,SIH,SIM}.R` — rodados. SIA em **streaming** (core completo,
      envelope agregado — evita segurar 22M linhas em RAM).
- [x] `get_denominadores_ibge.R` (Censo 2022) + `get_nascidos_vivos_SINASC.R`
      (2021–2024) — **rodados**.
- [x] `calcular_taxas.R` — padronização direta, IC gama, supressão N<5, tendência.
- [x] **`descritivo_cross_base.R` — 1º descritivo das 3 bases rodado** →
      [RESULTADOS_PRELIMINARES.md](RESULTADOS_PRELIMINARES.md).
- [x] **Incidência ao nascimento por traçadora** (`incidencia_nascimento_tracadoras.R`).
- [x] **Painel completo do teste do pezinho** (tradicional + expandido): 4 gaps não-EIM
      (D57/D56/D81/P371) re-extraídos em `eim_filtrado_pezinho/`, consolidados
      (`get_pezinho_gaps.R`) e integrados (`pezinho_panel.R`). Escopo `painel_pezinho`
      isolado das taxas de EIM.
- [x] **Painel Quarto** (`qmd/`) — 5 páginas (index, sia, sih, sim, pezinho),
      **self-contained** (`embed-resources`), renderizado em `docs/` + `.nojekyll` para
      GitHub Pages. Paleta EIM verde-azulado. Ver `docs/index.html`.
- [ ] Próximo: inequidades regionais + mapas detecção×oferta (CNES); custos APAC/TRE;
      pseudo-ID SIA; publicar no GitHub Pages.

## Ver o painel
Abrir `docs/index.html` no navegador (self-contained, funciona offline). Para publicar:
subir `docs/` para o GitHub e ativar Pages apontando para `/docs` (o `.nojekyll` já está lá).

## Fluxo de filtragem no remoto (Lika)
```sh
# por base (roda em ~/eim_scripts, saída em /media/.../eim_filtrado/{BASE}):
Rscript filtrar_cid_remoto.R --base=SIM --ano_min=2021 --ano_max=2023
# SIA paralelo por UF: xargs -P 5 sobre --uf={uf}
# depois, local: rsync -az Lika:/media/prospecmol/disk2/ronald/eim_filtrado/{BASE}/ data/filtered/{base}_eim/
```

## Pendências que dependem de você
- `[VERIFICAR]` rótulos CID-10 de 4 caracteres (portal DATASUS CID10 esteve fora do ar)
  e PCDT/incorporação das traçadoras sem PCDT na lista-FGTS (MSUD, galactosemia, ciclo
  da ureia, MPS II/VI, X-ALD, Wilson).
- SIM-DO 2024+ ainda não disponível no DATASUS (remoto tem até 2023).

## Como rodar (quando os dados chegarem)
```r
# local, na raiz do projeto datasus_EIM/
source("scripts/00_setup.R")   # instala pacotes, carrega lookup + utils
registrar_versao_lookup()      # audita a definição de caso
```
```sh
# no remoto (via ssh), para cada base:
Rscript filtrar_cid_remoto.R --base=SIA --in=/caminho/brutos/SIA --out=/caminho/eim/SIA --fmt=dbc
```
