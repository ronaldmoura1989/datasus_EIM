## Discussão clínico-genética e insights para o poder público

**Projeto DATASUS-EIM (Erros Inatos do Metabolismo) — perspectiva de genética clínica e medicina de doenças raras.**

> **Aviso de leitura (obrigatório).** Este é um estudo **ecológico/descritivo** sobre dados
> administrativos secundários (SIA/SIH 2021–2025; SIM 2021–2023; SINASC como denominador).
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

- **Hipotireoidismo congênito** (E03.1): detecção ambulatorial expressiva (38.782 registros SIA
  no 1º ano) com mortalidade infantil de **0,08/100 mil NV** — a menor entre as tratáveis de
  alto volume. Tratamento simples e barato (levotiroxina); triagem histórica (Fase I do PNTN).
- **PKU / fenilcetonúria** (E70.0): **1 óbito infantil** em todo o pool 2021–2023 (taxa
  suprimida por N<5), contra 7.063 registros SIA e 78 AIH no 1º ano. É o retrato canônico do
  sucesso do modelo triagem + dietoterapia isenta de fenilalanina: uma doença que, sem triagem,
  causa deficiência intelectual grave, e que rastreada e tratada **praticamente não mata no
  primeiro ano**.
- **Fibrose cística** (E84): maior detecção entre as tratáveis (50.826 registros SIA no 1º ano),
  mortalidade infantil **0,81/100 mil NV** — mais alta que PKU/HC porque a FC tem morbidade
  respiratória/pancreática progressiva mesmo sob tratamento, mas ainda muito abaixo do que seria
  sua letalidade sem cuidado organizado. Serve de **benchmark de doença bem codificada** (não é
  EIM *stricto sensu*).
- **HAC** (E25.0): mortalidade infantil **0,23/100 mil NV** — intermediária, coerente com o
  risco de crise perdedora de sal no neonato, mitigável se detectada e tratada a tempo.

Do outro lado, as **letais precoces** — aquelas em que o **óbito neonatal é o próprio desfecho
clínico da história natural**, mesmo quando a doença é detectada:

- **Distúrbios do ciclo da ureia** (E72.2): 8 óbitos infantis, mortalidade infantil
  **0,10/100 mil NV**, contra apenas 135 registros SIA e 14 AIH no 1º ano. A hiperamonemia
  neonatal é uma emergência metabólica que pode matar em horas a dias; a razão detecção-baixa /
  óbito-presente é a assinatura de uma doença que **mata antes de gerar acompanhamento crônico**.
- **MSUD / leucinose** (E71.0): 6 óbitos infantis, **0,08/100 mil NV**, com só 102 registros SIA
  e 33 AIH no 1º ano. Mesmo padrão — crise metabólica neonatal (encefalopatia por acúmulo de
  aminoácidos de cadeia ramificada) como apresentação.

A leitura genético-clínica é direta: **a triagem só converte incidência em sobrevida quando
existe janela terapêutica e tratamento efetivo** (dieta, cofator, hormônio, quelante). Para PKU,
HC, biotinidase e galactosemia, essa janela existe e é ampla. Para MSUD e ciclo da ureia, a
janela é **estreitíssima** (o dano pode ocorrer antes de o resultado do teste retornar), e a
triagem, embora essencial, precisa vir acoplada a **protocolo de emergência metabólica** e
**acesso rápido a centro de referência** — do contrário o desfecho continua sendo o óbito.

Contraste numérico útil: a mortalidade padronizada por EIM (idade×sexo, IC gama) é **estável em
~1,66/100 mil hab** (1,69 → 1,65 → 1,66 em 2021–2023), enquanto a **internação por EIM sobe
claramente** (2,17 → 2,83/100 mil, ~+9%/ano). A mortalidade infantil por EIM fica em
**~3,2–3,7/100 mil NV**. **Denominador de óbito estável + detecção/internação em alta** é
compatível com **expansão de diagnóstico e de TRE, não com aumento de incidência real** — exatamente
o que se esperaria de ampliação de triagem e de rede, não de mudança na biologia populacional.

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
transporte de colesterol). No painel, E75.2 aparece com 45.207 registros SIA, 3.124 AIH e 149
óbitos — mas **é impossível dizer, só pelo CID, quantos são de cada doença**. Como Fabry é XL e
Gaucher/NP-C são AR, nem a razão de sexo resolve a desagregação. O mesmo vale para **E74.0**, que
funde **todas as glicogenoses + doença de Pompe**, e para **E72.2**, que agrega **todo o ciclo da
ureia** (OTC ligada ao X + as formas recessivas). Para essas, a **única via de desagregação é
triangular o CID com o procedimento-APAC da enzima** (imiglucerase↔Gaucher, alglucosidase↔Pompe,
laronidase↔MPS I, idursulfase↔MPS II, galsulfase↔MPS VI) — o procedimento é **mais específico que
o CID**, invertendo a lógica usual `[CONFIRMAR códigos APAC via SIGTAP]`.

**(2) Doença de triagem escondida em código-balde inespecífico.** A **deficiência de biotinidase**
— EIM rastreado no pezinho (Fase IV), tratável com **biotina oral barata** — é codificada pelo MS
em **E88.9 ("distúrbio metabólico não especificado")**, o **mesmo balde do envelope de ruído**.
Resultado: os 14.280 registros SIA / 27.236 AIH / 1.450 óbitos rotulados "biotinidase" são um
**TETO**, não a doença — E88.9 agrega outros distúrbios, e a AIH-principal de 27.236 é sobretudo
ruído inespecífico. A "mortalidade infantil da biotinidase" de **0,91/100 mil NV** é o exemplo
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
pacientes**: MPS I/II/outras somam ~37.910 registros SIA mas concentram um volume enorme de AIH
(MPS "outras" 8.030; MPS II 1.803; MPS I 1.053 AIH), contra pouquíssimos óbitos (6–19). O motivo
é biológico-terapêutico: as MPS têm **TRE por infusão endovenosa periódica** (laronidase,
idursulfase, galsulfase), e **cada infusão gera uma AIH** — muitas vezes em regime de
**hospital-dia**, o que também explica a **permanência mediana ~0 dia** observada no recorte de
PE. Ou seja, **o número de AIH mede intensidade de tratamento crônico, não número de pacientes
nem gravidade aguda**. A gravidade aguda real (descompensação, UTI) está na cauda longa e nos EIM
letais precoces (ciclo da ureia, tirosinemia), não nas infusões de TRE.

Duas implicações genético-clínicas:

- A **desagregação por procedimento-APAC** (§A.2) não é só um truque de dado — é o que permite
  transformar "E75.2/E74.0/E76.x" em Gaucher, Pompe, MPS I, MPS II, MPS VI **identificáveis**, e
  portanto quantificar quem está de fato em TRE e a que custo.
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
  triagem **converte incidência em sobrevida onde há tratamento efetivo** (PKU: ~1 óbito infantil
  no pool; HC: 0,08/100 mil NV) mas **não basta sozinha** para os letais precoces (ciclo da ureia
  0,10; MSUD 0,08/100 mil NV), onde o óbito neonatal é o desfecho mesmo com detecção.
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
  não necessariamente aumento de incidência; mortalidade padronizada estável (~1,66/100 mil)
  reforça essa leitura.
- **Heterogeneidade extrema.** "EIM" agrega centenas de entidades incomparáveis — nunca ler um
  "total EIM" como doença; a narrativa se ancora em **traçadoras** e **subgrupos**, não no
  agregado.
- **Marcos normativos e prevalências `[VERIFICAR]`.** PNTN, Lei 14.154/2021, PCDT, incorporações
  CONITEC, rótulos de CID-10 e prevalências de literatura exigem confirmação em fonte primária
  antes de uso oficial.
- **SIM cobre só 2021–2023; idade no SIA é mal preenchida; E88.9/E78 são teto, não caso.**
