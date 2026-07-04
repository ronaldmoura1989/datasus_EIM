# Análise de dados do DATASUS sobre Erros Inatos do Metabolismo (EIM) no Brasil: plano consolidado

**Os Erros Inatos do Metabolismo (EIM / *inborn errors of metabolism*) são um GRUPO
HETEROGÊNEO de centenas de doenças genéticas raras** — defeitos monogênicos de vias
metabólicas (aminoacidopatias, acidúrias orgânicas, distúrbios do ciclo da ureia,
doenças lisossômicas de depósito, glicogenoses, defeitos da oxidação de ácidos graxos,
distúrbios mitocondriais, defeitos congênitos da glicosilação, entre outros). Este
documento adapta, para os EIM, a metodologia de análise dos microdados do DATASUS já
validada nos projetos de **autismo** e de **Hidradenite Supurativa** (`datasus_HS/`),
triangulando **SIA-PA** (ambulatorial), **SIH-RD** (internações) e **SIM-DO**
(mortalidade), com o **SINASC** (nascidos vivos) como quarto pilar/denominador.

> **Plano consolidado a partir de três revisões independentes, todas Opus 4.8:**
> **genética clínica** (definição de caso, taxonomia CID, doenças-traçadoras, política
> de triagem/alto custo), **epidemiologia/SUS** (desenho, denominadores, eixos,
> arcabouço normativo, limitações) e **bioinformática/engenharia de dados**
> (pipeline em R, captura multi-CID, taxas, reprodutibilidade). As três partes-fonte
> estão preservadas em `parte_geneticista.md`, `parte_epidemiologista.md` e
> `parte_bioinformata.md`.

> **Convenções de marcação (idênticas ao HS):** `[VERIFICAR]` = afirmação que exige
> confirmação documental na fonte oficial (CID-10 DATASUS/V2008, OMIM, Orphanet, PCDT,
> DOU, PNTN); `[CONFIRMAR via fetch_sigtab()]` = procedimento/CBO/APAC a validar na
> competência correta do SIGTAP. **Princípio inegociável: nunca inventar CID,
> prevalência, procedimento, portaria, valor de repasse ou número molecular.**

---

## 0. As três diferenças estruturais frente à Hidradenite Supurativa

O projeto HS analisava **uma** doença (`L732`). Os EIM mudam três eixos de premissa —
e cada mudança se propaga por todo o desenho:

| Dimensão | HS (referência) | EIM (este projeto) | Consequência |
|---|---|---|---|
| **Alvo** | 1 CID (`L732`) | **Grupo de centenas de CIDs** (E70–E90 + fora do E) | Captura deixa de ser "detecção booleana de 1 código" e vira **rotulagem por subgrupo fisiopatológico via *lookup table*** |
| **Granularidade** | doença única | **grupo × subgrupos × doenças-traçadoras** | Nunca reportar "total EIM" como entidade; três níveis lado a lado |
| **Denominador** | só IBGE (detecção/uso) | **IBGE (uso) + SINASC nascidos vivos (incidência ao nascimento)** | Cada traçadora tem denominador designado |
| **Papel do SIM** | exploratório, quase invisível | **eixo CENTRAL** — EIM grave costuma ser causa básica; óbito neonatal/infantil é desfecho de referência | SIM promovido a primeira linha para traçadoras neonatais letais |
| **Especificidade CID × procedimento** | CID mais específico que o procedimento | **Para lisossômicas, o procedimento-APAC da enzima é MAIS específico que o CID** (imiglucerase↔Gaucher etc.) | Triangular CID × APAC para desagregar doenças |
| **Modificador temporal de política** | incorporação do adalimumabe | **triagem neonatal (PNTN + Lei 14.154/2021)**, escalonada e desigual por UF | Quebra de série a sinalizar (como COVID/Censo) |

> **Ressalva-mãe (o equivalente ao "detecção ≠ prevalência" do HS): HETEROGENEIDADE
> EXTREMA.** "EIM" agrega doenças com biologia, tratamento, idade de início e
> letalidade incompatíveis. Um "total EIM" é **soma de maçãs com laranjas** — só
> admissível como *carga agregada de uso de serviço*, nunca como entidade
> epidemiológica. Repetir em cada eixo (§6) e em cada `.qmd`.

---

## 1. Desenho do estudo e unidade de análise

Estudo **ecológico/descritivo de séries temporais sobre dados secundários
administrativos**; **unidade = registro/atendimento (ou o óbito, no SIM), não o
indivíduo**. Não há identificador longitudinal no DATASUS público (SIA/SIH); o SIM
registra o óbito por indivíduo, mas sem encadeamento com atendimentos prévios. Toda
associação (EIM × região/idade/comorbidade) está sujeita à **falácia ecológica** e
**não autoriza inferência individual ou causal**. As bases têm unidades e
denominadores distintos e **NÃO são somáveis**.

### Granularidade em três níveis simultâneos (regra central)

| Nível | O que é | Papel analítico |
|---|---|---|
| **Grupo (guarda-chuva)** | E70–E90 (CORE) + entradas fora do bloco | Carga agregada de uso; **teto**, baixa especificidade — nunca "prevalência de EIM" |
| **Subgrupos fisiopatológicos** | aminoacidopatias · acidúrias orgânicas (reconstruído) · ciclo da ureia · FAOD · carboidratos/glicogenoses · galactosemia · esfingolipidoses · MPS · glicoproteinoses · peroxissomais · porfirias · purina-pirimidina · metais (Wilson) | Unidade de comparação **mais defensável** que o total |
| **Doenças-traçadoras** | CID de alta especificidade e relevância de política (§2.5) | Nível **mais informativo e menos ruidoso** — ancora narrativa e recomendação |

### O que é legitimamente inferível × NÃO inferível

| **Legitimamente inferível** | **NÃO inferível com este desenho** |
|---|---|
| Carga de uso de serviço por grupo/subgrupo | Prevalência / incidência **verdadeiras** |
| Padrões de codificação e qualidade do dado | Risco individual; causalidade; penetrância |
| Gasto atribuível por codificação (TRE/APAC, internação, fórmulas) | Trajetória do paciente; adesão real ao tratamento |
| Distribuição espacial da **detecção** e da **oferta** (centros de referência) | Distribuição espacial da **doença** (confundida por acesso/triagem) |
| Perfil demográfico dos **registros/óbitos** | Perfil do EIM na população viva (viés de gravidade/sobrevivência — §3) |
| **Mortalidade por EIM** (SIM, causa básica + linhas) | Letalidade real (denominador de casos verdadeiros desconhecido) |
| **Incidência ao nascimento/100 mil NV** para doenças **triadas** (proxy) | Incidência verdadeira de EIM **não triados** |

---

## 2. Taxonomia CID-10 e estratégia de captura

A CID-10 (e o DATASUS) organizam por **substrato** (aminoácido, carboidrato, lipídio…),
o que **não é isomórfico** à classificação mecanística moderna (Saudubray/ICIMD). A
CID-10 tem apenas **4 caracteres** — **não chega ao gene/doença molecular**. Formato
DATASUS: sempre **sem ponto** (E70.0 → `E700`).

> **⚠️ Todos os rótulos literais de 4 caracteres abaixo são de memória do modelo e o
> portal DATASUS CID10 esteve inacessível na redação → `[VERIFICAR rótulo]` contra a
> tabela oficial ([CID10 V2008, blocos E70–E90](http://www2.datasus.gov.br/cid10/V2008/WebHelp/e70_e90.htm)).**

### 2.1 Marcação de papel de cada CID

- **CORE** — EIM raro de alta especificidade (o CID mapeia com boa fidelidade a uma
  doença/grupo monogênico) → **núcleo** (análise primária).
- **LIMÍTROFE** — CID de EIM porém inespecífico/"não especificado"/agregador → **camada
  ampliada**.
- **INESPECÍFICO/NÃO-EIM** — doença comum multifatorial que "mora" no mesmo bloco
  (dislipidemia `E78`, gota `E790`, hemocromatose `E831`, intolerância à lactose `E73x`)
  → **fonte dominante de ruído**, tratada como o `L02x` foi na HS (**ENVELOPE**, nunca
  caso).

### 2.2 Mapa CID-10 por classe fisiopatológica (núcleo — resumo)

| Bloco | CIDs CORE principais `[VERIFICAR rótulo]` | Classe | Exemplos |
|---|---|---|---|
| **E70–E72** | `E700` PKU · `E701` hiperfenilalaninemias/BH4 · `E702` tirosinemia · `E710` MSUD · `E711` acidúrias orgânicas (BCAA) · `E713` FAOD · `E720` transporte AA · `E721` homocistinúria · `E722` **ciclo da ureia** · `E723` acid. glutárica I · `E724` ornitina · `E725` glicina | Aminoacidopatias / acidúrias / ciclo da ureia / FAOD | PKU, MSUD, tirosinemia I, OTC (XL), propiônica/metilmalônica |
| **E73–E74** | `E740` **glicogenoses** (inclui Pompe=GSD II) · `E741` frutose · `E742` **galactosemia** · `E744` piruvato | Carboidratos | galactosemia, GSD, Pompe¹ |
| **E75** | `E750` GM2 (Tay-Sachs) · `E751` GM1 · `E752` **outras esfingolipidoses** · `E754` NCL/Batten · `E755` depósito de lipídios | Esfingolipidoses / lisossômicas | Gaucher¹, Fabry¹, Niemann-Pick, Krabbe, MLD |
| **E76–E77** | `E760` MPS I · `E761` MPS II (Hunter, **XL**) · `E762` outras MPS · `E770` mucolipidose · `E771` glicoproteinoses | Depósito lisossômico (MPS/glicoproteínas) | Hurler, Hunter, Maroteaux-Lamy, alfa-manosidose |
| **E80** | `E800` porfiria eritropoética · `E802` porfirias agudas | Porfirias | porfiria aguda intermitente |
| **E79** | `E791` Lesch-Nyhan (**XL**) | Purina/pirimidina | Lesch-Nyhan |
| **E83** | `E830` **Wilson** (+Menkes XL) | Metais (cobre) | Doença de Wilson |
| **E84** | `E84x` **fibrose cística** | — (triagem/benchmark) | ver §2.4 |

> ¹ **Não-separabilidade crítica:** Gaucher, Fabry, Niemann-Pick etc. **colapsam em
> `E752`**; **Pompe cai em `E740`** (glicogenoses), não em E76. O CID **não isola** a
> maioria das traçadoras lisossômicas → a desagregação depende de triangular com o
> **procedimento-APAC da enzima** (§5).

**Nós taxonômicos que a CID-10 não resolve (declarar sempre):**
- **Acidúrias orgânicas** não têm bloco próprio — dispersas em `E711`+`E723`(+outros);
  qualquer subgrupo "acidúrias orgânicas" é **reconstrução aproximada**.
- **Doenças mitocondriais** (MELAS/Leigh/MERRF) são **praticamente inceptáveis** —
  espalhadas por `E88x` e por `G31x`/`G93x` (fora do capítulo E) → subgrupo grosseiro e
  muito subestimado.
- **CDG (glicosilação)** sem código dedicado — cai em `E748`/`E749`/`E771`.
- **X-ALD / Zellweger (peroxissomais)** — posição a `[VERIFICAR]` (`E71x`/`E75x`).

### 2.3 Decisões de inclusão/exclusão declaradas

- **`E830` Wilson → INCLUIR no núcleo** — EIM monogênico (AR), tratável (quelantes),
  diagnóstico tardio (adulto jovem); boa **traçadora de EIM de apresentação tardia**.
- **`E831` hemocromatose → EXCLUIR do núcleo** — *HFE* comum, penetrância baixa;
  comporta-se como traço multifatorial → **envelope**, nunca somada às raras.
- **`E78` (dislipidemia), `E790` (gota), `E73x` (lactase), `E888/E889` ("outros/SOE"),
  amiloidose adquirida → ENVELOPE** (teto de subcodificação, *bracketing*).
- **Fibrose cística (`E84`), HAC (`E250`), hipotireoidismo congênito (`E03`),
  hemoglobinopatias (`D56/D57`) → apenas no eixo triagem/política, como subgrupos
  ISOLADOS e nomeados** — não são EIM metabólicos *stricto sensu* e, por serem
  frequentes e bem codificados, **esmagariam o sinal das raras** se agregados.

### 2.4 Captura em camadas (restrita → +ampliada → +ENVELOPE)

Implementar numa **única passada** com função tipo `classificar_eim(cid)` que devolve
**classe fisiopatológica** E **camada** (`core`/`limítrofe`/`envelope`) por registro —
não filtro booleano reprocessado. Reportar as camadas **separadas** (CORE → +LIMÍTROFE),
mostrando o efeito de cada inclusão, exatamente como `L732 → +L73x` na HS.

> **Regra de ouro (idêntica ao `+L02x`):** a camada ENVELOPE é **limite superior
> absoluto de subcodificação possível**, nomeada "envelope", **nunca "casos EIM
> ampliados"**. Reportar a **razão CORE : não-especificado** por subgrupo como
> indicador de **qualidade diagnóstica/codificação** (análogo à razão `L02x/L732`, mas
> aqui *interna* ao capítulo E).

### 2.5 Doenças-traçadoras recomendadas

Critérios: (i) especificidade do CID; (ii) relevância de política (triagem e/ou TRE de
alto custo); (iii) cobertura de eixos contrastantes (neonatal↔adulto, AR↔XL,
ambulatorial↔internação↔óbito).

| Traçadora | CID-alvo `[VERIFICAR]` | Por que traçadora | Eixo que ilumina |
|---|---|---|---|
| **PKU / hiperfenilalaninemias** | `E700`,`E701` | Triagem histórica; fórmula de alto custo | Neonatal · política · fórmula |
| **MSUD** | `E710` | Emergência neonatal; fórmula; letalidade precoce | Neonatal · SIM · fórmula |
| **Galactosemia** | `E742` | Triagem (Lei 14.154); crise neonatal | Neonatal · dieta |
| **Ciclo da ureia** | `E722` | Hiperamonemia letal; OTC é **XL** | Neonatal · SIM · razão de sexo |
| **MPS I / II / VI** | `E760`,`E761`,`E762` | **TRE de altíssimo custo**; MPS II é XL | Custo · APAC · judicialização · sexo |
| **Gaucher** | `E752`¹ | **TRE (imiglucerase)**; protótipo tratável caro | Custo · CEAF/APAC · judicialização |
| **Pompe** | `E740`¹ | **TRE (alglucosidase)**; infantil letal + adulto | Custo · neonatal+adulto |
| **Fabry** | `E752`¹ | TRE; **XL**; apresentação adulta | Custo · adulto · sexo |
| **X-ALD** | `E71x`/`E75x`¹ | **XL**; TMO; triagem em expansão global | Neonatal · sexo · neurológico |
| **Wilson** | `E830`¹ | Apresentação tardia; quelantes; tratável | Adulto · CEAF · contraponto neonatal |
| **Fibrose cística** | `E84x` | Triagem; **benchmark** de "EIM bem codificado" | Política · calibração |

---

## 3. Assimetria de captura entre bases + o SIM como eixo central

Cada base captura o CID em campos diferentes; **"taxa SIA", "taxa SIH" e "taxa SIM" não
medem o mesmo conceito de caso** — não somar nem comparar trivialmente.

| Base | Campo(s) | Regra | Observação EIM |
|---|---|---|---|
| **SIA-PA** | `pa_cidpri` (+ `pa_cidpec` APAC, se presente) | 1 CID/registro | EIM crônico gera muitos registros/ano (genética, nutrição, fórmulas, TRE) → numerador **inflado** = intensidade de uso. APAC tende a ter CID melhor preenchido |
| **SIH-RD** | `diag_princ` + `diag_secun` + `diagsec1..9` | principal **OU** qualquer secundário | EIM frequentemente entra como **secundário** de uma descompensação (sepse, acidose, IRA) → reportar em **dois sabores** |
| **SIM-DO** | `causabas` + `linhaa`–`linhad` + `linhaii` | qualquer campo; multi-CID por célula; marcadores `†`/`*` | **Base CENTRAL** — ver abaixo |

**SIH em dois sabores (regra fixa):** (a) `diag_princ` = EIM (comparável ao SIA);
(b) EIM em **qualquer campo** (`if_any` sobre os `diagsec*`). Nunca misturar nem somar
com o SIA.

> **⚠️ Alerta de extração (herdado do HS §7.1):** se os brutos do SIH forem
> pré-filtrados só por `diag_princ`, o sabor "qualquer campo" **não é recuperável** e
> subestima gravemente a carga hospitalar de EIM (que vive nos secundários). Para EIM,
> o sabor "qualquer campo" é **essencial** → provavelmente re-extrair do RD completo.
> `[VERIFICAR filtro dos brutos]`.

### DESTAQUE — o SIM é a base central (inversão vs HS)

Na HS o SIM era exploratório (N≈65, 1 causa básica). Em EIM ocorre o oposto:

1. **Muitos EIM graves têm o óbito como desfecho de referência** (acidúrias orgânicas,
   ciclo da ureia, mitocondriais, lisossômicas) com **mortalidade neonatal/infantil
   elevada**, muitas vezes **antes de qualquer registro ambulatorial** → o SIM captura
   casos que nunca aparecem nas outras bases.
2. **O EIM tende a ser CAUSA BÁSICA (`causabas`)**, não apenas contribuinte — é a raiz
   da cadeia causal.
3. **Óbito neonatal/infantil por EIM é indicador de saúde pública próprio** — dialoga
   com mortalidade infantil evitável e oportunidade da triagem neonatal.

> **Regra de captura no SIM:** rodar `normalizar_cid_sim()` sobre `causabas` + todas as
> linhas; classificar cada óbito em **(i) EIM como causa básica** vs **(ii) EIM em
> qualquer linha (causa múltipla)** e reportar os dois. Analisar **idade ao óbito** e
> quantificar o **sub-registro** (quanto do EIM aparece só nas linhas, não em
> `causabas`).

### Viés de sobrevivência e de gravidade (estrutura, não ruído)

- **SIM** enviesa para os EIM **mais letais e precoces**.
- **SIA** enviesa para os EIM **tratáveis e cronicamente acompanhados** (o paciente
  sobrevive para gerar registros) — os que matam antes do diagnóstico ficam invisíveis.
- **SIH** fica intermediário. Ler cada base como uma **janela seletiva** distinta do
  espectro EIM e explicitar isso em toda comparação inter-base.

### Razão de sexo — faca de dois gumes (depende da herança do CID)

- **CID autossômicos recessivos** (maioria) → razão ~1:1 esperada; desvio acentuado é
  **bandeira de miscodificação ou acesso diferencial**, não achado biológico.
- **CID ligados ao X** (`E761` MPS II, `E752` Fabry parcial, X-ALD, `E791` Lesch-Nyhan,
  OTC em `E722`, Menkes em `E830`) → **predomínio masculino é o esperado biológico** e
  serve de **checagem de consistência sexo × CID**.

---

## 4. Denominadores e taxas — DOIS denominadores complementares

Ao contrário da HS (só denominador populacional), os EIM exigem **dois denominadores**,
cada um respondendo a uma pergunta. Usar o errado gera indicador sem sentido.

### (a) População geral IBGE → detecção/uso e mortalidade

- **Pergunta:** intensidade de uso (SIA/SIH) e mortalidade (SIM) por EIM na população,
  por UF/região e no tempo.
- **Fonte:** população residente **UF × sexo × faixa etária** via **`sidrar`** (Censo
  2022), população do ano-calendário do numerador.
- **Métrica:** por **100.000 hab**, **brutas e padronizadas** por idade/sexo lado a
  lado, com **IC gamma** (`epitools::ageadjust.direct()`). Padronização direta é
  indispensável (EIM concentram-se em idade pediátrica; UFs têm pirâmides distintas).
- **Interpretação:** índices de **detecção/uso e de mortalidade registrada**, não
  prevalência.

### (b) Nascidos vivos SINASC → incidência ao nascimento (diferencial)

- **Pergunta:** para EIM cobertos pela **triagem neonatal**, quantos casos incidem **ao
  nascimento** — denominador natural de doença congênita detectada logo após o parto.
- **Fonte:** **nascidos vivos (SINASC)** por **UF × ano** (`codmunres` = residência da
  mãe → UF), via `microdatasus`.
- **Métrica:** **casos por 100.000 NV** — proxy de **incidência ao nascimento**,
  defensável **só** para doenças triadas (numerador = casos identificados no 1º ano, ou
  óbitos infantis por aquele EIM).
- **Uso duplo:** (i) óbitos infantis por EIM ÷ NV = **coeficiente de mortalidade
  infantil específico por EIM** (comparável à MI geral); (ii) detecção <1 ano ÷ NV =
  incidência detectada ao nascimento.

> **⚠️ O denominador SINASC só vale para EIM de triagem neonatal.** Aplicá-lo a um EIM
> de apresentação tardia produz número sem sentido. **Cada traçadora/subgrupo tem um
> denominador designado** — documentar numa tabela de mapeamento denominador↔doença.

### Qual denominador para qual pergunta

| Numerador | Denominador | Métrica |
|---|---|---|
| Uso ambulatorial (SIA) | População IBGE | Registros/100 mil hab (padronizada) |
| Internações (SIH) | População IBGE | AIH distintas/100 mil hab (padronizada) |
| Mortalidade geral por EIM (SIM) | População IBGE | Óbitos/100 mil hab (padronizada) |
| **Mortalidade infantil por EIM** | **NV (SINASC)** | Óbitos <1 ano/100 mil NV |
| **Detecção ao nascimento** (triada) | **NV (SINASC)** | Casos <1 ano/100 mil NV |

### Harmonização, degrau do Censo e supressão (crítico em doença rara)

- **Faixas etárias:** definir grade canônica única e aplicar a **mesma** função a
  numerador e denominador. **Para EIM, refinar a faixa pediátrica** (a grade quinquenal
  do HS é grossa demais): **<1 mês (neonatal) · 1–11 meses · 1–4 · 5–9 · 10–14 · 15–19
  · 20+** para capturar apresentação neonatal e idade ao óbito.
- **Degrau do Censo 2022:** retrointerpolar a partir do Censo 2022 para toda a série
  (estrutura constante, como no HS) e/ou sinalizar a quebra. `[VERIFICAR]` completude
  do **SINASC** por UF/ano antes de usá-lo como denominador fino.
- **Supressão N<5 — REGRA ESTRUTURAL, não ressalva.** EIM são raros e fragmentados em
  centenas de subentidades; estratos finos (UF × subgrupo × faixa × ano) terão
  frequentemente N=1–2, **reidentificáveis** (criança com doença rara em município
  pequeno). Suprimir toda célula `N<5`; **agregar por região/subgrupo** e **pool de
  anos** quando necessário; **IC obrigatório**; **IC de Poisson exato** para contagens
  pequenas; evitar ranking de UFs com <10 eventos.

---

## 5. Triagem neonatal e terapias de alto custo (o eixo de política)

### 5.1 Triagem neonatal (PNTN / Lei 14.154/2021) — modificador temporal e espacial

O **Programa Nacional de Triagem Neonatal (PNTN)** e a **Lei 14.154/2021** são o
principal modificador da detecção de EIM na série — análogo ao papel do adalimumabe na
HS, mas atuando **sobre o numerador de detecção** (mais doenças rastreadas → mais
diagnósticos precoces).

- **Base histórica pré-lei** (`[VERIFICAR composição/fase]`): fenilcetonúria,
  hipotireoidismo congênito, doença falciforme/hemoglobinopatias, fibrose cística,
  hiperplasia adrenal congênita, deficiência de biotinidase.
- **Lei 14.154/2021** — amplia o teste do pezinho de forma **escalonada** (previstas
  ~50 doenças / 14 grupos ao fim) `[VERIFICAR número e cronograma efetivo — DOU/gov.br]`.
  As **etapas 2 e 3 cobrem exatamente nossos subgrupos-alvo:** etapa 2 = galactosemias,
  aminoacidopatias, ciclo da ureia, FAOD; etapa 3 = lisossômicas (MPS, Gaucher, Fabry,
  Pompe). `[VERIFICAR alocação por etapa]`.

**Efeitos esperados na série 2020–2025 (hipóteses, não achados):**
1. **Descontinuidade de detecção pós-2021** para os EIM que entraram na triagem →
   aumento **artefato de política de rastreio**, não de incidência (quebra de série a
   sinalizar, como COVID/Censo).
2. **Heterogeneidade espacial brutal:** a adesão à Lei 14.154 é **estadual e desigual**
   `[VERIFICAR adesão por UF]` → "detecção por UF" reflete **onde a triagem ampliada já
   opera**, confundindo política com epidemiologia. Reportar cobertura de triagem por UF
   ao lado do mapa de detecção.
3. **Deslocamento do momento do diagnóstico** (mais neonatal) muda a composição etária
   dos registros por efeito de rastreio.
4. **Janela curta / atraso de implementação** → grande parte do efeito pode ainda não
   ter aparecido; esperar sinal fraco.

> **Onde a triagem aparece no dado:** o teste do pezinho é **procedimento SIA**
> `[CONFIRMAR via fetch_sigtab()]`; o diagnóstico confirmado entra como CID em SIA/SIH; o
> **SIM capta a falha** (óbito por EIM não rastreado a tempo). Triangular dá o arco
> "rastreio → diagnóstico → desfecho".

### 5.2 Terapias de alto custo — o procedimento é mais específico que o CID

O eixo de política do EIM é **mais rico que o da HS** (um único biológico): múltiplas
**TRE enzima-específicas**, **fórmulas metabólicas** e **quelantes**, com forte
**judicialização** (medicamentos órfãos ultra-caros).

| Doença | Enzima/fármaco `[VERIFICAR incorporação/PCDT]` | CID diluído | Via |
|---|---|---|---|
| Gaucher | **imiglucerase**/velaglicerase/taliglucerase | `E752` | CEAF/APAC |
| Pompe | **alglucosidase alfa** | `E740` | alto custo |
| MPS I | **laronidase** | `E760` | CEAF/APAC |
| MPS II | **idursulfase** | `E761` | CEAF/APAC |
| MPS VI | **galsulfase** | `E762` | CEAF/APAC |
| Fabry | **agalsidase alfa/beta** | `E752` | `[VERIFICAR]` |
| Wilson | **D-penicilamina/trientina/zinco** (quelantes) | `E830` | `[VERIFICAR PCDT]` |
| Tirosinemia I | **nitisinona (NTBC)** | `E702` | órfão |
| PKU / MSUD | **fórmulas metabólicas** (isentas de Phe / BCAA) | `E700`/`E710` | componente especializado/judicial |

> **Ativo analítico central (inverte a HS):** como a **TRE é enzima-específica**, o
> **procedimento-APAC é MAIS específico que o CID** para identificar Gaucher, Pompe,
> Fabry e cada MPS (que colapsam em `E752`/`E740`). **Triangular CID × APAC-enzima é a
> via para desagregar as traçadoras lisossômicas.** `[CONFIRMAR via fetch_sigtab()]` os
> códigos APAC de cada enzima e a disponibilidade da base **SIA-AM/AP (APAC)** — se
> ausente `pa_cidpec`/APAC (limitação já vista no HS), a desagregação lisossômica fica
> inviável → sinalizar.

Procedimentos APAC/SIH a rastrear: TRE por enzima; dispensação de fórmula metabólica (se
existir); **TMO** (X-ALD, algumas leucodistrofias/MPS); **transplante hepático**
(tirosinemia, ciclo da ureia, Wilson fulminante); seguimento em **Serviço de Referência
em Doenças Raras** (CNES habilitado). `[VERIFICAR]`.

> **Judicialização (ressalva do adalimumabe amplificada):** medicamentos órfãos de EIM
> estão entre os **mais judicializados do SUS**; o dado administrativo **não distingue**
> via incorporada de ordem judicial, e parte do gasto (compras centralizadas, execução
> judicial, fórmulas) pode estar **fora do SIA/SIH**. Gasto atribuído é **piso**.

---

## 6. Eixos de análise acionáveis

> **Ressalva COVID-19 transversal:** 2020–2021 = colapso da produção eletiva e do acesso
> a genética/referência (e possível impacto sobre a triagem). Depressão 2020–2021 +
> recuperação = artefato de oferta, não tendência. Tratar como **período anômalo** na
> narrativa e na modelagem. (Para EIM de triagem o efeito é menor — triagem é mandatória.)

1. **Rede de referência e triagem — vazios assistenciais.** Mapear via **CNES** os
   Serviços de Referência em Triagem Neonatal e centros que registram EIM; cobertura
   territorial e vazios diagnósticos. Confundimento dominante por oferta → **dois mapas
   lado a lado (detecção × oferta)**; nunca afirmar prevalência.
2. **Perfil etário pediátrico e sexo.** Pirâmide com a grade fina (§4); razão de sexo
   **por subgrupo/traçadora** (interpretação depende da herança — §3), não no agregado.
3. **Internações e permanência.** Taxa de internação; `dias_perm` (EIM descompensado →
   UTI, internações longas); procedimentos críticos (diálise, suporte metabólico);
   reinternação como proxy limitado. SIH nos **dois sabores**, sem somar com SIA.
4. **MORTALIDADE (eixo central).** (a) idade ao óbito por subgrupo; (b) mortalidade
   infantil por EIM/100 mil NV (SINASC); (c) causa básica vs causa múltipla —
   quantificar sub-registro; (d) proporção de óbitos com CID inespecífico (`E88x`).
5. **Custos.** Componentes **separados** (nunca "total" sem ressalva): TRE via APAC;
   fórmulas metabólicas; transplantes (SIH). `pa_valapr` (SIA) e
   `val_tot`/`val_sh`/`val_sp` (SIH). TRE domina e é fortemente judicializada.
6. **Inequidades regionais — tensão dupla.** Sul/Sudeste tendem a **maior detecção**
   (viés de oferta); o **Nordeste** pode ter **maior incidência real** de EIM AR por
   **consanguinidade** `[VERIFICAR magnitude na literatura]`. Os dois gradientes **empurram
   em sentidos opostos** e o dado **não os separa** → afirmar "mais **detecção**", não
   "mais EIM".
7. **Qualidade do dado.** Completude de `pa_cidpri`/`diagsec`/`causabas`/raça-cor; CID
   válido e específico vs inespecífico; consistência sexo × CID (entidades XL);
   completude do **SINASC**. Distinguir variação de **qualidade** de variação de **carga**.
8. **Teste de tendência temporal.** Poisson/quasi-Poisson (ou binomial negativa se
   sobredispersão) `n ~ ano`, **offset `log(denominador)`** (pop ou NV), com IC.
   Ressalva COVID obrigatória. **Confundidor específico:** a expansão da triagem (Lei
   14.154) eleva detecção sem alterar incidência → modelar como **quebra estrutural /
   covariável de período**, não tendência suave.

---

## 7. Arcabouço normativo SUS a verificar e citar

> **⚠️ [VERIFICAR] em TODOS os números, datas, portarias e listas de doenças.** O quadro
> é um **mapa de onde procurar**, não fonte de números. Portarias são revisadas,
> consolidadas e renumeradas; a lista triada está em expansão por etapas. **Distinguir
> relatório CONITEC ≠ portaria de incorporação ≠ PCDT** (atos diferentes — lição do HS).

| Instrumento | O que regula (a confirmar) | Onde validar |
|---|---|---|
| **Política Nacional de Atenção Integral às Pessoas com Doenças Raras** — Portaria GM/MS **199/2014** `[VERIFICAR/consolidação]` | Diretrizes, raras genéticas (incl. EIM), serviços/habilitação, incentivo | gov.br/saude; buscar texto **consolidado** |
| **PNTN** — Portaria **822/2001** `[VERIFICAR/vigência]` | Institui o teste do pezinho, fases (I–IV), SRTN | gov.br/saude; conferir consolidação e fases por UF |
| **Lei 14.154/2021** `[VERIFICAR etapas/cronograma]` | Expande o rol por **etapas** (EIM adicionais); implantação progressiva | **DOU** + gov.br/saude — **crítico** para §6.8 (detecção × política) |
| **Serviços de Referência** (SRTN + centros de raras habilitados) | Habilitação, competências, distribuição | **CNES** + portarias de habilitação (DOU) |
| **Incorporações CONITEC** — TRE (Gaucher, MPS, Pompe…), fórmulas `[VERIFICAR cada]` | Quais EIM têm terapia incorporada, critérios (PCDT), desde quando | **gov.br/conitec** (relatório) + **DOU** (portaria SCTIE/GM) |
| **PCDT** por doença | Diagnóstico, elegibilidade, dispensação de TRE/fórmula | gov.br/saude (versão **vigente**, não cartilha estadual) |
| **CEAF** | Via de dispensação de TRE (LME/APAC) | Portarias CEAF + SIGTAP (`[CONFIRMAR via fetch_sigtab()]`) |

**Roteiro de validação:** (1) gov.br/conitec → relatório + nº da portaria; (2) DOU
(in.gov.br) → número, data e texto **vigente**; (3) gov.br/saude → Portarias de
Consolidação (verificar se 199/2014 e 822/2001 foram absorvidas); (4) CNES →
habilitações por UF; (5) SIGTAP na competência → códigos e valores de TRE/APAC.

> **Conexão com a análise:** os eixos temporal (§6.8) e de custos (§6.5) **dependem** de
> fixar essas datas — especialmente as **etapas da Lei 14.154** e as **datas de
> incorporação de cada TRE** — para separar política de epidemiologia. Sem esses marcos
> verificados, a série temporal não é interpretável.

---

## 8. Limitações específicas de EIM no DATASUS

Além de **todas** as ressalvas herdadas do HS (desenho ecológico; registro ≠ pessoa;
sem ID longitudinal; bases não somáveis; taxas de **detecção/uso** e não prevalência;
efeito COVID 2020–2021; degrau do Censo 2022; LGPD/supressão N<5; left-truncation), os
EIM adicionam:

1. **Heterogeneidade extrema** — "EIM" agrega centenas de entidades incomparáveis;
   número agregado dominado por poucos CID e por inespecíficos. **Sempre** decompor em
   grupo × subgrupos × traçadoras; nunca reportar "total EIM" como doença. **(ressalva-mãe)**
2. **CID capta fenótipo/substrato, não a doença molecular** — `E752` = dezenas de
   esfingolipidoses; `E740` = todas as glicogenoses + Pompe; `E722` = todo o ciclo da
   ureia. Desagregação depende de triangular com procedimento/enzima (§5) e, mesmo
   assim, parcial.
3. **Subdiagnóstico e diagnóstico tardio massivos** — odisseia diagnóstica; numerador é
   fração pequena e enviesada; viés de acesso a centros de referência.
4. **Letalidade antes do diagnóstico** — os EIM graves matam no período neonatal antes
   de gerar registro ambulatorial; ficam só no SIM (reforça §3) e mesmo lá podem escapar
   sob causa inespecífica (sepse, acidose, encefalopatia, IRA).
5. **Códigos "não especificados"/"outros" inflados** (`E729`,`E749`,`E759`,`E769`,
   `E779`,`E888`,`E889`) — deslocam massa para o envelope e esvaziam os CIDs específicos.
6. **Doença comum "morando" no capítulo E** (`E78`, `E790`, `E831`, `E73x`) — se
   agregadas, dominam e afogam o sinal raro.
7. **Fibrose cística e as "não-metabólicas da triagem" esmagam o agregado** — nunca
   diluir no total; sempre subgrupo isolado.
8. **Mitocondriais e CDG praticamente inceptáveis** pela CID-10 → subgrupos grosseiros e
   muito subestimados; declarar.
9. **Mudança de política de triagem confunde detecção com incidência** (Lei 14.154) e a
   heterogeneidade de adesão por UF gera **falso gradiente geográfico**.
10. **Razão de sexo depende da herança** do CID (XL esperado masculino vs AR ~1:1) — não
    uniforme como na HS.
11. **Denominadores com descontinuidade** — degrau do Censo 2022 (IBGE) e completude
    variável do SINASC; o SINASC só vale para EIM de triagem.
12. **Custos incompletos e judicialização** — TRE e fórmulas trafegam por vias
    (judicial, componente especializado, estadual) parcialmente **fora do SIA/SIH** →
    gasto é piso; `pa_cidpec`/APAC possivelmente indisponível na extração.
13. **Prevalência da literatura só como moldura de plausibilidade** (PKU ~1:10.000, MPS
    combinada ~1:25.000, Gaucher ~1:40.000 — **`[VERIFICAR TODAS]`**), para dimensionar o
    gap de captação; **nunca somar prevalências** de doenças distintas.

---

## 9. Implementação técnica (R) — arquitetura do pipeline

Reaproveita a engenharia do `datasus_HS/` — **stack, `utils.R`, scripts numerados,
Parquet particionado, `calcular_taxas.R`, pseudo-ID e publicação Quarto/GitHub Pages** —
com adaptações pontuais. É um **fork adaptado, não um redesenho**.

### 9.1 Stack
`tidyverse` (análise) · **`data.table`** (SINASC/SIA nacional, varredura multi-CID) ·
**`arrow`** (Parquet particionado `ano×uf`, `schema()` explícito) · **`microdatasus`**
(`fetch_datasus`/`process_sia/sih/sim/sinasc`) + `read.dbc` (fallback) · `janitor` ·
**`epitools::ageadjust.direct`** (padronização + IC gamma) · `stats/MASS`
(Poisson/quasi-Poisson/NB) · **`sidrar`** (pop IBGE) · **`geobr`** (mapas) · `naniar`
(QC) · `igraph` (pseudo-ID) · `renv`/`digest`/`here` (reprodutibilidade). Pinar SHA de
`microdatasus`/`read.dbc` no `renv.lock`.

### 9.2 O coração novo — lookup table CID→classe (`eim_lookup.R`)
Em vez de detecção booleana de 1 CID, uma **tabela de prefixos** (E70–E90 + correlatos)
mapeia para **classe fisiopatológica** + **camada** (`core`/`envelope`) + flag
`triagem_neonatal`. `classificar_eim(cid)` casa por **prefixo, mais específico primeiro**
(*first-match*: `E700` PKU vence `E7` envelope) numa **única passada**. Para volume,
filtro grosso por **regex única compilada** na ingestão; `classificar_eim()` só nas
linhas retidas. **Versionar a lookup** (`manifest/eim_lookup_versao.csv` com hash
`digest`) — **a definição de caso É a lookup**; mudá-la muda todos os números.
`[VERIFICAR cada prefixo com o geneticista]` — os prefixos são ilustrativos.

### 9.3 Varredura por base
- **SIA:** filtro por regex de prefixo **na ingestão**, arquivo a arquivo
  (`load → filter → save/descarta → gc()`); **agregar o denominador de uso antes de
  descartar**; **nunca** carregar SIA nacional em RAM.
- **SIH:** detecção dinâmica das colunas de diagnóstico (`detectar_cols_diag`) +
  `if_any(any_of(cols_diag), eh_eim)`; **dois sabores** (principal vs qualquer campo);
  contar **AIH distinta** (`ident=5` = continuação), não linha.
- **SIM:** `normalizar_cid_sim()` (herdado) extrai a **lista completa** de códigos por
  célula e trata daga/asterisco (`†*`); testar EIM em `causabas` + linhas; separar causa
  básica vs causa múltipla.
- **SINASC:** `process_sinasc` → NV por `codmunres`→UF × ano (residência da mãe, para
  bater com o numerador por residência); agregar na ingestão (não guardar 60+ colunas);
  campo `codanomal` (multi-CID) como sinal **exploratório** de EIM ao nascer, não
  numerador principal.

### 9.4 Taxas e supressão
`taxas_padronizadas()` (bruta + padronizada + IC gamma na mesma linha), estratificável
por `classe`. **`suprimir_taxa()`** zera a própria taxa/IC quando eventos < limiar
(N<5), com fallback para macrorregião / pool de anos e **IC de Poisson exato** para
contagens pequenas. **`incidencia_nascimento()`** — casos incidentes ÷ NV × 100 mil para
as traçadoras de triagem. Tendência via quasi-Poisson com offset `log(pop)` (detecção)
ou `log(NV)` (incidência), `broom::tidy(..., exponentiate=TRUE)`.

### 9.5 Pseudo-ID — aplicação condicional
Herda `feature_eng_pacientes_SIA.R` (blocking `sexo×munpcn`, janela `ano_nasc±1`,
componentes conexos `igraph`, resultado como **INTERVALO**). **Aplicar só nos subgrupos
crônicos de alto volume SIA** (lisossômicas em TRE, PKU em acompanhamento) e **pular** nas
traçadoras raras onde a supressão N<5 domina. Cautela: `ano_nasc_proxy` tem resolução
ruim em <1 ano (chave pediátrica fraca). **Dedup de AIH no SIH: manter
incondicionalmente** (barato, sem ambiguidade).

### 9.6 Riscos técnicos
Volume do SIA (filtrar na ingestão) · disponibilidade SIM/SINASC 2024–2025 (PRELIM /
opendatasus; marcar `preliminar`) · mudança de layout entre anos (`casar_tipos` +
schema-união) · definição de caso instável (versionar lookup) · `pa_cidpec`/APAC
possivelmente ausente para rastrear TRE · left-truncation na incidência.

---

## 10. Plano analítico em 5 fases

**Fase 1 — Extração e preparação.** Transferir/validar brutos (SIA/SIH **mensais**;
SIM/SINASC **anuais**); **verificar filtro real do SIH** (sabor "qualquer campo") e
disponibilidade de **SIM/SINASC 2024–2025**; encoding latin1→UTF-8; coerção de
tipos; construir e **versionar `eim_lookup.R`** (revisão clínica dos prefixos);
rotular camadas+subgrupos com `classificar_eim()`; **agregar denominadores de uso na
ingestão** (SIA não cabe em RAM); Parquet particionado `ano×uf`; baixar pop IBGE
(`sidrar`) e **NV por UF×ano (SINASC)**; harmonizar faixas (grade pediátrica fina).

**Fase 2 — Diagnóstico da rede.** Mapear via CNES os SRTN e centros que registram EIM;
cobertura territorial; vazios diagnósticos (`geobr`); cobertura de triagem por UF.

**Fase 3 — Perfil, utilização e MORTALIDADE.** Séries 2020–2025 com ressalva COVID e
teste de tendência (Poisson/offset); decompor por sexo, faixa (grade fina), raça/cor e
**subgrupo/traçadora**; **taxas padronizadas com IC**; SIH nos dois sabores;
**mortalidade como eixo de primeira linha** (idade ao óbito, MI por EIM/100 mil NV,
causa básica vs múltipla, sub-registro).

**Fase 4 — Custos, incidência ao nascimento e inequidades.** TRE via APAC (triangular
CID × enzima), fórmulas, transplantes — componentes separados; **incidência ao
nascimento** das traçadoras de triagem; inequidades regionais (padronizadas, tensão
oferta × consanguinidade); sensibilidade CORE ↔ +LIMÍTROFE ↔ +ENVELOPE.

**Fase 5 — Painel e publicação.** `index.qmd` com KPIs, mapas (detecção × oferta;
incidência ao nascimento) e tendências; recomendações (expansão de oferta/triagem,
qualificação diagnóstica/codificação, manejo do alto custo); website Quarto
(self-contained) via **GitHub Pages** (`docs/` + `.nojekyll`).

---

## 11. Convenções analíticas e tema visual

- **Ferramentas:** `tidyverse`; `rstatix`; `ggplot2`+`ggpubr`; `flextable`+`officer`
  (e `gt` em HTML); mapas `geobr`. `.qmd` **self-contained** (`embed-resources: true`).
- **Sanity checks mínimos** antes de avançar: grade completa por base (0 faltantes);
  **eventos por `classe`×base** (nenhuma classe vazia por erro de prefixo); proporção
  core vs envelope plausível; completude de CID/`codanomal`; NV SINASC vs totais
  publicados; incidência das traçadoras vs faixas da literatura (`[VERIFICAR]`).
- **Toda métrica agregada de "EIM total" carrega a ressalva de heterogeneidade** (§8.1)
  e é lida como carga de uso de serviço, não prevalência.
- **Todos os rótulos de CID, números OMIM/ORPHA/prevalência, portarias PNTN/Lei 14.154,
  incorporações de TRE e códigos APAC estão `[VERIFICAR]` / `[CONFIRMAR via
  fetch_sigtab()]`** e não devem ser publicados sem confirmação em fonte primária.

---

## Fontes consultadas (a confirmar em fonte primária)

- Estrutura CID-10 E70–E90: [DataSUS CID10 V2008](http://www2.datasus.gov.br/cid10/V2008/WebHelp/e70_e90.htm) — rótulos de 4 caracteres **[VERIFICAR]**.
- [Lei 14.154/2021 — Planalto](https://www.planalto.gov.br/ccivil_03/_ato2019-2022/2021/lei/l14154.htm); [sanção — Câmara](https://www.camara.leg.br/noticias/765233-sancionada-lei-que-amplia-o-teste-do-pezinho-no-sus/); [reestruturação do PNTN — MS](https://www.gov.br/saude/pt-br/assuntos/noticias/2024/junho/ministerio-desenvolve-acoes-para-reestruturar-o-programa-nacional-de-triagem-neonatal); adesão por UF (Metrópoles, 2026) — **cronograma/composição por etapa `[VERIFICAR]`**.
- Mecanismo/herança/gene por doença: OMIM, Orphanet, GeneReviews — números **`[VERIFICAR]`**.
- Nosologia mecanística: Saudubray, *Inborn Metabolic Diseases*; ICIMD.

> **Partes-fonte deste plano** (revisões independentes, Opus 4.8):
> `parte_geneticista.md` · `parte_epidemiologista.md` · `parte_bioinformata.md`.


