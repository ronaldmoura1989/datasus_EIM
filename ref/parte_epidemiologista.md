# Erros Inatos do Metabolismo (EIM) no DATASUS — perspectiva EPIDEMIOLÓGICA/SUS

**Os Erros Inatos do Metabolismo (EIM) são um GRUPO HETEROGÊNEO de centenas de
doenças genéticas raras** — defeitos monogênicos de vias metabólicas
(aminoacidopatias, acidúrias orgânicas, defeitos do ciclo da ureia, doenças
lisossômicas de depósito, glicogenoses, defeitos de oxidação de ácidos graxos,
defeitos mitocondriais, defeitos congênitos da glicosilação, entre outros). Este
documento adapta, para os EIM, a metodologia de análise dos microdados do DATASUS
já validada nos projetos de autismo e de **Hidradenite Supurativa** (ver
`../datasus_HS/datasus_hs.md` e `CLAUDE.md`), triangulando **SIA-PA**
(ambulatorial), **SIH-RD** (internações) e **SIM-DO** (mortalidade), com o
**SINASC** como denominador de nascidos vivos. Diferentemente da HS, os EIM têm
**dois denominadores legítimos e complementares** — população geral (IBGE) e
nascidos vivos (SINASC) — e uma **inversão do papel das bases: aqui o SIM é
central, não exploratório**, porque muitos EIM têm o óbito (neonatal/infantil)
como desfecho de referência e frequentemente figuram como **causa básica**.

> **Convenções de marcação:** `[VERIFICAR]` = afirmação que exige confirmação
> documental na fonte oficial (portaria, prevalência, lista de doenças triadas);
> `[CONFIRMAR via fetch_sigtab()]` = código de procedimento/CBO/APAC a validar na
> competência correta do SIGTAP. Princípio inegociável do projeto: **nunca
> inventar** CID, procedimento, CBO, portaria, valor de repasse ou número de
> prevalência.

> Guia operacional (stack, runbook, convenções de código): reaproveitar o padrão
> de **`../datasus_HS/CLAUDE.md`**, adaptando CID-alvo, camadas de captura e a
> adição do denominador SINASC.

---

## 1. Desenho do estudo e unidade de análise

Trata-se de um **estudo ecológico/descritivo de séries temporais sobre dados
secundários administrativos**, cuja **unidade de análise é o registro/atendimento
(ou o óbito, no SIM), não o indivíduo**. Não há identificador longitudinal no
DATASUS público (SIA/SIH); o SIM registra o evento-óbito por indivíduo, mas sem
encadeamento com atendimentos prévios. Toda associação observada (EIM × região,
EIM × idade, EIM × comorbidade) está sujeita à **falácia ecológica** e **não
autoriza inferência individual ou causal**.

As bases têm unidades e denominadores distintos e **NÃO são somáveis**: um mesmo
paciente gera N registros SIA + M internações SIH ao longo da vida, e no limite 1
óbito no SIM. Somar "casos" entre bases é dupla contagem. Cada base responde a uma
pergunta própria (acesso/uso ambulatorial · carga e permanência hospitalar ·
mortalidade e causa básica) e é reportada **em paralelo**, nunca consolidada num
"total de casos EIM".

### Particularidade estrutural dos EIM: grupo heterogêneo

Diferentemente da HS (uma entidade, um CID nuclear `L732`), **EIM não é uma
doença — é um agrupamento de centenas de entidades** com epidemiologia, idade de
apresentação, gravidade, tratamento e mortalidade radicalmente distintos (uma
fenilcetonúria tratada tem prognóstico muito diferente de uma acidúria orgânica
grave ou de uma doença lisossômica de depósito). Consequência metodológica
central: **a análise deve ter granularidade em três níveis simultâneos**, nunca
apenas o guarda-chuva agregado.

| Nível de granularidade | O que é | Papel analítico |
|---|---|---|
| **Grupo (guarda-chuva EIM)** | Bloco CID-10 **E70–E90** (distúrbios metabólicos) + entradas relevantes fora do bloco `[VERIFICAR escopo]` | Carga total / visão macro; **teto agregado**, baixa especificidade clínica |
| **Subgrupos** | Aminoacidopatias (E70–E72), metabolismo de carboidratos (E73–E74), lipídios (E75, incl. lisossômicas), outros (E76–E83, E88…) `[VERIFICAR mapeamento]` | Perfis distintos de idade/mortalidade/custo; unidade de comparação regional |
| **Doenças traçadoras** | CID específicos de alta prioridade: fenilcetonúria (E700), doenças da triagem neonatal ampliada, doenças com TRE incorporada (ex.: Gaucher, MPS, Pompe) `[VERIFICAR CID e incorporação CONITEC]` | Ancoragem em política (PNTN, doenças raras); análise nominal defensável |

> **Princípio da agregação:** relatar **sempre** o guarda-chuva E70–E90 **e** a
> decomposição por subgrupos **e** um conjunto fechado de traçadoras. O número
> agregado de "EIM" isolado é enganoso — mistura entidades incomparáveis e é
> dominado por códigos inespecíficos. As três camadas devem aparecer lado a lado.

### O que é legitimamente inferível × NÃO inferível

| **Legitimamente inferível** | **NÃO inferível com este desenho** |
|---|---|
| Carga de uso de serviço (intensidade ambulatorial/hospitalar) por grupo/subgrupo | Prevalência / incidência **verdadeiras** de EIM na população |
| Padrões de codificação e qualidade do dado (completude, CID inespecífico) | Risco individual; causalidade; penetrância |
| Gasto **atribuível por codificação** (TRE/APAC, internação, fórmulas) | Trajetória do paciente; adesão real ao tratamento |
| Distribuição espacial da **detecção** e da **oferta** (centros de referência) | Distribuição espacial da **doença** (confundida por acesso/triagem) |
| Perfil demográfico **dos registros/óbitos** (≠ da doença na população) | Perfil do EIM na população viva (viés de gravidade e de sobrevivência — §2) |
| **Mortalidade por EIM** (SIM: causa básica + linhas) — desfecho de referência | Letalidade real (denominador de casos verdadeiros é desconhecido) |
| **Incidência ao nascimento por 100 mil NV** para doenças de **triagem neonatal** (proxy, §3) | Incidência verdadeira de EIM **não triados** (invisíveis até adoecer/morrer) |

> **Princípio interpretativo único, repetido em cada eixo e em cada `.qmd`:** o
> que se mede são **taxas de detecção/uso de serviço e de mortalidade
> registrada**, não prevalência nem incidência verdadeiras — exceto a
> aproximação de **incidência ao nascimento** para as doenças efetivamente
> cobertas pela triagem neonatal, e ainda assim condicionada à cobertura e à
> etapa vigente do teste do pezinho (§3, §5). Reforçar nominal e visualmente
> (rótulos de eixo, títulos, nota de rodapé em toda tabela).

---

## 2. Assimetria de captura entre bases (definição de caso NÃO é comparável)

Cada base captura o CID em campos diferentes e com regras diferentes. **A "taxa
SIA", a "taxa SIH" e a "taxa SIM" não medem o mesmo conceito de caso** e não
devem ser somadas nem comparadas trivialmente. Onde o(s) CID de EIM aparece(m):

| Base | Campo(s) de diagnóstico | Regra de captura | Observação para EIM |
|---|---|---|---|
| **SIA-PA** | `pa_cidpri` (principal) — nesta extração **sem** `pa_cidpec`/secundários | **1 CID por registro** | Um EIM em acompanhamento gera muitos registros/ano (consultas genética/nutrição, fórmulas, exames, TRE). Numerador **inflado** = intensidade de uso. **APAC (alto custo/TRE)** tende a ter CID melhor preenchido; produção de baixa complexidade subcodifica. |
| **SIH-RD** | `diag_princ` + `diag_secun` + `diagsec1`…`diagsec9` | Principal **OU** qualquer secundário | EIM frequentemente entra como **secundário** de uma descompensação (sepse, acidose, convulsão, IRA). Reportar em **dois sabores separados** (abaixo). |
| **SIM-DO** | `causabas` (causa básica) + `linhaa`–`linhad` (Parte I) + `linhaii` (Parte II) | Qualquer campo; cada célula pode ter **vários CIDs** e marcadores `†`/`*` | **Central para EIM** — ver destaque abaixo. Normalizar (remover daga/asterisco) e extrair todos os códigos por célula. |

### SIH em dois sabores (regra fixa, herdada do HS §2)

- **(a) `diag_princ` = EIM** — motivo principal da internação (estritamente
  comparável ao conceito do SIA). Em EIM tende a subestimar, pois a internação é
  frequentemente rotulada pela **descompensação aguda**, não pela doença de base.
- **(b) EIM em qualquer campo** — `if_any` sobre `diag_princ` + `diag_secun` +
  `diagsec1..9` presentes. Capta o EIM como comorbidade de base da internação.
- **Nunca misturar os dois nem somar com o SIA.**

> **⚠️ Alerta de extração (herdado do HS §7.1):** se os brutos do SIH forem
> pré-filtrados pelo usuário **apenas por `diag_princ`**, o sabor "qualquer campo"
> **não é recuperável** e subestimará gravemente a carga hospitalar de EIM (que
> vive nos secundários). **Decidir cedo:** para EIM, o sabor "qualquer campo" é
> **essencial** — provavelmente será necessário **re-extrair do RD completo**, não
> aceitar filtro só por principal. `[VERIFICAR filtro aplicado nos brutos]`.

### DESTAQUE — em EIM o SIM é a base CENTRAL (inversão vs HS)

Na HS o SIM era exploratório (doença quase nunca é causa de óbito; N≈65, só 1 como
causa básica). **Em EIM ocorre o oposto:**

1. **Muitos EIM graves têm o óbito como desfecho de referência** — acidúrias
   orgânicas, defeitos do ciclo da ureia, doenças mitocondriais e lisossômicas de
   depósito cursam com **mortalidade neonatal/infantil elevada**, muitas vezes
   **antes de qualquer diagnóstico ambulatorial** (o paciente morre sem passar
   pelo SIA). Logo o SIM captura casos que **nunca aparecem** nas outras bases.
2. **O EIM tende a ser CAUSA BÁSICA (`causabas`)**, não apenas contribuinte —
   diferente da HS. A doença metabólica hereditária é a raiz da cadeia causal que
   leva ao óbito, então figura legitimamente na causa básica ou nas linhas da
   Parte I. Isso torna a **mortalidade um resultado central e não exploratório**.
3. **Óbito neonatal/infantil por EIM é um indicador de saúde pública próprio** —
   dialoga com mortalidade infantil evitável, oportunidade da triagem neonatal e
   vazios diagnósticos (§4, §5). Deve ser tratado como **eixo principal**, com
   análise de **idade ao óbito** e **causas múltiplas** (todas as linhas), não só
   `causabas`.

> **Regra de captura no SIM:** rodar `normalizar_cid_sim()` sobre `causabas` +
> todas as linhas; classificar cada óbito em **(i) EIM como causa básica** vs
> **(ii) EIM mencionado em qualquer linha (causa múltipla)** e reportar os dois.
> A menção em causa múltipla capta EIM subjacente a um óbito atribuído à
> descompensação aguda — análogo ao "qualquer campo" do SIH.

### Viés de sobrevivência e de gravidade (consequência analítica)

- **SIM** enviesa para os EIM **mais letais e de apresentação precoce**.
- **SIA** enviesa para os EIM **tratáveis e cronicamente acompanhados** (o
  paciente sobrevive para gerar registros: fenilcetonúria em dieta, doenças com
  TRE). Os EIM que **matam antes do diagnóstico** ficam invisíveis no SIA.
- **SIH** fica em posição intermediária (descompensações agudas).
- Portanto o **perfil de subgrupos difere sistematicamente entre bases** — não é
  ruído, é estrutura. Ler cada base como uma **janela seletiva** distinta do
  espectro EIM, e explicitar isso em toda comparação inter-base.

---

## 3. Denominadores e taxas — DOIS denominadores complementares

Ao contrário da HS (que só tinha o denominador populacional geral), os EIM exigem
**dois denominadores distintos**, cada um respondendo a uma pergunta diferente.
Usar o denominador errado gera um indicador sem sentido.

### (a) População geral IBGE → taxas de detecção/uso e de mortalidade

- **Pergunta:** qual a intensidade de uso de serviço (SIA/SIH) e a mortalidade
  (SIM) por EIM na população, por UF/região e no tempo.
- **Fonte:** população residente por **UF × sexo × faixa etária** via **`sidrar`**
  (API SIDRA/IBGE), usando a população do **ano-calendário** de cada numerador.
- **Métrica:** casos/registros/óbitos por **100.000 habitantes**, **brutos e
  padronizados por idade e sexo lado a lado, com IC pelo método gamma**
  (`epitools::ageadjust.direct()`). Padronização direta é indispensável porque os
  EIM concentram-se em idade pediátrica (§4) e UFs têm estruturas etárias
  diferentes; comparar UFs sem padronizar confunde carga com pirâmide etária.
- **Interpretação:** são índices de **DETECÇÃO/USO e de MORTALIDADE REGISTRADA**,
  não de prevalência. Rotular como "casos registrados por 100 mil" / "óbitos por
  100 mil", nunca "prevalência".

### (b) Nascidos vivos (SINASC) → incidência ao nascimento (diferencial dos EIM)

- **Pergunta:** para os EIM cobertos pela **triagem neonatal (teste do pezinho)**,
  quantos casos incidem **ao nascimento** — o denominador natural de uma doença
  congênita detectada logo após o parto.
- **Fonte:** **nascidos vivos (SINASC)** por **UF × ano** (e, quando útil, por
  sexo e características maternas), via `microdatasus`/DATASUS.
- **Métrica:** **casos por 100.000 NV** (ou por 100 mil NV do ano de nascimento) —
  uma **proxy de incidência ao nascimento**, defensável **apenas** para as doenças
  efetivamente triadas e no numerador correspondente (idealmente casos
  identificados no 1º ano de vida, ou óbitos neonatais/infantis por aquele EIM).
- **Uso duplo:**
  - **Numerador SINASC-based no SIM:** óbitos infantis por EIM ÷ NV do mesmo ano =
    **coeficiente de mortalidade infantil específico por EIM** (por 100 mil NV) —
    indicador de saúde pública direto, comparável à mortalidade infantil geral.
  - **Numerador de detecção precoce:** registros/APAC de doença triada em <1 ano
    ÷ NV = proxy de **incidência detectada ao nascimento**.

> **⚠️ O denominador SINASC só vale para EIM de triagem neonatal.** Aplicar NV como
> denominador a um EIM de apresentação tardia (p.ex. doença lisossômica de início
> juvenil/adulto) produz um número **sem sentido epidemiológico**. **Regra:** cada
> traçadora/subgrupo tem **um denominador designado** — NV (SINASC) para as
> congênitas de detecção precoce; população geral (IBGE) para as de curso crônico
> em qualquer idade. Documentar a escolha por traçadora numa tabela de
> mapeamento denominador↔doença.

### Qual denominador para qual pergunta

| Pergunta / numerador | Denominador correto | Métrica | Ressalva |
|---|---|---|---|
| Uso ambulatorial (SIA), qualquer EIM | População IBGE (UF×sexo×idade) | Registros/100 mil hab (padronizada) | Intensidade de uso, não prevalência |
| Internações (SIH), qualquer EIM | População IBGE | Internações/100 mil hab (padronizada) | Somar AIH distinta, não linha |
| Mortalidade geral por EIM (SIM) | População IBGE | Óbitos/100 mil hab (padronizada) | Causa básica vs qualquer linha (§2) |
| **Mortalidade infantil por EIM** | **NV do ano (SINASC)** | Óbitos <1 ano / 100 mil NV | Coeficiente específico; comparar à MI geral |
| **Detecção ao nascimento** (doença triada) | **NV do ano (SINASC)** | Casos <1 ano / 100 mil NV | Só p/ doenças efetivamente triadas |

### Harmonização, degrau do Censo 2022 e supressão de células (crítico em doença rara)

- **Harmonização de faixas etárias (pré-requisito da padronização).** Definir
  **faixas canônicas únicas** e aplicar a **mesma** função de faixa ao numerador
  (idade do paciente/óbito, respeitando a unidade `cod_idade` do SIM/SIH e
  `pa_idade` do SIA) **e** ao denominador IBGE. **Para EIM, refinar a faixa
  pediátrica** (a grade quinquenal do HS é grossa demais): usar cortes
  **<1 mês (neonatal) · 1–11 meses · 1–4 · 5–9 · 10–14 · 15–19 · 20+** para
  capturar a apresentação neonatal/infantil e a idade ao óbito. Faixas
  não-idênticas numerador↔denominador invalidam a taxa.
- **Degrau do Censo 2022.** A série 2020–2025 combina metodologias: 2020–2021
  (estimativas pós-Censo 2010), 2022 (Censo 2022, que revisou a população para
  baixo) e 2023–2025 (pós-Censo 2022). Isso cria um **degrau artificial** que pode
  ser confundido com mudança real de detecção/mortalidade. **Decisão:**
  retrointerpolar a partir do Censo 2022 para toda a série e/ou sinalizar a quebra.
  O denominador **SINASC** tem descontinuidade própria (cobertura/completude do
  registro de nascimento variável no espaço/tempo) — `[VERIFICAR]` completude do
  SINASC por UF/ano antes de usá-lo como denominador fino.
- **Supressão N<5 (LGPD — MAIS crítico que na HS).** EIM são **raros e
  fragmentados em centenas de subentidades**; estratos finos (UF × subgrupo × faixa
  pediátrica × ano) terão frequentemente **N=1–2**, potencialmente
  **reidentificáveis** (uma criança com doença rara num município pequeno). **Regra
  reforçada:** suprimir toda célula com `N < 5` na divulgação; **agregar por
  região** (não UF) e por **subgrupo** (não traçadora nominal) quando o N for
  baixo; nunca publicar cruzamentos finos. Taxas sobre numeradores pequenos são
  **instáveis** — reportar **sempre com IC** e evitar ranking de UFs por taxas
  baseadas em <10 eventos.

---

## 4. Eixos de análise acionáveis (adaptados a EIM)

> **Ressalva COVID-19 transversal a todo eixo de série temporal.** Em 2020–2021
> houve colapso da produção ambulatorial e de procedimentos eletivos no SUS, além
> de queda de acesso a serviços de genética/referência e possível impacto sobre a
> triagem neonatal. Qualquer série 2020–2025 mostrará **depressão 2020–2021 +
> recuperação que é artefato de oferta pandêmica, não tendência da doença**.
> Tratar 2020–2021 como **período anômalo** na narrativa e na modelagem.

1. **Rede de referência e triagem neonatal — vazios assistenciais.** Mapear, via
   **CNES**, os **Serviços de Referência em Triagem Neonatal (SRTN)** e centros
   que registram EIM (genética médica, TRE/alto custo); cobertura territorial e
   **vazios diagnósticos** (regiões sem oferta apesar de população/NV esperados).
   Confundimento dominante por oferta: a "taxa de detecção de EIM por UF" e a
   "densidade de serviços de referência" estão entrelaçadas → variação geográfica
   mede majoritariamente **acesso, não doença**. Reportar **dois mapas lado a lado
   (detecção × oferta)**.

2. **Perfil etário pediátrico e sexo.** Ênfase na **faixa neonatal/infantil**
   (pirâmide com a grade fina do §3); a maioria dos EIM é de apresentação precoce.
   Sexo: em geral sem forte predomínio, **exceto entidades ligadas ao X**
   (p.ex. deficiência de OTC no ciclo da ureia; MPS II/Hunter) `[VERIFICAR]` →
   avaliar razão de sexo **por subgrupo/traçadora**, não no agregado. Testar
   tendência com Poisson (item 8), não só descrever a curva.

3. **Internações e permanência.** Taxa de internação; **permanência**
   (`dias_perm`) — EIM descompensado gera internações longas em UTI; proporção com
   procedimento crítico (diálise, suporte metabólico); **reinternação** como proxy
   de gravidade/instabilidade metabólica (limitado — sem ID longitudinal).
   Reportar SIH nos **dois sabores** (§2) e não somar com SIA.

4. **MORTALIDADE (eixo central — §2).** (a) **Idade ao óbito** por subgrupo
   (distribuição concentrada em <1 ano para os graves); (b) **mortalidade infantil
   por EIM** por 100 mil NV (denominador SINASC, §3), comparável à MI geral;
   (c) **causa básica vs causa múltipla** (todas as linhas) — quantificar o
   **sub-registro** medindo quanto do EIM aparece só nas linhas e não em
   `causabas`; (d) proporção de óbitos por EIM com **CID inespecífico** (E88.x,
   códigos-guarda-chuva) — indicador de baixa especificidade diagnóstica.

5. **Custos.** Componentes **separados** (nunca um "total" sem ressalva):
   **TRE de alto custo via APAC** (terapia de reposição enzimática — Gaucher,
   MPS, Pompe etc. `[VERIFICAR incorporação CONITEC e código APAC]`); **fórmulas
   metabólicas especiais** (dietas isentas/modificadas — via componente
   especializado/judicial `[VERIFICAR fluxo de custeio]`); **transplantes**
   (hepático/medula em EIM selecionados) via SIH. Reportar `pa_valapr` (SIA) e
   `val_tot`/`val_sh`/`val_sp` (SIH). A TRE domina o gasto e é **fortemente
   judicializada** — o dado administrativo não distingue via judicial de
   administrativa (§6).

6. **Inequidades regionais.** Taxas padronizadas por região/UF com IC; razão de
   taxas. **Tensão interpretativa dupla:** Sul/Sudeste tendem a **maior detecção**
   por concentração de serviços de referência (viés de oferta), enquanto o
   **Nordeste** pode ter **maior incidência real** de EIM autossômicos recessivos
   por **maior consanguinidade** `[VERIFICAR magnitude na literatura]`. Ou seja,
   um gradiente Sul-Sudeste na detecção pode **coexistir com** um gradiente NE na
   ocorrência verdadeira — e o dado administrativo **não separa os dois**. Não
   afirmar "mais EIM no Sul/Sudeste": afirmar "mais **detecção**".

7. **Qualidade do dado.** Completude de `pa_cidpri`/`diagsec`/`causabas`/raça-cor;
   proporção de CID de EIM **válido e específico** vs inespecífico; consistência
   sexo × CID (entidades ligadas ao X); oportunidade; duplicidade; completude do
   **SINASC** (denominador). Distinguir variação de **qualidade** de variação de
   **carga**.

8. **Teste de tendência temporal.** Regressão de **Poisson (ou binomial negativa
   se houver sobredispersão)** `n_eventos ~ ano`, **offset `log(denominador)`**
   (população IBGE ou NV, conforme o eixo — §3), com IC; reportar razão de taxas
   anual. **Ressalva obrigatória COVID 2020–2021** (excluir/marcar como anômalo).
   **Confundidor específico de EIM:** mudança de **política de triagem** (expansão
   da Lei 14.154/2021, §5) **aumenta a detecção sem aumentar a incidência** — uma
   tendência de alta pós-expansão é **artefato de política**, não epidemiologia
   (§6). Modelar a expansão como **quebra estrutural / covariável de período**, não
   como tendência suave.

---

## 5. Arcabouço normativo SUS a verificar/citar

> **⚠️ [VERIFICAR] em TODOS os números, datas, portarias e listas de doenças.** O
> quadro abaixo é um **mapa de onde procurar**, não uma fonte de números. Portarias
> são revisadas, consolidadas e renumeradas; a lista de doenças triadas está em
> **expansão por etapas** (Lei 14.154/2021); incorporações de TRE/fórmulas mudam a
> cada ciclo CONITEC. **Não publicar nenhum número/data/critério sem confirmar na
> fonte primária** (gov.br/saude, gov.br/conitec, DOU/Imprensa Nacional).

| Instrumento | O que regula (a confirmar) | Onde achar / como validar |
|---|---|---|
| **Política Nacional de Atenção Integral às Pessoas com Doenças Raras** — Portaria GM/MS **199/2014** `[VERIFICAR nº/vigência e consolidação]` | Diretrizes, eixos (raras de origem genética, incl. EIM), serviços/habilitação, incentivo financeiro | gov.br/saude; buscar o texto **consolidado** (Portaria de Consolidação vigente pode ter absorvido a 199/2014) |
| **Programa Nacional de Triagem Neonatal (PNTN)** — Portaria **822/2001** `[VERIFICAR nº/vigência]` | Institui o "teste do pezinho" no SUS, fases (I–IV), SRTN | gov.br/saude; conferir se foi **consolidada** e as fases vigentes por UF |
| **Lei 14.154/2021** — ampliação da triagem neonatal `[VERIFICAR etapas e cronograma de implantação]` | Expande o rol de doenças triadas por **etapas** (inclui EIM adicionais e outras raras); implantação progressiva e dependente de estrutura | **DOU** (texto da lei) + gov.br/saude (regulamentação/cronograma por etapa); **crítico** para o item 8 do §4 (detecção × política) |
| **Serviços de Referência** (SRTN e centros de doenças raras habilitados) | Habilitação, competências, distribuição territorial | **CNES** (habilitações/serviços) + portarias de habilitação no DOU; base do eixo de vazios (§4.1) |
| **Incorporações CONITEC** — TRE (Gaucher, MPS I/II/IVA/VI, Pompe…), fórmulas metabólicas, outros `[VERIFICAR cada uma: doença, data, condicionantes]` | Quais EIM têm terapia incorporada no SUS, com que critérios (PCDT), desde quando | **gov.br/conitec** (relatórios de recomendação) + **DOU** (portaria SCTIE/GM de incorporação). ⚠️ Distinguir **relatório CONITEC** ≠ **portaria de incorporação** ≠ **PCDT** (atos diferentes — lição do HS §8) |
| **PCDT específicos** por doença (quando existirem) | Critérios de diagnóstico, elegibilidade e dispensação de TRE/fórmula | gov.br/saude (PCDT vigente) — sempre a **versão atual**, não cartilha estadual |
| **Componente Especializado da Assistência Farmacêutica (CEAF)** | Via de dispensação de TRE de alto custo (LME/APAC) | Portarias do CEAF vigentes + SIGTAP (código APAC — `[CONFIRMAR via fetch_sigtab()]`) |
| **Financiamento** | Custeio da triagem, das TRE e das fórmulas; incentivos de habilitação | Fundo a fundo / blocos de financiamento vigentes; SIGTAP para valores |

**Como validar nas fontes primárias (roteiro):**
1. **gov.br/conitec** → buscar por doença/tecnologia → **relatório de recomendação**
   e o **nº da portaria de incorporação** na decisão.
2. **DOU (in.gov.br)** → confirmar número, data e **texto vigente** da portaria
   (checar se foi alterada/revogada/consolidada).
3. **gov.br/saude → Portarias de Consolidação (GM/MS)** → verificar se o ato
   original (199/2014, 822/2001) foi absorvido e qual o dispositivo atual.
4. **CNES** → habilitações e serviços especializados por estabelecimento/UF.
5. **SIGTAP** (competência do período) → códigos de TRE/APAC e valores.

> **Conexão com a análise:** os eixos temporal (§4.8) e de custos (§4.5)
> **dependem** de fixar essas datas — especialmente as **etapas da Lei
> 14.154/2021** e as **datas de incorporação de cada TRE** — para separar mudança
> de política de mudança epidemiológica. Sem esses marcos verificados, a série
> temporal não é interpretável.

---

## 6. Limitações específicas de EIM no DATASUS

1. **Subdiagnóstico** — parcela expressiva dos EIM **nunca é diagnosticada** (falta
   de suspeição, ausência de teste confirmatório, óbito atribuído a causa
   inespecífica). O numerador é um **piso**; taxas são de detecção, não de
   ocorrência.
2. **Diagnóstico tardio** — EIM de apresentação insidiosa (algumas lisossômicas,
   mitocondriais) levam anos até o CID correto; o "primeiro registro" na janela
   2020–2025 sofre **censura à esquerda** (left-truncation) — não distingue caso
   incidente de prevalente. Não inferir "idade ao diagnóstico" nem atraso.
3. **Letalidade antes do diagnóstico** — os EIM mais graves matam no período
   neonatal antes de gerar registro ambulatorial; ficam **só no SIM** (reforça o
   papel central do SIM, §2) e mesmo lá podem escapar (item 4).
4. **CID inespecífico e má codificação** — grande fração pode cair em códigos
   guarda-chuva (E88.x "outros distúrbios metabólicos", ou fora do bloco E70–E90)
   ou ser mascarada pela **manifestação aguda** (sepse, acidose, encefalopatia,
   IRA) na causa básica. Baixa especificidade → subgrupos/traçadoras subcontados.
5. **Heterogeneidade do grupo** — "EIM" agrega centenas de entidades
   incomparáveis; o número agregado é dominado por poucos CID e por inespecíficos.
   **Sempre** decompor em grupo × subgrupos × traçadoras (§1) e nunca reportar um
   "total EIM" isolado como se fosse uma doença.
6. **Sem identificador longitudinal** (SIA/SIH públicos) → conta
   **registros/atendimentos, não pessoas**; um paciente crônico infla o numerador.
   Recidiva, adesão à TRE, trajetória e consolidação de comorbidades por indivíduo
   são inviáveis (ou só aproximáveis por pseudo-ID, com todos os erros do HS §5.1).
7. **Células pequenas / LGPD** — raridade + centenas de subentidades → estratos
   finos com N=1–2, **reidentificáveis** (criança com doença rara em município
   pequeno). Supressão `N<5`, agregação por região/subgrupo, IC obrigatório;
   taxas instáveis sobre <10 eventos (§3).
8. **Mudança de política de triagem confunde detecção com incidência** — a
   expansão da Lei 14.154/2021 (§5) **eleva a detecção** de EIM triados sem alterar
   a incidência real. Uma tendência de alta pós-expansão é **artefato de política**;
   modelar como quebra estrutural, não tendência (§4.8). Simetricamente,
   heterogeneidade **entre UFs** na etapa de triagem implantada gera **falso
   gradiente geográfico** de "incidência".
9. **Assimetria/incomparabilidade entre bases** — definição de caso difere por
   construção (1 CID no SIA · principal+9 secundários no SIH · causa básica+linhas
   no SIM); as janelas são **seletivas por gravidade/sobrevivência** (§2). Não
   somar, não comparar taxas trivialmente.
10. **Denominadores com descontinuidade** — degrau do Censo 2022 (IBGE) e
    completude variável do **SINASC** no espaço/tempo (§3); o denominador SINASC
    **só vale para EIM de triagem neonatal**.
11. **Efeito COVID-19 (2020–2021)** — colapso da produção eletiva e possível
    impacto sobre triagem/acesso a genética; período anômalo na série (§4).
12. **Custos incompletos e judicialização** — TRE de alto custo é fortemente
    **judicializada** e parte das **fórmulas metabólicas** pode trafegar por vias
    (judicial, componente especializado, estadual) que **não estão** integralmente
    no SIA-PA/APAC público → gasto atribuído é **piso**, e o dado administrativo
    não distingue via judicial de administrativa.
13. **Procedimento ≠ doença** — o SIGTAP é organizado por procedimento; a
    identificação do EIM depende do **CID associado**, sujeito à codificação. Sem
    `pa_cidpec`/APAC detalhado nesta extração, o rastreio de TRE pode exigir a base
    **SIA-AM/AP (APAC)**, não disponível no PA `[VERIFICAR]`.

---

### Fontes e dependências a fixar antes da redação final
- **Escopo de CID** do guarda-chuva EIM (bloco E70–E90 + entradas fora do bloco) e
  o **mapeamento subgrupo↔CID** e **traçadora↔CID** — `[VERIFICAR]`.
- **Mapeamento denominador↔doença** (IBGE vs SINASC por traçadora — §3).
- **Marcos normativos** com datas confirmadas (§5), sobretudo etapas da Lei
  14.154/2021 e incorporações CONITEC de TRE.
- **Disponibilidade das bases** (SIM-DO/SINASC do ano final; filtro real dos brutos
  SIH — sabor "qualquer campo", §2).
