# EIM no DATASUS — Enquadramento genético-clínico e definição de caso

> **Contribuição do geneticista clínico** ao plano de análise dos microdados do
> DATASUS (SIA-PA / SIH-RD / SIM-DO) sobre os **Erros Inatos do Metabolismo (EIM /
> *inborn errors of metabolism*, IEM)**. Estrutura, rigor e convenções de marcação
> herdados do projeto de Hidradenite Supurativa (`datasus_hs.md`, `CLAUDE.md`) — a
> **doença é OUTRA** e o conteúdo clínico abaixo é específico de EIM.

> **Convenções de marcação (idênticas ao HS):** `[VERIFICAR]` = afirmação que exige
> confirmação documental na fonte oficial (tabela CID-10 DATASUS/CID10 V2008,
> OMIM, Orphanet, PCDT, DOU, PNTN); `[CONFIRMAR via fetch_sigtab()]` = procedimento/
> CBO/APAC a validar no SIGTAP na competência correta. **Princípio inegociável:
> nunca inventar CID, prevalência, procedimento, portaria ou número molecular.**
> Os rótulos literais dos CIDs E70–E90 abaixo provêm de memória de treino do modelo e
> da estrutura conhecida da CID-10; **todos os rótulos de 4 caracteres devem ser
> conferidos contra a tabela oficial DATASUS** (`http://www2.datasus.gov.br/cid10/`
> esteve inacessível no momento da redação) → marcados `[VERIFICAR rótulo]`.

> **Diferença estrutural crítica frente ao HS.** A HS é **uma** doença (`L732`). O
> "EIM" **não é uma doença** — é um **guarda-chuva de centenas de doenças
> monogênicas distintas**, com mecanismos, idades de início, heranças, tratamentos e
> letalidades radicalmente diferentes. Isso muda tudo: **não existe "captura restrita
> de um CID"** e sim **taxonomia de um capítulo inteiro (E70–E90) + EIM fora do
> capítulo E**; **não se soma "casos de EIM"** como se fosse uma entidade; a razão
> sinal:ruído varia por subgrupo em ordens de grandeza; e — ao contrário da HS — a
> **mortalidade neonatal/infantil (SIM) pode ser a base MAIS informativa** para
> várias classes, não a menos. Toda a seção epidemiológica/bioinformática deve herdar
> essa ressalva de heterogeneidade (§6).

---

## 1. Taxonomia e definição do grupo EIM — mapa CID-10 estruturado

### 1.1 Lógica de classificação adotada

Adotamos uma **taxonomia fisiopatológica** (classe de via metabólica afetada), que é
a organização usada em genética metabólica (Saudubray *et al.*, *Inborn Metabolic
Diseases*, e nosologia Orphanet/ICIMD — *International Classification of Inherited
Metabolic Disorders*) e que **atravessa** os blocos numéricos da CID-10. A CID-10 (e o
DATASUS) organizam por **substrato** (aminoácido, carboidrato, lipídio…), o que **não
é isomórfico** à classificação mecanística moderna — daí o mapa cruzado abaixo.

> **Formato DATASUS:** CID sempre **sem ponto** (E70.0 → `E700`; E76.02 não existe na
> CID-10 de 4 caracteres — a granularidade máxima é 4 caracteres, ex. `E7602`
> **[VERIFICAR se existe]**). No SIA `pa_cidpri`; no SIH `diag_princ` + `diagsec1–9`;
> no SIM `causabas` + `linhaa–d` + `linhaii`. A CID-10 tem apenas 4 caracteres — não
> chega ao nível de doença molecular individual (ver §6).

> **Marcação de papel** em cada tabela:
> - **CORE** = EIM raro de alta especificidade (o CID mapeia com boa fidelidade a uma
>   doença/grupo monogênico reconhecível) → entra no **núcleo** (§2).
> - **LIMÍTROFE** = CID de EIM porém inespecífico, "não especificado", ou que agrega
>   entidades heterogêneas → **camada ampliada / envelope**.
> - **INESPECÍFICO/NÃO-EIM** = código que **não** deve ser lido como EIM raro sem
>   contexto (inclui doença comum multifatorial que "mora" no mesmo bloco, ex.
>   dislipidemias comuns E78, gota E79.0, hemocromatose E83.1). **Fonte dominante de
>   ruído** — tratar como o `L02x` foi tratado na HS (envelope, não caso).

---

### 1.2 Aminoacidopatias — metabolismo de aminoácidos (E70–E72)

| CID (DATASUS) | Descrição `[VERIFICAR rótulo]` | Classe fisiopatológica | Exemplos de doença | Papel |
|---|---|---|---|---|
| `E700` | Fenilcetonúria clássica (PKU) | Aminoacidopatia (aromáticos) | PKU (*PAH*) | **CORE** |
| `E701` | Outras hiperfenilalaninemias | Aminoacidopatia | HPA, def. BH4 (*PTS*, *QDPR*, *PCBD1*, *GCH1*) | **CORE** |
| `E702` | Distúrbios do metab. da tirosina | Aminoacidopatia | Tirosinemia I (*FAH*), II, III | **CORE** |
| `E703` | Albinismo | Melanina (não-EIM metabólico clássico) | Albinismo óculo-cutâneo | LIMÍTROFE |
| `E708`/`E709` | Outros / não especificados metab. aromáticos | Aminoacidopatia inespecífica | — | LIMÍTROFE |
| `E710` | Doença da urina em xarope de bordo (MSUD) | Aminoacidopatia BCAA | MSUD (*BCKDHA/B*, *DBT*) | **CORE** |
| `E711` | Outros distúrbios do metab. de BCAA | Acidúria orgânica / BCAA | Ac. isovalérica, propiônica, metilmalônica, etc. | **CORE** |
| `E712` | Distúrbio do metab. de BCAA não especif. | BCAA inespecífico | — | LIMÍTROFE |
| `E713` | Distúrbios do metab. de ácidos graxos | Oxidação de ácidos graxos (FAOD) | MCAD, LCHAD, VLCAD (*ACADM*, *HADHA*, *ACADVL*) | **CORE** |
| `E714`/`E715` | (carnitina/outros — bloco FAOD) `[VERIFICAR estrutura de 4º caractere]` | FAOD / carnitina | Def. de carnitina, CPT I/II | **CORE** |
| `E72` (bloco) | Outros distúrbios do metab. de aminoácidos | ver desdobramento abaixo | — | misto |
| `E720` | Distúrbios do transporte de aminoácidos | Transporte AA | Cistinúria, Hartnup, Lowe | **CORE** |
| `E721` | Distúrbios do metab. de AA sulfurados | Aminoacidopatia | Homocistinúria (*CBS*), def. MTHFR | **CORE** |
| `E722` | Distúrbios do metab. do ciclo da ureia | **Ciclo da ureia** | OTC (XL), ASS/citrulinemia, ASL, CPS1, NAGS, arginase | **CORE** |
| `E723` | Distúrbios do metab. da lisina/hidroxilisina | Acidúria/AA | Acidúria glutárica tipo I (*GCDH*) | **CORE** |
| `E724` | Distúrbios do metab. da ornitina | AA | Atrofia girata (*OAT*) | **CORE** |
| `E725` | Distúrbios do metab. da glicina | AA | Hiperglicinemia não cetótica (*GLDC*, *AMT*) | **CORE** |
| `E728`/`E729` | Outros / não especificados | AA inespecífico | — | LIMÍTROFE |

> **Nó taxonômico importante:** as **acidúrias orgânicas** (propiônica, metilmalônica,
> isovalérica, glutárica) **não têm bloco CID-10 próprio** — estão dispersas em
> `E711` (BCAA) e `E72x` (lisina/glicina). O CID-10 **não permite isolar "acidúria
> orgânica" como classe** com fidelidade. Consequência: qualquer subgrupo "acidúrias
> orgânicas" será uma **reconstrução aproximada** a partir de `E711`+`E723`(+outros),
> a ser declarada como tal. **[VERIFICAR]** o mapeamento exato dos 4ºs caracteres de
> `E71`/`E72`.

---

### 1.3 Carboidratos (E73–E74)

| CID | Descrição `[VERIFICAR rótulo]` | Classe | Exemplos | Papel |
|---|---|---|---|---|
| `E730` | Deficiência congênita de lactase | Carboidrato | — | LIMÍTROFE |
| `E731` | Outra deficiência de lactase | Carboidrato comum | Intolerância à lactose (comum!) | **INESPECÍFICO** |
| `E738`/`E739` | Outras / intolerância à lactose SOE | comum | — | **INESPECÍFICO** |
| `E740` | Doença de depósito de glicogênio (**glicogenoses**) | Carboidrato / lisossômico (tipo II) | GSD I–XI; **Pompe = GSD II** (lisossômica, ver §1.6) | **CORE** |
| `E741` | Distúrbios do metab. da frutose | Carboidrato | Intolerância hereditária à frutose (*ALDOB*) | **CORE** |
| `E742` | Distúrbios do metab. da galactose | Carboidrato | **Galactosemia** (*GALT*, *GALK1*, *GALE*) | **CORE** |
| `E743` | Outros distúrbios da absorção intestinal de carboidratos | Carboidrato | — | LIMÍTROFE |
| `E744` | Distúrbios do metab. do piruvato / gliconeogênese | Mitocondrial/energético | Def. piruvato desidrogenase/carboxilase | **CORE** |
| `E748`/`E749` | Outros / não especificados | inespecífico | Inclui **CDG** (glicosilação) `[VERIFICAR onde CDG cai na CID-10]` | LIMÍTROFE |

> **CDG (*congenital disorders of glycosylation*)** — grupo grande e crescente — **não
> tem código CID-10 dedicado óbvio**; costuma cair em `E748`/`E749` ou `E771`
> (glicoproteínas). **[VERIFICAR]** — outra classe que a CID-10 não resolve.

---

### 1.4 Lipídios / lipoproteínas — atenção ao ruído (E75, E78)

| CID | Descrição `[VERIFICAR rótulo]` | Classe | Exemplos | Papel |
|---|---|---|---|---|
| `E750` | Gangliosidose GM2 | Esfingolipidose | Tay-Sachs (*HEXA*), Sandhoff (*HEXB*) | **CORE** |
| `E751` | Outras gangliosidoses | Esfingolipidose | GM1 (*GLB1*) | **CORE** |
| `E752` | Outras esfingolipidoses | Depósito lisossômico | Fabry (*GLA*, XL), Gaucher¹, Niemann-Pick, Krabbe, MLD | **CORE** |
| `E753` | Esfingolipidose não especificada | Lisossômico inespecífico | — | LIMÍTROFE |
| `E754` | Lipofuscinose ceroide neuronal | Lisossômico | NCL / Batten (*CLN*) | **CORE** |
| `E755`/`E756` | Outros distúrbios do depósito de lipídios / não especif. | Lisossômico | Wolman/CESD (*LIPA*) | **CORE**/LIMÍTROFE |
| `E78` (bloco) | **Distúrbios do metab. de lipoproteínas** | **Metabólico COMUM** | Hipercolesterolemia comum, dislipidemias | **INESPECÍFICO** |
| `E780` | Hipercolesterolemia pura | comum / (HF rara²) | **Hipercolesterolemia familiar** *escondida* aqui² | **INESPECÍFICO** (com ressalva²) |

> ¹ **Gaucher** e a maior parte das esfingolipidoses **caem em `E752`** ("outras
> esfingolipidoses") — a CID-10 **não dá código próprio** a Gaucher, Fabry,
> Niemann-Pick etc. individualmente. Ou seja: **`E752` é um agregado de várias
> doenças-traçadoras** e **não pode ser lido como "Gaucher"**. Para isolar Gaucher/
> Fabry/Pompe será necessário **triangular com o procedimento APAC de TRE específica**
> (§5), não o CID. **[VERIFICAR]** se há 5º caractere / subcategoria brasileira.
>
> ² **`E78`/`E780` é dominado por dislipidemia comum multifatorial** — NÃO é EIM raro.
> A **Hipercolesterolemia Familiar (HF)** (monogênica, *LDLR/APOB/PCSK9*) mora aqui,
> indistinguível por CID da hipercolesterolemia comum. **Decisão: `E78` fica FORA do
> núcleo EIM** (envelope, e mesmo assim de baixíssima especificidade). HF, se de
> interesse, exige abordagem própria (não confundível no dado administrativo).

---

### 1.5 Leucodistrofias e peroxissomais

As leucodistrofias estão **dispersas**: MLD e Krabbe em `E752` (esfingolipidoses);
**adrenoleucodistrofia ligada ao X (X-ALD)** classicamente em **`E713`?**/`E714`?
`[VERIFICAR — X-ALD costuma cair em E71.3 "distúrbios do metabolismo de ácidos graxos"
ou em E71.5 peroxissomais]`. Doenças **peroxissomais** (espectro Zellweger, X-ALD,
condrodisplasia punctata rizomélica):

| CID | Descrição `[VERIFICAR rótulo]` | Classe | Exemplos | Papel |
|---|---|---|---|---|
| `E715` | Distúrbios peroxissomais `[VERIFICAR]` | Peroxissomal | Zellweger (*PEX*), X-ALD (*ABCD1*, XL) | **CORE** |

> **[VERIFICAR] posição de X-ALD e Zellweger na CID-10 DATASUS** — é ponto sensível
> porque X-ALD é doença-traçadora (§2) e a atribuição de código impacta a captura.

---

### 1.6 Depósito lisossômico — MPS e glicoproteínas (E76, E77)

Bloco de **maior especificidade** do capítulo (bom sinal:ruído) e o mais relevante
para o eixo de política (TRE de altíssimo custo).

| CID | Descrição `[VERIFICAR rótulo]` | Doença | Gene | Herança | Papel |
|---|---|---|---|---|---|
| `E760` | Mucopolissacaridose tipo I (MPS I) | Hurler/Scheie | *IDUA* | AR | **CORE** |
| `E761` | Mucopolissacaridose tipo II (MPS II) | Hunter | *IDS* | **XL** | **CORE** |
| `E762` | Outras mucopolissacaridoses | MPS III/IV/VI/VII | *SGSH*, *GALNS*, *ARSB*, *GUSB* | AR | **CORE** |
| `E763` | Mucopolissacaridose não especificada | MPS SOE | — | — | LIMÍTROFE |
| `E768`/`E769` | Outros distúrbios do metab. de glicosaminoglicanos / SOE | — | — | LIMÍTROFE |
| `E770` | Defeitos na modif. pós-traducional de enzimas lisossômicas | Glicoproteinose | Mucolipidose II/III (*GNPTAB*) | AR | **CORE** |
| `E771` | Defeitos na degradação de glicoproteínas | Glicoproteinose | Alfa-manosidose, aspartilglucosaminúria, fucosidose | AR | **CORE** |
| `E778`/`E779` | Outros / não especificados | — | — | LIMÍTROFE |

> **MPS II (Hunter) é ligada ao X** → **razão de sexo esperada fortemente masculina**
> em `E761` (ver §3). Boa checagem de consistência sexo × CID (§6.8 do HS): registros
> `E761` femininos são bandeira de miscodificação (ou raras heterozigotas
> manifestantes). **Pompe (GSD II)** é lisossômica mas **classificada em `E740`**
> (glicogenoses) — atenção ao caçá-la fora do bloco E76.

---

### 1.7 Metais — Wilson, hemocromatose (E83) — **decisão de inclusão**

| CID | Descrição `[VERIFICAR rótulo]` | Doença | Gene | Papel |
|---|---|---|---|---|
| `E830` | Distúrbios do metab. do cobre | **Doença de Wilson** (*ATP7B*, AR) + Menkes (*ATP7A*, XL) | monogênico | **CORE** (Wilson) |
| `E831` | Distúrbios do metab. do ferro | **Hemocromatose** (*HFE* comum, penetrância baixa) | comum/monogênico | **LIMÍTROFE** |
| `E832` | Distúrbios do metab. do zinco | Acrodermatite enteropática (*SLC39A4*) | AR | LIMÍTROFE |
| `E833` | Distúrbios do metab. do fósforo | Raquitismo hipofosfatêmico (*PHEX*, XL) | monogênico | LIMÍTROFE |
| `E835`/`E838`/`E839` | Cálcio / outros / não especificados | misto | — | INESPECÍFICO |

> **Decisão recomendada sobre E83:**
> - **`E830` (Wilson) → INCLUIR no núcleo.** É EIM monogênico (AR), com tratamento de
>   alto custo (quelantes — §5), diagnóstico frequentemente tardio (adulto jovem),
>   letalidade evitável. Boa **doença-traçadora do EIM de apresentação tardia**
>   (contraponto aos EIM neonatais). O bloco `E830` também contém **Menkes** (cobre,
>   XL) — não são separáveis por CID; declarar.
> - **`E831` (hemocromatose) → NÃO incluir no núcleo.** A hemocromatose hereditária
>   *HFE* é **comum** (heterozigose ~1:10 em europeus) e de **penetrância clínica
>   baixa**; comporta-se como traço multifatorial, não como EIM raro. É **ruído
>   análogo ao `L02x`/`E78`**. Se entrar, só como **envelope** rotulado, jamais somado
>   às doenças raras. **[VERIFICAR ancestralidade]:** frequência do *HFE* na população
>   brasileira miscigenada é menor que em europeus, mas ainda longe de "raro".

---

### 1.8 Porfirias (E80)

| CID | Descrição `[VERIFICAR rótulo]` | Classe | Exemplos | Papel |
|---|---|---|---|---|
| `E800` | Porfiria eritropoética hereditária | Porfiria | Porfiria eritropoética congênita | **CORE** |
| `E801` | Porfiria cutânea tardia | Porfiria (predom. adquirida!) | PCT (mais ambiental/HCV/álcool que monogênica) | LIMÍTROFE |
| `E802` | Outras porfirias | Porfiria | Porfiria aguda intermitente (*HMBS*), variegata, coproporfiria | **CORE** |
| `E803`/`E804` | Defeitos da catalase/peroxidase; Sínd. de Gilbert/Crigler-Najjar `[VERIFICAR]` | Bilirrubina | Gilbert (comum!), Crigler-Najjar (raro) | LIMÍTROFE |
| `E806`/`E807` | Outros / não especificados do metab. da bilirrubina | Bilirrubina | — | LIMÍTROFE |

> Porfirias são de **apresentação predominantemente adulta** e AD (as agudas) → outro
> contraponto ao eixo neonatal. **PCT (`E801`)** é largamente **adquirida** → não é EIM
> raro puro. **Gilbert** (se em `E80x` `[VERIFICAR]`) é comuníssimo → ruído.

---

### 1.9 Purinas e pirimidinas (E79)

| CID | Descrição `[VERIFICAR rótulo]` | Classe | Exemplos | Papel |
|---|---|---|---|---|
| `E790` | Hiperuricemia sem sinais de artrite/tofo | comum | — | **INESPECÍFICO** |
| `E791` | Síndrome de Lesch-Nyhan | Purina | Lesch-Nyhan (*HPRT1*, XL) | **CORE** |
| `E798`/`E799` | Outros / não especificados metab. purina-pirimidina | Purina/pirimidina | Def. ADA/PNP, xantinúria, def. APRT | LIMÍTROFE/CORE |

> **`E790` (hiperuricemia/gota) domina o bloco `E79` e é COMUM** → não-EIM raro. A
> doença-traçadora aqui é **`E791` (Lesch-Nyhan)**, XL, rara, com fenótipo
> neurocomportamental marcante. **Gota NÃO é EIM raro.**

---

### 1.10 Mitocondriais — o "buraco" da CID-10

As **doenças mitocondriais** (cadeia respiratória; mtDNA ou nuclear-codificadas) são
**mal servidas pela CID-10**. Não há bloco dedicado limpo. Elas se espalham por:

- `E883` `[VERIFICAR]` / `E88x` (outros distúrbios metabólicos) — algumas acidoses
  lácticas / síndromes;
- `G31.8`/`G31.9`, `G93.4` (encefalopatias — **fora do capítulo E**);
- `E742` região piruvato (`E744`) para defeitos energéticos;
- síndromes específicas (MELAS, MERRF, Leigh, Kearns-Sayre) frequentemente codificadas
  por **manifestação neurológica**, não metabólica.

> **Conclusão dura:** **doença mitocondrial é essencialmente NÃO-CAPTURÁVEL de forma
> específica pela CID-10.** Qualquer tentativa de subgrupo "mitocondrial" será
> grosseira e deve ser declarada como provavelmente muito subestimada. **[VERIFICAR]**
> onde MELAS/Leigh caem na CID-10 DATASUS (provável `E88`+`G` neurológicos).

---

### 1.11 E88 e adjacências — o "outros" (envelope por excelência)

| CID | Descrição `[VERIFICAR rótulo]` | Papel |
|---|---|---|
| `E880` | Distúrbios do metab. de proteínas plasmáticas NCOP | LIMÍTROFE (inclui def. **alfa-1-antitripsina** `[VERIFICAR]`) |
| `E881` | Lipodistrofia NCOP | LIMÍTROFE |
| `E882` | Lipomatose NCOP | INESPECÍFICO |
| `E888`/`E889` | Outros distúrbios metabólicos especificados / SOE | **ENVELOPE** (agrega mitocondriais, CDG, etc.) |
| `E85` (bloco) | **Amiloidose** | LIMÍTROFE (amiloidose hereditária *TTR* rara vs adquirida) |
| `E84` (bloco) | **Fibrose cística** | **CORE** (EIM/monogênica AR; ver §4 — triagem neonatal) |

> **`E888`/`E889` é o envelope máximo** — agrega o que a CID-10 não classificou
> (mitocondriais, CDG, defeitos novos). Alta sensibilidade, **especificidade
> desprezível**. Tratar como a camada `+L02x` da HS: **teto de subcodificação
> possível (*bracketing*), nunca estimativa reportável**.
>
> **Fibrose cística (`E84`)** é formalmente um EIM (defeito monogênico AR do CFTR,
> canal de cloreto) e **está na triagem neonatal** (§4). É de longe o "EIM" mais
> prevalente e com melhor codificação/rede assistencial → **se incluída, DOMINA
> numericamente e distorce qualquer "total EIM"**. **Decisão recomendada: reportar
> FC SEMPRE como subgrupo isolado**, nunca diluída no agregado, e considerar excluí-la
> do "EIM metabólico *stricto sensu*" para não mascarar as demais (justificativa em §2).

---

### 1.12 EIM relevantes FORA do capítulo E (sinalização obrigatória)

A restrição a E70–E90 **perde EIM importantes** que a CID-10 alocou por
**manifestação de órgão**, não por bioquímica. Rastrear em `diagsec*` (SIH) e nas
linhas do SIM:

| EIM | CID provável `[VERIFICAR]` | Capítulo | Observação |
|---|---|---|---|
| Fibrose cística | `E84x` | IV (E) | *dentro* de E, mas fora de E70–E83 |
| Doenças mitocondriais (MELAS/Leigh/MERRF) | `G31x`, `G93x`, `E88x` | VI (G) + IV | dispersas |
| Adrenoleucodistrofia / leucodistrofias | `E71x`/`E75x` + `G60x`? | IV + VI | dispersas |
| Deficiência de biotinidase | `E53.8`? / `D81`? `[VERIFICAR]` | IV / III | **está na triagem neonatal (§4)** |
| Hiperplasia adrenal congênita (HAC) | `E250` (def. 21-hidroxilase) | IV (E) | **triagem neonatal**; EIM da esteroidogênese |
| Hipotireoidismo congênito | `E03x` | IV (E) | **triagem neonatal**; nem sempre "metabólico" clássico |
| Doença falciforme / hemoglobinopatias | `D57x`, `D56x` | III (D) | **triagem neonatal**; não é EIM metabólico, mas entra na mesma política |
| Imunodeficiências primárias (SCID por def. ADA) | `D81x` + `E799`? | III + IV | ADA-SCID é EIM de purina *e* IDP |
| Homocistinúria / def. cobalamina | `E721`, `E72x`, `D51x`? | IV + III | B12/folato dispersos |
| Def. de alfa-1-antitripsina | `E880`? | IV | pulmão/fígado |

> **Decisão de escopo recomendada:** o **eixo primário** é **E70–E83 + E88** (núcleo
> metabólico raro). **`E84` (FC), `E250` (HAC), `E03` (hipotireoidismo congênito),
> hemoglobinopatias (D56/D57)** entram **apenas no eixo "triagem neonatal / política"
> (§4)**, **sempre como subgrupos nomeados e separados**, porque (a) não são EIM
> metabólicos *stricto sensu* e (b) sua alta frequência e boa codificação **esmagariam**
> o sinal das doenças raras verdadeiras se agregadas.

---

## 2. Estratégia de captura em camadas (restrita ↔ ampliada / ENVELOPE)

Herdando a lógica **RESTRITA → +AMPLIADA → +ENVELOPE** do HS (`datasus_hs.md` §2), mas
adaptada a um **guarda-chuva de doenças** em vez de um CID único. Implementar com uma
função análoga a `camada_cid()` (rótulo por registro numa passada — `CLAUDE.md` §5),
retornando o **nível de camada** E o **subgrupo fisiopatológico** simultaneamente.

### 2.1 Núcleo de alta especificidade (análise primária)

CIDs onde o código mapeia com **boa fidelidade** a um EIM raro reconhecível
(marcados **CORE** acima):

`E700`,`E701`,`E702` · `E710`,`E711`,`E713`(+FAOD) · `E720`,`E721`,`E722`,`E723`,
`E724`,`E725` · `E740`,`E741`,`E742`,`E744` · `E750`,`E751`,`E752`,`E754`,`E755` ·
`E760`,`E761`,`E762`,`E770`,`E771` · `E830`(Wilson) · `E791` · `E800`,`E802`.

Prós: alta especificidade; comparável a registros de EIM e à literatura; numerador
"limpo". Contras: subestima (muitos EIM caem em "não especificados"; mitocondriais/CDG
escapam).

### 2.2 Camada ampliada

Acrescenta os **LIMÍTROFE** — "não especificados" dentro de blocos CORE (`E709`,`E712`,
`E729`,`E749`,`E753`,`E763`,`E769`,`E779`,`E799`,`E809`…) e classes de fidelidade
intermediária. Ganha sensibilidade, perde especificidade. Reportar **em camadas
separadas** (`CORE` → `+LIMÍTROFE`), mostrando o efeito de cada inclusão, exatamente
como `L732 → +L73x` na HS.

### 2.3 Camada ENVELOPE (teto de subcodificação — NÃO é caso)

`E888`/`E889` (outros/SOE), `E78x` (dislipidemia comum), `E831` (hemocromatose),
`E730`/`E731` (intolerância à lactose), `E790` (hiperuricemia/gota), e o `E88`
residual. **Razão sinal:ruído desfavorável em ordens de grandeza** — dominado por
doença **comum** que "mora" no capítulo metabólico.

> **Regra de ouro (idêntica ao `+L02x` do HS):** a camada ENVELOPE é **limite superior
> absoluto de subcodificação possível (*bracketing*)**, nomeada **"envelope"**, nunca
> "casos EIM ampliados". A hiperuricemia/dislipidemia/lactase comuns **não são EIM
> raro** — sua inclusão serve só para **dimensionar o teto**, não para estimar carga.

### 2.4 Granularidade recomendada da análise (3 níveis, reportados em paralelo)

1. **Grupo total EIM (CORE)** — **apenas como indicador de carga agregada de uso de
   serviço**, com ressalva permanente de que **soma doenças biologicamente distintas**
   (§6). Nunca interpretar como "prevalência de EIM".
2. **Subgrupos fisiopatológicos** — aminoacidopatias · acidúrias orgânicas
   (reconstruído, §1.2) · ciclo da ureia · FAOD · carboidratos/glicogenoses ·
   galactosemia · esfingolipidoses · MPS · glicoproteinoses · peroxissomais ·
   porfirias · purina/pirimidina · metais(Wilson). Unidade analítica **mais
   defensável** que o total.
3. **DOENÇAS-TRAÇADORAS** de alta especificidade e relevância de política (abaixo) —
   **o nível mais informativo e menos ruidoso** para narrativa e recomendação.

### 2.5 Lista recomendada de doenças-traçadoras

Critérios de seleção: (i) **especificidade do CID** (mapeamento razoável CID→doença);
(ii) **relevância de política pública** (triagem neonatal e/ou terapia de alto custo);
(iii) **cobertura de eixos contrastantes** (neonatal vs adulto; AR vs XL; tratável vs
não; ambulatorial vs internação vs óbito).

| Traçadora | CID-alvo `[VERIFICAR]` | Por que traçadora | Eixo que ilumina |
|---|---|---|---|
| **PKU / hiperfenilalaninemias** | `E700`,`E701` | Triagem neonatal histórica (etapa 1); fórmula metabólica de alto custo | Neonatal · política · CEAF-fórmula |
| **MSUD** | `E710` | Emergência metabólica neonatal; fórmula; letalidade precoce | Neonatal · SIM · fórmula |
| **Galactosemia** | `E742` | Triagem (Lei 14.154 etapa 2); crise neonatal | Neonatal · dieta |
| **Ciclo da ureia** (grupo) | `E722` | Hiperamonemia neonatal letal; OTC é **XL** | Neonatal · SIM · razão sexo |
| **MPS I / II / VI** | `E760`,`E761`,`E762` | **TRE de altíssimo custo** (laronidase/idursulfase/galsulfase); MPS II é XL | Custo · APAC · judicialização · sexo |
| **Doença de Gaucher** | `E752`¹ | **TRE (imiglucerase)**; protótipo de EIM tratável de alto custo | Custo · CEAF/APAC · judicialização |
| **Doença de Pompe** | `E740`¹ | **TRE (alglucosidase)**; forma infantil letal + adulta | Custo · neonatal+adulto |
| **Doença de Fabry** | `E752`¹ | TRE; **XL**; apresentação adulta | Custo · adulto · sexo |
| **X-ALD** | `E71x`/`E75x`¹ `[VERIFICAR]` | **XL**; triagem neonatal em expansão global; TMO | Neonatal · sexo · neurológico |
| **Doença de Wilson** | `E830`¹ | **Apresentação tardia (adulto jovem)**; quelantes; tratável | Adulto · CEAF-quelante · contraponto neonatal |
| **Fibrose cística** | `E84x` | Triagem; alta prevalência relativa; rede consolidada | Política · benchmark de "EIM bem codificado" |

> ¹ **Ressalva de não-separabilidade (crítica):** Gaucher, Fabry, Niemann-Pick etc.
> **compartilham `E752`**; Pompe está em `E740` junto de todas as glicogenoses; X-ALD/
> Wilson têm posição a confirmar. **O CID NÃO isola a maioria das traçadoras
> lisossômicas.** A separação real depende de **triangular com o procedimento APAC da
> TRE específica** (imiglucerase↔Gaucher, alglucosidase↔Pompe, laronidase↔MPS I,
> idursulfase↔MPS II, galsulfase↔MPS VI, agalsidase↔Fabry — §5), que é
> **enzima-específico** e, portanto, **mais específico que o CID** para essas doenças.
> Este é o **inverso da HS**, onde o CID era mais específico que o procedimento.

---

## 3. Fenótipo → genótipo e história natural relevantes ao desenho

### 3.1 Idade de início — bimodal, com consequências sobre qual base informa

| Padrão de início | Exemplos | Base DATASUS mais informativa |
|---|---|---|
| **Neonatal/lactente, agudo, letal** | MSUD, ciclo da ureia, acidúrias orgânicas, galactosemia clássica, FAOD grave, Pompe infantil | **SIM (mortalidade infantil/neonatal)** + SIH (UTI neonatal). Ver §3.4 |
| **Infantil progressivo** | MPS, esfingolipidoses, glicogenoses, mitocondriais | SIH + SIA (TRE/seguimento) |
| **Adulto/tardio** | Wilson, Fabry, porfirias agudas, Pompe adulto, Gaucher tipo I leve | SIA/SIH adulto; SIM menos específico |

> **Inversão de premissa frente à HS.** Na HS o SIM era "quase invisível" (N=65). Em
> EIM, para o **subconjunto neonatal letal**, o **SIM pediátrico/neonatal pode ser a
> base MAIS informativa** — óbito precoce por descompensação metabólica é justamente
> onde o registro existe. **Decisão: promover o SIM de "exploratório" (como na HS) a
> eixo de primeira linha para as traçadoras neonatais** (MSUD, ciclo da ureia,
> acidúrias orgânicas, FAOD, galactosemia). Rastrear `causabas` **e** `linhaa–d`/
> `linhaii` (a descompensação metabólica pode estar na linha, com sepse/óbito como
> causa básica).

### 3.2 Herança e razão de sexo esperada

- **Maioria autossômica recessiva (AR).** Implica **razão de sexo ~1:1** esperada.
  **Desvios acentuados de 1:1 em CID AR = bandeira de miscodificação ou de acesso
  diferencial**, não achado biológico (ressalva análoga ao viés de gravidade da HS).
- **Ligadas ao X (XL) — predomínio masculino esperado:** **MPS II (Hunter, `E761`)**,
  **Fabry (`E752`, parcial)**, **X-ALD (*ABCD1*)**, **Lesch-Nyhan (`E791`)**, **OTC**
  (ciclo da ureia, dentro de `E722` — heterozigotas podem manifestar), **Menkes**
  (`E830`), **Hunter**. → nesses CIDs, **razão de sexo M:F fortemente > 1 é o esperado
  biológico**; usar como **checagem de consistência sexo × CID** (§6.8 do HS).
- **Mitocondriais de mtDNA:** herança **materna**, heteroplasmia — não capturável no
  dado administrativo, mas relevante ao interpretar agregados familiares (inexistentes
  no DATASUS público — sem ID longitudinal).

### 3.3 Consanguinidade e distribuição regional (Nordeste)

EIM AR têm frequência elevada em **populações com maior taxa de consanguinidade e
efeito fundador**. O **Nordeste do Brasil** apresenta **maior prevalência histórica de
uniões consanguíneas** que outras regiões `[VERIFICAR magnitude — literatura de
genética de populações brasileira, ex. Santos/Weller, e dados de efeito fundador
regional; NÃO citar número sem fonte]`. Consequência para o desenho:

> **Hipótese testável (a priori):** para EIM **AR**, a **taxa de detecção por
> UF/região pode ser genuinamente maior no NE** por maior frequência alélica
> (consanguinidade/fundador), **e não apenas por acesso**. Isso **compete** com o
> confundimento por oferta (o NE tem *menos* centros de referência → subdetecção).
> **Os dois efeitos empurram em sentidos opostos** e o dado administrativo **não os
> separa**. Reportar como no HS: **mapa de detecção × mapa de oferta (CNES) lado a
> lado**, sem afirmar prevalência. Efeito fundador específico (ex. clusters regionais
> de MPS VI no NE `[VERIFICAR — há literatura brasileira sobre MPS VI e efeito
> fundador no NE]`) é **hipótese a levantar, não a assumir**.

### 3.4 Letalidade precoce → o SIM ganha centralidade (e traz seus próprios vieses)

A letalidade neonatal alta de vários EIM (ciclo da ureia, acidúrias orgânicas, MSUD,
FAOD, galactosemia) significa que:

- parte dos casos **morre antes de qualquer registro ambulatorial (SIA) ou de
  diagnóstico** → **subcaptura fatal**: o EIM pode figurar como "sepse neonatal",
  "insuficiência hepática", "encefalopatia" (SIM `causabas`) **sem o CID metabólico**;
- **mortalidade infantil evitável** é justamente o argumento de política para triagem
  neonatal (§4) → o SIM é **o desfecho-chave de impacto**, não um apêndice;
- **[VERIFICAR]** viabilidade de cruzar `causabas` de óbito infantil com CIDs
  metabólicos nas linhas — pode revelar EIM ocultos sob causa básica inespecífica.

### 3.5 Ancoragem em bancos (para verificação, não para inventar)

Para cada traçadora, ancorar mecanismo/herança/gene em **OMIM** e nosologia/prevalência
em **Orphanet (ORPHA)** — p.ex. PKU (OMIM #261600, *PAH*), MSUD (#248600), Gaucher
(#230800, *GBA1*), Pompe (#232300, *GAA*), MPS I (#607014/#607015, *IDUA*), MPS II
(#309900, *IDS*), Fabry (#301500, *GLA*), X-ALD (#300100, *ABCD1*), Wilson (#277900,
*ATP7B*), tirosinemia I (#276700, *FAH*). **[VERIFICAR todos os números OMIM/ORPHA
antes de publicar — citados de memória do modelo; confirmar em omim.org / orpha.net.]**
GeneReviews (NCBI Bookshelf) como porta de entrada revisada por doença.

---

## 4. Interface com a triagem neonatal (teste do pezinho / PNTN) e a Lei 14.154/2021

O **Programa Nacional de Triagem Neonatal (PNTN)** e a **Lei 14.154/2021** são o
principal **modificador temporal da detecção** de EIM na série — análogo ao papel que a
incorporação do adalimumabe teve na HS, mas com efeito **sobre o numerador de
detecção** (mais doenças rastreadas → mais diagnósticos precoces registrados).

### 4.1 Situação legal (com marcações de verificação)

- **Lei 14.154, de 26/05/2021** — amplia o teste do pezinho no SUS de forma
  **escalonada**, prevendo até **~50 doenças / 14 grupos** ao fim da implementação
  `[VERIFICAR número exato de grupos/doenças]`. A **regulamentação e o cronograma** de
  cada etapa cabem ao Ministério da Saúde `[VERIFICAR portarias de regulamentação e
  datas efetivas de cada etapa — DOU/gov.br]`.
- **Antes da lei (base histórica do PNTN):** rastreio de **fenilcetonúria,
  hipotireoidismo congênito, doença falciforme/hemoglobinopatias, fibrose cística,
  hiperplasia adrenal congênita, deficiência de biotinidase** (6 doenças / "fase IV"
  do PNTN antigo) `[VERIFICAR composição exata por fase do PNTN pré-2021]`.

### 4.2 Escalonamento previsto (etapas) — `[VERIFICAR cronograma e vigência efetiva]`

| Etapa | Grupos incluídos (previsto) | EIM relevantes ao nosso escopo |
|---|---|---|
| 1 | Fenilalanina (PKU), hemoglobinopatias, toxoplasmose congênita | **PKU (`E700/E701`)** |
| 2 | **Galactosemias, aminoacidopatias, distúrbios do ciclo da ureia, distúrbios da beta-oxidação de ácidos graxos** | **Galactosemia (`E742`), MSUD/aminoacidopatias (`E71x`), ciclo da ureia (`E722`), FAOD (`E713`)** |
| 3 | **Doenças lisossômicas** | **MPS, esfingolipidoses, Gaucher, Fabry, Pompe (`E74/E75/E76`)** |
| 4 | Imunodeficiências primárias | ADA-SCID (interface purina) |
| 5 | Atrofia muscular espinhal (AME) | (não-EIM; fora do escopo metabólico) |

> **Fonte:** texto da Lei 14.154/2021 (etapas) e material do MS/PNTN. **A ORDEM e o
> CONTEÚDO das etapas 2 e 3 são exatamente os subgrupos EIM que mais nos interessam.**
> **[VERIFICAR]** literalmente contra o art. da lei e as portarias — o rótulo "etapa"
> e a alocação de doenças por etapa **variam entre fontes secundárias** e a
> **implementação efetiva está muito atrasada** (relatos de poucos estados aderindo até
> 2025/2026 `[VERIFICAR situação atual da adesão por UF]`).

### 4.3 Efeito esperado na série temporal 2020–2025 (hipóteses)

1. **Descontinuidade de detecção pós-2021** para os EIM que entraram na triagem
   (galactosemia, aminoacidopatias, ciclo da ureia, FAOD, lisossômicas) → **aumento de
   registros que é artefato de política de rastreio, não de incidência** — ressalva
   **análoga à COVID e ao Censo** no HS: quebra de série a sinalizar, não tendência.
2. **Heterogeneidade espacial brutal:** como a adesão à Lei 14.154 é **estadual e
   desigual** `[VERIFICAR]`, a "detecção de EIM por UF" refletirá **em que UFs a
   triagem ampliada já opera**, confundindo política com epidemiologia. **Reportar
   cobertura de triagem por UF (se houver fonte) ao lado do mapa de detecção.**
3. **Deslocamento do momento do diagnóstico** (mais neonatal, menos tardio) →
   composição etária dos registros pode mudar ao longo da série por **efeito de
   rastreio**, não por mudança da doença.
4. **Janela curta / atraso de implementação:** dado o atraso, **grande parte do efeito
   pode ainda não ter aparecido em 2020–2025** → esperar sinal fraco e não
   sobreinterpretar.

> **Onde a triagem aparece no dado:** o teste do pezinho em si é **procedimento SIA**
> `[CONFIRMAR via fetch_sigtab() — códigos de coleta/análise de triagem neonatal]`; o
> **diagnóstico confirmado** entra como CID (E70–E90) em SIA/SIH. O **SIM** capta a
> **falha** do sistema (óbito por EIM não rastreado a tempo). Triangular os três dá o
> arco "rastreio → diagnóstico → desfecho".

---

## 5. Terapias de alto custo e eixo de política

O eixo de política do EIM é **mais rico que o da HS** (um único biológico): há
**múltiplas TRE enzima-específicas**, **fórmulas metabólicas** e **quelantes**, com
forte componente de **judicialização** (medicamentos órfãos ultra-caros).

### 5.1 Terapia de Reposição Enzimática (TRE) — enzima-específica → mais específica que o CID

| Doença | Enzima/fármaco (DCB) `[VERIFICAR incorporação e PCDT]` | CID diluído | Componente |
|---|---|---|---|
| Gaucher | **imiglucerase** / velaglicerase / taliglucerase | `E752` | CEAF / APAC medicamento `[VERIFICAR]` |
| Pompe | **alglucosidase alfa** | `E740` | alto custo `[VERIFICAR incorporação SUS]` |
| MPS I (Hurler) | **laronidase** | `E760` | CEAF/APAC `[VERIFICAR]` |
| MPS II (Hunter) | **idursulfase** | `E761` | CEAF/APAC `[VERIFICAR]` |
| MPS VI (Maroteaux-Lamy) | **galsulfase** | `E762` | CEAF/APAC `[VERIFICAR]` |
| Fabry | **agalsidase alfa/beta** | `E752` | `[VERIFICAR incorporação — histórico de judicialização]` |

> **Ativo analítico central:** como a **TRE é enzima-específica**, o **procedimento/
> medicamento de alto custo é MAIS específico que o CID** para identificar Gaucher,
> Pompe, Fabry e cada MPS (que colapsam em `E752`/`E740`). **Inverte a estratégia da
> HS**: aqui **triangular CID × procedimento-APAC da enzima** é a via para
> **desagregar** doenças-traçadoras lisossômicas. **[CONFIRMAR via fetch_sigtab()]** os
> códigos APAC de cada enzima e a disponibilidade de **SIA-AM/AP (APAC)** — lembrando
> a limitação já registrada no HS de que a extração pode **não trazer `pa_cidpec`** nem
> a base APAC (`CLAUDE.md` §7.1). **Sem a base APAC, a desagregação lisossômica fica
> inviável** → sinalizar como no HS.

### 5.2 Fórmulas metabólicas (dietoterapia)

- **PKU:** fórmula isenta de fenilalanina; **MSUD:** fórmula isenta de BCAA;
  aminoacidopatias/ciclo da ureia: fórmulas/aminoácidos especiais.
- Dispensação frequentemente por **componente especializado / demanda judicial /
  programas estaduais** — **fonte de judicialização crônica** (fórmulas de alto custo,
  uso vitalício). **[VERIFICAR]** se e como aparecem no SIA (procedimento de
  dispensação de fórmula/nutrição) ou se são majoritariamente extra-SUS/judiciais →
  provável **invisibilidade parcial no DATASUS**.

### 5.3 Quelantes (Wilson) e outros

- **Wilson (`E830`):** **D-penicilamina, trientina, zinco** — quelantes de cobre; uso
  vitalício. `[VERIFICAR componente de dispensação e PCDT de Wilson]`.
- **Tirosinemia I:** **nitisinona (NTBC)** — órfão de alto custo `[VERIFICAR]`.

### 5.4 Procedimentos APAC a rastrear (lista de trabalho — `[CONFIRMAR via fetch_sigtab()]`)

- APAC de **medicamento de alto custo** por enzima (§5.1);
- APAC/procedimento de **dispensação de fórmula metabólica** (se existir);
- **TMO** (transplante de medula) para X-ALD/algumas leucodistrofias e MPS `[VERIFICAR]`;
- **transplante hepático** (tirosinemia, ciclo da ureia, Wilson fulminante) — SIH;
- consultas/seguimento em **serviço de referência em doenças raras** (CBO/estabelecimento
  CNES habilitado — cruzar com a rede de **Serviços de Referência em Doenças Raras**
  instituída pela política nacional `[VERIFICAR portaria da Política Nacional de
  Atenção Integral às Pessoas com Doenças Raras — PNAIPDR/2014 e habilitações]`).

> **Judicialização — ressalva idêntica ao adalimumabe do HS, amplificada.** Os
> medicamentos órfãos de EIM estão entre os **mais judicializados do SUS**. O dado
> administrativo **não distingue** dispensação via política incorporada vs via ordem
> judicial; e parte do gasto pode estar **fora do SIA/SIH** (compras centralizadas,
> execução judicial). **Não afirmar "gasto total do SUS com TRE" a partir do DATASUS
> isoladamente** — reportar o que o SIA/APAC capta, com ressalva explícita de
> subcaptura por via judicial/extra-SIA.

---

## 6. Ressalvas interpretativas específicas do grupo EIM

Além de **todas** as ressalvas herdadas do HS (desenho ecológico; unidade = registro
não pessoa; sem ID longitudinal; bases não somáveis; taxas de **detecção/uso** e não
prevalência; efeito COVID 2020–2021; descontinuidade do denominador Censo 2022; LGPD/
supressão N<5; left-truncation), o EIM adiciona ressalvas **próprias e severas**:

1. **HETEROGENEIDADE EXTREMA — não somar doenças distintas.** "EIM" agrega centenas de
   doenças com biologia, tratamento e prognóstico incompatíveis. **Um "total EIM" é uma
   soma de maçãs com laranjas** — só admissível como *carga agregada de uso de serviço*,
   nunca como entidade epidemiológica. **Priorizar subgrupos e traçadoras** (§2.4). Esta
   é a ressalva-mãe, a repetir em cada eixo e cada `.qmd` (como o "detecção ≠
   prevalência" no HS).

2. **CID capta FENÓTIPO/SUBSTRATO, não a doença molecular.** A CID-10 de 4 caracteres
   **não chega ao gene**. `E752` = dezenas de esfingolipidoses distintas; `E740` =
   todas as glicogenoses + Pompe; `E722` = todos os defeitos do ciclo da ureia. **A
   desagregação para doença molecular é impossível só com CID** — depende de
   triangular com **procedimento/enzima** (§5) e, mesmo assim, parcial.

3. **Subdiagnóstico e diagnóstico tardio massivos.** EIM raros têm **anos de atraso
   diagnóstico** (odisseia diagnóstica) e **subdiagnóstico fatal** (morte antes do
   diagnóstico, §3.4). O numerador é **fração pequena e enviesada** dos casos reais —
   pior que na HS. **Viés de gravidade e de acesso a centros de referência**: só chega
   a `E7xx` quem alcançou um serviço especializado capaz de codificar corretamente →
   o perfil capturado é o de **quem acessou a rede de doenças raras**, concentrada em
   capitais/Sudeste-Sul (competindo com o gradiente de consanguinidade do NE — §3.3).

4. **Códigos "não especificados" e "outros" inflados.** Grande parte dos EIM cai em
   `E729`,`E749`,`E759`,`E769`,`E779`,`E888`,`E889` porque o codificador não dispõe do
   diagnóstico molecular no momento do registro. Isso **desloca massa para o envelope**
   e **esvazia os CIDs específicos** — subestimando as traçadoras e superestimando o
   "outros". Reportar a **razão CORE : não-especificado** por subgrupo como **indicador
   de qualidade diagnóstica/codificação** (análogo à razão `L02x/L732` do HS, mas aqui
   *interna* ao capítulo E).

5. **Doença comum "morando" no capítulo metabólico.** `E78` (dislipidemia), `E790`
   (gota/hiperuricemia), `E831` (hemocromatose *HFE*), `E73x` (intolerância à lactose)
   são **comuns e multifatoriais**, não EIM raros. Se agregadas, **dominam o capítulo E
   e afogam o sinal raro**. Exclusão explícita do núcleo (§1, §2.3).

6. **Fibrose cística e as "não-metabólicas da triagem" esmagam o agregado.** FC
   (`E84`), HAC (`E250`), hipotireoidismo congênito (`E03`), hemoglobinopatias
   (D56/D57) são **muito mais frequentes e mais bem codificadas** que os EIM
   metabólicos raros → **nunca diluir no total**; sempre subgrupo isolado (§1.11).

7. **Mitocondriais e CDG praticamente inceptáveis** pela CID-10 (§1.10, §1.3) →
   qualquer subgrupo "mitocondrial"/"CDG" é grosseiro e **muito subestimado**;
   declarar.

8. **Efeito da triagem neonatal como confundidor temporal e espacial** (§4) — a
   ampliação escalonada e desigual por UF mistura **mudança de detecção por política**
   com epidemiologia. Tratar como quebra de série sinalizada (como COVID/Censo no HS).

9. **Razão de sexo como faca de dois gumes.** Em CID **XL** (MPS II, Fabry, X-ALD,
   Lesch-Nyhan, OTC) o predomínio masculino é **esperado** e serve de **controle de
   qualidade**; em CID **AR**, desvio de 1:1 é **bandeira de erro/acesso** — a
   interpretação da razão de sexo **depende da herança do CID específico**, não é
   uniforme como na HS (onde 3:1 F:M era o esperado único).

10. **Prevalência da literatura só como moldura de plausibilidade.** Prevalências
    individuais de EIM (ex. PKU ~1:10.000, MPS combinada ~1:25.000, Gaucher ~1:40.000
    `[VERIFICAR TODAS — números de memória; confirmar em Orphanet/literatura brasileira,
    ex. estudos de triagem e o consórcio brasileiro de EIM]`) servem só para
    **dimensionar o gap de captação** (carga esperada × população vs capturado), **nunca
    como denominador**. **Não somar prevalências** de doenças distintas para "prevalência
    de EIM".

---

## 7. Decisões de escopo consolidadas (síntese operacional para o bioinformata)

- **Núcleo primário:** E70–E83(CORE)+ subgrupos + traçadoras (§1, §2.1, §2.5).
- **`E78`, `E790`, `E831`, `E73x`, `E888/889`, amiloidose adquirida → ENVELOPE**, nunca
  caso (§2.3).
- **`E830` Wilson → INCLUIR** (traçadora de EIM tardio tratável); **`E831` hemocromatose
  → EXCLUIR** do núcleo (§1.7).
- **FC/HAC/hipotireoidismo congênito/hemoglobinopatias → só no eixo triagem/política,
  como subgrupos isolados** (§1.11, §4).
- **SIM promovido a eixo de primeira linha para traçadoras neonatais letais** (§3.1,
  §3.4) — diferente da HS.
- **Desagregação lisossômica (Gaucher/Fabry/Pompe/MPS) via triangulação CID × APAC-
  enzima** — depende da base APAC/`pa_cidpec`, possivelmente indisponível (§5.1).
- **Toda métrica agregada de "EIM total" carrega a ressalva de heterogeneidade** (§6.1)
  e é lida como **carga de uso de serviço**, não prevalência.
- **Camadas implementadas numa passada** por função tipo `camada_cid()` retornando
  `nivel` (CORE/LIMÍTROFE/ENVELOPE) **e** `subgrupo` fisiopatológico (`CLAUDE.md` §5).
- **Todos os rótulos de CID, números OMIM/ORPHA/prevalência, portarias PNTN/Lei
  14.154, incorporações de TRE e códigos APAC estão marcados `[VERIFICAR]` /
  `[CONFIRMAR via fetch_sigtab()]`** e não devem ser publicados sem confirmação em
  fonte primária.

---

## Fontes consultadas (geneticista) — a confirmar em fonte primária

- Estrutura CID-10 E70–E90 (blocos e categorias de 3 caracteres): busca web
  (HiDoctor/Sanar/DataSUS CID10 V2008) — **rótulos de 4 caracteres NÃO verificados
  literalmente** (portal DATASUS inacessível na redação; `[VERIFICAR]`).
- Lei 14.154/2021 e etapas do PNTN: Planalto (texto da lei), Senado/Câmara (notícias de
  sanção), Ministério da Saúde/gov.br (reestruturação PNTN 2024), Metrópoles (adesão por
  UF, 2026) — **cronograma efetivo e composição por etapa `[VERIFICAR]`**.
- Mecanismo/herança/gene por doença: OMIM, Orphanet, GeneReviews — **números `[VERIFICAR]`**.
- Nosologia mecanística: Saudubray, *Inborn Metabolic Diseases*; ICIMD (classificação
  internacional de EIM) — referência conceitual de memória do modelo.
