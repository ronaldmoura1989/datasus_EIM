# Guia de filtragem e processamento dos microdados do DATASUS

**Para quem:** quem for começar uma análise nova (outra doença ou outro grupo de doenças) a
partir dos brutos 2010+ já baixados no R550-2. O guia reúne o raciocínio do projeto
`datasus_EIM`: o que fazer em cada etapa, por quê e quais erros já cometemos. Os scripts
citados estão em `datasus_EIM/scripts/` e servem de molde.

**Bases cobertas:** SIA-PA (ambulatorial), SIH-RD (internação), SIM-DO (óbitos) e SINASC
(nascidos vivos), com população do IBGE e procedimentos do SIGTAP.

---

## 1. Princípios

1. **Os brutos não se tocam.** Os DBC originais em `~/Documentos/ronald/datasus_raw/` são
   compartilhados por todos os projetos. Nunca apagar, mover nem reescrever no lugar. Cada
   projeto gera os seus filtrados em pasta própria.
2. **Nunca carregar uma base inteira em memória.** O SIA-PA 2010–2025 tem 6,7 bilhões de
   linhas. Um DBC lido ocupa de 6 a 9 vezes o tamanho do arquivo em RAM, e o SIA inteiro passaria
   de 1 TB (o R550-2 tem 370 GB). Tudo é feito arquivo a arquivo, e só se juntam os recortes
   pequenos.
3. **Uma passada, várias perguntas.** A filtragem marca cada linha com flags por escopo
   (`hit_eim`, `hit_hemato`…) em vez de gerar um recorte por projeto. Antes de refiltrar,
   veja se o escopo de que você precisa já está nos filtrados.
4. **O denominador vem do arquivo inteiro, antes do filtro.** Depois de filtrar, não há
   mais como saber quantos atendimentos, internações ou óbitos existiam no total.
5. **A definição de caso é uma tabela versionada, não um CID solto.** Mudar a tabela muda
   todos os números, por isso cada versão é registrada com hash.
6. **Separar o certo do provável.** Use camadas (núcleo × inespecífico × teto) e publique
   intervalos em vez de um número único quando o código CID é ambíguo.
7. **Os dados medem uso de serviço e óbito registrado, nunca prevalência ou incidência
   verdadeira.** As bases não se somam.
8. **Nenhum número é digitado à mão no texto publicado.** Todo número sai do cálculo, por
   R inline. Na série longa, frases como "mortalidade estável" ou "+9%/ano" ficaram erradas
   justamente porque estavam escritas à mão.
9. **Supressão de N < 5 (LGPD)** em toda saída: contagens e também as taxas calculadas
   sobre elas.
10. **Jobs longos rodam em tmux** e são retomáveis (checkpoint por arquivo). Rodar de novo
    deve ser sempre seguro.

---

## 2. Onde estão as coisas

| O quê | Onde (R550-2, usuário `ronald`) |
|---|---|
| DBC originais 2010+ (12.122 arquivos, 209 GB) | `~/Documentos/ronald/datasus_raw/{SIA-PA,SIH-RD,SIM-DO[/PRELIM],SINASC[/PRELIM]}` |
| Manifesto do FTP (arquivo, URL, tamanho esperado) | `~/Documentos/ronald/datasus_raw/manifest/manifesto_atual.tsv` |
| Catálogo de colunas por base × ano | `~/Documentos/ronald/datasus_raw/logs/schema_{catalogo,resumo}.tsv` |
| Filtrados do EIM e correlatos (parquet) | `~/Documentos/ronald/datasus_filtrado/<BASE>/{filtrado,denominador,ok}/` |
| Ambiente R | conda env `datasus` (`~/miniconda3/envs/datasus`, R 4.4, read.dbc, microdatasus, arrow, tmux) |
| tmux | `~/miniconda3/envs/datasus/bin/tmux` (não há tmux no sistema) |
| Quarto | `~/opt/quarto-1.9.37/bin/quarto` (o do conda-forge é quebrado) |

O servidor não tem sudo. Tudo vive no env conda, e o ambiente é recriado com
`scripts/r550/setup_ambiente.sh` e `setup_painel.sh`.

**Lika (legado):** `/media/prospecmol/disk2/ronald/` guarda RData antigos (SIA/SIH
2020–2025 pelo `fetch_datasus`, SIM 2013–2025 já processado) e os filtrados de outros
projetos (cardio, EII, SINAN dengue). A série 2010+ do R550-2 os substitui. Atenção: o SIM
do Lika vem processado pelo microdatasus (nomes e códigos diferentes do bruto).

---

## 3. Etapa 1 — Download dos brutos (já feito; repetir só para atualizar)

Scripts: `scripts/r550/gerar_manifesto.py`, `baixar_brutos.sh`, `verificar_download.py`.

| Base | Diretório FTP (`ftp.datasus.gov.br/dissemin/publicos/`) | Arquivo | Periodicidade |
|---|---|---|---|
| SIA-PA | `SIASUS/200801_/Dados` | `PA{UF}{AA}{MM}[a-z].dbc` (UFs grandes vêm em partes a, b, c…) | mensal |
| SIH-RD | `SIHSUS/200801_/Dados` | `RD{UF}{AA}{MM}.dbc` | mensal |
| SIM-DO | `SIM/CID10/DORES` e `SIM/PRELIM/DORES` | `DO{UF}{AAAA}.dbc` | anual |
| SINASC | `SINASC/1996_/Dados/DNRES` e `SINASC/PRELIM/DNRES` | `DN{UF}{AAAA}.dbc` | anual |

- **Manifesto primeiro.** Liste o FTP com o tamanho esperado de cada arquivo. O download só
  aceita um arquivo quando o tamanho bate exatamente, e quem tem tamanho diferente
  (o DATASUS republicou) é baixado de novo. Assim o processo é retomável e detecta
  republicação.
- **Preliminar × definitivo:** um ano preliminar que já tem definitivo é descartado. O ano
  preliminar fica numa subpasta `PRELIM` e é marcado como `status_dado = PRELIM` em todas as
  etapas seguintes. **Ele não entra nas taxas.**
- **Não use `microdatasus::fetch_datasus` para baixar:** ele apaga o DBC, carrega tudo em
  RAM e não retoma. O microdatasus serve para consultar tabelas (SIGTAP), não para
  baixar.
- Download com 4 conexões em paralelo, em tmux. A passada inteira (12.122 arquivos,
  224 GB) levou cerca de 6 horas em 21/10/2026.

**Corte temporal do projeto EIM:** SIA e SIH em 2010–2025 (os mensais vão até 2026, então
2025 é o último ano completo). SIM e SINASC definitivos em 2010–2024 (2025 é preliminar).
Começar em 2010 tira a pandemia do papel de ano-base e cobre o período anterior à Política
Nacional de Doenças Raras (Portaria GM/MS 199/2014).

---

## 4. Etapa 2 — Filtragem (um DBC por processo)

Scripts: `scripts/r550/config_filtro.R` (escopos), `filtrar_um.R` (um arquivo),
`orquestrar_filtro.sh` (paralelismo).

### 4.1 O que cada processo faz, na ordem

1. Lê o DBC com `read.dbc(as.is = TRUE)` e põe os nomes de coluna em MAIÚSCULAS. O nome das
   colunas muda entre anos e o maiúsculo evita divergências bobas.
2. **Calcula o denominador agregado sobre todas as linhas** (tabela abaixo).
3. Calcula as flags `hit_<escopo>` por linha.
4. Mantém só as linhas com algum hit.
5. **Converte todas as colunas para texto.** O tipo e o número de colunas mudam ao longo da
   série (SIA de 54 para 62 colunas, SIH de 86 para 113, SIM de 59 para 87). Gravar como
   texto evita que a junção dos anos quebre. Números saem sem notação científica, e o texto
   latin1 é convertido para UTF-8 (o parquet exige UTF-8).
6. Acrescenta colunas de rastreio (`arq`, `arq_uf`, `arq_ano`, `arq_mes`, `arq_parte`,
   `status_dado`).
7. Grava em `.tmp`, renomeia (escrita atômica) e cria `ok/<ARQ>.ok` com o tamanho do DBC.
   Um arquivo que já tem `.ok` com o mesmo tamanho é pulado.

Denominadores gravados por arquivo (`denominador/<ARQ>.parquet`):

| Base | Contagens | Estratos |
|---|---|---|
| SIA-PA | linhas, Σ `PA_QTDAPR`, Σ `PA_VALAPR` | competência, `PA_DOCORIG`, grupo do procedimento (4 díg.), UF de residência |
| SIH-RD | AIH distintas, óbitos, diárias | ano/mês de competência, `IDENT`, UF de residência, UF do hospital, sexo |
| SIM-DO | óbitos | ano, UF de residência, sexo, faixa quinquenal, causa básica (3 caracteres) |
| SINASC | nascidos vivos | ano, UF de residência, sexo, `IDANOMAL` |

### 4.2 Onde está o CID em cada base

| Base | Campos com um CID | Campos com vários CIDs |
|---|---|---|
| SIA-PA | `PA_CIDPRI`, `PA_CIDSEC`, `PA_CIDCAS` | — |
| SIH-RD | `DIAG_PRINC`, `DIAG_SECUN`, `DIAGSEC1`…`DIAGSEC9`, `CID_ASSO`, `CID_MORTE` | — |
| SIM-DO | `CAUSABAS`, `CAUSABAS_O` | `LINHAA`, `LINHAB`, `LINHAC`, `LINHAD`, `LINHAII` |
| SINASC | — | `CODANOMAL` |

- **SIM, causas múltiplas:** cada linha da declaração traz vários CIDs concatenados com
  asterisco (`*A419*J960`). Use o regex `(^|\*)(prefixos)`, que casa o prefixo em qualquer
  posição.
  - **Erro que já cometemos:** o filtro antigo lia só os 4 primeiros caracteres de cada
    linha e perdia todo óbito em que o EIM aparecia só nas causas múltiplas.
  - Em 2021–2023, a correção levou os óbitos com EIM em qualquer linha de 10.554 para
    40.673 (errata do Ciclo 4).
- **SINASC, `CODANOMAL`:** blocos de 4 caracteres sem separador (`Q059Q669`). Use o regex
  `^(.{4})*(prefixos)`, que casa só nas posições múltiplas de 4. Sem essa restrição, o
  prefixo casaria no meio de um código.
- **Prefixo, não igualdade:** o CID do DATASUS vem sem ponto (`E700`). Prefixos de 3 ou 4
  caracteres são casados no início do campo, depois de remover espaços e passar a maiúsculas.
- **Procedimento SIGTAP** (`PA_PROC_ID` no SIA; `PROC_REA` e `PROC_SOLIC` no SIH):
  10 dígitos, também casados por prefixo de qualquer tamanho. Por exemplo, `0202100` pega o
  subgrupo inteiro de genética.

### 4.3 Escopos que já existem nos filtrados

Antes de refiltrar, confira em `config_filtro.R` se o que você precisa já está
capturado:

| Flag | Conteúdo |
|---|---|
| `hit_eim` | os 66 prefixos da lookup de EIM (cap. E70–E90, triagem fora do cap. E, painel do pezinho: D56/D57/D81/P37.1, contexto de doenças raras) |
| `hit_hemato` | D55–D58, D61.0, D64.0, D66, D67, D68.0–2, D68.5, D69.1, D74.0, D75.0, T45.4 |
| `hit_nefro` | E26.8, N25.1, N25.8, N07, Q61.2, Q61.3, Q61.5 |
| `hit_genetica` | 02.02.10 inteiro, confirmatórios 02.02.11, avaliação de doenças raras/aconselhamento genético, coleta HLA-B |
| `hit_medicamento` | TRE das MPS, Pompe, Gaucher, Fabry, miglustate, Wilson, moduladores de CFTR, sapropterina, fludrocortisona, tafamidis, quelantes de ferro, burosumabe, hidroxiureia |
| `hit_lab` | G6PD, AT-III, fator de von Willebrand, Hb instável/fetal, proteína C/S, meta-Hb, fator VIII, fibrinogênio, oxalato, cistina |

Volume da passada de 22/10/2026 (24 processos em paralelo, cerca de 2 h 30 min, pico de
4,2 GB por processo):

| Base | Arquivos | Linhas lidas | Linhas filtradas |
|---|---|---|---|
| SIA-PA | 5.806 | 6,74 bilhões | 65,7 milhões |
| SIH-RD | 5.398 | 204 milhões | 783 mil |
| SIM-DO | 459 | 22,9 milhões | 219 mil |
| SINASC | 459 | 46,0 milhões | 1.155 |

### 4.4 Projeto novo que precisa de CIDs ou procedimentos fora desses escopos

1. Acrescente um escopo novo em `ESCOPO_CID` ou `ESCOPO_PROC`. Se o escopo vier de uma
   lookup própria, leia os prefixos dela, como o EIM faz com `EIM_LOOKUP$prefixo`, em vez de
   copiar a lista à mão.
2. **Rode a filtragem para uma pasta nova.** O checkpoint `.ok` é por pasta de saída, e
   rodar sobre `datasus_filtrado/` pularia tudo, além de mexer nos filtrados de outro
   projeto:
   ```bash
   # no R550-2, dentro de tmux
   OUT=~/Documentos/ronald/datasus_filtrado_<projeto> \
     bash scripts/r550/orquestrar_filtro.sh --base todas --jobs 24 --dry-run   # conferir
   OUT=~/Documentos/ronald/datasus_filtrado_<projeto> \
     bash scripts/r550/orquestrar_filtro.sh --base todas --jobs 24
   ```
3. Valide antes da passada completa: rode `--uf PE --ano-min 2021 --ano-max 2021` e compare
   com uma contagem conhecida. Fizemos isso contra os filtrados do Lika e o resultado foi
   idêntico.
4. O orquestrador ordena os arquivos do maior para o menor (o pior caso começa cedo),
   roda um processo R por arquivo (isola a memória e sobrevive a falha do código C do
   `read.dbc`) e registra cada arquivo em `status_filtro.tsv`.

---

## 5. Mudanças de schema e completude ao longo da série

Antes de interpretar uma tendência, confira em `schema_resumo.tsv` se o campo que você
usa existe e é preenchido em todos os anos. O que já sabemos:

| Base | Campo | O que muda |
|---|---|---|
| SIA-PA | `PA_CIDSEC` | 7–8% preenchido até 2014, depois praticamente 0. **Use só o CID principal em série longa.** |
| SIA-PA | `PA_RACACOR` | de 36% (2010) para 94% preenchido. Uma tendência por raça/cor no início da série mede preenchimento. |
| SIH-RD | CID secundário | `DIAG_SECUN` até 2014 (de 8% para 17% preenchido); `DIAGSEC1`–`9` a partir de 2014/15 (de 17% para 29%). Contar "em qualquer campo" cresce por preenchimento. **A série longa usa o diagnóstico principal.** |
| SIM-DO | `LINHAII` | a parte II da declaração passa de 37% (2010) para 51% (2024) de preenchimento. A contagem "em qualquer linha" cresce um pouco só por isso. `LINHAA` e `CAUSABAS_O` ficam estáveis (cerca de 98% e 100%). |
| SIM-DO | colunas | de 59 para 87 colunas |
| todas | número de colunas | SIA de 54 para 62, SIH de 86 para 113 (por isso tudo é gravado como texto) |

---

## 6. Etapa 3 — Consolidação por base

Molde: `scripts/get_eim_data_from_{SIA,SIH,SIM}.R`. Lê os parquet filtrados, fica com a flag
do seu escopo, classifica pela lookup e grava em `data/consolidated/`.

**Regra geral:** os filtrados estão todos em texto. Converta de volta para número tudo que
for somado, como `PA_QTDAPR`, `PA_VALAPR`, `VAL_TOT` e `DIAS_PERM`. Já tivemos um erro por
somar `pa_qtdapr` como texto.

### 6.1 SIA-PA (ambulatorial)

- **Ano analítico = ano de `PA_CMP`** (competência do atendimento), não o mês do arquivo
  (processamento). Um atendimento de dezembro de 2024 faturado em 2025 conta em 2024.
  Registros com `PA_CMP` fora da janela saem.
- **Tipo de documento (`PA_DOCORIG`):**
  - `P`/`S`: APAC (procedimento principal/secundário), com paciente, CID e número da
    autorização (`PA_AUTORIZ`);
  - `I`: BPA individualizado, com CID e paciente;
  - `C`: BPA consolidado, **sem CID, idade, sexo nem residência**.
  - No BPA-C, o volume é a soma de `PA_QTDAPR`, não o número de linhas. Um recorte por CID ou
    residência só enxerga I/P/S. Informe a fração do volume que esse recorte cobre.
- **Residência:** município `PA_MUNPCN` (6 dígitos; os 2 primeiros são a UF). O
  estabelecimento é `PA_UFMUN`. Residência × estabelecimento mede fluxo de pacientes.
- **Idade:** `PA_IDADE` já está em anos inteiros (aceitar 0–110). **Sexo:** `M`/`F`.
- **Memória:** guarde registros completos só do que é raro (núcleo e inespecífico). O que é
  volumoso e inespecífico (no EIM, o "envelope", dominado por dislipidemia E78, cerca de 50
  milhões de linhas) vira **contagens agregadas** já na leitura. Processe arquivo a arquivo,
  com `gc()` periódico.

### 6.2 SIH-RD (internação)

- **A unidade é a AIH distinta:** conte `N_AIH` distintas, não linhas, porque uma AIH
  de longa permanência reaparece em várias competências. O campo `IDENT` marca o tipo de
  AIH. O projeto trata `IDENT == 5` como continuação; conferir no dicionário antes de usar.
- **Ano** = ano da competência do arquivo (`ANO_CMPT`).
- **Dois "sabores":**
  - (a) a condição como **diagnóstico principal**: é a série comparável ao SIA e a
    usada nas tendências;
  - (b) a condição **em qualquer campo**: é teto, e cresce com o preenchimento (seção 5).
- **Residência** `MUNIC_RES`; **hospital** `MUNIC_MOV`.
- **Idade** = `IDADE` + `COD_IDADE` (4 = anos, 3 = meses, 2 = dias, 1 = horas,
  0 = minutos). **Sexo:** `1` = masculino, `3` = feminino. Óbito hospitalar: `MORTE == 1`.
  UTI: `UTI_MES_TO > 0`.
- **Faturamento ≠ morbidade:** algumas UFs faturam infusão de terapia de reposição
  enzimática como AIH de hospital-dia (PE faz isso muito mais que as outras). Uma razão alta
  no SIH pode ser só o modo de faturar.

### 6.3 SIM-DO (óbitos)

- **Causa básica × qualquer linha** é o eixo central. O projeto mantém três colunas
  explícitas:
  - `*_causa_basica`: causa básica na camada núcleo. **É o número primário**, comparável
    às outras bases;
  - `*_cb_ampliado`: causa básica incluindo os códigos inespecíficos. É o teto de
    subcodificação;
  - `*_qualquer`: qualquer linha da declaração (causas múltiplas).
- **Nunca deixe o teto entrar no número primário.** O erro que cometemos: o KPI de
  mortalidade usava a camada ampliada e herdava dislipidemia, gota e hemocromatose. O
  resultado era uma idade mediana ao óbito de 71 anos num grupo de doenças que mata no
  primeiro ano de vida. Audite sempre a composição do numerador (os 25 CIDs mais frequentes
  na causa básica e a distribuição por camada).
- **Idade:** `IDADE` tem 3 dígitos. O 1º é a unidade (0 = minutos, 1 = horas, 2 = dias,
  3 = meses, 4 = anos, 5 = 100 anos ou mais) e os outros dois são o valor (`decode_idade_sim`).
  Óbito infantil = idade < 1 ano.
  - **Cuidado com o SIM processado pelo microdatasus (Lika):** lá o campo `idade_decode` é
    a UNIDADE, não o valor decodificado.
- **Sexo:** `1`/`2`. **Residência:** `CODMUNRES`. Só anos **definitivos** entram nas
  taxas; o preliminar fica num arquivo à parte.

### 6.4 SINASC (nascidos vivos)

- É o **denominador da incidência ao nascimento e da mortalidade infantil** (por 100 mil
  nascidos vivos). Vem dos agregados da filtragem, calculados sobre todas as declarações:
  UF de residência da mãe (`CODMUNRES`) × ano × sexo (`scripts/get_nascidos_vivos_SINASC.R`).
- Use só anos definitivos (`carregar_nv(incluir_preliminar = FALSE)`).
- O numerador do SINASC (anomalias em `CODANOMAL`) cobre só anomalias congênitas visíveis
  ao nascer. Doenças metabólicas quase não aparecem aí (1.155 linhas em 15 anos).

### 6.5 Códigos comuns

- Município IBGE com 6 dígitos (os 2 primeiros são a UF). Recife = `261160`. A tabela
  código → UF → região está em `utils.R` (`.UF_COD`, `uf_from_mun`, `mapear_uf_regiao`).
- **Não use `mun_res_uf` do SIM processado como sigla:** esse campo traz o nome por extenso
  do estado.
- O texto já está em UTF-8 desde a filtragem. **Não reconverta de latin1**, ou os
  acentos se corrompem.

---

## 7. Definição de caso: a lookup

Molde: `scripts/eim_lookup.R`. A definição de caso **é** essa tabela.

- **Prefixo CID-10 (sem ponto) → grupo, camada e metadados** (herança, triagem, PCDT,
  traçadora).
- **O prefixo mais específico vence:** a tabela é ordenada por comprimento decrescente e o
  primeiro match vale (`E700` PKU vence `E70` vence `E7`).
- **Três camadas:**
  - **núcleo (core):** código inequívoco, usado na análise primária;
  - **limítrofe:** a condição, mas código inespecífico ("não especificado", agregador);
  - **envelope:** categoria que abriga também condições comuns que não são da doença em
    estudo. É teto de subcodificação, **nunca caso confirmado**.
- Separe também o **escopo** (núcleo da doença × condições correlatas fora do capítulo) e
  não some os dois sem rótulo.
- **Confira os 4º caracteres contra a CID-10.** Erros já encontrados: E80.3 não é
  bilirrubina; E85.0/E85.2 são heredofamiliares; E71.4 não existe.
- **Cruze com a lista oficial do MS** de doenças raras (`ref/crosswalk_lista_raras_MS.md`).
  O cruzamento mostra o que o CID não separa (E75.2 = Gaucher + Fabry + Niemann-Pick C;
  deficiência de biotinidase escondida no código genérico E88.9).
- **Versione:** cada execução grava o hash da lookup em `manifest/<…>_lookup_versao.csv`.
- **Um código pode ser dominado por outra condição.** Exemplos: E83.3 é 99% doença renal
  crônica (sevelamer), não raquitismo hipofosfatêmico ligado ao X; E75.2 é dominado por
  Gaucher. Nesses casos, conte pelo medicamento (seção 8) ou omita a contagem por CID.

---

## 8. SIGTAP: procedimentos e medicamentos

Moldes: `sia_procedimentos_sigtap.R`, `separacao_medicamento_apac.R`,
`genetica_sus_procedimentos.R`.

### 8.1 Códigos e nomes

- Procedimento SIGTAP = 10 dígitos: grupo (2) · subgrupo (2) · forma de organização (2) ·
  procedimento (3) · dígito verificador (1). Exemplos:
  - `02.02.10` = genética (citogenética, molecular, exoma);
  - `02.02.11` = triagem neonatal e confirmatórios;
  - `06.04` = medicamentos do Componente Especializado (CEAF).
- **Nomes:** use `microdatasus::sigtab`, a tabela embutida (offline e reprodutível, com cerca
  de 5,5 mil procedimentos). `microdatasus::fetch_sigtab()` é só o reserva.
  - Códigos novos podem não ter nome: marque `[VERIFICAR nome SIGTAP]`.
  - Para inferir o que um código sem nome é, olhe o perfil: CID, data de início e idade.
    Foi assim que identificamos `0604240120` como TRE de Fabry e `0604860030` como ETI
    pediátrico.
- **Vigência:** muitos códigos só passam a existir em certo ano (vários medicamentos e
  confirmatórios moleculares a partir de 2014 ou depois). Ausência antes disso pode ser só a
  inexistência do código, não falta de oferta.

### 8.2 O medicamento separa o que o CID junta

A APAC do CEAF registra o medicamento dispensado. Duas aplicações:

- **Desambiguar:** o CID agrega doenças e o medicamento indica qual é.
  - Exemplos: em E76.x (MPS), laronidase → MPS I, idursulfase → II, galsulfase → VI; em
    E74.0, alglicosidase → Pompe; em E75.2, imiglucerase → Gaucher e TRE de Fabry → Fabry.
  - Se a mesma APAC tem mais de um medicamento, o tipo é a **interseção** dos conjuntos de
    doença ({Gaucher, NP-C} ∩ {Gaucher} = Gaucher). Interseção vazia = ambíguo.
- **Estratificar:** o CID já é específico e o medicamento indica fenótipo ou genótipo.
  - Exemplos: ETI → fibrose cística com ≥1 F508del; sapropterina → PKU responsiva a BH4;
    fludrocortisona → HAC perdedora de sal; tafamidis → amiloidose TTR em tratamento.
- **Pacientes em tratamento = mediana mensal de APAC distintas** (`PA_AUTORIZ`) com o
  medicamento, num ano de referência completo. Uma APAC do CEAF agrupa os medicamentos de
  um paciente no mês. Isso mede quem está em tratamento, não quem tem diagnóstico.
- **Vínculo com o SIH:** a AIH não registra medicamento. Ligue a AIH à APAC por sexo × ano
  de nascimento × município (e, sem candidato, × UF). Aceite só tipos compatíveis com o
  CID da AIH.
- **Limite conhecido:** o município do paciente nas APAC do CEAF **não é confiável**. Em PE
  quase todas saem como Recife, e houve um lote com municípios trocados (2024-03).

### 8.3 Testes e exames

- **Contar exames, não linhas:** some `PA_QTDAPR`, porque o BPA-C traz várias unidades por
  linha.
- Oferta (UF do estabelecimento) é diferente de acesso (UF de residência). A matriz
  residência × estabelecimento mostra quem faz o exame fora do estado.

---

## 9. Denominadores populacionais (IBGE)

Molde: `scripts/get_denominadores_ibge.R`.

- **Fonte:** IBGE, *Projeções da População — Revisão 2024*, tabela 2 (população por sexo e
  grupo quinquenal, 2000–2070, Brasil, regiões e UFs):
  `https://ftp.ibge.gov.br/Projecao_da_Populacao/Projecao_da_Populacao_2024/projecoes_2024_tab2_grupo_quinquenal.xlsx`
  (o arquivo fica em cache em `data/denominators/`).
- **Por que essa fonte:** é uma série anual única, retroprojetada e ancorada no Censo 2022.
  Emendar Censo 2010, projeção de 2018 e Censo 2022 cria degraus artificiais.
  - **Erro que já cometemos:** repetir o Censo 2022 como constante em todos os anos. Assim,
    toda tendência de taxa refletia só o numerador.
- **Estrutura:** UF × ano × sexo × faixa quinquenal (0–4 … 75–79, 80+, somando 80–84, 85–89
  e 90+). A grade de faixas do numerador e a do denominador têm de ser idênticas.
- **Conferência automática:** o número de linhas tem de ser 27 UFs × anos × 2 sexos × faixas,
  sem faixa NA. Imprima também o total do Brasil por ano.
- **Nascidos vivos** (para taxas por nascido vivo): SINASC (seção 6.4), nunca a população
  de 0 anos do IBGE.

---

## 10. Taxas, tendência e supressão

Molde: `scripts/calcular_taxas.R` (+ `utils.R`).

- **`contar_estrato()`:** conta eventos por UF × ano × sexo × faixa quinquenal (com estratos
  extras opcionais). Com `distinct_por = "n_aih"`, conta entidades distintas.
  **Avisa quantas linhas descartou** por UF, sexo ou faixa ausente. Uma perda silenciosa
  subestima a taxa.
- **`taxas_padronizadas()`:** padronização direta por idade × sexo
  (`epitools::ageadjust.direct`, IC gama) com população-padrão Brasil 2022, por 100 mil.
  - Restrinja o denominador aos anos que existem no numerador.
  - **Erro que já cometemos ("anos-fantasma"):** a população cobria 2010–2025 e o SIM só ia
    até 2024. Agrupar por ano criava um 2025 com população e zero óbitos; agrupar por UF
    somava pessoas-ano sem numerador.
- **Incidência ao nascimento:** casos com idade < 1 ano no ano *t* ÷ nascidos vivos do ano
  *t* (SINASC), com IC de Poisson exato. **Mortalidade infantil por causa:** óbitos < 1 ano
  (causa básica, núcleo) ÷ nascidos vivos.
- **Tendência (`tendencia_poisson()`):** modelo quasi-Poisson com
  `eventos ~ ano + offset(log(denominador))`. Reporte a variação anual
  `(exp(β) − 1) × 100 %` com IC 95%.
  - Faça a análise de sensibilidade sem 2020–2022 (`excluir_covid = TRUE`).
  - Um IC que cruza o zero não é tendência, e assim deve ser escrito.
  - **Erro que já cometemos:** na janela 2021–2025, a "alta de +9%/ano" das internações
    era só a recuperação pós-COVID. Na série 2010–2025, as internações não têm tendência.
- **Supressão:** `suprimir_taxa()` apaga taxa e IC quando há menos de 5 eventos.
  `suprimir_pequenas()` faz o mesmo com contagens. Aplique em toda saída publicada,
  inclusive nas tabelas de apoio (TSV/CSV).

---

## 11. Pacientes distintos no SIA (pseudo-ID)

Molde: `scripts/pseudo_id_motor.R`. O SIA não tem identificador de paciente. A estimativa
de pessoas usa ligação determinística por quase-identificadores, resolvida por componentes
conexos (`igraph`):

| Variante | Chave | Papel |
|---|---|---|
| estrita | sexo × município × raça/cor × ano de nascimento exato | limite superior |
| intermediária | sexo × município × raça/cor × ano de nascimento ±1 | estimativa central |
| frouxa | sexo × município × ano de nascimento ±1 | limite inferior |

- O ano de nascimento é aproximado por ano da competência − idade (a idade é truncada em
  anos).
- **Ligação certa por número de APAC:** registros de APAC (`P`/`S`) com o mesmo
  `PA_AUTORIZ` e o mesmo sexo são o mesmo paciente. Isso corrige município trocado dentro
  da mesma APAC.
- **Raça/cor ausente vira a categoria "NI"**, não exclusão.
  - **Erro que já cometemos:** forçar paciente próprio para cada registro sem raça inflava
    a contagem em cerca de 10 vezes. As MPS em PE apareciam com cerca de 1.100 "pacientes"
    para cerca de 70 em tratamento por mês.
- **Publique um intervalo** (frouxa–estrita), nunca um ponto. O pseudo-ID agrupa
  registros; não é um identificador (LGPD).

---

## 12. Publicação (painel Quarto)

- **Números no texto vêm de R inline.** Textos longos ficam em `ref/*.md` e entram por
  `{{< include >}}`. O include é expandido antes do knitr, por isso R inline funciona
  dentro deles.
  - Para a Discussão, um arquivo de funções de acesso (`qmd/_discussao_numeros.R`) dá
    ao texto nomes estáveis para os números (`inc("PKU", "mi")`, `TR$sim$var`…).
  - Subtítulos e títulos de figuras também são calculados. "~40×" e "SIM só até 2023" ficaram
    errados quando mudou a série.
- **Renderize uma página por comando** (`quarto render pagina.qmd`). Render em lote funde os
  `.qmd` num único `.knit.md`.
- Use o Quarto oficial (`~/opt/quarto-1.9.37`). Exporte `PROJ_DATA`, `PROJ_LIB` e
  `GDAL_DATA` do env conda, senão os mapas `sf` falham com "crs_parameters NA".
- Antes de publicar, procure no HTML gerado: `NA` solto, código R vazado e anos da janela
  antiga fora das notas de lançamento.

---

## 13. Armadilhas operacionais

| Sintoma | Causa | O que fazer |
|---|---|---|
| Job morre quando a sessão SSH cai | `nohup`/`setsid` numa sessão SSH única não persiste | Sempre usar tmux: `~/miniconda3/envs/datasus/bin/tmux new -d -s nome "comando; echo $? > feito.done"`, e esperar o arquivo `.done` |
| Comando SSH longo trava | render ou pipeline segurando a sessão | Lançar em tmux e acompanhar pelo arquivo-sentinela |
| `pkill -f script.sh` derruba a própria sessão | o padrão casa com o próprio comando do pkill | `pkill -f "[s]cript.sh"` |
| Pacote não existe no conda-forge (`r-geobr`, `r-sidrar`) e a instalação inteira falha | conda é tudo ou nada | `--dry-run` antes; instalar esses pelo R |
| Quarto do conda não renderiza | pacote quebrado no conda-forge | Quarto oficial em `~/opt` |
| Soma dá erro ou zero | coluna numérica ficou texto no filtrado | `as.numeric()` na consolidação |
| Acentos corrompidos | reconversão latin1 → UTF-8 em texto já UTF-8 | não chamar `corrigir_encoding` nos filtrados 2010+ |
| SSH do R550-2 para o Lika falha | `/etc/ssh/ssh_config` do R550-2 é inválido | `ssh -F ~/.ssh/config_lika` (chave `~/.ssh/id_ed25519_lika`) |
| Memória estoura | carregar muitos parquet do SIA de uma vez | `arrow::open_dataset()` lazy, agregar dentro do arrow e coletar só o resultado pequeno (ver `scripts/listas_base_numeros.R`) |

---

## 14. Checklist para um projeto novo

1. [ ] **Definição de caso:** lookup própria com prefixos CID (e procedimentos SIGTAP, se
   for o caso), camadas núcleo/limítrofe/envelope, cruzada com a lista do MS e conferida
   contra a CID-10. Registrar o hash.
2. [ ] **Escopo já filtrado?** Comparar os prefixos com `config_filtro.R`. Se tudo estiver
   coberto, usar `datasus_filtrado/` e a flag existente. Se não, criar o escopo e filtrar
   para `datasus_filtrado_<projeto>/` (seção 4.4), validando antes numa UF × ano.
3. [ ] **Catálogo de schema:** conferir em `schema_resumo.tsv` se os campos usados existem e
   são preenchidos em toda a série.
4. [ ] **Copiar o esqueleto:** `00_setup.R` (ANOS, ANOS_SIM, DIR_FILTRADO, N_SUPRESSAO),
   `utils.R`, `calcular_taxas.R` e os `get_*` (trocar `hit_eim` pela flag do projeto e a
   lookup pela sua).
5. [ ] **Denominadores:** `get_denominadores_ibge.R` e `get_nascidos_vivos_SINASC.R` servem
   sem mudanças (dependem só de ANOS e do diretório dos filtrados).
6. [ ] **Consolidar** cada base com as regras da seção 6 (ano por `PA_CMP`, AIH distintas,
   causa básica × qualquer linha, só definitivos).
7. [ ] **Auditar o numerador:** os 25 CIDs mais frequentes, distribuição por camada, idade
   mediana. Ela faz sentido para a doença?
8. [ ] **Taxas padronizadas, tendência quasi-Poisson** (com e sem 2020–2022) e supressão N < 5.
9. [ ] **Se o CID for ambíguo:** separar pelo medicamento da APAC (seção 8.2).
10. [ ] **Publicar** com números calculados (seção 12) e notas de lançamento que expliquem
    o que mudou em relação à versão anterior.

---

## 15. Mapa dos scripts (`datasus_EIM/scripts/`)

| Etapa | Script | Reaproveitável como está? |
|---|---|---|
| Manifesto e download | `r550/gerar_manifesto.py`, `r550/baixar_brutos.sh`, `r550/verificar_download.py` | sim |
| Validação de leitura | `r550/validar_amostra.R`, `r550/catalogo_schema.R` | sim |
| Filtragem | `r550/config_filtro.R`, `r550/filtrar_um.R`, `r550/orquestrar_filtro.sh` | sim (só acrescentar escopo) |
| Definição de caso | `eim_lookup.R` | molde |
| Consolidação | `get_eim_data_from_{SIA,SIH,SIM}.R` | molde (trocar flag e lookup) |
| Denominadores | `get_denominadores_ibge.R`, `get_nascidos_vivos_SINASC.R` | sim |
| Taxas e tendência | `calcular_taxas.R`, `utils.R` | sim |
| SIGTAP e medicamentos | `sia_procedimentos_sigtap.R`, `separacao_medicamento_apac.R` | molde |
| Testes genéticos (todos os CIDs) | `genetica_sus_procedimentos.R` | sim |
| Pacientes distintos | `pseudo_id_motor.R` | sim |
| Agregação lazy de muitos arquivos | `listas_base_numeros.R` | molde |
| Pipeline completo + render | `r550/rodar_pipeline.sh` (`--de NN`, `--so-render`) | molde |
