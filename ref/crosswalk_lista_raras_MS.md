# Crosswalk — Lista de Doenças Raras do SUS (MS/CGRAR) × escopo EIM

Fonte: **"Lista de Doenças Raras no âmbito do SUS"** (Coordenação-Geral de Doenças
Raras — CGRAR/DAET/SAES, Ministério da Saúde), elaborada em atenção à **Lei nº
13.932/2019** (saque do FGTS por doença rara). **29 doenças**, todas com **PCDT**.
Extraída de `ref/Lista de Doenças Raras.pdf` (6 páginas) via `pymupdf`.

> **Papel no projeto:** esta lista dá **CIDs oficiais com PCDT** — resolve vários
> `[VERIFICAR]` de código e confirma quais traçadoras têm terapia/protocolo rastreável
> no SUS. Marcada como `pcdt_ms = TRUE` na `eim_lookup.R`. **Não é uma lista de EIM** —
> é uma lista geral de raras; separamos abaixo o que entra no núcleo EIM, no eixo
> triagem/política, e o que é apenas contexto de rede.

## As 29 doenças (CID oficial da lista)

| # | Doença | CID-10 (lista MS) | Classificação no projeto EIM |
|---|---|---|---|
| 1 | Acromegalia | E22.0 | contexto (endócrino, não-EIM núcleo) |
| 2 | Anemia Aplástica | D61.0–.3/.8/.9 | contexto (hematológica) |
| 3 | Anemia Hemolítica Autoimune | D59.1 | contexto (hematológica) |
| 4 | Angioedema Hereditário (C1-INH) | T78.3 | contexto (imuno) |
| 5 | Atrofia Muscular Espinhal (AME) | G12.0 | contexto (neuromuscular) — **na lookup p/ cruzamento** |
| 6 | **Deficiência de Biotinidase** | **E88.9** | **NÚCLEO EIM (triagem)** — ⚠️ MS a coloca no código-envelope E88.9 |
| 7 | Deficiência de GH (Hipopituitarismo) | E23.0 | contexto (endócrino) |
| 8 | Dermatopolimiosite | M33 | contexto (reumato) |
| 9 | **Doença de Fabry** | **E75.2** | **NÚCLEO EIM — traçadora** (lisossômica, XL, TRE) |
| 10 | **Doença de Gaucher** | **E75.2** | **NÚCLEO EIM — traçadora** (lisossômica, TRE imiglucerase) |
| 11 | **Niemann-Pick C** | **E75.2** | **NÚCLEO EIM — traçadora** (lisossômica) |
| 12 | **Doença de Pompe** | **E74.0** | **NÚCLEO EIM — traçadora** (glicogenose II/lisossômica, TRE) |
| 13 | Esclerose Lateral Amiotrófica (ELA) | G12.2 | contexto (neuro) |
| 14 | Esclerose Múltipla | G35 | contexto (neuro) |
| 15 | Espondilite Anquilosante | M45 | contexto (reumato) |
| 16 | **Fenilcetonúria** | **E70.0** | **NÚCLEO EIM — traçadora** (aminoacidopatia, triagem, fórmula) |
| 17 | **Fibrose Cística** | **E84** | **NÚCLEO EIM — traçadora/benchmark** (triagem) |
| 18 | Hemofilia A | D66 | contexto (coagulação) — **na lookup p/ cruzamento** |
| 19 | Hemofilia B | D67 | contexto (coagulação) — **na lookup p/ cruzamento** |
| 20 | Hemoglobinúria Paroxística Noturna | D59.5 | contexto (hematológica) |
| 21 | **Hiperplasia Adrenal Congênita** | **E25.0** | **triagem/política** (fora de E70–E90) |
| 22 | **Hipotireoidismo Congênito** | **E03.1** | **triagem/política** (fora de E70–E90) |
| 23 | **Homocistinúria Clássica** | **E72.1** | **NÚCLEO EIM — traçadora** (aminoacidopatia) |
| 24 | Lúpus Eritematoso Sistêmico | M32.1/.9 | contexto (reumato) |
| 25 | Miastenia Gravis | G70.0 | contexto (neuromuscular) |
| 26 | **Mucopolissacaridose Tipo I** | **E76.0** | **NÚCLEO EIM — traçadora** (lisossômica, TRE laronidase) |
| 27 | Osteogênese Imperfeita | Q78.0 | contexto (óssea) |
| 28 | **Polineuropatia Amiloidótica Familiar** | **E85.1** | **NÚCLEO EIM — traçadora** (amiloidose TTR, EIM tardio) |
| 29 | Púrpura Trombocitopênica Idiopática | D69.3 | contexto (hematológica) |

## Achados que impactam a definição de caso

1. **`E75.2` agrega TRÊS doenças distintas** da lista (Fabry, Gaucher, Niemann-Pick C) —
   **confirma empiricamente a não-separabilidade por CID** apontada no plano. A
   desagregação exige triangular com o **procedimento-APAC da enzima** (imiglucerase ↔
   Gaucher; agalsidase ↔ Fabry) — não o CID.
2. **Def. de biotinidase → `E88.9`** (nosso código-**envelope**). Uma doença de triagem
   neonatal com PCDT "mora" no maior balde inespecífico do capítulo. Consequência:
   `E88.9` **não pode ser lido como envelope puro** — contém pelo menos uma traçadora.
   Marcada na lookup com `tracadora = "Biotinidase"` + `triagem = TRUE`, isolável só por
   contexto (idade neonatal + procedimento/PCDT).
3. **Pompe → `E74.0`** (glicogenoses), não E76 — confirma o alerta de "caçar Pompe fora
   do bloco lisossômico".
4. **PAF/TTR → `E85.1`** — confirma amiloidose familiar como EIM tardio tratável com
   PCDT; distinta da amiloidose adquirida (resto de E85, limítrofe).
5. **HAC (`E25.0`) e Hipotireoidismo congênito (`E03.1`)** estão **fora de E70–E90** —
   entram só no eixo triagem/política, como subgrupos isolados (`escopo = fora_capitulo_E`).

## Traçadoras do plano confirmadas pela lista oficial (PCDT existente)

PKU (E70.0) · Homocistinúria (E72.1) · Pompe (E74.0) · Fabry/Gaucher/Niemann-Pick C
(E75.2) · MPS I (E76.0) · PAF-TTR (E85.1) · Biotinidase (E88.9) · Fibrose cística (E84)
· HAC (E25.0) · Hipotireoidismo congênito (E03.1).

**Traçadoras do plano SEM PCDT nesta lista** (validar incorporação à parte): MSUD,
galactosemia, ciclo da ureia, MPS II/VI, X-ALD, Wilson, Lesch-Nyhan. `[VERIFICAR]` PCDT
/ incorporação CONITEC de cada uma (podem ter protocolo próprio fora desta lista-FGTS).
