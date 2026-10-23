## Discussão clínico-genética e insights para o poder público

**Projeto DATASUS-EIM (Erros Inatos do Metabolismo) — perspectiva de genética clínica e medicina de doenças raras.**

> **Aviso de leitura (obrigatório).** Este é um estudo **ecológico/descritivo** sobre dados
> administrativos secundários (SIA/SIH `r PER`; SIM e SINASC `r PER_SIM`, definitivos; SINASC como denominador).
> A unidade é o **registro/atendimento** (ou o óbito no SIM), **não a pessoa**. As taxas são de
> **detecção/uso e mortalidade registrada — nunca prevalência**. As três bases medem conceitos
> distintos e **não se somam**. Nenhuma associação aqui autoriza inferência causal ou individual
> (falácia ecológica). Rótulos de CID-10, prevalências de literatura e marcos normativos (PNTN,
> Lei 14.154/2021, PCDT, incorporações de TRE) estão marcados `[VERIFICAR]` onde não confirmados
> em fonte primária e não devem ser publicados como fato sem checagem.

---

# Parte A — Discussão clínico-genética dos resultados

## A.1 A dissociação incidência × mortalidade infantil à luz da história natural

O achado mais informativo do eixo de mortalidade (SIM como base central) é uma **dissociação
entre detecção e mortalidade infantil** que separa dois perfis biológicos de EIM — e essa
separação **é história natural, não ruído de dado**.

De um lado, as **doenças tratáveis e rastreadas** mostram alta intensidade de acompanhamento no
1º ano com mortalidade infantil baixíssima:

- **Hipotireoidismo congênito** (E03.1): detecção ambulatorial expressiva (`r N(inc("Hipotireoidismo_cong", "sia"))` registros SIA
  no 1º ano; `r N(inc("Hipotireoidismo_cong", "aih"))` AIH) com mortalidade infantil de **`r D2(inc("Hipotireoidismo_cong", "mi"))`/100 mil NV**
  (`r N(inc("Hipotireoidismo_cong", "obitos"))` óbitos no pool `r PER_SIM`) — muito abaixo de FC e HAC, com volume de acompanhamento comparável ou maior.
  Tratamento simples e barato (levotiroxina); triagem histórica (Fase I do PNTN).
- **PKU / fenilcetonúria** (E70.0): **`r N(inc("PKU", "obitos"))` óbitos infantis** em todo o pool `r PER_SIM`
  (**`r D2(inc("PKU", "mi"))`/100 mil NV**, a menor taxa entre as traçadoras com taxa publicável), contra
  `r N(inc("PKU", "sia"))` registros SIA e `r N(inc("PKU", "aih"))` AIH no 1º ano. É o retrato canônico do
  sucesso do modelo triagem + dietoterapia isenta de fenilalanina: uma doença que, sem triagem,
  causa deficiência intelectual grave, e que rastreada e tratada **praticamente não mata no
  primeiro ano**.
- **Fibrose cística** (E84): maior detecção entre as tratáveis (`r N(inc("Fibrose_cistica", "sia"))` registros SIA no 1º ano;
  `r N(inc("Fibrose_cistica", "aih"))` AIH), mortalidade infantil **`r D2(inc("Fibrose_cistica", "mi"))`/100 mil NV**
  (`r N(inc("Fibrose_cistica", "obitos"))` óbitos) — mais alta que PKU/HC porque a FC tem morbidade
  respiratória/pancreática progressiva mesmo sob tratamento, mas ainda muito abaixo do que seria
  sua letalidade sem cuidado organizado. Serve de **benchmark de doença bem codificada** (não é
  EIM *stricto sensu*).
- **HAC** (E25.0): mortalidade infantil **`r D2(inc("HAC", "mi"))`/100 mil NV** (`r N(inc("HAC", "obitos"))` óbitos;
  `r N(inc("HAC", "sia"))` registros SIA no 1º ano) — intermediária entre HC/PKU e FC, coerente com o
  risco de crise perdedora de sal no neonato, mitigável se detectada e tratada a tempo.

Do outro lado, as **letais precoces** — aquelas em que o **óbito neonatal é o próprio desfecho
clínico da história natural**, mesmo quando a doença é detectada:

- **Distúrbios do ciclo da ureia** (E72.2): `r N(inc("Ciclo_ureia", "obitos"))` óbitos infantis, mortalidade infantil
  **`r D2(inc("Ciclo_ureia", "mi"))`/100 mil NV**, contra apenas `r N(inc("Ciclo_ureia", "sia"))` registros SIA e
  `r N(inc("Ciclo_ureia", "aih"))` AIH no 1º ano. A hiperamonemia neonatal é uma emergência metabólica que pode
  matar em horas a dias; a razão detecção-baixa / óbito-presente é a assinatura de uma doença que
  **mata antes de gerar acompanhamento crônico**.
- **MSUD / leucinose** (E71.0): `r N(inc("MSUD", "obitos"))` óbitos infantis, **`r D2(inc("MSUD", "mi"))`/100 mil NV**, com só
  `r N(inc("MSUD", "sia"))` registros SIA e `r N(inc("MSUD", "aih"))` AIH no 1º ano. Mesmo padrão — crise metabólica
  neonatal (encefalopatia por acúmulo de aminoácidos de cadeia ramificada) como apresentação.

**Atenção à métrica.** Com a série longa, a taxa de mortalidade infantil *por nascido vivo* **não separa
sozinha** os dois perfis: ela mistura incidência da doença (rara nas letais precoces) com letalidade, e as
letais precoces têm taxa por NV baixa (ciclo da ureia `r D2(inc("Ciclo_ureia", "mi"))`, MSUD `r D2(inc("MSUD", "mi"))`) justamente por serem raras — inferior à da HAC
(`r D2(inc("HAC", "mi"))`) e comparável à do HC (`r D2(inc("Hipotireoidismo_cong", "mi"))`). O que separa os perfis é a **razão óbito infantil ÷ registros SIA no 1º ano**:
cerca de `r D1(1000 * inc("Ciclo_ureia", "obitos") / inc("Ciclo_ureia", "sia"))` óbitos por mil registros no ciclo da ureia, contra
`r D1(1000 * inc("Hipotireoidismo_cong", "obitos") / inc("Hipotireoidismo_cong", "sia"))` no HC e `r D1(1000 * inc("PKU", "obitos") / inc("PKU", "sia"))` na PKU
(FC: `r D1(1000 * inc("Fibrose_cistica", "obitos") / inc("Fibrose_cistica", "sia"))`; HAC: `r D1(1000 * inc("HAC", "obitos") / inc("HAC", "sia"))`). Isto é uma razão entre
numeradores de bases distintas — **índice de contraste, não letalidade** — e é lido como tal.

A leitura genético-clínica é direta: **a triagem só converte incidência em sobrevida quando
existe janela terapêutica e tratamento efetivo** (dieta, cofator, hormônio, quelante). Para PKU,
HC, biotinidase e galactosemia, essa janela existe e é ampla. Para MSUD e ciclo da ureia, a
janela é **estreitíssima** (o dano pode ocorrer antes de o resultado do teste retornar), e a
triagem, embora essencial, precisa vir acoplada a **protocolo de emergência metabólica** e
**acesso rápido a centro de referência** — do contrário o desfecho continua sendo o óbito.

Contraste numérico útil: a mortalidade padronizada por EIM (idade×sexo, IC gama) está **`r TR$sim$dir`**
(`r TR$sim$var`; `r SERIE$sim`/100 mil hab, `r PER_SIM`), enquanto a internação por EIM está
**`r TR$sih$dir`** (`r TR$sih$var`; `r SERIE$sih`, `r PER`). A mortalidade infantil por EIM oscila em
**`r D2(MI$min)`–`r D2(MI$max)`/100 mil NV** (`r N(MI$obitos_min)`–`r N(MI$obitos_max)` óbitos/ano), **`r MI$tr$dir`** (`r MI$tr$var`).
A leitura é mais cautelosa que a da janela curta: a série longa **não** mostra internação em alta contínua
(o aparente crescimento recente era recuperação pós-pandemia), e a **mortalidade geral em alta lenta com mortalidade
infantil sem tendência** é compatível com **melhor identificação/codificação da causa básica e envelhecimento
da coorte diagnosticada** (mais EIM de início tardio reconhecidos), mais do que com mudança na biologia
populacional. **Não é possível, com este desenho, atribuir a alta a incidência real** — hipótese de
expansão de diagnóstico e de TRE segue plausível, mas não demonstrada.

> **Ressalva.** "Detecção no 1º ano" via SIA são **registros, não crianças** (a idade no SIA é
> mal preenchida) — leem-se como **intensidade de uso**, não incidência. A mortalidade infantil
> (SIM, causa básica) é o indicador robusto. Valores de incidência da literatura na tabela
> comparativa estão `[VERIFICAR]`.

## A.2 Os limites da CID-10 para a doença molecular — vigilância cega por design

A CID-10 organiza por **substrato** (aminoácido, lipídio, carboidrato) e tem só **4 caracteres**;
ela **não chega ao gene nem à doença molecular**. Isso tem duas consequências graves para
vigilância de doença rara, ambas visíveis nos números:

**(1) Colapso de doenças distintas num único código.** O **E75.2** agrega **Gaucher + Fabry +
Niemann-Pick C** — três doenças com genes, heranças e terapias diferentes (Gaucher AR com TRE por
imiglucerase; Fabry **ligada ao X** com agalsidase; Niemann-Pick C sem TRE, mecanismo de
transporte de colesterol). No painel, E75.2 aparece com `r N(trac("Gaucher_Fabry_NPC", "SIA"))` registros SIA, `r N(trac("Gaucher_Fabry_NPC", "SIH"))` AIH e `r N(trac("Gaucher_Fabry_NPC", "SIM"))`
óbitos (causa básica) — mas **é impossível dizer, só pelo CID, quantos são de cada doença**. Como Fabry é XL e
Gaucher/NP-C são AR, nem a razão de sexo resolve a desagregação. O mesmo vale para **E74.0**, que
funde **todas as glicogenoses + doença de Pompe**, e para **E72.2**, que agrega **todo o ciclo da
ureia** (OTC ligada ao X + as formas recessivas). Para essas, a **única via de desagregação é
triangular o CID com o procedimento-APAC da enzima** (imiglucerase↔Gaucher, alglucosidase↔Pompe,
laronidase↔MPS I, idursulfase↔MPS II, galsulfase↔MPS VI) — o procedimento é **mais específico que
o CID**, invertendo a lógica usual `[CONFIRMAR códigos APAC via SIGTAP]`. O painel já
publica esse caminho na **página de Pernambuco**: a separação de doenças pelo **medicamento da APAC** (MPS VI/IVA/I/II/VII, Pompe,
Gaucher, Fabry, Wilson) desfaz parte desses baldes e é a demonstração prática do argumento.

**(2) Doença de triagem escondida em código-balde inespecífico.** A **deficiência de biotinidase**
— EIM rastreado no pezinho (Fase IV), tratável com **biotina oral barata** — é codificada pelo MS
em **E88.9 ("distúrbio metabólico não especificado")**, o **mesmo balde do envelope de ruído**.
Resultado: os `r N(trac("Biotinidase (E88.9 proxy/TETO)", "SIA"))` registros SIA / `r N(trac("Biotinidase (E88.9 proxy/TETO)", "SIH"))` AIH / `r N(trac("Biotinidase (E88.9 proxy/TETO)", "SIM"))` óbitos rotulados "biotinidase" são um
**TETO**, não a doença — E88.9 agrega outros distúrbios, e a AIH-principal é sobretudo
ruído inespecífico. A "mortalidade infantil da biotinidase" de **`r D2(inc("Biotinidase (E88.9 TETO)", "mi"))`/100 mil NV**
(`r N(inc("Biotinidase (E88.9 TETO)", "obitos"))` óbitos) — a maior de todas as traçadoras — é o exemplo
perfeito do artefato: **a biotinidase tratada quase não mata** — esses óbitos são de outros
distúrbios metabólicos letais que caem no mesmo E88.9. Ou seja, o sistema tem uma doença de
triagem que ele **não consegue enxergar no próprio dado de vigilância**.

Para além dessas, a CID-10 torna **mitocondriais** (espalhadas em E88.x e fora do capítulo E, em
G31.x/G93.x) e **CDG/defeitos de glicosilação** (sem código dedicado) **praticamente inceptáveis**
— subgrupos grosseiros e muito subestimados por construção. **Vigiar doença rara com CID-10 é
vigiar com uma lente que funde entidades e esconde outras.**

## A.3 Subdiagnóstico, diagnóstico tardio e viés de gravidade/sobrevivência entre bases

Os EIM sofrem de **odisseia diagnóstica** clássica — do primeiro sintoma ao diagnóstico
molecular podem passar anos, com múltiplas consultas e internações inespecíficas. No dado
administrativo isso se manifesta como **numerador que é uma fração pequena e enviesada** dos casos
verdadeiros, e o viés tem estrutura previsível: **cada base é uma janela seletiva distinta do
espectro EIM**.

- O **SIM** enviesa para os EIM **mais letais e precoces** — captura crianças que morreram, às
  vezes **antes de qualquer registro ambulatorial** (o óbito é a primeira e única aparição do
  caso no sistema), e mesmo lá o EIM pode escapar sob causa inespecífica (sepse, acidose,
  encefalopatia, IRA neonatal). Por isso o SIM é a **base central** aqui, invertendo o papel
  marginal que teve em projetos de doença crônica não letal.
- O **SIA** enviesa para os EIM **tratáveis e cronicamente acompanhados** — o paciente
  **sobrevive para gerar registros** (genética, nutrição, fórmulas, infusões). Os EIM que matam
  antes do diagnóstico são **invisíveis** aqui.
- O **SIH** fica intermediário, e precisa ser lido em **dois sabores não somáveis** (EIM como
  diagnóstico principal vs. EIM em qualquer campo/secundário), porque o EIM frequentemente entra
  como **secundário** de uma descompensação.

A consequência para a interpretação é forte: **a diferença de perfil de traçadoras entre SIA, SIH
e SIM não é inconsistência de dado — é o gradiente de gravidade/sobrevivência tornado visível.**
Fibrose cística, PKU e hipotireoidismo dominam o SIA (crônicos que vivem); ciclo da ureia e MSUD
pesam relativamente mais no SIM (letais que morrem cedo). Ler qualquer base isolada como "a
epidemiologia dos EIM" seria erro grosseiro.

## A.4 Doenças lisossômicas e o peso da terapia de reposição enzimática (TRE)

As **mucopolissacaridoses (MPS)** têm **peso hospitalar desproporcional ao seu número de
pacientes**: MPS I/II/outras somam `r N(trac("MPS_I", "SIA") + trac("MPS_II", "SIA") + trac("MPS_outras", "SIA"))` registros SIA mas concentram um volume expressivo de AIH
(MPS "outras" `r N(trac("MPS_outras", "SIH"))`; MPS II `r N(trac("MPS_II", "SIH"))`; MPS I `r N(trac("MPS_I", "SIH"))` AIH), contra poucos óbitos
por causa básica em `r PER_SIM` (MPS "outras" `r N(trac("MPS_outras", "SIM"))`; MPS II `r N(trac("MPS_II", "SIM"))`; MPS I `r N(trac("MPS_I", "SIM"))`). O motivo
é biológico-terapêutico: as MPS têm **TRE por infusão endovenosa periódica** (laronidase,
idursulfase, galsulfase), e **cada infusão gera uma AIH** — muitas vezes em regime de
**hospital-dia**, o que também explica a **permanência mediana muito curta (próxima de zero)** observada no recorte de
PE. Ou seja, **o número de AIH mede intensidade de tratamento crônico, não número de pacientes
nem gravidade aguda**. A gravidade aguda real (descompensação, UTI) está na cauda longa e nos EIM
letais precoces (ciclo da ureia, tirosinemia), não nas infusões de TRE.

Duas implicações genético-clínicas:

- A **desagregação por procedimento-APAC** (§A.2) não é só um truque de dado — é o que permite
  transformar "E75.2/E74.0/E76.x" em Gaucher, Pompe, MPS I, MPS II, MPS VI **identificáveis**, e
  portanto quantificar quem está de fato em TRE e a que custo — caminho que a página de
  Pernambuco já percorre ao separar MPS VI/IVA/I/II/VII, Pompe, Gaucher, Fabry e Wilson pelo medicamento da APAC.
- O **gasto medido é um piso**: TRE e fórmulas trafegam também por **judicialização** e compras
  centralizadas, parcialmente **fora do SIA/SIH**. Medicamentos órfãos de EIM estão entre os mais
  judicializados do SUS; o dado administrativo não distingue via incorporada de ordem judicial.

## A.5 Consanguinidade / efeito fundador no Nordeste — hipótese para EIM autossômicos recessivos

A **imensa maioria dos EIM é autossômica recessiva** (aminoacidopatias, acidúrias orgânicas,
galactosemia, MSUD, a maioria das lisossômicas; exceções XL notáveis: Fabry, MPS II/Hunter, OTC,
Lesch-Nyhan). Para doenças AR, **consanguinidade e efeito fundador elevam a incidência real** —
uniões entre parentes aumentam a probabilidade de homozigose por descendência, e populações com
isolamento histórico acumulam alelos fundadores. O Nordeste brasileiro, e Pernambuco em
particular, é uma região com **maior consanguinidade relatada** e com **alta prevalência de
doença falciforme** (que domina o painel do pezinho no estado) — o que torna **plausível** uma
maior incidência de EIM AR na região `[VERIFICAR magnitude na literatura brasileira de
consanguinidade e efeito fundador — p.ex. estudos do Nordeste]`.

Aqui está o **nó interpretativo central**, e é preciso ser explícito: **este dado ecológico não
consegue separar dois gradientes que empurram em sentidos opostos.**

- **Consanguinidade/efeito fundador** puxaria a **incidência real** para cima no Nordeste.
- **Acesso a centros de referência** puxa a **detecção** para cima no **Sul/Sudeste** (mais
  serviços, mais genética, mais triagem qualificada).

No recorte de PE isso aparece de forma nítida: **Recife concentra a maior parte do ambulatorial
do estado** — a cidade participa muito mais no SIA (uso contínuo no centro de referência) do que
no SIM (óbito, que ocorre onde a pessoa mora, mais distribuído pelo interior). O município de
residência registrado pode **já ser o de encaminhamento/TFD**, não o de origem. Portanto: a
concentração no Recife reflege **acesso à rede**, não onde os casos "existem". **Afirmar "mais
detecção", nunca "mais doença"** — a distinção real entre incidência e acesso exige desenho
específico (busca ativa, denominador de triados por UF), não é inferível deste descritivo.

---

# Parte B — Insights acionáveis para o poder público (ângulo genético-clínico)

> Cada recomendação vem ancorada a um achado, com **ação proposta** e **como o SUS mediria o
> avanço**. Todas respeitam a ressalva ecológica: são hipóteses de política a testar, não
> conclusões causais.

## B.1 Ampliar e qualificar a triagem neonatal, priorizando por tratabilidade × letalidade

- **Achado motivador.** A dissociação incidência × mortalidade infantil (§A.1) mostra que a
  triagem **converte incidência em sobrevida onde há tratamento efetivo** (PKU: `r N(inc("PKU", "obitos"))` óbitos infantis
  no pool `r PER_SIM`; HC: `r D2(inc("Hipotireoidismo_cong", "mi"))`/100 mil NV) mas **não basta sozinha** para os letais precoces (ciclo da ureia
  `r D2(inc("Ciclo_ureia", "mi"))`; MSUD `r D2(inc("MSUD", "mi"))`/100 mil NV — taxas baixas por NV por serem doenças raras, mas com óbito desproporcional ao
  acompanhamento registrado, §A.1), onde o óbito neonatal é o desfecho mesmo com detecção.
- **Ação.** Acelerar a implementação escalonada da **Lei 14.154/2021** priorizando as Etapas 2–3
  (aminoacidopatias, galactosemias, ciclo da ureia, beta-oxidação, lisossômicas)
  `[VERIFICAR cronograma efetivo por UF na Portaria GM/MS 7.293/2025]`, mas **acoplando cada
  doença de janela terapêutica estreita a um protocolo de emergência metabólica** (retorno rápido
  do resultado, fluxo de contato imediato com referência, disponibilidade de fórmula/medicação de
  urgência). Triar MSUD ou ciclo da ureia **sem** via de resposta em horas não reduz óbito.
- **Como o SUS mediria.** (i) **Mortalidade infantil específica por EIM/100 mil NV** (SINASC como
  denominador) por traçadora, série anual — queda esperada nas tratáveis à medida que a triagem se
  universaliza; (ii) **tempo entre coleta e resultado** e **tempo até primeiro atendimento em
  referência** (indicador de processo do PNTN); (iii) **cobertura de triagem por UF** reportada
  ao lado da detecção, para não confundir política com epidemiologia.

## B.2 Estruturar a confirmação diagnóstica molecular — fechar o ciclo da triagem

- **Achado motivador.** A CID-10 **não chega à doença molecular** (§A.2): E75.2 funde
  Gaucher/Fabry/NP-C, E74.0 funde as glicogenoses + Pompe, E88.9 esconde a biotinidase. Triagem
  positiva é **suspeita**, não diagnóstico — sem laboratório confirmatório (enzimático/molecular)
  e sem geneticista, o ciclo não fecha e o dado de vigilância permanece cego.
- **Ação.** Instituir/expandir **laboratório confirmatório de referência** (espectrometria de
  massas em tandem para Etapa 2; dosagem enzimática e **sequenciamento** para lisossômicas e
  demais) vinculado ao PNTN, com **fluxo formal triagem-positiva → confirmação → diagnóstico
  molecular**. Garantir **geneticista clínico** no ponto de confirmação (interpretação de
  variante, aconselhamento, definição de conduta).
- **Como o SUS mediria.** (i) **Proporção de triagens positivas com confirmação laboratorial
  concluída** e tempo até confirmação; (ii) **proporção de casos com diagnóstico molecular
  específico** (não apenas CID-balde); (iii) **queda na proporção de óbitos codificados em CID
  inespecífico** (E88.x) — proxy de melhora da especificidade diagnóstica.

## B.3 Rede de centros de referência em doenças raras e genética médica

- **Achado motivador.** A concentração no Recife (§A.5) e o padrão de encaminhamento (interior
  "aparece pouco" no SIA porque **encaminha** ao centro da capital; TFD com residência atualizada)
  evidenciam **rede centralizada e vazios assistenciais no interior**. A odisseia diagnóstica
  (§A.3) é agravada pela escassez de geneticistas.
- **Ação.** Fortalecer a **Política Nacional de Atenção Integral às Pessoas com Doenças Raras**
  (Portaria GM/MS 199/2014 `[VERIFICAR consolidação vigente]`) com **habilitação de novos serviços
  de referência**, **formação de recursos humanos** (residência/fellowship em genética médica e
  em erros inatos do metabolismo) e **teleconsulta/telegenética** para levar suporte especializado
  ao interior sem depender de deslocamento por TFD.
- **Como o SUS mediria.** (i) **Cobertura territorial** — nº e distribuição de serviços de
  referência habilitados (CNES) e razão população/serviço por macrorregião; (ii) **dois mapas
  lado a lado (detecção × oferta)** para monitorar redução de vazios; (iii) **tempo/distância
  média até o centro de referência**; (iv) **nº de geneticistas por 100 mil hab** por UF;
  (v) volume de **teleconsultas** de genética para municípios do interior.

## B.4 Acesso a dietoterapia / fórmulas metabólicas e TRE com critérios de PCDT

- **Achado motivador.** O sucesso das tratáveis rastreadas depende de **dieta/fórmula** (PKU,
  MSUD, galactosemia) — cujo acesso trafega por vias parcialmente **judiciais e fora do SIA/SIH**
  — e o **peso hospitalar das MPS/lisossômicas** é TRE por infusão (§A.4), com gasto medido que é
  **piso** e forte judicialização.
- **Ação.** Consolidar **PCDT vigentes** com critérios claros de elegibilidade,
  início/manutenção/suspensão para **TRE** e para **fórmulas metabólicas**, garantindo
  **dispensação regular** (evitar que a via de acesso seja a judicial) e vinculando a
  desagregação por **procedimento-APAC-enzima** ao monitoramento `[VERIFICAR PCDT e incorporações
  CONITEC de cada enzima/fórmula]`.
- **Como o SUS mediria.** (i) **Continuidade de dispensação** (proporção de pacientes em TRE/dieta
  sem interrupção); (ii) **proporção do acesso por via judicial vs. incorporada** (indicador de
  falha da via regular); (iii) **gasto por doença desagregada via APAC-enzima** (não "total
  lisossômicas"); (iv) **AIH de infusão em hospital-dia** como proxy de pacientes ativos em TRE
  (com ressalva de que AIH ≠ paciente).

## B.5 Aconselhamento genético em regiões de alta consanguinidade

- **Achado motivador.** A maioria dos EIM é **AR** (§A.5); consanguinidade e efeito fundador
  elevam a incidência real de EIM AR, e o Nordeste/PE é região de maior consanguinidade relatada e
  de alta carga de doença falciforme (também AR) `[VERIFICAR magnitude]`. Para doença AR, o risco
  de recorrência em casais aparentados é substancial e **prevenível com informação**.
- **Ação.** Estruturar **aconselhamento genético** acessível em regiões de maior consanguinidade —
  incluindo **triagem de portadores** em famílias com caso-índice, aconselhamento pré-concepcional
  e reprodutivo, e articulação com atenção primária. Integrar ao trabalho dos centros de
  referência (B.3) e à telegenética.
- **Como o SUS mediria.** (i) **Nº de famílias com caso-índice de EIM AR que receberam
  aconselhamento** e triagem de portadores; (ii) **cobertura de aconselhamento pré-natal/pré-
  concepcional** em municípios de maior consanguinidade; (iii) monitoramento longitudinal de
  **recorrência familiar** (com as devidas salvaguardas éticas e de LGPD — doença rara por
  município é reidentificável, exigindo supressão N<5 e agregação).

## B.6 Registro/codificação que permita distinguir a doença molecular

- **Achado motivador.** Toda a discussão §A.2 mostra que a **CID-10 é insuficiente para
  vigilância de doença rara**: funde entidades (E75.2, E74.0, E72.2) e esconde outras (biotinidase
  em E88.9). Hoje só a triangulação **CID × procedimento-APAC** desagrega parte das lisossômicas —
  e ainda assim de forma parcial.
- **Ação.** (i) Adotar/estimular no SUS um **sistema de codificação mais granular para doenças
  raras** — vínculo com **Orphacode/ORDO** e, no horizonte, com o **diagnóstico genético**
  (variante/gene) — para que a doença molecular seja identificável no registro; (ii) no curto
  prazo, **padronizar o par CID + procedimento-APAC-enzima** como chave de desagregação;
  (iii) resolver a codificação da **biotinidase** para fora do balde E88.9.
- **Como o SUS mediria.** (i) **Proporção de registros de doença rara com Orphacode/diagnóstico
  molecular vinculado** (meta crescente); (ii) **razão CORE : não-especificado** por subgrupo
  (proxy de qualidade de codificação — quanto menos massa no E88.x/E7x9, melhor); (iii)
  **consistência sexo × CID** para entidades XL (Fabry, MPS II, OTC, Lesch-Nyhan) como checagem
  de qualidade; (iv) capacidade de **isolar biotinidase** no dado após correção de codificação.

---

## Ressalvas finais (transversais a A e B)

- **Causalidade não é inferível.** Desenho ecológico, unidade = registro/óbito, sem ID
  longitudinal. Gradientes geográficos misturam **incidência real e acesso** — não separáveis
  aqui.
- **Detecção/uso ≠ prevalência.** Séries em alta (SIA/SIH) refletem **expansão de triagem e TRE**,
  não necessariamente aumento de incidência; a mortalidade padronizada **`r TR$sim$dir`**
  (`r TR$sim$var`) e a internação **`r TR$sih$dir`** pedem cautela: a série longa não sustenta a narrativa simples de "tudo em alta por expansão".
- **Heterogeneidade extrema.** "EIM" agrega centenas de entidades incomparáveis — nunca ler um
  "total EIM" como doença; a narrativa se ancora em **traçadoras** e **subgrupos**, não no
  agregado.
- **Marcos normativos e prevalências `[VERIFICAR]`.** PNTN, Lei 14.154/2021, PCDT, incorporações
  CONITEC, rótulos de CID-10 e prevalências de literatura exigem confirmação em fonte primária
  antes de uso oficial.
- **SIM/SINASC cobrem `r PER_SIM` (definitivos), SIA/SIH `r PER`; idade no SIA é mal preenchida; E88.9/E78 são teto, não caso.**
