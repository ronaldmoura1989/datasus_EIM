# Plano técnico (Bioinformática / Engenharia de dados em R) — EIM no DATASUS

> **Escopo desta seção.** Implementação técnica em R da análise de microdados do DATASUS
> sobre **Erros Inatos do Metabolismo (EIM)** — grupo de doenças raras (CID-10 **E70–E90**
> + correlatos), triangulando **SIA-PA** (ambulatorial), **SIH-RD** (internações),
> **SIM-DO** (mortalidade) e integrando **SINASC** (nascidos vivos, denominador de
> **incidência ao nascimento**). Reaproveita a engenharia validada no projeto de
> Hidradenite Supurativa (`datasus_HS/`) — **stack, convenções, `utils.R`, padrão de
> scripts numerados, Parquet particionado, `calcular_taxas.R`, pseudo-ID e publicação
> Quarto/GitHub Pages** são herdados com adaptações pontuais, sinalizadas abaixo.
>
> **O que muda estruturalmente vs HS** (1 CID `L732`): (i) o alvo é um **grupo de
> centenas de CIDs** → a captura deixa de ser "detecção booleana de 1 código" e vira
> **rotulagem por subgrupo fisiopatológico via lookup table**; (ii) entra o **SINASC**
> como 4ª base (denominador de nascidos vivos); (iii) o eixo central deixa de ser
> "detecção/uso" para incluir **incidência ao nascimento por 100 mil NV** para as
> doenças-traçadoras da **triagem neonatal** ("teste do pezinho"); (iv) a raridade é
> extrema → **supressão de células N<5 é regra estrutural, não ressalva**, e muitos
> estratos serão vazios.
>
> **Marcação de pendências (herdada do HS):** `[VERIFICAR]` = exige confirmação
> documental; `[CONFIRMAR via fetch_sigtab()]` = código de procedimento/APAC/CBO a
> validar na competência. **Nunca inventar** CID, subgrupo, procedimento, portaria de
> triagem neonatal ou número de incidência.

---

## 1. Stack e arquitetura do pipeline

### 1.1 Pacotes (herda o `pkgs_cran`/`pkgs_github` do HS `00_setup.R`, + adições EIM)

| Finalidade | Pacotes | Nota EIM |
|---|---|---|
| Manipulação / iteração | `tidyverse` (`dplyr`, `tidyr`, `purrr`, `stringr`, `forcats`, `lubridate`) | padrão do projeto |
| Volume / bind / linkage pesado | **`data.table`** | SINASC nacional (~2,5 M NV/ano × 6 anos) e varredura multi-CID exigem `data.table`; **não** `map_dfr` sobre brutos |
| Colunar / lazy | **`arrow`** (`write_dataset`, `open_dataset`, `schema`) | Parquet particionado por `ano`×`uf`; fixar `schema()` explícito |
| Extração DATASUS | **`microdatasus`** (`fetch_datasus`, `process_sia/sih/sim/sinasc`, `tabMun`); **`read.dbc`** (fallback `.dbc`) | pinar SHA no `renv.lock` (§6). Alternativa PCDaS-Fiocruz p/ validação cruzada |
| Limpeza de nomes | `janitor::clean_names()` | sempre após carregar |
| Estatística | **`rstatix`**, `broom` (tidy de modelos); **`epitools::ageadjust.direct`** (padronização + IC gama); `MASS::glm.nb`/`stats::glm` (Poisson/quasi-Poisson tendência) | tendência com offset `log(pop)` ou `log(NV)` |
| Denominador populacional | **`sidrar`** (API SIDRA) | pop IBGE UF×sexo×faixa (Censo 2022) |
| Denominador de incidência | **SINASC** via `microdatasus` (nascidos vivos UF×ano) | **diferencial deste projeto** |
| Gráficos / tabelas | `ggplot2`+`ggpubr`, `patchwork`; `flextable`+`officer`, `gt` | herdado |
| Mapas | **`geobr`** + `geom_sf` | mapas de incidência ao nascimento por UF |
| QC de missing | `naniar` | completude de `codanomal`/CID |
| Reprodutibilidade | `renv`, `yaml`, `digest`, `here` | `renv::snapshot()` obrigatório |

Adições ao vetor do `00_setup.R` (mantendo canais CRAN→Bioc→GitHub do `ensure_pkg`):
`igraph` (componentes conexos do pseudo-ID, já usado no HS), nada de Bioconductor
previsto — **mas** se algum `.qmd` puxar Bioc, manter o override de namespaces do
HS (`select <- dplyr::select`, `filter <- dplyr::filter`, etc. — HS `00_setup.R` L49–54).

### 1.2 Estrutura de diretórios e scripts numerados (espelha o HS)

```
datasus_EIM/
├── CLAUDE.md                      # guia operacional (clonar do HS, trocar HS→EIM)
├── datasus_eim.md                 # metodologia/plano (parte epidemiológica)
├── _quarto.yml                    # website → output-dir: docs
├── renv.lock
├── scripts/
│   ├── 00_setup.R                 # ensure_pkg, params (CID_GRUPO, ANOS, FAIXAS_BR), seed, dirs
│   ├── utils.R                    # herda HS + classificar_eim(), varredura multi-CID
│   ├── eim_lookup.R              # LOOKUP TABLE CID→classe (o coração deste projeto)
│   ├── 01_validar_brutos.R        # grade + conteúdo (SIA/SIH/SIM/SINASC)
│   ├── get_eim_data_from_SIA.R    # ingestão FILTRADA por regex de prefixo → parquet/sia_eim
│   ├── get_eim_data_from_SIH.R    # diag_princ + diagsec1..9 (if_any) → parquet/sih_eim
│   ├── get_eim_data_from_SIM.R    # causabas + linhaa..d + linhaii (multi-CID, †/*) → sim_eim
│   ├── get_denominadores_ibge.R   # pop IBGE UF×sexo×faixa (sidrar, cache) — herda HS
│   ├── get_nascidos_vivos_SINASC.R# NV por UF×ano (denominador de INCIDÊNCIA) — NOVO
│   ├── feature_eng_pacientes_SIA.R# pseudo-ID (avaliar por subgrupo — §5) — herda HS
│   └── calcular_taxas.R           # taxas det/uso + INCIDÊNCIA ao nascimento/100 mil NV
├── qmd/
│   ├── index.qmd                  # KPIs + mapa incidência ao nascimento
│   ├── sia_eim.qmd  sih_eim.qmd  sim_eim.qmd  sinasc_eim.qmd
├── data/
│   ├── raw/{SIA,SIH,SIM,SINASC}/  # brutos (transferidos/baixados)
│   ├── filtered/{sia,sih,sim}_eim/
│   ├── denominators/{pop_ibge.parquet, nascidos_vivos.parquet}
│   ├── parquet/{sia_eim,sih_eim,sim_eim}/    # particionado ano+uf
│   └── consolidated/{sia,sih,sim}_eim_nacional.RData
├── logs/run_log_{sia,sih,sim,sinasc}.csv
├── manifest/                      # params_run_*.yaml, checksums, eim_lookup_versao.csv
└── docs/                          # site + .nojekyll
```

`.gitignore`, versionamento (`scripts/`, `qmd/`, `docs/`, `manifest/`, `renv.lock`)
e o `_quarto.yml` são idênticos ao HS.

### 1.3 Encoding, tipos, granularidade (herda `utils.R` do HS sem alteração)

- **Encoding latin1→UTF-8 SEMPRE** após carregar (`corrigir_encoding()` do HS). **Crítico
  no SIM** (marcadores `†`/`*` na notação daga-asterisco) e em nomes de município —
  **sempre juntar por código IBGE, nunca por nome**.
- **Coerção de tipos** (`coagir_tipos()` do HS): monetários (`pa_valapr`, `val_tot`,
  `val_sh`, `val_sp`) com `readr::parse_number()`; datas (`dt_inter`, `dt_saida`,
  `dt_obito`, `dtnasc` do SINASC) com `lubridate::ymd()`; CIDs/códigos IBGE preservados
  como `character` com zero-padding.
- **Granularidade real:** **SIA/SIH mensais** (iterar UF×ano×mês, ou por trimestre se os
  brutos vierem consolidados como no HS §7.1); **SIM anual** por UF; **SINASC anual** por
  UF. `TRIMESTRES` é só agregação de relatório, nunca chave.
- **`casar_tipos()`** (HS `utils.R`) antes de `bind_rows()` — layout de SINASC/SIH muda
  entre anos (colunas novas geram superset; `bind_rows` preenche `NA`).

---

## 2. Captura por CID para um grupo grande (E70–E90 + correlatos)

Este é o **ponto que mais diverge do HS**. Em vez de `camada_cid()` (booleano sobre 1
código), desenhamos **`classificar_eim(cid)`** que faz **uma passada** e devolve **classe
fisiopatológica** + **nível de especificidade** (core vs envelope), via **lookup table**
(`data.frame` CID→classe) aplicada por **regex de prefixo**.

### 2.1 Lookup table (`scripts/eim_lookup.R`) — CID → subgrupo fisiopatológico

O grupo E70–E90 é heterogêneo. A tabela mapeia **prefixos** (3–4 chars, sem ponto) para
uma **classe fisiopatológica** e uma **camada** (`core` = EIM inequívoco vs `envelope` =
categoria que também abriga não-EIM, análoga ao `L02x` do HS). Estrutura sugerida
`[VERIFICAR cada linha com geneticista — a lista abaixo é ilustrativa, não exaustiva]`:

```r
# eim_lookup.R — CID-10 (sem ponto) → subgrupo fisiopatológico de EIM.
# ⚠️ Prefixos ilustrativos [VERIFICAR/COMPLETAR com genética/dicionário CID-10].
# camada: "core" (EIM inequívoco) | "envelope" (abrange não-EIM — teto, não caso).
# match por PREFIXO (str_starts) → mais específico primeiro (ordem importa).
EIM_LOOKUP <- tibble::tribble(
  ~prefixo, ~classe,                         ~camada,
  # --- Aminoacidopatias (E70–E72) ---
  "E700",   "aminoacidopatia_PKU",           "core",     # fenilcetonúria clássica (triagem neonatal)
  "E701",   "aminoacidopatia_outras_fenil",  "core",
  "E71",    "aminoacidopatia_BCAA_MSUD",     "core",     # inclui MSUD/leucinose (triagem)
  "E72",    "aminoacidopatia_outras",        "core",
  # --- Metabolismo de carboidratos (E73–E74) ---
  "E730",   "intol_lactose_congenita",       "envelope", # E73 abriga intol. adquirida (não-EIM)
  "E74",    "carboidrato_glicogenose_etc",   "core",     # glicogenoses, galactosemia (triagem)
  # --- Lipídios / lisossômicas (E75) ---
  "E75",    "lisossomica_esfingolipidose",   "core",     # Gaucher, Fabry, Niemann-Pick, Tay-Sachs
  # --- Metabolismo mineral / outras (E76–E78, E79, E80) ---
  "E76",    "mucopolissacaridose",           "core",     # MPS I–VII
  "E77",    "glicoproteina_CDG",             "core",
  "E80",    "porfiria_bilirrubina",          "core",     # porfirias; E80.4 Crigler-Najjar/Gilbert
  # --- Ciclo da ureia / outras metabólicas (E88 e afins) ---
  "E884",   "mitocondrial",                  "core",     # [VERIFICAR mapeamento exato]
  "E72",    "ciclo_ureia",                   "core",     # hiperamonemias em subcódigos de E72 [VERIFICAR]
  # --- Envelope amplo (E70–E90 não classificado acima) ---
  "E7",     "eim_metabolico_outros",         "core",
  "E88",    "eim_metabolico_outros",         "envelope", # E88 abriga distúrbios não-EIM
  "E90",    "eim_manifest_alhures",          "envelope"  # cód. daga/asterisco em outras doenças
) |>
  dplyr::mutate(prefixo = toupper(prefixo)) |>
  dplyr::arrange(dplyr::desc(nchar(prefixo)))   # mais específico ganha no match
```

> **Decisões de desenho da lookup:**
> - **Ordenar por comprimento decrescente do prefixo** e resolver por *first-match* →
>   `E700` (PKU) vence `E7` (envelope). Espelha a lógica "mais específico primeiro" e
>   evita a regex aberta que o HS evitou em `camada_cid()`.
> - **Coluna `camada` (core/envelope)** é o análogo do `L732` vs `L02x` do HS: `envelope`
>   = categorias CID que abrigam **também** condições não-EIM (ex.: E73 intolerância à
>   lactose adquirida; E88 distúrbios metabólicos diversos) → reportar como **teto de
>   subcodificação**, nunca como caso confirmado (*bracketing*).
> - **Coluna `classe`** dá o subgrupo fisiopatológico (aminoacidopatia / lisossômica /
>   ciclo da ureia / mucopolissacaridose / mitocondrial / …) para estratificar todas as
>   análises. Uma coluna adicional `triagem_neonatal` (lógico) marca as
>   **doenças-traçadoras do teste do pezinho** `[VERIFICAR painel PNTN vigente]` — usadas
>   no cálculo de **incidência ao nascimento** (§4).
> - **Versionar a lookup** em `manifest/eim_lookup_versao.csv` (data + hash `digest`) —
>   a definição de caso É a lookup; mudá-la muda todos os números.

### 2.2 `classificar_eim()` — rotulagem por camada/subgrupo numa única passada

```r
# utils.R (EIM) — devolve tibble com classe + camada por código, em UMA passada.
# Vetorizado: recebe vetor de CIDs, casa por prefixo contra EIM_LOOKUP.
classificar_eim <- function(cids, lookup = EIM_LOOKUP) {
  x <- stringr::str_sub(stringr::str_trim(toupper(as.character(cids))), 1, 4)
  # match por prefixo: para cada cid, o 1º prefixo (mais específico) que ele começa
  idx <- purrr::map_int(x, function(c) {
    if (is.na(c) || c == "") return(NA_integer_)
    hit <- which(stringr::str_starts(c, lookup$prefixo))
    if (length(hit)) hit[1] else NA_integer_   # lookup já ordenada desc(nchar)
  })
  tibble::tibble(
    cid    = x,
    classe = lookup$classe[idx],
    camada = lookup$camada[idx],
    eh_eim = !is.na(idx)
  )
}
# Conveniência booleana (modo restrito = só core; ampliado = core+envelope):
eh_eim <- function(cids, modo = "restrito", lookup = EIM_LOOKUP) {
  cl <- classificar_eim(cids, lookup)
  if (modo == "restrito") cl$eh_eim & cl$camada == "core"
  else                    cl$eh_eim
}
```

> **Performance:** para o SINASC/SIA nacional, o `map_int` acima é lento. Na ingestão em
> volume, usar uma **regex única compilada** (`paste0("^(", paste(prefixos, collapse="|"),
> ")")`) para o **filtro grosso** (mantém/descarta linha) e só rodar `classificar_eim()`
> nas linhas retidas para atribuir `classe`/`camada`. Ou um `data.table` join por prefixo
> truncado. **Filtrar na ingestão, nunca carregar o SIA nacional em RAM** (§2.3).

### 2.3 Varredura por base

**SIA-PA** — CID em `pa_cidpri` (principal) e `pa_cidpec` (CID especial APAC, quando
presente — **confirmar** que a extração o traz; no HS não vinha). Filtro grosso por regex
de prefixo **na ingestão**, arquivo a arquivo (padrão autism `get_autism_data_from_SIA.R`:
`load` → `filter(str_detect(PA_CIDPRI, regex_eim))` → `save`/descarta → `gc()`):

```r
regex_eim <- paste0("^(", paste(EIM_LOOKUP$prefixo, collapse = "|"), ")")
ler_sia <- function(fp) {
  x <- carregar_obj(fp) |> janitor::clean_names()
  x <- dplyr::filter(x, stringr::str_detect(pa_cidpri, regex_eim) |
                        (("pa_cidpec" %in% names(x)) & stringr::str_detect(pa_cidpec, regex_eim)))
  if (!nrow(x)) return(NULL)
  dplyr::bind_cols(x, classificar_eim(x$pa_cidpri))   # anexa classe/camada
}
# denominador de UTILIZAÇÃO agregado ANTES de descartar (count por uf,ano,mes,sexo,faixa)
```

**SIH-RD** — `diag_princ` + `diag_secun` + `diagsec1..9`. Detecção **dinâmica** das
colunas (`detectar_cols_diag()` do HS) e `dplyr::if_any(any_of(cols_diag), ...)`:

```r
cols_diag <- detectar_cols_diag(sih)              # herda utils HS
sih <- sih |>
  dplyr::mutate(
    eim_principal = eh_eim(diag_princ, modo = MODO_CAPTURA),
    eim_qualquer  = dplyr::if_any(dplyr::any_of(cols_diag),
                                  ~ eh_eim(.x, modo = MODO_CAPTURA)),
    classe_princ  = classificar_eim(diag_princ)$classe
  )
# Reportar DOIS sabores (como no HS §2): (a) principal (comparável ao SIA);
# (b) qualquer campo (if_any sobre diagsec*). NUNCA somar com o SIA.
```

**SIM-DO** — `causabas` + `linhaa`/`linhab`/`linhac`/`linhad` + `linhaii`. Cada célula
pode conter **vários CIDs** e marcadores `†`/`*` → estender `normalizar_cid_sim()` do HS
(que já remove `†*` e extrai a lista de códigos) e testar EIM em **qualquer** código:

```r
# utils.R (EIM) — TRUE se ALGUM código EIM aparece em qualquer campo de causa.
detecta_eim_sim <- function(df, cols = c("causabas","linhaa","linhab","linhac","linhad","linhaii"),
                            modo = MODO_CAPTURA) {
  cols <- intersect(cols, names(df))
  cods_por_linha <- purrr::pmap(df[cols], function(...) {
    unlist(purrr::map(list(...), ~ unlist(normalizar_cid_sim(.x))))  # herda HS
  })
  purrr::map_lgl(cods_por_linha, ~ any(eh_eim(.x, modo = modo)))
}
# extrai TAMBÉM a classe do 1º código EIM encontrado, p/ estratificar por subgrupo.
```

Diferença central vs HS-SIM: o HS testava `str_detect(campo, "L732")` (1 código); aqui
extraímos a **lista completa** de códigos por célula (`normalizar_cid_sim`) e casamos
contra a lookup — o mecanismo daga/asterisco (`E90` "manifestações em outras doenças"
classificadas alhures) é **exatamente** o cenário multi-CID que o SINASC `codanomal`
também exibe (§4). Reutiliza-se a mesma normalização.

---

## 3. Denominadores

### 3.1 População IBGE (herda `get_denominadores_ibge.R` do HS, sem alteração)

`sidrar::get_sidra()` na tabela **9514** (Censo 2022, UF×sexo×faixa quinquenal), com
**cache skip-if-exists**, replicada como estrutura constante 2020–2025 (decisão do HS:
evita o **degrau Censo↔projeção de 2022**; a tendência é guiada pelo numerador). Faixas
canônicas `FAIXAS_BR` idênticas ao numerador (`harmonizar_faixa()`). Retrointerpolação
a partir do Censo 2022 já embutida na decisão "estrutura constante". Denominador de
**prevalência/detecção** (taxas SIA/SIH/SIM por 100 mil hab).

### 3.2 SINASC — nascidos vivos por UF×ano (denominador de INCIDÊNCIA — NOVO)

**Diferencial deste projeto.** Para EIM de **triagem neonatal**, a métrica correta não é
"detecção por 100 mil habitantes" e sim **incidência ao nascimento por 100 mil nascidos
vivos** — casos identificados / NV do mesmo UF×ano. O SINASC dá o denominador.

```r
# get_nascidos_vivos_SINASC.R — NV por UF×ano (+opcional sexo p/ padronização).
# SINASC é ANUAL por UF (fetch_datasus year_start/year_end, information_system="SINASC").
# Padrão herdado de autismo/SINASC/SINASC.qmd (loop anual + process_sinasc + clean_names).
# NÃO precisamos das 60+ colunas → agregar a NV por UF (codmunres→uf) na ingestão.
ler_sinasc_ano <- function(ano, dir_raw) {
  fp <- file.path(dir_raw, sprintf("sinasc_%d.RData", ano))
  x  <- carregar_obj(fp) |> janitor::clean_names() |> corrigir_encoding()
  x |>
    dplyr::mutate(uf = uf_from_mun(codmunres), sexo = dplyr::recode(as.character(sexo),
                  "1"="Masculino","2"="Feminino", .default = NA_character_)) |>
    dplyr::filter(uf %in% UFS) |>
    dplyr::count(uf, sexo, name = "nv") |>
    dplyr::mutate(ano = ano)
}
nascidos_vivos <- purrr::map_dfr(ANOS, ler_sinasc_ano, dir_raw = DIR_SINASC)
arrow::write_parquet(nascidos_vivos, here::here("data/denominators/nascidos_vivos.parquet"))
```

> **Notas SINASC:**
> - **`codmunres`** (residência da mãe) → UF via `uf_from_mun()` (herda HS). Coerência
>   com o numerador: EIM diagnosticado deve usar **UF de residência** (não de nascimento)
>   para bater com o denominador de NV por residência.
> - **`process_sinasc()`** existe no `microdatasus` (validado em `SINASC.qmd`). Se a
>   versão instalada divergir de argumentos, validar colunas pós-carga
>   (`stopifnot("codmunres" %in% names(x))`).
> - **SINASC 2024–2025 preliminar/ausente** (§6 riscos): `fetch_datasus` sinaliza dados
>   `PRELIM`. Marcar `base_nv = "preliminar"` nesses anos.
> - **Opcional — EIM no próprio SINASC:** o campo **`codanomal`** (anomalias congênitas,
>   multi-código, 4 chars concatenados) pode conter EIM detectados ao nascer. O padrão de
>   split já existe em `SINASC.qmd` (`gsub("(.{4})(?=.{1,})","\\1;", codanomal, perl=TRUE)`
>   → `grepl(paste(prefixos, collapse="|"), codanomal)`). Reaproveitável **diretamente**
>   com os prefixos EIM — porém EIM metabólico raramente é anomalia estrutural
>   registrada em `codanomal`; usar como **sinal exploratório**, não numerador principal.

### 3.3 Harmonização de faixas numerador↔denominador

- **Padronização por idade/sexo (SIA/SIH/SIM):** `harmonizar_faixa()` idêntica nos dois
  lados (herda HS) — pré-requisito da taxa padronizada.
- **Incidência ao nascimento:** o denominador é **NV** (sem faixa etária — todos idade 0);
  o numerador são **casos incidentes ao nascer** (idade ~0 no SIA/SIH/SIM **no ano de
  nascimento**, ou identificados via SINASC). Aqui **não há padronização por idade** — a
  taxa é bruta por UF×ano, estratificável por sexo. Documentar que numerador (detecção no
  1º ano) e denominador (NV) devem cobrir a **mesma coorte de nascimento** (aproximação:
  casos de idade 0–1 no ano *t* / NV do ano *t*), com a ressalva de **left-truncation**
  (herdada do HS §6.7): sem ID longitudinal, "1ª detecção na janela" ≠ diagnóstico ao
  nascer. **Incidência ao nascimento é aproximação de detecção precoce, não incidência
  verdadeira** — rótulo obrigatório.

---

## 4. Cálculo de taxas

Herda `calcular_taxas.R` do HS (padronização direta idade×sexo, IC gama via
`epitools::ageadjust.direct`, `contar_estrato()`, `taxas_padronizadas()`,
`taxa_bruta()`), com **três adições EIM**:

### 4.1 Padronização direta + brutas lado a lado (herdado)

`taxas_padronizadas(num, pop, grupos = "uf")` já devolve `taxa_bruta` e `taxa_pad` com
`ic_inf`/`ic_sup` gama na mesma linha. Estratificar por **`classe`** (subgrupo
fisiopatológico) via `grupos = c("uf","classe")` — cada subgrupo é raro, então muitos
estratos terão eventos 0 (o `left_join` + `replace_na(n,0)` do HS já trata).

### 4.2 Supressão N<5 — REGRA ESTRUTURAL (não ressalva)

Em EIM a raridade é a norma. Aplicar `suprimir_pequenas()` (HS `utils.R`) **em toda
saída divulgada** e, além disso:

```r
# Suprimir a PRÓPRIA taxa quando o numerador de eventos < N_SUPRESSAO (não só a contagem).
suprimir_taxa <- function(df, col_ev = "eventos", limiar = N_SUPRESSAO) {
  df |> dplyr::mutate(dplyr::across(c(taxa_bruta, taxa_pad, ic_inf, ic_sup),
                                    ~ dplyr::if_else(.data[[col_ev]] < limiar, NA_real_, .x)))
}
```

> Justificativa: com N<5 a taxa padronizada e seu IC gama são instáveis **e**
> potencialmente reidentificáveis (UF pequena × subgrupo raro × sexo). Preferir
> **agregação por macrorregião** (`mapear_uf_regiao()`) ou **pool de anos** (pessoa-anos)
> quando a UF×ano×classe não atingir o limiar. Reportar quantas células foram suprimidas
> (indicador de qualidade/transparência).

### 4.3 Incidência ao nascimento por 100 mil NV (traçadoras de triagem) — NOVO

```r
# calcular_taxas.R (EIM) — incidência ao nascimento p/ doenças de triagem neonatal.
incidencia_nascimento <- function(num_incidente, nv, grupos = c("uf","ano"),
                                  classes_triagem = NULL, por = 1e5) {
  n <- num_incidente
  if (!is.null(classes_triagem)) n <- dplyr::filter(n, classe %in% classes_triagem)
  n <- n |> dplyr::group_by(dplyr::across(dplyr::all_of(grupos))) |>
    dplyr::summarise(casos = sum(n), .groups = "drop")
  d <- nv |> dplyr::group_by(dplyr::across(dplyr::all_of(grupos))) |>
    dplyr::summarise(nv = sum(nv), .groups = "drop")
  n |> dplyr::left_join(d, by = grupos) |>
    dplyr::mutate(inc_nasc = por * casos / nv) |>
    suprimir_taxa(col_ev = "casos")               # supressão N<5 também aqui
}
# IC de Poisson exato p/ contagens pequenas (mais honesto que normal em doença rara):
#   epitools::pois.exact(casos, pt = nv/por)  → limites por 100 mil NV.
```

### 4.4 Teste de tendência Poisson/quasi-Poisson com offset (herdado, adaptado)

```r
# Tendência temporal da CONTAGEM com offset log(pop) [detecção] ou log(NV) [incidência].
# quasi-Poisson absorve superdispersão (comum em contagens raras agregadas).
tendencia_poisson <- function(dados, offset_col = "pop") {
  m <- stats::glm(eventos ~ ano, family = quasipoisson(link = "log"),
                  offset = log(dados[[offset_col]]), data = dados)
  broom::tidy(m, conf.int = TRUE, exponentiate = TRUE) |>   # razão de taxas por ano
    dplyr::filter(term == "ano")
}
# Ressalva COVID (herdada do HS §6): 2020–2021 = período anômalo de produção
# ambulatorial. Para EIM de triagem neonatal o efeito é MENOR (triagem é mandatória),
# mas SIA/SIH eletivos caem → sinalizar ANOS_COVID e, se necessário, modelar com dummy.
```

---

## 5. Pseudo-individualização / episódios — avaliação crítica

Herda a engenharia do HS (`feature_eng_pacientes_SIA.R`): blocking `sexo×munpcn`, janela
`ano_nasc±1`, componentes conexos `igraph`, gradiente estrita↔frouxa, resultado como
**INTERVALO** `[registros ; pseudo-pacientes]`. **Mas a decisão de aplicá-la em EIM é
condicional:**

**A favor:** crianças com EIM crônico (ex.: PKU em dieta, MPS em terapia de reposição
enzimática via APAC) geram **muitos registros SIA/ano** — a razão registros/paciente é
informativa (intensidade de uso), e o numerador inflado distorce "casos" se não
deduplicado.

**Contra / cautelas específicas de EIM:**
- **Chave mais fraca em pediatria.** `ano_nasc_proxy = ano_cmp − idade` tem **resolução
  ruim em <1 ano** (idade em meses/dias). Para EIM neonatal a chave `sexo×munpcn×ano_nasc`
  colide muito em coortes de nascimento densas. Considerar refinar com **mês de
  nascimento** quando disponível, ou restringir o pseudo-ID a subgrupos com idade >1 ano.
- **Foco em subgrupos/traçadoras com N menor.** Se a análise central for **incidência ao
  nascimento** de poucas traçadoras (N pequeno por UF×ano), o ganho do pseudo-ID é
  marginal — a supressão N<5 domina e o intervalo estrita↔frouxa fica largo demais para
  ser útil. **Recomendação:** aplicar pseudo-ID **apenas nos subgrupos crônicos de alto
  volume SIA** (lisossômicas em TRE, PKU em acompanhamento), e **pular** nas traçadoras
  raras onde se reporta contagem direta com supressão.
- **SIH — deduplicação de AIH** (herdada, sempre aplicável): contar **AIH distinta**
  (`n_aih`), marcar `aih_continuacao` (`ident=5`), não linha. Barato e sem ambiguidade →
  **manter incondicionalmente**.

**LGPD (linha vermelha, herdada §5.1 HS):** pseudo-ID é agrupador interno, só saem
agregados, supressão N<5, granularidade de divulgação em UF/região. Em EIM (raras +
pediátricas) o risco de reidentificação é **maior** → limiar de supressão possivelmente
mais conservador que 5 `[VERIFICAR política do projeto]`.

---

## 6. Saídas e reprodutibilidade

### 6.1 Artefatos intermediários e logs (herda HS)
- **Parquet particionado `ano`×`uf`** para SIA/SIH/SIM-EIM (`arrow::write_dataset`,
  `schema()` explícito fixando monetários `double` e CIDs `character`) — consulta lazy
  `open_dataset() |> filter() |> summarise() |> collect()`.
- **`run_log_{sia,sih,sim,sinasc}.csv`** via `log_run()` (HS `utils.R`): ts, base, uf,
  competência, status, n_lidas, n_hs→**n_eim**, msg. Um log por base.
- **`manifest/`**: `params_run_*.yaml`, checksums `digest`, **`eim_lookup_versao.csv`**
  (hash da lookup — a definição de caso).

### 6.2 Tabelas de validação/completude
- `validar_grade_completa()` (HS): SIA/SIH = 27×6×12 (ou ×4 tri); SIM/SINASC = 27×6.
  `stop()` se faltantes antes de avançar.
- `qc_basico()` (HS): completude de `pa_cidpri`/`diag*`/`codanomal`, proporção de CID
  válido, consistência sexo×CID. **Tabela de contagem por `classe`×base** (quantos
  eventos por subgrupo fisiopatológico) — sanity check central do projeto.

### 6.3 Painel Quarto + publicação (herda HS §9)
- `.qmd` **self-contained** (`embed-resources: true`), `_quarto.yml` `type: website`,
  `output-dir: docs`, `execute: echo:false, cache:true`, `lang: pt`.
- **`geobr`** para mapas de **incidência ao nascimento por UF** (coropléticos) e
  **detecção por 100 mil hab** lado a lado (o confundimento por oferta/acesso do HS §6.5
  se aplica: mapa de detecção mede acesso à genética/triagem, não incidência real).
- **GitHub Pages:** `docs/` + **`.nojekyll`**; versionar `scripts/`, `qmd/`, `docs/`,
  `manifest/`, `renv.lock`.
- **`renv`**: `renv::snapshot()` após instalar; pinar SHA de `microdatasus`/`read.dbc`
  (argumentos de `process_*` variam entre versões — risco §6.4).

### 6.4 Riscos técnicos

| Risco | Detalhe | Mitigação |
|---|---|---|
| **Volume do SIA** | SIA-PA nacional não cabe em RAM; multi-CID amplia o universo vs 1 CID do HS | **Filtrar na ingestão** por regex de prefixo, arquivo a arquivo, `gc()`; agregar denominador de uso antes de descartar; `purrr::walk`, nunca `map_dfr` sobre brutos |
| **Disponibilidade SIM/SINASC 2024–2025** | SIM-DO e SINASC saem com atraso; 2025 provavelmente ausente/PRELIM | `fetch_datasus` sinaliza PRELIM; usar prévia opendatasus p/ SIM 2025 (padrão HS Part B); marcar `base = "preliminar"`; `[VERIFICAR]` disponibilidade a cada run |
| **Mudança de layout entre anos** | `diagsec*` (SIH) e colunas SINASC variam por ano; SIH 2025 é superset (`+FONTE_ORC` no HS) | Detecção dinâmica (`detectar_cols_diag`, `any_of`); `casar_tipos()` antes de `bind_rows`; schema Parquet = união de colunas |
| **Definição de caso instável** | a lookup CID→classe **é** a definição; erro/omissão de prefixo muda todos os números | Versionar `eim_lookup.R` (hash no manifest); **`[VERIFICAR]` cada prefixo com geneticista**; reportar core vs envelope separados |
| **Encoding daga/asterisco (SIM)** | `†`/`*` e multi-CID por célula quebram o match | `corrigir_encoding()` + `normalizar_cid_sim()` (extrai lista de códigos) — herdado e testado no HS |
| **Raridade → estratos vazios / reidentificação** | N<5 pervasivo em UF×ano×classe×sexo | Supressão estrutural (`suprimir_pequenas`/`suprimir_taxa`); agregar em macrorregião/pool de anos; IC Poisson exato p/ N pequeno |
| **`pa_cidpec` ausente no SIA** | rastrear terapia de alto custo (TRE lisossômicas via APAC) exige `pa_cidpec`/SIA-AM | Confirmar na extração; se ausente, usar SIA-AM/AP (APAC) ou código de procedimento `[CONFIRMAR via fetch_sigtab()]` |
| **Left-truncation / incidência** | sem ID longitudinal, "1ª detecção na janela" ≠ diagnóstico ao nascer | Rótulo "incidência ao nascimento (aproximação de detecção precoce)"; restringir a coorte idade 0–1 no ano de NV; ressalva transversal |

---

### Sanity checks mínimos antes de seguir (herda checklist HS)
1. `validar_grade_completa()` = 0 faltantes por base.
2. Tabela **eventos por `classe`×base** (nenhuma classe deve estar vazia por engano de prefixo).
3. `janitor::tabyl(base, camada)` — proporção core vs envelope plausível.
4. Completude de CID/`codanomal` por UF×ano (`qc_basico`) — degraus indicam mudança de layout.
5. NV SINASC por UF×ano vs totais publicados IBGE/DATASUS (ordem de grandeza).
6. Incidência ao nascimento das traçadoras vs faixas da literatura `[VERIFICAR]` (PKU
   ~1:10.000, MSUD, galactosemia…) — gap grande = subdetecção, não erro necessariamente.
7. `renv.lock` gerado e SHAs pinados.
```