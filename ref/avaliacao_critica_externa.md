# Avaliação da crítica externa ao painel EIM

> Auditoria da crítica recebida (agente externo que leu **apenas a home**) contra o
> código (`scripts/`), os `.qmd` e o site renderizado (`docs/`).
> Veredito por ponto + achados novos que a crítica não podia ver.

## Resumo

| # | Crítica | Veredito |
|---|---|---|
| 1 | Inconsistência aritmética → contaminação por *garbage codes* | **Procede no diagnóstico, erra no mecanismo** |
| 2 | "SIM é o eixo mais estável e robusto" é otimista demais | **Procede** |
| 3 | Janela 2021–2025 garante tendência crescente artefatual | **Procede em parte** (vale p/ SIA/SIH, **não** p/ SIM) |
| 4 | As três séries no mesmo gráfico não são comensuráveis | **Procede em parte** (remédio já existe, não está na home) |
| 5 | Mapa por UF precisa de suavização e de residência vs ocorrência | **Metade procede** (suavização sim; residência já resolvida) |
| 6a | Números de destaque deveriam sair como intervalo (*bracketing*) | **Procede** |
| 6b | `[VERIFICAR]` em rótulo de CID-10 = join incompleto | **Não procede como diagnóstico**, procede como recomendação |
| + | DiD da Lei 14.154, cobertura de triagem, razão mort./detecção, custo | **Parcialmente já feito; um item é inviável com os dados atuais** |

---

## 1. A inconsistência aritmética é real — mas os códigos acusados não estão na definição de caso

**A aritmética está certa.** 10.114 óbitos / 3 anos = 3.371/ano ≈ 1,66/100 mil × ~203 M.
Os óbitos infantis são **278** no pool 2021–2023 (`docs/sim_eim.html`), ou seja **2,7%** —
**97,3% dos óbitos atribuídos a EIM ocorrem depois do 1º ano de vida**, exatamente como a
crítica deduziu sem ver a página.

**O painel já publica a evidência que confirma o problema, sem tirar a conclusão.**
`docs/sim_eim.html` mostra **idade mediana ao óbito = 71,0 anos** e uma pirâmide etária.
Idade mediana de 71 anos é incompatível com a frase de abertura da home ("doenças genéticas
raras em que a triagem neonatal precoce muda radicalmente o prognóstico").

**Mas o mecanismo apontado está errado.** E86 (depleção de volume) e E87 (distúrbios
hidroeletrolíticos) — os *garbage codes* clássicos de óbito de idoso — **não existem na
lookup** (`scripts/eim_lookup.R`) e portanto **não entram em nenhum número do painel**. Os
prefixos capturados no bloco E são E70–E80, E83, E84, E85, E88, E90.

**A causa real é outra, e é de código.** Em `scripts/get_eim_data_from_SIM.R:36`:

```r
eim_causa_basica = eh_eim(causabas, "ampliado", "todos")
```

`"ampliado"` = **core + limítrofe + envelope** (`scripts/utils.R:48-52`). Ou seja o KPI
**10.114** inclui a camada envelope — **E78 (dislipidemia), E79.0 (gota), E83.1
(hemocromatose), E85 fallback (amiloidose adquirida), E88.x e E90** — precisamente os
códigos que a própria lookup declara "NUNCA caso confirmado".

Isso contrasta com as outras duas bases, que usam a camada restrita:

| Base | Definição no código | Camada |
|---|---|---|
| SIA (KPI da home) | `filter(camada == "core")` (`qmd/index.qmd`) | core |
| SIH `eim_principal` | `eh_eim(diag_princ, MODO_CAPTURA, "todos")`, `MODO_CAPTURA = "restrito"` | core |
| **SIM `eim_causa_basica`** | **`eh_eim(causabas, "ampliado", "todos")`** | **core + limítrofe + envelope** |

O gráfico da home tem o título **"Triangulação das três bases (core, 2021–2025)"** —
mas a série do SIM **não é core**. A crítica acertou o sintoma sem poder ver a linha de código.

**Ordem de grandeza do contaminante.** Somando os óbitos das traçadoras nomeadas em
`RESULTADOS_PRELIMINARES.md` §2 (1.251) + o balde E88.9 rotulado "proxy/TETO" (1.450),
restam **~7.400 óbitos (73%)** fora de qualquer traçadora — em fallbacks limítrofes e no
envelope. Não dá para decompor exatamente aqui (`data/` é gitignored), o que reforça a
recomendação da crítica.

### Ação
1. Trocar `"ampliado"` por `MODO_CAPTURA` (restrito) em `eim_causa_basica`, mantendo uma
   coluna `eim_cb_ampliado` separada para o teto — como já se faz no SIA e no SIH.
2. Publicar a **distribuição por CID de 4 dígitos e por camada** dos óbitos, na página do SIM.
3. Corrigir o KPI da home: se o número honesto ficar ~2–3 mil/ano em vez de 10.114,
   a narrativa nacional muda, e o eixo infantil (278 óbitos, 3,2–3,7/100 mil NV) passa a ser
   o número de vitrine.

---

## 2. "SIM é o eixo mais estável e robusto" — procede, e o problema é pior do que a crítica diz

A crítica está certa: cobertura/completude ≠ **validade da definição de caso**. Dois vieses
simultâneos (subnotificação por causa competidora; sobrenotificação por código inespecífico).

Há um agravante que a crítica não viu. `docs/sim_eim.html` afirma:

> "Em **95,8%** dos óbitos que mencionam um EIM, ele é a **causa básica** — ou seja, a doença
> **mata diretamente**."

Esse 95,8% é **circular**. O denominador (10.554) é o conjunto de óbitos que o *próprio filtro*
capturou, e o filtro roda sobre `causabas` + linhas. Um EIM verdadeiro codificado como sepse
ou insuficiência respiratória, sem nenhum código E na DO, é **invisível ao denominador** —
não vira "4,2%", vira zero. O 95,8% mede a estrutura da lookup, não a letalidade da doença.

### Ação
- Reescrever a frase da home ("eixo mais estável e mais robusto") e a inferência do 95,8%.
- Manter "SIM é a base de melhor **cobertura e completude**"; retirar "melhor validade".

---

## 3. Tendência artefatual — procede para SIA/SIH, e **desmente a home** no SIM

A crítica está certa quanto ao mecanismo (2021 como pior ano-base: rebote pós-pandemia +
expansão de APAC/SIGTAP + melhora de preenchimento de diagnóstico secundário). Sem série
longa não se separa tendência de recuperação. Vale para SIA e SIH.

**Mas os dados do próprio painel contradizem a home.** `RESULTADOS_PRELIMINARES.md` §3:

| ano | SIA | SIH (princ.) | SIM (causa básica) |
|---|---|---|---|
| 2021 | 175.894 | 4.391 | 3.415 |
| 2022 | 198.332 | 4.924 | 3.345 |
| 2023 | 203.508 | 5.330 | 3.354 |
| 2024 | 233.002 | 5.730 | — |
| 2025 | 237.440 | 5.648 | — |

O SIM está **estável/levemente em queda** (3.415 → 3.345 → 3.354) e o SIH **caiu** de 2024
para 2025. A página do SIM diz corretamente "estável: 1,69 → 1,65 → 1,66"; **a home diz
"Todas as três bases estão em alta no período"** — afirmação factualmente errada para o SIM
e que contradiz a própria página interna do painel.

**Sobre 2025 parcial:** os volumes de 2025 estão no nível de 2024 (SIA 237k vs 233k), o que
indica ano **não truncado**. Ainda assim a crítica está certa em exigir que isso seja
**declarado**; hoje não está em lugar nenhum das páginas.

### Ação
- Corrigir a frase "todas as três bases em alta" na home.
- Declarar explicitamente a completude de 2025 (SIA/SIH) e a indisponibilidade do SIM 2024+.
- Rodar a série longa (2010–2025) se o custo de reextração permitir; senão, marcar 2021 como
  ano-base pandêmico no gráfico.

---

## 4. Comensurabilidade das séries — procede em parte; o remédio pedido **já existe**

Está certo que SIA-PA conta **registros de produção**, não pessoas, e que colocar isso ao
lado de óbitos convida à leitura que o box de cautela proíbe.

Dois reparos:

- O gráfico **já usa eixo Y duplo** com fator explícito e subtítulo "SIA ~40× maior". Eixo
  duplo com razão de 40× é má prática, mas não é a mesma coisa que série crua sobreposta.
  A sugestão de **base 100 = 2021 ou painéis separados** é melhor e deve ser adotada.
- A **razão registros/paciente que a crítica pede já está calculada e publicada** —
  `docs/sia_eim.html`, tabela de pseudo-pacientes (*record linkage* determinístico):
  fibrose cística **5,30** reg./paciente, PKU 4,73, hipotireoidismo congênito 5,93.
  A estimativa da crítica ("dezenas de APACs/ano", "alguns milhares de indivíduos") está
  **duas ordens de grandeza fora**: a FC sozinha tem ~104–112 mil pseudo-pacientes.

### Ação
- Indexar a triangulação em base 100 = 2021 (ou painéis separados).
- Trazer a razão registros/paciente para a **home**, junto do KPI de 1.048.176.

---

## 5. Mapa por UF — suavização procede; residência vs ocorrência **já está resolvida no código**

**Procede:** não há suavização espacial. `scripts/calcular_taxas.R` faz padronização direta
idade×sexo com IC gama (`epitools::ageadjust.direct`) e supressão N<5 — nada de Empirical
Bayes ou BYM/INLA. Em evento raro com N pequeno, AC/RR/AP vão para os extremos por ruído.
A recomendação é válida e implementável.

**Não procede** a suspeita de UF de ocorrência. O pipeline usa **residência em todas as
bases**:

- SIM: `uf_res = uf_from_mun(codmunres)` (`get_eim_data_from_SIM.R:70`)
- SIH: `uf_res = uf_from_mun(munic_res)` (`get_eim_data_from_SIH.R:57`)
- SIA: `uf_pcn = uf_from_mun(pa_munpcn)` (`get_eim_data_from_SIA.R:48`)

O receio específico ("em SIH sobretudo, UF de ocorrência infla os estados com centro de
referência") **não se aplica**. O que procede é a metade documental: **os mapas nacionais
não dizem que são de residência**. Só a página de PE explicita. E a ressalva residual —
paciente que migra para perto do centro de referência e passa a ter ali seu município de
residência — já está registrada em `pe_eim.qmd:596`, mas não nas páginas nacionais.

### Ação
- Empirical Bayes (ou BYM/INLA) nos mapas de taxa por UF; manter o mapa bruto ao lado.
- Escrever "por UF de **residência**" na legenda dos quatro mapas nacionais.

---

## 6. Os dois pontos de vitrine

### 6a. Bracketing nos números de destaque — procede

Certo. Na **home** o SIA sai só como core (1.048.176) sem o envelope ao lado; o *bracketing*
só aparece dentro da página do SIA. Se o desenho central do estudo é o intervalo
core↔envelope, ele tem de aparecer onde o leitor para.

**Achado adicional, mais grave, que a crítica não podia ver: os dois números não batem entre si.**

| Página | KPI | Valor |
|---|---|---|
| home (`index.qmd`) | "registros ambulatoriais (SIA, core)" | **1.048.176** |
| página SIA (`sia_eim.qmd`) | "registros core (EIM nomeados)" | **1.345.758** |

Mesmo rótulo, dois valores. A causa é `data/consolidated/sia_eim_core.rds`, que
`get_eim_data_from_SIA.R:64` grava com `camada %in% c("core","limitrofe")` — o arquivo
chamado "core" contém **core + limítrofe**. A home lê o Parquet e filtra `camada == "core"`;
a página do SIA lê o RDS inteiro. A diferença (297.582 registros) é a camada limítrofe
rotulada como core. **Mesmo bug de camada do ponto 1, em outro lugar.**

### 6b. `[VERIFICAR]` em rótulos de CID-10 — o diagnóstico está errado, a recomendação está certa

Não há **join** de rótulos de CID-10 no pipeline: a lookup carrega nomes de subgrupo
escritos à mão, e o `[VERIFICAR]` é uma marca de honestidade do autor sobre a **atribuição
clínica do 4º caractere**, não um join que falhou (`eim_lookup.R:18` registra que o portal
DATASUS CID10 V2008 estava fora do ar na redação). Nas páginas renderizadas, os `[VERIFICAR]`
que aparecem são majoritariamente de **incidência da literatura**, **marcos normativos** e
**nomes SIGTAP** — não de rótulo de CID.

Mas a recomendação de fundo é correta e barata, e a auditoria contra a tabela oficial
CID-10 já rende **dois erros concretos**:

- **`E803` está errado.** A lookup diz `metab_bilirrubina — "Gilbert (comum) / Crigler-Najjar
  (raro)"`. Na CID-10, **E80.3 = defeitos da catalase e da peroxidase** (acatalasemia).
  **Gilbert é E80.4** e **Crigler-Najjar é E80.5**. Consequência prática: a **síndrome de
  Gilbert (E80.4)**, condição benigna presente em ~5% da população, cai hoje no *fallback*
  `E80` e é contada como **limítrofe** — mais um contaminante de adulto no mesmo balde do
  ponto 1.
- **`E85` sub-classifica hereditárias como adquiridas.** Só `E851` está marcado core. Mas
  **E85.0 (amiloidose heredofamiliar não neuropática)** e **E85.2 (heredofamiliar não
  especificada)** também são familiares, e caem no fallback `E85` descrito como "amiloidose
  adquirida — não-EIM".
- A verificar: **`E884`** ("mitocondrial") — E88.4 foi introduzido em revisões posteriores da
  CID-10 e pode não existir na tabela **V2008** usada pelo DATASUS. Se não existir, a linha
  é inerte e a nota "[VERIFICAR — muito subestimado]" tem outra explicação.

### Ação
- Home: KPI do SIA como intervalo `[core ; core+envelope]`; idem para o SIM depois da correção do ponto 1.
- Reconciliar os dois KPIs de SIA (renomear `sia_eim_core.rds` → `sia_eim_core_limitrofe.rds`
  e filtrar na página, ou alinhar as duas leituras).
- Auditar a lookup inteira contra a tabela oficial CID-10 V2008; corrigir E80.3/E80.4/E80.5,
  E85.0/E85.2; confirmar E88.4.

---

## O que a crítica acrescentaria — avaliação

| Sugestão | Situação |
|---|---|
| **DiD da Lei 14.154/2021** (implantação escalonada por fase e UF) | Novo e valioso. **Bloqueado hoje** pela mesma razão que a `discussao.qmd` já registra: o cronograma efetivo por UF está `[VERIFICAR]` (Portaria GM/MS 7.293/2025 não confirmada em fonte primária). Sem a matriz UF × fase × data, não há tratamento nem controle. É uma tarefa de fonte normativa antes de ser de modelagem. |
| **Cobertura de triagem** (procedimento de triagem no SIA ÷ NV, por UF-ano) | Excelente indicador, e a `discussao.qmd` já o recomenda ("cobertura efetiva por UF"). **Mas não sai "de graça" dos dados baixados**: `scripts/filtrar_cid_remoto.R` filtra o SIA **por CID** (`PA_CIDPRI/PA_CIDSEC/PA_CIDCAS` contra a regex EIM). O procedimento de coleta de triagem neonatal vem em geral **sem CID de EIM** e portanto **não está no recorte extraído**. Exige uma **nova passada de extração por `pa_proc_id`** no remoto. |
| **Razão mortalidade/detecção por UF** | Viável **agora** com o que já está consolidado, e é o melhor discriminador de "falha de acesso" vs "programa funcionando". A `discussao.qmd` já o propõe como indicador ("razão detecção/óbitos por macrorregião") mas **não o calcula**. Maior retorno por esforço da lista. |
| **Eixo de custo** (valor aprovado SIA/SIH) | **Já implementado**, inclusive com a ressalva que a crítica sugere. SIA: KPI "R$ 191.179.205 (core)" + top-15 SIGTAP com valor. SIH: KPI "gasto hospitalar (principal)". `discussao.qmd`: "o gasto medido é um **piso** — TRE e fórmulas trafegam também por judicialização e compras centralizadas". |

---

## Síntese

A crítica é **substantiva e majoritariamente válida**, e é notável que tenha inferido o
problema central — contaminação da mortalidade por códigos inespecíficos de adulto — a
partir de dois números da home. Erra em três lugares verificáveis: acusa E86/E87, que não
estão na definição de caso; supõe UF de ocorrência, quando o pipeline usa residência em
todas as bases; e lê os `[VERIFICAR]` como falha de join, quando são marca deliberada de
atribuição não confirmada. Subestima também o que já está feito (razão registros/paciente,
eixo de custo, Lei 14.154 tratada como confundidor na discussão).

Corrigido o mecanismo, o achado principal se sustenta e tem uma causa de **uma linha**:
`eim_causa_basica` usa `"ampliado"` enquanto SIA e SIH usam `restrito`. A mesma confusão de
camada aparece no `sia_eim_core.rds` (core+limítrofe salvo como "core"), gerando dois valores
para o mesmo KPI em duas páginas.

**Prioridade de correção:**

1. `eim_causa_basica` → camada restrita; republicar o KPI do SIM e a distribuição por CID de 4 dígitos.
2. Reconciliar os dois KPIs de SIA (1.048.176 vs 1.345.758).
3. Corrigir a home: "todas as três bases em alta" (falso p/ SIM) e "eixo mais estável e mais robusto".
4. Corrigir E80.3/E80.4/E80.5 e E85.0/E85.2 na lookup; auditar o resto contra a CID-10 V2008.
5. Declarar completude de 2025 e "UF de residência" nos mapas nacionais.
6. Empirical Bayes nos mapas; triangulação em base 100; bracketing nos KPIs da home.
7. Razão mortalidade/detecção por UF (viável já); cobertura de triagem (exige nova extração por `pa_proc_id`).
