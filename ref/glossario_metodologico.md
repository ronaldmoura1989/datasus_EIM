---
title: "Glossário metodológico"
subtitle: "Como ler os termos técnicos do painel EIM · DATASUS"
---

Este glossário explica, em linguagem acessível, os termos de método usados no
painel. Cada verbete traz uma definição curta e uma nota de **por que importa**
para interpretar os números. Está organizado em quatro blocos: (1) camadas de
captura por CID, (2) como cada base do DATASUS captura o EIM, (3) taxas,
denominadores e padronização e (4) privacidade, incerteza e cuidados de leitura.

> **Regra transversal do painel:** todos os números são de **detecção, uso de
> serviço e mortalidade registrada** — **nunca de prevalência**. As bases medem
> coisas diferentes e **não se somam**.

---

## 1. Camadas de captura por especificidade do CID

A CID-10 tem apenas 4 caracteres e **não chega ao nível do gene ou da doença
molecular**. Um mesmo código pode abrigar desde um EIM raro específico até uma
doença comum. Por isso o painel classifica cada código em **camadas**, conforme
o quanto ele identifica de fato um EIM.

Core (núcleo)
: Código CID-10 de **alta especificidade**, que mapeia com boa fidelidade um EIM
  raro (ex.: `E700` fenilcetonúria, `E710` MSUD). É a **camada primária** de
  análise — a que sustenta as taxas e a narrativa.
: **Por que importa:** é a leitura mais confiável; quando o painel diz "taxa de
  EIM", quase sempre está falando do *core*.

Limítrofe
: Código de EIM porém **inespecífico ou agregador** ("outros", "não
  especificado") — é EIM, mas não diz qual. Fica numa **camada intermediária**,
  reportada à parte do *core*.
: **Por que importa:** infla o numerador com casos reais mas mal
  caracterizados; mostrar separado permite ver o efeito de incluí-lo.

Envelope
: Categoria CID que **abriga doença comum não-EIM** morando no mesmo bloco do
  capítulo E (sobretudo `E78` dislipidemia; também gota, hemocromatose,
  intolerância à lactose). Serve **apenas como teto** (ver *bracketing*) e é
  **nunca contada como caso de EIM**. No SIA, o envelope é cerca de **20× o
  core** — quase tudo é doença comum, não EIM raro.
: **Por que importa:** se o envelope fosse somado ao *core*, afogaria por
  completo o sinal das doenças raras. Ele existe só para dimensionar o limite
  máximo do que a subcodificação poderia esconder.

Bracketing (limite superior de subcodificação)
: Uso do envelope como **teto absoluto** do quanto de EIM poderia estar
  escondido sob códigos inespecíficos. É um **limite de plausibilidade**, não
  uma estimativa de casos: o número real de EIM está em algum ponto **entre o
  core e o envelope**, muito mais perto do core.
: **Por que importa:** responde à pergunta "e se muito EIM estiver mal
  codificado?" sem inventar casos — mostra o pior cenário como fronteira, não
  como contagem.

---

## 2. Como cada base do DATASUS captura o EIM

As três bases olham o mesmo grupo de doenças por **janelas seletivas
diferentes**: o ambulatório vê os crônicos que sobrevivem e são acompanhados; a
internação vê descompensações e terapias de alto custo; o óbito vê os letais
precoces. Por isso os perfis diferem — e por isso **não se somam**.

Causa básica vs causa múltipla / qualquer linha (SIM)
: Na Declaração de Óbito, a **causa básica** (`causabas`) é a doença que
  **iniciou a cadeia de eventos** que levou à morte — o EIM como raiz. **Causa
  múltipla / qualquer linha** conta o EIM em **qualquer parte** do atestado
  (linhas A–D e a linha II), inclusive quando é só contribuinte.
: **Por que importa:** nos EIM, o EIM costuma ser a causa básica (a doença
  mata diretamente). A diferença entre "qualquer linha" e "causa básica" mede o
  **sub-registro** — quanto do EIM só aparece como coadjuvante.

Diagnóstico principal vs qualquer campo — os "dois sabores" do SIH
: Cada internação (AIH) tem um **diagnóstico principal** (o motivo da
  internação) e vários **secundários**. O painel reporta o SIH em **dois
  sabores**: (a) **principal** — leitura conservadora, o EIM foi o motivo; (b)
  **qualquer campo** — principal ou qualquer secundário, um teto que inclui
  comorbidade e contexto. Os dois **não se somam** entre si nem com o SIA.
: **Por que importa:** muito EIM entra no hospital como diagnóstico secundário
  de uma descompensação (sepse, acidose). Olhar só o principal subestima a carga
  hospitalar; olhar qualquer campo superestima o "motivo".

Detecção / uso ≠ prevalência
: Os números do painel medem **atos registrados** (atendimentos, internações,
  óbitos), não **quantas pessoas têm a doença** na população. Não existe fonte
  censitária de prevalência de EIM no Brasil.
: **Por que importa:** é o erro de leitura mais grave a evitar. "Mais registros
  numa UF" quase sempre significa **mais acesso, oferta e triagem** ali — não
  necessariamente mais doença.

Grupo heterogêneo
: "EIM" não é uma doença: é um **guarda-chuva de centenas de doenças** genéticas
  distintas, com biologia, idade de início, tratamento e letalidade
  incompatíveis. Um "total de EIM" é **soma de maçãs com laranjas** — só vale
  como *carga agregada de uso de serviço*, nunca como entidade epidemiológica.
: **Por que importa:** nunca interpretar um "total EIM" como se fosse a
  prevalência de uma condição única. A comparação defensável é por **subgrupo**
  ou por **traçadora**, não pelo agregado.

Traçadora (doença-traçadora)
: Doença **específica e bem codificada**, escolhida para **ancorar a narrativa**
  por ter CID de alta especificidade e relevância de política (triagem e/ou
  terapia de alto custo) — ex.: PKU, MSUD, fibrose cística, MPS, Gaucher. É o
  nível **mais informativo e menos ruidoso** da análise.
: **Por que importa:** substitui o "total EIM" (que não significa nada) por
  entidades concretas e comparáveis. Cada traçadora é contada pelo seu CID
  nomeado, com a mesma regra nas três bases.

---

## 3. Taxas, denominadores e padronização

Uma taxa só tem sentido com **numerador** (o que se conta) e **denominador**
(sobre qual população) bem definidos, e comparações entre lugares/anos exigem
**padronização** para não confundir doença com estrutura etária.

Padronização direta por idade e sexo
: Técnica que **remove o efeito da composição etária e de sexo** ao comparar
  populações. Aplica as taxas específicas por faixa a uma **população-padrão
  única**, produzindo taxas comparáveis entre UFs e anos.
: **Por que importa:** os EIM concentram-se na idade pediátrica e as UFs têm
  pirâmides etárias diferentes. Sem padronizar, um estado "mais jovem" pareceria
  ter mais EIM só pela estrutura da população, não pela doença.

Taxa por 100 mil habitantes vs por 100 mil nascidos vivos (NV)
: **Por 100 mil habitantes** (denominador IBGE) responde "quanta
  detecção/uso/mortalidade há na população geral". **Por 100 mil nascidos
  vivos** (denominador SINASC) responde "quantos casos incidem ao nascer" — o
  denominador natural de uma doença congênita detectada logo após o parto.
: **Por que importa:** usar o denominador errado gera indicador sem sentido. O
  denominador de nascidos vivos **só vale para EIM de triagem neonatal**;
  aplicá-lo a uma doença de apresentação tardia produz um número absurdo.

Incidência ao nascimento (proxy)
: Estimativa de **quantos casos surgem ao nascer** por 100 mil NV, usando como
  numerador os casos identificados no 1º ano de vida (ou os óbitos infantis por
  aquele EIM). É um **proxy** — uma aproximação defensável **apenas** para
  doenças cobertas pela triagem neonatal.
: **Por que importa:** é o diferencial do projeto (a HS não tinha isso), mas é
  uma proxy: não é a incidência verdadeira, e não vale para EIM não triados nem
  para os que se manifestam tarde.

IC gama / IC de Poisson exato (intervalos de confiança)
: **Intervalo de confiança (IC)** é a **faixa de incerteza** em torno de uma
  taxa estimada. O **IC gama** é o método apropriado para o IC de **taxas
  padronizadas** (via `epitools::ageadjust.direct`). O **IC de Poisson exato** é
  o adequado para **contagens pequenas** de eventos raros, como óbitos por uma
  traçadora específica.
: **Por que importa:** em doença rara, o número anual é pequeno e oscila muito
  ao acaso. O IC mostra que uma diferença entre anos ou UFs pode ser só ruído
  estatístico, não tendência real. Ler sempre a taxa **com** seu IC.

---

## 4. Privacidade, incerteza e cuidados de leitura

Supressão N<5 (LGPD)
: Regra que **oculta toda célula com menos de 5 eventos** (ex.: uma UF-ano-doença
  com 1 ou 2 óbitos). Em doença rara, um número tão pequeno poderia
  **reidentificar** o paciente (uma criança com doença rara num município
  pequeno). É uma **regra estrutural**, não uma ressalva opcional, ancorada na
  LGPD (Lei 13.709/2018 — dado de saúde é dado pessoal sensível).
: **Por que importa:** algumas linhas aparecem como "N<5 (suprimido)" **de
  propósito**, para proteger indivíduos. Quando necessário, agrega-se por
  região ou por pool de anos para poder reportar com segurança.

Pseudo-individualização / pseudo-paciente
: O SIA e o SIH públicos **não têm identificador de paciente**: cada linha é um
  atendimento, não uma pessoa. A **pseudo-individualização** agrupa registros
  que provavelmente pertencem à mesma pessoa (por sexo, município e ano de
  nascimento aproximado) para **estimar** o número de indivíduos — resultado
  reportado como **intervalo (pseudo-paciente)**, nunca como contagem exata.
: **Por que importa:** "registros" e "pessoas" são coisas diferentes. Um
  paciente de MPS em terapia de reposição enzimática gera dezenas de AIH de
  infusão por ano. Sem pseudo-individualização, contar registros infla
  grosseiramente o número de pacientes.

Grupo heterogêneo — ver §2 (repetido aqui como cuidado de leitura)
: Reforço: **não somar doenças distintas** e **não interpretar "total EIM"** como
  uma doença. Cada traçadora tem história natural própria.

Escopo painel_pezinho isolado
: As condições **não-EIM** rastreadas pelo teste do pezinho (doença falciforme
  `D57`, talassemias `D56`, imunodeficiências/SCID `D81`, toxoplasmose congênita
  `P371`) são analisadas num **pipeline separado** (`escopo = painel_pezinho`) e
  **nunca somadas às taxas de EIM** das demais páginas. Elas aparecem **só** na
  página do pezinho.
: **Por que importa:** a doença falciforme sozinha tem volume comparável ao core
  de EIM inteiro. Se fosse agregada, contaminaria todas as taxas de EIM. O
  isolamento garante que os números de EIM permaneçam limpos.

---

## Convenções de marcação

`[VERIFICAR]`
: Afirmação (rótulo CID, valor de incidência da literatura, portaria, data) que
  **exige confirmação em fonte oficial** (CID-10 DATASUS V2008, OMIM, Orphanet,
  PCDT, DOU, gov.br/saude) antes de ser publicada como definitiva.

**Fontes de método:** `plano_analise_EIM_datasus.md` (§1 desenho, §2 taxonomia
CID, §3 assimetria entre bases, §4 denominadores) e `RESULTADOS_PRELIMINARES.md`.
