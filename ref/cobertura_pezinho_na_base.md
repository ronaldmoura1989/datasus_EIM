# Cobertura do painel do TESTE DO PEZINHO na base DATASUS-EIM

> Verifica QUAIS doenças do teste do pezinho (tradicional PNTN + expandido Lei
> 14.154/2021) estão presentes nas três bases consolidadas (SIA/SIH/SIM) e QUAIS
> ficaram de fora por não terem sido capturadas no filtro de extração remoto
> (`scripts/filtrar_cid_remoto.R::PREF`). Gerado a partir dos `.rds` consolidados.
> Números REAIS rodados em R (blocos abaixo). Data: 2026-07-03.
>
> **Distinção obrigatória:** este projeto tem escopo **EIM metabólico** (E70–E90 +
> HAC/hipotireoidismo de triagem). O **painel do pezinho** é um recorte de *política de
> triagem neonatal* que **cruza** com o EIM mas o **excede** — inclui doenças NÃO-EIM
> (hemoglobinopatias, IDP/SCID, toxoplasmose). Ver §5 para a proposta de marcar isso na
> lookup sem contaminar as taxas de EIM.

---

## 1. Painel do pezinho montado (CID-10 DATASUS, sem ponto)

`etapa`: **T** = tradicional (PNTN, 6 grupos históricos) · **E** = expandido (Lei
14.154/2021, implantação em fases). `eim` = é EIM metabólico (entra no núcleo do
projeto) vs doença de triagem NÃO-EIM (só eixo pezinho).

```r
PEZINHO <- tibble::tribble(
  ~cid,   ~doenca,                                   ~etapa, ~eim,
  # ---- Tradicional (PNTN) ----
  "E700", "Fenilcetonuria (PKU)",                    "T", TRUE,
  "E701", "Hiperfenilalaninemias/BH4",               "T", TRUE,
  "E031", "Hipotireoidismo congenito",               "T", FALSE,
  "D57",  "Doenca falciforme",                       "T", FALSE,   # hemoglobinopatia
  "D56",  "Talassemias",                             "T", FALSE,   # hemoglobinopatia
  "E84",  "Fibrose cistica",                         "T", TRUE,
  "E250", "Hiperplasia adrenal congenita (HAC)",     "T", FALSE,
  "E889", "Deficiencia de biotinidase",              "T", TRUE,    # MS codifica em E88.9
  # ---- Expandido (Lei 14.154/2021) ----
  "E742", "Galactosemia",                            "E", TRUE,
  "E710", "MSUD (leucinose)",                        "E", TRUE,
  "E711", "Acidurias organicas (BCAA)",              "E", TRUE,
  "E713", "FAOD (MCAD/LCHAD/VLCAD)",                 "E", TRUE,
  "E714", "Def. carnitina / CPT",                    "E", TRUE,
  "E721", "Homocistinuria",                          "E", TRUE,
  "E722", "Defeitos do ciclo da ureia",             "E", TRUE,
  "E720", "Outras aminoacidopatias (transporte)",    "E", TRUE,
  "E723", "Aciduria glutarica tipo I",              "E", TRUE,
  "E724", "Metab. ornitina",                         "E", TRUE,
  "E725", "Hiperglicinemia nao cetotica",           "E", TRUE,
  "E75",  "Esfingolipidoses (lisossomicas)",        "E", TRUE,
  "E76",  "Mucopolissacaridoses",                    "E", TRUE,
  "E740", "Glicogenoses / Pompe",                    "E", TRUE,
  "D81",  "Imunodeficiencias primarias (SCID)",     "E", FALSE,   # IDP/imuno
  "G120", "Atrofia muscular espinhal (AME)",         "E", FALSE,   # neuromuscular
  "P371", "Toxoplasmose congenita",                  "E", FALSE   # congenita/infecciosa
)
```

**Observações de codificação (armadilhas):**
- **Toxoplasmose congênita = `P37.1`** (capítulo P, afecções perinatais), confirmado —
  o item da tarefa marcado "[VERIFICAR]" está correto. `P37.0` é tétano congênito,
  `P37.1` é toxoplasmose. Painel expandido usa **P37** de forma ampla; recomenda-se
  filtrar `P371` especificamente.
- **Doença falciforme = `D57`** (D57.0–D57.8); **talassemias = `D56`**. Fazem parte do
  pezinho tradicional desde 2001, mas são **hemoglobinopatias, não EIM**.
- **SCID / IDP = `D81`** (D81.0–D81.9, imunodeficiências combinadas). Triagem por TREC
  é a fase mais recente do expandido.
- **Biotinidase** "mora" em **E88.9** (código-envelope), como já documentado na lookup.
- **AME (G12.0)** entrou na triagem neonatal expandida (SMN1) — já está na lookup como
  contexto e É capturada.

---

## 2. Cobertura na extração (filtro remoto) e GAPS

O filtro remoto (`filtrar_cid_remoto.R`) capturou os prefixos:

```
E70 E71 E72 E73 E74 E75 E76 E77 E78 E79 E80 E83 E84 E85 E88 E90   (núcleo E70–E90)
E250 E031                                                          (triagem fora do E)
G120 D66 D67                                                       (raras contexto)
```

Um CID do pezinho está **coberto** se seu código casa algum desses prefixos. Resultado
real (`str_starts(cid, regex_extr)`):

| CID | Doença | Etapa | EIM | Coberto na extração |
|---|---|---|:---:|:---:|
| E700 | Fenilcetonúria (PKU) | T | sim | **SIM** |
| E701 | Hiperfenilalaninemias/BH4 | T | sim | **SIM** |
| E031 | Hipotireoidismo congênito | T | não | **SIM** |
| **D57** | **Doença falciforme** | T | não | **NÃO** |
| **D56** | **Talassemias** | T | não | **NÃO** |
| E84 | Fibrose cística | T | sim | **SIM** |
| E250 | Hiperplasia adrenal congênita | T | não | **SIM** |
| E889 | Deficiência de biotinidase | T | sim | **SIM** (via E88) |
| E742 | Galactosemia | E | sim | **SIM** |
| E710 | MSUD | E | sim | **SIM** |
| E711 | Acidúrias orgânicas (BCAA) | E | sim | **SIM** |
| E713 | FAOD (MCAD/LCHAD/VLCAD) | E | sim | **SIM** |
| E714 | Def. carnitina / CPT | E | sim | **SIM** |
| E721 | Homocistinúria | E | sim | **SIM** |
| E722 | Ciclo da ureia | E | sim | **SIM** |
| E720 | Outras aminoacidopatias | E | sim | **SIM** |
| E723 | Acidúria glutárica I | E | sim | **SIM** |
| E724 | Metab. ornitina | E | sim | **SIM** |
| E725 | Hiperglicinemia não cetótica | E | sim | **SIM** |
| E75 | Esfingolipidoses | E | sim | **SIM** |
| E76 | Mucopolissacaridoses | E | sim | **SIM** |
| E740 | Glicogenoses / Pompe | E | sim | **SIM** |
| **D81** | **IDP / SCID** | E | não | **NÃO** |
| G120 | AME | E | não | **SIM** |
| **P371** | **Toxoplasmose congênita** | E | não | **NÃO** |

### GAPS de extração — 4 CIDs do pezinho AUSENTES do escopo do filtro

| CID | Doença | Etapa | Motivo |
|---|---|---|---|
| **D57** | Doença falciforme | Tradicional | prefixo D57 nunca esteve no `PREF` (não-EIM) |
| **D56** | Talassemias | Tradicional | prefixo D56 nunca esteve no `PREF` (não-EIM) |
| **D81** | IDP / SCID | Expandido | prefixo D81 nunca esteve no `PREF` (não-EIM) |
| **P371** | Toxoplasmose congênita | Expandido | capítulo P não estava no `PREF` (não-EIM) |

**Todo o núcleo metabólico do pezinho (tradicional + expandido) está coberto.** Os 4
gaps são exatamente as doenças de triagem **não-metabólicas** — coerente com o desenho
do projeto, que filtrou o capítulo E + triagem endócrina. Os gaps não são erro; são
escopo. A questão (§4) é se o painel do pezinho **completo** exige incorporá-los.

---

## 3. Contagens por base — o que já temos (pezinho COBERTO)

Match por prefixo em **qualquer campo de CID** (SIA: `pa_cidpri/sec/cas`; SIH:
`diag_princ/secun/diagsec1..9/cid_asso/cid_morte`; SIM: `causabas/causabas_o/linhaa..d/linhaii`)
e no **campo principal** (SIA `pa_cidpri`; SIH `diag_princ`; SIM `causabas`).

| CID | Doença | SIA princ | SIA qualq | SIH princ | SIH qualq | SIM c.básica | SIM qualq |
|---|---|--:|--:|--:|--:|--:|--:|
| E700 | PKU | 120.295 | 120.324 | 1.296 | 1.326 | 6 | 6 |
| E701 | Hiperfenilalanin. | 1.105 | 1.107 | 95 | 106 | 0 | 0 |
| E031 | Hipotireoidismo cong. | 136.546 | 136.546 | 104 | 426 | 26 | 28 |
| E84 | Fibrose cística | 568.665 | 568.665 | 6.442 | 7.373 | 826 | 832 |
| E250 | HAC | 58.291 | 58.291 | 440 | 601 | 28 | 28 |
| E889 | Biotinidase (E88.9 TETO) | 0 | 9 | 27.236 | 28.624 | 1.450 | 1.517 |
| E742 | Galactosemia | 1.125 | 1.128 | 47 | 58 | 3 | 3 |
| E710 | MSUD | 660 | 660 | 88 | 100 | 10 | 10 |
| E711 | Acidúrias orgânicas | 529 | 538 | 411 | 435 | 11 | 11 |
| E713 | FAOD | 1.708 | 1.710 | 281 | 339 | 39 | 42 |
| E714 | Def. carnitina/CPT | 0 | 0 | 0 | 0 | 0 | 0 |
| E721 | Homocistinúria | 269 | 270 | 16 | 88 | 3 | 3 |
| E722 | Ciclo da ureia | 584 | 585 | 134 | 187 | 30 | 31 |
| E720 | Outras aminoac. | 783 | 784 | 85 | 160 | 23 | 23 |
| E723 | Ac. glutárica I | 331 | 332 | 36 | 46 | 5 | 5 |
| E724 | Metab. ornitina | 60 | 60 | 15 | 21 | 2 | 2 |
| E725 | Hiperglicinemia | 212 | 214 | 60 | 67 | 42 | 42 |
| E75 | Esfingolipidoses | 48.988 | 48.988 | 3.650 | 3.892 | 271 | 276 |
| E76 | Mucopolissacaridoses | 39.634 | 39.634 | 12.608 | 12.716 | 78 | 79 |
| E740 | Glicogenoses/Pompe | 4.679 | 4.679 | 777 | 834 | 37 | 38 |
| G120 | AME (contexto) | 45.612 | 45.612 | 3.355 | 3.469 | 59 | 59 |

**Leituras rápidas:**
- **`E714` (def. carnitina/CPT) = 0 em todas as bases.** Ou o 4º caractere real difere,
  ou é subcodificada em E71.1/E71.8. Alinha com o `[VERIFICAR 4º char]` da lookup.
- **Biotinidase (E88.9)**: SIA principal ≈ 0 mas SIH/SIM altíssimos — confirma que E88.9
  é **balde inespecífico** (TETO), já tratado como "proxy" no descritivo. Não é
  biotinidase real em bloco.
- **E721 (homocistinúria)**: SIH sobe de 16 (principal) para 88 (qualquer) — muito
  aparece como diagnóstico secundário.

### GAPS: o que aparece dos não-cobertos é só CO-OCORRÊNCIA (não confie)

Os CIDs de gap retornam contagens **minúsculas** e apenas porque a AIH/óbito tinha um
EIM *capturado* em outro campo (a extração salvou a linha inteira). Não é a incidência
nacional real dessas doenças:

| CID | SIH diag_princ | SIH em qualquer secundário |
|---|--:|--:|
| D57 (falciforme) | 21 | 23 |
| D56 (talassemias) | 3 | 12 |
| D81 (IDP/SCID) | 0 | 3 |
| P37 (toxoplasmose) | 1 | 2 |

Para dimensionar: a doença falciforme tem **>60 mil internações/ano** no SIH nacional
(ordem de grandeza pública) — capturamos **21 AIH em 5 anos**. Ou seja, o que temos
desses 4 gaps é **ruído de co-ocorrência**, ~0% da carga real. **NÃO usar** essas
contagens para nada além de demonstrar o gap.

---

## 4. Detecção no 1º ano de vida (idade_anos < 1) — pezinho coberto

Denominadores SINASC: **NV 2021–2025 = 10.165.924** (SIH); **NV 2021–2023 = 7.776.599**
(SIM, base só vai até 2023). Taxas por 100 mil NV. (Supressão N<5 **não** aplicada nesta
tabela exploratória — aplicar antes de qualquer publicação.)

| CID | Doença | SIA <1a | SIH <1a (AIH) | SIH/100k NV | SIM <1a | SIM/100k NV |
|---|---|--:|--:|--:|--:|--:|
| E889 | Biotinidase (E88.9 TETO) | 0 | 2.062 | 20,28 | 71 | 0,91 |
| E84 | Fibrose cística | 50.826 | 714 | 7,02 | 63 | 0,81 |
| G120 | AME (contexto) | 2.205 | 300 | 2,95 | 8 | 0,10 |
| E250 | HAC | 11.471 | 220 | 2,16 | 18 | 0,23 |
| E76 | Mucopolissacaridoses | 243 | 117 | 1,15 | 1 | 0,01 |
| E700 | PKU | 6.973 | 70 | 0,69 | 1 | 0,01 |
| E031 | Hipotireoidismo cong. | 38.782 | 51 | 0,50 | 6 | 0,08 |
| E740 | Glicogenoses/Pompe | 150 | 43 | 0,42 | 7 | 0,09 |
| E75 | Esfingolipidoses | 157 | 34 | 0,33 | 12 | 0,15 |
| E742 | Galactosemia | 301 | 33 | 0,32 | 2 | 0,03 |
| E710 | MSUD | 102 | 33 | 0,32 | 6 | 0,08 |
| E711 | Acidúrias orgânicas | 88 | 28 | 0,28 | 6 | 0,08 |
| E713 | FAOD | 171 | 23 | 0,23 | 5 | 0,06 |
| E722 | Ciclo da ureia | 135 | 14 | 0,14 | 8 | 0,10 |
| E720 | Outras aminoac. | 75 | 10 | 0,10 | 1 | 0,01 |
| E725 | Hiperglicinemia | 47 | 9 | 0,09 | 0 | 0,00 |
| E701 | Hiperfenilalanin. | 90 | 8 | 0,08 | 0 | 0,00 |
| E723 | Ac. glutárica I | 39 | 5 | 0,05 | 1 | 0,01 |
| E724 | Metab. ornitina | 22 | 5 | 0,05 | 2 | 0,03 |
| E714 | Def. carnitina/CPT | 0 | 0 | 0,00 | 0 | 0,00 |
| E721 | Homocistinúria | 14 | 0 | 0,00 | 0 | 0,00 |

Isto **complementa** `incidencia_nascimento_tracadoras.R` (que roda só sobre as
*traçadoras nominais* da lookup) — aqui varremos **cada CID do pezinho** (inclui grupos
E711/E713/E720/E723/E724/E725 que não são traçadoras nominais). Não há duplicação: o
script existente é por `tracadora`, este é por `cid` do painel.

> **Ressalva idade SIA** (herdada do descritivo): `idade_anos` no SIA é mal preenchida →
> "SIA <1a" é intensidade de registro, não incidência. SIH (AIH) e SIM (óbito) são
> robustos. Biotinidase 20,28/100k NV via SIH é TETO E88.9, não taxa real.

---

## 5. Avaliação de RE-EXTRAÇÃO

### Precisa re-extrair? Depende do escopo do produto final.

- **Se o objetivo é EIM metabólico** (escopo declarado do projeto): **NÃO re-extrair.**
  100% do núcleo metabólico do pezinho já está na base. Os 4 gaps são não-EIM.
- **Se o objetivo é "cobertura/desempenho do painel do pezinho COMPLETO"** (tradicional
  + expandido, incluindo hemoglobinopatias/IDP/toxoplasmose): **SIM, re-extrair** os 4
  prefixos ausentes — sem eles o painel tradicional fica incompleto (falciforme +
  talassemia são 2 dos 6 grupos históricos do PNTN).

### Prefixos a adicionar ao filtro (`filtrar_cid_remoto.R`, variável `PREF`)

```r
# ADICIONAR a PREF (e sincronizar eim_lookup.R quando aplicável):
"D57",   # doença falciforme (D57.0–D57.8)  — VOLUME MUITO ALTO (ver risco)
"D56",   # talassemias (D56.0–D56.9)
"D81",   # imunodeficiências combinadas / SCID (D81.0–D81.9)
"P371"   # toxoplasmose congênita (usar P371 específico; evitar P37 amplo)
```

### Dimensionamento de risco de VOLUME (crítico para D57)

- **D57 (doença falciforme) é MUITO frequente** — comparável ou pior que o envelope E78.
  Ordem de grandeza pública: **>60 mil internações SIH/ano** e centenas de milhares de
  registros SIA/ano (crônicos em hematologia/hemocentros). Uma re-extração ampla de D57
  **inflaria a base** de forma análoga ao E78 (que sozinho fez o envelope SIA ser ~20× o
  core). **Risco alto de estourar tempo/tamanho** no filtro remoto e no rsync.
  - Mitigação recomendada: extrair D57 em **arquivo/objeto SEPARADO** (não misturar no
    core EIM), com agregação já no remoto (por uf×ano×trimestre×faixa×sexo, como o
    envelope), trazendo **só o agregado** — não os microdados linha a linha.
- **D56 (talassemias)**: volume moderado, seguro extrair em microdados.
- **D81 (IDP/SCID)**: raro, volume baixo, seguro.
- **P371 (toxoplasmose congênita)**: usar o prefixo **específico `P371`** e não `P37`
  amplo (P37 inclui outras infecções congênitas comuns). Volume baixo-moderado.

**Recomendação operacional:** re-extrair **D56 + D81 + P371** como microdados (baixo
custo) e **D57 como AGREGADO separado** (tratamento tipo-envelope), preservando a
separação EIM vs painel-pezinho-completo. Rodar por UF em teste (`--uf=ac`) antes do
nacional para medir o volume real de D57.

---

## 6. Proposta de extensão da `eim_lookup.R`

Marcar a **etapa do pezinho** por CID **sem** contaminar o escopo EIM. Duas colunas
novas (`pezinho_tradicional`, `pezinho_expandido`) e um novo valor de `escopo` para os
não-EIM de triagem.

```r
# Adicionar colunas na tribble EIM_LOOKUP (default FALSE nos demais):
#   ~pezinho_tradicional, ~pezinho_expandido
# Ex. de linhas já existentes que recebem marcação:
#   E700  -> pezinho_tradicional = TRUE
#   E701  -> pezinho_tradicional = TRUE   (hiperfenilalaninemias entram com PKU)
#   E031  -> pezinho_tradicional = TRUE
#   E84   -> pezinho_tradicional = TRUE
#   E250  -> pezinho_tradicional = TRUE
#   E889  -> pezinho_tradicional = TRUE   (biotinidase; ressalva E88.9 TETO)
#   E742,E710,E711,E713,E714,E721,E722,E720,E723,E724,E725,
#   E75,E76,E740 -> pezinho_expandido = TRUE

# NOVAS linhas (não-EIM de triagem) — escopo isolado "painel_pezinho":
"D57",  "doenca_falciforme",     "hemoglobinopatia", "envelope",  "Doenca_falciforme", "AR", TRUE, TRUE,  "painel_pezinho", "Pezinho tradicional. NÃO-EIM. VOLUME MUITO ALTO → tratar como envelope separado.",
"D56",  "talassemia",            "hemoglobinopatia", "core",      "Talassemia",        "AR", TRUE, FALSE, "painel_pezinho", "Pezinho tradicional. NÃO-EIM.",
"D81",  "imunodeficiencia_comb", "imunodeficiencia", "core",      "SCID",              "mista", TRUE, TRUE, "painel_pezinho", "Pezinho expandido (TREC/SCID). NÃO-EIM.",
"P371", "toxoplasmose_congenita","congenita_infecc", "core",      "Toxo_congenita",    NA,   TRUE, FALSE, "painel_pezinho", "Pezinho expandido. Usar P371 específico, não P37 amplo. NÃO-EIM."
```

**Regras para manter a separação:**
1. `escopo == "painel_pezinho"` **nunca** entra em `PREFIXOS_NUCLEO` nem em nenhuma taxa
   de EIM — só no eixo "cobertura do pezinho".
2. Conjuntos derivados novos:
   ```r
   PREFIXOS_PEZINHO_TRAD <- EIM_LOOKUP$prefixo[EIM_LOOKUP$pezinho_tradicional %in% TRUE]
   PREFIXOS_PEZINHO_EXP  <- EIM_LOOKUP$prefixo[EIM_LOOKUP$pezinho_expandido  %in% TRUE]
   PREFIXOS_PEZINHO      <- union(PREFIXOS_PEZINHO_TRAD, PREFIXOS_PEZINHO_EXP)
   ```
3. As taxas de EIM continuam filtrando por `escopo %in% c("nucleo_eim","fora_capitulo_E")`
   — o painel_pezinho fica de fora por construção.
4. Versionar em `manifest/eim_lookup_versao.csv` (a lookup é a definição de caso).

---

## Blocos R efetivamente rodados

Scripts de trabalho: `scratch_pezinho.R` (montagem + cobertura + contagens) e
`scratch_pezinho2.R` (leakage + detecção 1º ano). Reproduzem todas as tabelas acima a
partir de `data/consolidated/*.rds` e `data/denominators/nascidos_vivos.parquet`. Núcleo:

```r
PREF_EXTR <- c("E70","E71","E72","E73","E74","E75","E76","E77","E78","E79","E80",
               "E83","E84","E85","E88","E90","E250","E031","G120","D66","D67")
regex_extr <- paste0("^(", paste(sort(PREF_EXTR), collapse="|"), ")")
PEZINHO <- PEZINHO |> mutate(coberto = str_starts(cid, regex_extr))

norm <- function(v) str_sub(str_trim(toupper(as.character(v))), 1, 4)
conta_cid <- function(df, cols, cid) {
  cols <- intersect(cols, names(df)); hit <- rep(FALSE, nrow(df))
  for (cc in cols) hit <- hit | str_starts(norm(df[[cc]]), fixed(cid))
  sum(hit, na.rm = TRUE)
}
```
