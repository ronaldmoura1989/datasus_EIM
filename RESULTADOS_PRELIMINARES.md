# EIM no DATASUS — Resultados preliminares (primeiro descritivo cross-base)

> Gerado por `scripts/descritivo_cross_base.R` sobre os dados consolidados.
> Janela: SIA/SIH **2021–2025**, SIM **2021–2023** (DATASUS não publicou SIM 2024+).
> **Taxas de detecção/uso e mortalidade registrada — NÃO prevalência.** As três bases
> medem coisas distintas e **não se somam**.

## 1. Volume por base e camada (não somável entre bases)

| Base | n |
|---|---|
| SIA — registros ambulatoriais (core) | 1.048.176 |
| SIA — registros ambulatoriais (**envelope**, teto de subcodificação) | 21.058.893 |
| SIH — AIH com EIM como diagnóstico principal (core) | 26.023 |
| SIH — AIH com EIM em qualquer campo | 154.375 |
| SIM — óbitos com EIM como causa básica | 10.114 |
| SIM — óbitos com EIM em qualquer linha | 10.554 |

O envelope (E78 dislipidemia sobretudo) é **~20× o core** no SIA — confirma que a maior
parte do capítulo E no ambulatorial é doença comum, não EIM raro (tratado como
*bracketing*, nunca caso).

## 2. Doenças-traçadoras × três bases (camada core)

O **perfil de traçadoras difere por base** — não é ruído, é a **janela seletiva por
gravidade/sobrevivência** prevista no plano (SIA = crônicos acompanhados; SIH =
descompensações/TRE; SIM = letais precoces).

| Traçadora | SIA (registros) | SIH (AIH princ.) | SIM (causa básica) |
|---|---|---|---|
| Fibrose cística | 568.665 | 6.442 | 826 |
| Hipotireoidismo congênito | 136.546 | 104 | 26 |
| PKU | 121.400 | 1.391 | 6 |
| Hiperplasia adrenal congênita | 58.291 | 440 | 28 |
| Gaucher/Fabry/Niemann-Pick C (E75.2) | 45.207 | 3.124 | 149 |
| PAF-TTR (amiloidose familiar) | 32.233 | 115 | 16 |
| Wilson | 31.967 | 156 | 72 |
| MPS (outras III/IVA/VI) | 19.955 | 8.030 | 16 |
| MPS II (Hunter, XL) | 10.885 | 1.803 | 19 |
| MPS I | 7.070 | 1.053 | 6 |
| Pompe | 4.679 | 777 | 37 |
| Galactosemia | 1.125 | 47 | 3 |
| Tirosinemia | 727 | 434 | 7 |
| MSUD | 660 | 88 | 10 |
| Ciclo da ureia | 584 | 134 | 30 |
| **Biotinidase (E88.9 proxy/TETO)** | 14.280 | 27.236 | 1.450 |

> **Regra do painel (corrigida):** cada traçadora é contada pelo seu **CID nomeado,
> independentemente da camada**, com a **mesma regra nas três bases** — distinto da
> varredura agregada core/envelope da §1. (Antes, um filtro `camada=="core"` aplicado só
> a SIA/SIH zerava indevidamente Biotinidase e o bloco de contexto nessas colunas.)
>
> **Biotinidase** é EIM de triagem neonatal, mas o MS a codifica em **E88.9** — o mesmo
> balde inespecífico do envelope. Reportada como **linha isolada rotulada "proxy/TETO"**
> (superestima: E88.9 agrega outros distúrbios; a AIH-principal de 27.236 é sobretudo
> ruído inespecífico, não biotinidase real) e **fora** do agregado envelope da §1.
>
> As MPS têm **peso hospitalar desproporcional** (infusões de TRE via AIH).

**Contexto / benchmark — raras NÃO-EIM (nunca somar ao total de EIM):**

| (contexto) | SIA | SIH (princ.) | SIM (causa básica) |
|---|---|---|---|
| Atrofia muscular espinhal (AME) | 45.612 | 3.355 | 59 |
| Hemofilia A | 64.159 | 2.561 | 48 |
| Hemofilia B | 10.424 | 519 | 3 |

## 3. Séries temporais (core) — todas em alta

| ano | SIA | SIH (princ.) | SIM (causa básica) |
|---|---|---|---|
| 2021 | 175.894 | 4.391 | 3.415 |
| 2022 | 198.332 | 4.924 | 3.345 |
| 2023 | 203.508 | 5.330 | 3.354 |
| 2024 | 233.002 | 5.730 | — |
| 2025 | 237.440 | 5.648 | — |

## 4. Taxas padronizadas (idade×sexo, IC gama) por 100 mil hab

**Mortalidade por EIM (causa básica):** estável — **1,69 → 1,65 → 1,66** (2021–2023).

**Internação por EIM (principal, core):** **em alta clara — 2,17 → 2,43 → 2,64 → 2,83**
(2021–2024; 2,79 em 2025), razão de taxas ~+9%/ano. Compatível com expansão de
detecção/TRE, não necessariamente aumento de incidência.

## 5. Mortalidade infantil por EIM / 100 mil nascidos vivos (denominador SINASC)

| ano | óbitos <1 ano | nascidos vivos | por 100 mil NV | IC95% |
|---|---|---|---|---|
| 2021 | 100 | 2.677.101 | **3,74** | 3,04–4,54 |
| 2022 | 96 | 2.561.922 | **3,75** | 3,04–4,58 |
| 2023 | 82 | 2.537.576 | **3,23** | 2,57–4,01 |

## 6. Incidência ao nascimento por traçadora (diferencial do projeto)

Pool 2021–2023, denominador SINASC = 7.776.599 NV. Mortalidade infantil (SIM causa
básica, <1 ano) por 100 mil NV, IC de Poisson exato, supressão N<5.
`scripts/incidencia_nascimento_tracadoras.R` → `manifest/incidencia_nascimento_tracadoras.csv`.

| Traçadora | Óbitos <1a | Mort. inf./100k NV (IC95%) | Detecção 1º ano (SIH AIH / SIA reg.) | Incid. lit. [VERIFICAR] |
|---|---|---|---|---|
| Fibrose cística | 63 | **0,81** (0,62–1,04) | 714 / 50.826 | ~12 |
| HAC | 18 | 0,23 (0,14–0,37) | 220 / 11.471 | ~8 |
| Gaucher/Fabry/NP-C | 10 | 0,13 (0,06–0,24) | 23 / 69 | — |
| Ciclo da ureia | 8 | 0,10 (0,04–0,20) | 14 / 135 | ~3 |
| Pompe | 7 | 0,09 (0,04–0,19) | 43 / 150 | — |
| Hipotireoidismo cong. | 6 | 0,08 (0,03–0,17) | 51 / 38.782 | ~40 |
| MSUD | 6 | 0,08 (0,03–0,17) | 33 / 102 | ~0,8 |
| Galactosemia | 2 | N<5 | 33 / 301 | ~2,5 |
| PKU | 1 | N<5 | 78 / 7.063 | ~10 |
| MPS I/II/outras | 0 | N<5 | 6–72 / 42–114 | — |
| Biotinidase (E88.9 **TETO**) | 71 | 0,91 (0,71–1,15) | 0 / 0 | ~1,7 |

**Leitura:** dissociação incidência × mortalidade infantil separa os dois perfis —
**tratáveis rastreadas** (hipotireoidismo, PKU, FC: alta detecção no 1º ano, mortalidade
infantil baixíssima → triagem+tratamento funcionando) vs **letais precoces** (ciclo da
ureia, MSUD: óbito infantil é o desfecho). **Biotinidase 0,91 é TETO E88.9** (outros
distúrbios metabólicos mortais, não biotinidase real, que rastreada quase não mata).

> **Ressalva:** mortalidade infantil (SIM) é robusta; "detecção 1º ano" via SIA são
> **registros, não crianças** (idade SIA mal preenchida) → intensidade, não incidência.
> Valores de literatura `[VERIFICAR]`.

## 7. Painel COMPLETO do teste do pezinho (tradicional + expandido)

Após re-extração dos 4 CIDs não-EIM ausentes (D57 falciforme, D56 talassemias, D81
IDP/SCID, P371 toxoplasmose congênita) em pipeline isolado (`escopo=painel_pezinho`,
nunca somado às taxas de EIM). `scripts/pezinho_panel.R` → `manifest/pezinho_panel.csv`.
Detecção no 1º ano de vida por 100 mil NV (SINASC). **Não somar entre bases.**

**Tradicional (PNTN):**

| Doença | CID | SIA princ | SIH princ | SIM c.básica | SIH <1a/100k NV | SIM <1a/100k NV |
|---|---|--:|--:|--:|--:|--:|
| **Doença falciforme** | D57 | 1.181.932 | 67.229 | 1.581 | **18,5** | 0,36 |
| Fibrose cística | E84 | 568.665 | 6.444 | 826 | 7,0 | 0,81 |
| Hipotireoidismo cong. | E031 | 136.546 | 104 | 26 | 0,50 | 0,08 |
| PKU | E700 | 120.295 | 1.296 | 6 | 0,69 | 0,01 |
| HAC | E250 | 58.291 | 440 | 28 | 2,16 | 0,23 |
| **Talassemias** | D56 | 35.744 | 980 | 56 | 0,16 | 0,00 |
| Biotinidase (E88.9 TETO) | E889 | 0 | 27.236 | 1.450 | 20,3 | 0,91 |

**Expandido (Lei 14.154/2021):**

| Doença | CID | SIA princ | SIH princ | SIM c.básica | SIH <1a/100k NV | SIM <1a/100k NV |
|---|---|--:|--:|--:|--:|--:|
| Esfingolipidoses | E75 | 48.988 | 3.650 | 271 | 0,33 | 0,15 |
| AME (contexto) | G120 | 45.612 | 3.355 | 59 | 2,95 | 0,10 |
| Mucopolissacaridoses | E76 | 39.634 | 12.608 | 78 | 1,15 | 0,01 |
| **Toxoplasmose congênita** | P371 | 13.468 | 9.502 | 80 | **93,1** | 0,82 |
| **IDP / SCID** | D81 | 9.994 | 637 | 34 | 1,40 | 0,21 |
| Glicogenoses/Pompe | E740 | 4.679 | 777 | 37 | 0,42 | 0,09 |
| FAOD | E713 | 1.708 | 281 | 39 | 0,23 | 0,06 |
| Galactosemia | E742 | 1.125 | 47 | 3 | 0,32 | 0,03 |
| MSUD | E710 | 660 | 88 | 10 | 0,32 | 0,08 |
| Ciclo da ureia | E722 | 584 | 134 | 30 | 0,14 | 0,10 |

**Achados novos (gaps re-extraídos):**
- **Doença falciforme domina o painel**: 1,18M registros SIA, 67 mil AIH, 1.581 óbitos —
  de longe a maior carga do pezinho. Detecção hospitalar no 1º ano 18,5/100k NV.
- **Toxoplasmose congênita**: **maior detecção hospitalar no 1º ano de todo o painel
  (93,1/100k NV)** — coerente com tratamento neonatal prolongado; 80 óbitos.
- **IDP/SCID** (triagem TREC, fase recente): 637 AIH, 34 óbitos, mortalidade infantil
  0,21/100k NV.
- Volume de D57 (~1,24M SIA) é ~como o core EIM inteiro, mas **isolado** em
  `escopo=painel_pezinho` — não contamina nenhuma taxa de EIM.

## Ressalvas
- Detecção/uso ≠ prevalência; grupo heterogêneo (não interpretar "total EIM").
- SIA age é mal preenchida; envelope é teto, não caso; SIM só até 2023.
- Rótulos CID-10 de 4 caracteres e PCDT de algumas traçadoras ainda `[VERIFICAR]`.
