# Painel de doenças da Triagem Neonatal no SUS — base normativa e mapeamento CID-10

**Projeto:** DATASUS-EIM (erros inatos do metabolismo)
**Objetivo deste documento:** delimitar com precisão o painel do "teste do pezinho" no SUS — o tradicional (PNTN / Portaria GM/MS 822/2001, "Fase IV") e o expandido (Lei 14.154/2021) — para fundamentar o cálculo de incidência/detecção ao nascimento por doença rastreada e para explicitar o que uma extração restrita a **E70–E90** captura ou não captura.
**Data de compilação:** 2026-07 · **Tom:** técnico-cético · **Marcações:** `[VERIFICAR]` onde a fonte é secundária ou o detalhe (nº de portaria, CID exato, data de vigência) não foi confirmado em fonte primária.

> **Aviso metodológico permanente.** Normas do PNTN mudam com frequência. Números de portaria, CIDs de codificação administrativa e datas de vigência por etapa devem ser reconferidos em fonte primária (gov.br/saude — área Triagem Neonatal; BVS Saúde Legis; DOU/in.gov.br) antes de qualquer publicação. Este documento fixa o entendimento verificado até a data acima.

---

## 1. Painel TRADICIONAL — PNTN (Portaria GM/MS 822/2001 e evolução até "Fase IV")

O PNTN foi instituído pela **Portaria GM/MS nº 822, de 06/06/2001**, que estruturou a triagem em **fases de habilitação progressiva** dos estados. A quarta fase (biotinidase + HAC) foi incluída pela **Portaria GM/MS nº 2.829, de 14/12/2012**, e sua implementação nacional só se completou por volta de **2020** `[VERIFICAR ano exato de conclusão em cada UF]`. A **toxoplasmose congênita** foi incorporada posteriormente ao escopo do "pezinho básico" já sob a lógica da Lei 14.154/2021 (Etapa 1) — não constava da Portaria 822/2001 original.

### Tabela 1 — Painel tradicional do PNTN (pré-Lei 14.154)

| Doença | CID-10 (c/ ponto) | CID-10 (s/ ponto) | Classe | Fase PNTN (Port. 822/2001) | Observação |
|---|---|---|---|---|---|
| Fenilcetonúria | E70.0 | E700 | EIM — metabólico (aminoacidopatia) | Fase I | Também E70.1 (outras hiperfenilalaninemias) `[VERIFICAR uso]` |
| Hipotireoidismo congênito | E03.1 | E031 | Endócrino | Fase I | |
| Doença falciforme e outras hemoglobinopatias | D57 (falciforme); D56 (talassemias) | D57 / D56 | Hematológico | Fase II | Escopo inclui variantes; D57.0–D57.8 e D56.- `[VERIFICAR subcategorias adotadas]` |
| Fibrose cística (mucoviscidose) | E84 (E84.0/E84.1/E84.8/E84.9) | E84 | Metabólico/genético multissistêmico | Fase III | Em E80–E90 do capítulo IV, mas **não** é EIM stricto sensu |
| Hiperplasia adrenal congênita (HAC) | E25.0 | E250 | Endócrino | Fase IV (Port. 2.829/2012) | E25.0 = HAC associada a deficiência enzimática |
| Deficiência de biotinidase | E88.9 (codificação administrativa MS) | E889 | EIM — metabólico | Fase IV (Port. 2.829/2012) | **Ressalva:** E88.9 é "distúrbio metabólico não especificado"; o MS usa esse código por ausência de CID-10 específico. Isso **inviabiliza identificar biotinidase por CID** nas bases DATASUS (E88.9 é inespecífico). `[VERIFICAR se há uso de subcódigo local]` |

**Notas críticas:**
- "Fase" (Port. 822) = etapa de habilitação/financiamento dos estados, **não** confundir com "Etapa" da Lei 14.154 (numeração diferente).
- Deficiência de biotinidase e HAC ("Fase IV") só passaram a ser oferecidas de forma universal tardiamente; a série temporal de detecção reflete a **expansão da oferta**, não a incidência real.

---

## 2. Painel EXPANDIDO — Lei 14.154/2021

**Lei nº 14.154, de 26/05/2021** (altera o ECA — Lei 8.069/1990). Define lista mínima de doenças a serem rastreadas, organizada em **5 etapas escalonadas**, com implementação a ser regulamentada pelo MS. A lei entrou em vigor **365 dias após a publicação** (Art. 2º; publicação em 27/05/2021 → vigência a partir de ~27/05/2022). A regulamentação operacional principal veio com a **Portaria GM/MS nº 7.293, de 26/06/2025** (altera as Portarias de Consolidação GM/MS nº 5 e nº 6/2017).

### Tabela 2 — Etapas da Lei 14.154/2021, grupos de doenças e classe

| Etapa | Grupo de doenças | Exemplos de doenças | Faixa CID-10 (aprox.) | Classe predominante | No escopo E70–E90? |
|---|---|---|---|---|---|
| **1** | Painel histórico (7 condições) | Fenilcetonúria/hiperfenilalaninemias; hipotireoidismo congênito; doença falciforme e outras hemoglobinopatias; fibrose cística; HAC; deficiência de biotinidase; **toxoplasmose congênita** | E70.0-E70.1; E03.1; D57/D56; E84; E25.0; E88.9; **P37.1** | Misto (metabólico, endócrino, hematológico, **infeccioso**) | Parcial — ver §4 |
| **2** | Galactosemias; aminoacidopatias; distúrbios do ciclo da ureia; distúrbios da beta-oxidação de ácidos graxos | Galactosemia (E74.2); leucinose/MSUD (E71.0); acidúrias orgânicas (E71.1–E72.-); def. de OTC e outros do ciclo da ureia (E72.2/E72.4); MCAD e outros distúrbios da beta-oxidação (E71.3) | **E70–E74; E72** | EIM — metabólico | **Sim (núcleo do escopo EIM)** |
| **3** | Doenças lisossômicas | Mucopolissacaridoses (E76.-); doença de Pompe (E74.0 — glicogenose II); Gaucher, Fabry, Niemann-Pick, MPS (E75.-/E77.-) | **E74.0; E75; E76; E77** | EIM — metabólico (lisossômico) | **Sim** |
| **4** | Imunodeficiências primárias | SCID e outras IDP (SCID/T-B) | **D80–D84** (ex.: D81.-, D83.-) | Imunológico | **Não** (fora de E70–E90) |
| **5** | Atrofia muscular espinhal (AME) | AME tipo I e outras | **G12.0 / G12.1** | Neuromuscular (genético) | **Não** (fora de E70–E90) |

`[VERIFICAR]` — Os **CIDs por doença das Etapas 2–5 são atribuição analítica deste documento**, não constam textualmente da Lei 14.154 (a lei enumera grupos, não CIDs). Cada CID deve ser confirmado contra o CID-10 vigente e contra a codificação administrativa que o MS/SIA-SUS venha a adotar para os procedimentos de triagem. A meta declarada é expandir para **~50 patologias** ao final do escalonamento — a lista fina de cada etapa é definida em ato infralegal `[VERIFICAR lista nominal na Port. 7.293/2025 e anexos]`.

---

## 3. Datas, portarias e cronograma efetivo (até 2025/2026)

| Ato normativo | Data | Objeto | Status/vigência |
|---|---|---|---|
| Portaria GM/MS 822 | 06/06/2001 | Institui o PNTN; Fases I–III | Vigente (consolidada) |
| Portaria GM/MS 2.829 | 14/12/2012 | Inclui **Fase IV** (biotinidase + HAC) | Implementação concluída ~2020 `[VERIFICAR]` |
| **Lei 14.154** | 26/05/2021 | Triagem ampliada; 5 etapas; ~50 doenças | Em vigor desde ~27/05/2022 (Art. 2º) |
| Portaria GM/MS 1.369 | 06/06/2022 | Inclui procedimentos de triagem na tabela SUS e destina recursos | Vigente `[VERIFICAR escopo]` |
| Pactuação CIT | 29/02/2024 | Reestruturação do PNTN pactuada na CIT | Marco de governança |
| Portaria GM/MS 3.580 | 18/04/2024 | Câmaras Técnicas Assessoras (sangue/hemoderivados e triagem neonatal) | Vigente |
| **Portaria GM/MS 7.293** | 26/06/2025 | **Regulamenta o PNTN ampliado**; altera Port. Consolidação 5 e 6/2017 | Marco regulatório central da Lei 14.154 |
| Portaria GM/MS 9.067 | 02/12/2025 | Reestrutura a Câmara Técnica Assessora do PNTN | Vigente |
| Portaria SAES/MS 3.838 | 24/02/2026 | Designa representantes da Câmara Técnica | Vigente |

**Cronograma efetivo por etapa `[VERIFICAR — crítico]`:**
- **Etapa 1** — em operação (painel histórico + toxoplasmose já ofertados; universalização heterogênea por UF).
- **Etapa 2 (galactosemias, aminoacidopatias, ciclo da ureia, beta-oxidação)** — incorporação prevista/regulamentada pela Port. 7.293/2025; **início efetivo por UF ainda em curso em 2025–2026**. Datas de partida por estado devem ser confirmadas (ex.: notas informativas LACEN estaduais).
- **Etapas 3–5 (lisossômicas, IDP, AME)** — escalonamento posterior; **não universalizadas** até a data deste documento `[VERIFICAR situação em 2026]`.

> **A adesão é estadual e desigual.** Cada UF habilita etapas em ritmo próprio (capacidade laboratorial — espectrometria de massas em tandem para Etapa 2 —, financiamento e pactuação em CIB). Isso é determinante para o §5.

---

## 4. Como cada doença aparece nas bases DATASUS e o problema de cobertura

Ponto central para o projeto: **uma extração restrita a E70–E90 (capítulo IV do CID-10, "Doenças endócrinas, nutricionais e metabólicas", subgrupo dos distúrbios metabólicos) NÃO cobre o painel completo do pezinho.**

### Tabela 3 — Doença × CID × dentro/fora de E70–E90

| Doença | CID-10 | Capturado por extração E70–E90? | Onde aparece nas bases DATASUS |
|---|---|---|---|
| Fenilcetonúria | E70.0 | **Sim** | SIM (causas), SIH/SIA (diagnóstico), SINASC (anomalias — limitado) |
| Deficiência de biotinidase | E88.9 | Sim (faixa), mas **inespecífico** | E88.9 não isola biotinidase — indistinguível de outros distúrbios metabólicos NE |
| Galactosemia | E74.2 | **Sim** | SIH/SIA, SIM |
| Aminoacidopatias (MSUD, acidúrias) | E71.-, E72.- | **Sim** | SIH/SIA, SIM |
| Distúrbios do ciclo da ureia | E72.2 / E72.4 | **Sim** | idem |
| Beta-oxidação (MCAD etc.) | E71.3 | **Sim** | idem |
| Doenças lisossômicas (Pompe, MPS, Gaucher...) | E74.0, E75.-, E76.-, E77.- | **Sim** | idem |
| Fibrose cística | E84.- | **Sim** (faixa E80–E90) | SIH/SIA/SIM — mas não é EIM stricto sensu |
| Hipotireoidismo congênito | **E03.1** | **NÃO** (E00–E07, endócrino) | Fora da faixa metabólica |
| Hiperplasia adrenal congênita | **E25.0** | **NÃO** (E20–E35, endócrino) | Fora da faixa metabólica |
| Doença falciforme / hemoglobinopatias | **D57 / D56** | **NÃO** (cap. III — sangue) | SIH/SIA/SIM; sistema próprio de hemoglobinopatias |
| Toxoplasmose congênita | **P37.1** | **NÃO** (cap. XVI — perinatal/infeccioso) | SINASC/SIM (afecções perinatais); notificação |
| Imunodeficiências primárias (SCID) | **D80–D84** | **NÃO** (cap. III — imunológico) | SIH/SIA/SIM |
| Atrofia muscular espinhal (AME) | **G12.0/G12.1** | **NÃO** (cap. VI — nervoso) | SIH/SIA/SIM; judicialização (nusinersena/onasemnogene) |

**Sinalização explícita — o que NÃO é capturado por extração restrita a E70–E90:**
- Hipotireoidismo congênito (E03.1) e HAC (E25.0) → **endócrino**, faixa E00–E35.
- Hemoglobinopatias (D57/D56) → **cap. III (sangue)**.
- Toxoplasmose congênita (P37.1) → **cap. XVI (perinatal)**.
- Imunodeficiências primárias (D80–D84) → **cap. III (imunológico)**.
- AME (G12.0/G12.1) → **cap. VI (SNC)**.
- Deficiência de biotinidase: dentro de E70–E90 por faixa, mas em **E88.9 inespecífico** → não isolável por CID.

---

## 5. Recomendação de escopo para o eixo "incidência ao nascimento das doenças de triagem"

### 5.1 Definição de dois conjuntos (recomendado trabalhar com ambos, rotulados)

- **Conjunto A — EIM metabólicos stricto sensu (E70–E90 com exclusões):** fenilcetonúria/hiperfenilalaninemias, galactosemias, aminoacidopatias, distúrbios do ciclo da ureia, beta-oxidação, doenças lisossômicas. É o **núcleo do projeto DATASUS-EIM** e o que uma extração E70–E90 captura. **Excluir** fibrose cística e E88.9 (biotinidase) das taxas por CID específico, ou tratá-las com ressalva explícita.
- **Conjunto B — painel completo do pezinho (todas as doenças de triagem):** exige extração **multi-capítulo** (E00–E07, E20–E35, D56–D57, D80–D84, G12, P37.1 além de E70–E90). Necessário se o objetivo for cobrir o painel legal da Lei 14.154, não apenas EIM.

### 5.2 Agrupamento sugerido
Estratificar por (i) classe (metabólico / endócrino / hematológico / infeccioso / imunológico / neuromuscular), (ii) etapa da Lei 14.154, e (iii) fase histórica do PNTN — para permitir leitura tanto clínica quanto de política.

### 5.3 Ressalva epidemiológica central (obrigatória em qualquer produto)
> **A expansão escalonada e desigual por UF confunde "detecção" com "incidência ao nascimento" ao longo da série.** O aumento de casos detectados de uma doença (ex.: HAC pós-2012; galactosemia/aminoacidopatias pós-2022–2025) reflete **ampliação da oferta e da cobertura de triagem**, não necessariamente mudança na incidência real. Consequências:
> - Séries temporais de detecção têm **quebra estrutural** nas datas de habilitação de cada fase/etapa por UF.
> - Comparações interestaduais são **confundidas pela heterogeneidade de adesão** (uma UF sem Etapa 2 terá "incidência zero" artificial de galactosemia).
> - Para estimar **incidência ao nascimento**, o denominador correto é o de **nascidos vivos efetivamente triados para aquela doença naquela UF/ano** (não o total de nascidos vivos do SINASC), sob pena de subestimar sistematicamente a incidência onde a cobertura é parcial.
> - Bases assistenciais (SIH/SIA/SIM) captam **casos que chegaram ao serviço/óbito**, não a triagem populacional — divergem do dado programático do PNTN (que não está integralmente disponível em TabNet público) `[VERIFICAR disponibilidade de dado de produção da triagem por doença]`.

### 5.4 Próximo passo de vigilância/análise
1. Confirmar em fonte primária a **lista nominal e os CIDs** das Etapas 2–5 na Portaria 7.293/2025 e anexos.
2. Levantar, por UF e ano, a **data de habilitação de cada fase/etapa** (para marcar quebras na série).
3. Definir o **denominador de triados por doença** (produção SIA-SUS dos procedimentos de triagem + SINASC), não apenas nascidos vivos.
4. Decidir formalmente escopo **A vs B** conforme a pergunta do eixo, e documentar as exclusões (fibrose cística, E88.9).

---

## Fontes consultadas (verificar sempre a versão vigente)

- Planalto — Lei nº 14.154/2021: https://www.planalto.gov.br/ccivil_03/_ato2019-2022/2021/lei/l14154.htm
- Câmara — texto Lei 14.154/2021: https://www2.camara.leg.br/legin/fed/lei/2021/lei-14154-26-maio-2021-791392-publicacaooriginal-162894-pl.html
- BVS Saúde Legis — Portaria GM/MS 822/2001: https://bvsms.saude.gov.br/bvs/saudelegis/gm/2001/prt0822_06_06_2001.html
- BVS Saúde Legis — Portaria GM/MS 7.293/2025: https://bvsms.saude.gov.br/bvs/saudelegis/gm/2025/prt7293_27_06_2025.html
- MS — Triagem Neonatal / Legislação geral: https://www.gov.br/saude/pt-br/composicao/saes/triagem-neonatal/legislacao/legislacao-geral
- MS — Reestruturação do PNTN (2024): https://www.gov.br/saude/pt-br/assuntos/noticias/2024/junho/ministerio-desenvolve-acoes-para-reestruturar-o-programa-nacional-de-triagem-neonatal
- Senado — sanção da Lei 14.154/2021: https://www12.senado.leg.br/noticias/materias/2021/05/27/sancionada-lei-que-amplia-doencas-rastreadas-em-teste-do-pezinho-do-sus
