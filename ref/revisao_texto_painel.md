---
title: "Revisão de clareza do texto do painel EIM"
subtitle: "Jargão não explicado, siglas soltas e afirmações que pedem ressalva"
---

Revisão página a página das `.qmd` do painel, focada em legibilidade para
não-especialistas (gestores, conselhos de saúde, jornalistas). Para cada trecho
apontado: **onde**, **o problema** e a **sugestão**. Recomendação transversal ao
final.

> **Recomendação-mãe:** incluir, na navegação do site, um link visível para o
> novo **Glossário metodológico** (`ref/glossario_metodologico.md`) e, na
> primeira ocorrência de cada termo técnico em cada página, criar um link ou
> nota de rodapé para o verbete correspondente. Isso resolve a maioria dos
> pontos abaixo sem sobrecarregar o texto corrido.

---

## `index.qmd` (página inicial)

1. **"camadas *core*, *limítrofe* e *envelope*"** (linha ~35). Três termos
   técnicos introduzidos na primeira frase, sem definição. É a porta de entrada
   do painel — o leigo trava aqui.
   - **Sugestão:** acrescentar uma glosa curta entre parênteses: "camadas
     *core* (EIM específico e nomeado), *limítrofe* (EIM mas inespecífico) e
     *envelope* (doença comum usada só como teto máximo — nunca como caso)". E
     linkar ao glossário.

2. **"AIH"** (KPIs, linhas 41–42). A sigla aparece sem expansão nos cartões de
   indicador.
   - **Sugestão:** na primeira menção, "AIH (Autorização de Internação
     Hospitalar — cada internação)". Nos cartões, considerar rótulo
     "internações (AIH)".

3. **"janela seletiva"** (callout "Como ler", linha 54). Termo técnico usado sem
   explicar.
   - **Sugestão:** "cada base é uma **janela seletiva** — enxerga só uma fatia do
     grupo: SIA vê os crônicos acompanhados; SIH, as descompensações e infusões;
     SIM, os casos que matam cedo".

4. **"bracketing"** (Navegação, linha 125). Aparece só no rótulo do link, sem
   nenhuma definição na página inicial.
   - **Sugestão:** trocar por "core vs envelope (teto de subcodificação)" no
     texto do link, deixando "bracketing" para a página SIA já com o glossário
     linkado.

5. **"pessoa-anos"** (legenda do mapa, linha 115). Conceito de denominador não
   explicado, aparece só na legenda.
   - **Sugestão:** simplificar a legenda para "por 100 mil habitantes
     (padronizada)"; reservar a discussão de pessoa-anos para uma nota técnica.

6. **Afirmação que pede ressalva:** "Todas as três bases estão **em alta**...
   reflete sobretudo aumento de detecção" (linha 101). Correta, mas a ressalva
   COVID (2020–2021 = represamento e recuperação da produção eletiva) não
   aparece e ajudaria a explicar a inclinação.
   - **Sugestão:** acrescentar meia frase: "parte da subida de 2021–2022 também
     reflete a **recuperação pós-COVID** da produção eletiva".

---

## `sia_eim.qmd` (Ambulatorial)

1. **"*bracketing*"** (linhas 30–31 e título da seção, linha 39). É o primeiro
   lugar onde o termo aparece com peso, mas segue sem definição própria.
   - **Sugestão:** primeira ocorrência com glosa: "teto de subcodificação
     (*bracketing*: o limite máximo do que a codificação errada poderia
     esconder — não uma contagem de casos)". Linkar ao glossário.

2. **"E78 dislipidemia"** (linha 30). O leitor não-clínico não sabe que
   dislipidemia (colesterol/triglicerídeos alto) é uma doença comuníssima — que
   é justamente o ponto.
   - **Sugestão:** "sobretudo **E78 dislipidemia** (colesterol/triglicerídeos
     altos — doença comum, não EIM)".

3. **"AIH" / "TRE"** aparecem indiretamente; **"TRE"** é expandida só em outras
   páginas. Aqui "terapia de reposição enzimática" aparece por extenso — bom.
   Verificar consistência de introduzir a sigla TRE uma vez por página.

4. **"proxy/TETO"** (callout traçadoras, linha 86). "proxy" é jargão.
   - **Sugestão:** "reportada à parte como **teto** (proxy — aproximação por
     excesso: E88.9 agrega outros distúrbios, não só biotinidase)".

5. **"pessoa-anos"** (legenda do mapa, linha 116). Mesmo ponto do index.
   - **Sugestão:** "por 100 mil habitantes (padronizada por idade e sexo)".

6. **"idade... mal preenchida (`pa_idade`...)"** (Limitações, linha 126). O nome
   da variável bruta (`pa_idade`) é ruído para o leitor de gestão.
   - **Sugestão:** manter a mensagem, mas mover o nome técnico da variável para
     parêntese opcional ou nota; "a **idade no SIA é frequentemente ausente ou
     agregada**, então a estratificação por idade nesta base é frágil".

7. **Afirmação que pede ressalva:** "Fibrose cística domina o volume" (subtítulo
   do gráfico, linha 79). Correto, mas convém lembrar que **volume de registros
   ≠ número de pacientes** (FC gera muito acompanhamento crônico).
   - **Sugestão:** subtítulo com meia ressalva: "...domina o **volume de
     registros** (acompanhamento crônico intenso, não necessariamente mais
     pacientes)".

---

## `sih_eim.qmd` (Internações)

1. **"dois sabores"** (subtítulo, linhas 3, 28 e título, linha 36). Expressão
   coloquial-técnica que o painel usa como termo próprio, mas nunca define
   formalmente no corpo.
   - **Sugestão:** o texto das linhas 32–34 já explica bem os dois sabores; basta
     linkar "dois sabores" ao glossário na primeira ocorrência (subtítulo) e
     manter a definição inline que já existe. Boa página nesse ponto.

2. **"AIH"** (KPIs e todo o texto). Sigla central da página, nunca expandida.
   - **Sugestão:** na abertura, "cada **AIH** (Autorização de Internação
     Hospitalar) é **uma internação, não uma pessoa**".

3. **"TRE"** (linha 27). Expandida corretamente na primeira menção ("terapia de
   reposição enzimática — TRE"). Bom — manter esse padrão nas demais páginas.

4. **"`diag_princ`" / "`diagsec1–9`"** (linhas 33–34). Nomes de variáveis brutas
   no texto voltado ao leitor.
   - **Sugestão:** manter em `código` mas com a tradução ao lado, como já está
     parcialmente; para o leigo, "(o campo do diagnóstico principal)" e "(os
     campos de diagnóstico secundário)".

5. **"razão de taxas ~+9%/ano"** (linhas 105, 109). "razão de taxas" é jargão de
   epidemiologia.
   - **Sugestão:** "cresce cerca de **9% ao ano** (razão de taxas ~1,09)".

6. **Afirmação que pede ressalva:** "MPS têm peso hospitalar desproporcional...
   cada paciente gera múltiplas AIH de infusão" (callout, linhas 83–86). Boa
   ressalva já presente. Reforçar que isso **não** significa que MPS seja mais
   frequente que as outras — é intensidade de tratamento.
   - **Sugestão:** fechar o callout com: "portanto o peso das MPS aqui mede
     **intensidade de tratamento**, não que sejam as mais **frequentes**".

7. **"2% sup. omitidos"** (subtítulo do histograma, linha 124). Abreviação
   obscura.
   - **Sugestão:** "(2% das internações mais longas foram omitidas do gráfico
     para legibilidade)".

---

## `sim_eim.qmd` (Mortalidade)

1. **"inversão relevante em relação a doenças de baixa letalidade (como a
   hidradenite)"** (linha 27) e **"Inverso da HS"** (nota da tabela, linha 49).
   A referência à hidradenite / "HS" é interna ao projeto e **não significa nada
   para o leitor externo**.
   - **Sugestão:** remover a menção à HS do texto público ou reformular:
     "diferentemente de doenças de baixa letalidade, aqui a mortalidade é o eixo
     central". Guardar a comparação com HS para documentação interna.

2. **"causa básica" vs "qualquer linha / contribuinte"** (KPIs e seção "Onde o
   EIM aparece na DO", linhas 39–50). Conceitos centrais da página, usados sem
   definição para o leigo.
   - **Sugestão:** uma frase na abertura: "a **causa básica** é a doença que
     **iniciou** a cadeia que levou à morte; nas outras linhas o EIM aparece só
     como **contribuinte**". Linkar ao glossário.

3. **"DO"** (título da seção, linha 39; nota, linha 49). Sigla de Declaração de
   Óbito não expandida na seção.
   - **Sugestão:** "Onde o EIM aparece na **Declaração de Óbito (DO)**".

4. **"IC Poisson exato"** (nota da tabela, linha 125). Jargão estatístico numa
   nota voltada ao leitor.
   - **Sugestão:** "faixa de incerteza (IC 95%) calculada por método apropriado
     a **eventos raros** (Poisson exato)".

5. **"TETO E88.9"** (callout, linha 136 e tabela). "TETO" em caixa alta sem
   explicar; E88.9 é um código.
   - **Sugestão:** "Biotinidase 0,91/100k NV é um **teto** (limite máximo): o
     código E88.9 agrega outros distúrbios metabólicos mortais, não biotinidase
     de verdade".

6. **"pool 2021–2023"** (título da tabela de incidência, linha 124). "pool" é
   anglicismo técnico.
   - **Sugestão:** "somando os anos de 2021 a 2023 (pool)" ou simplesmente
     "acumulado 2021–2023".

7. **Afirmação forte que pede cuidado:** "triagem + tratamento precoce
   **funcionando**" (callout, linha 133). Interpretação plausível e bem
   construída, mas causal a partir de dado ecológico.
   - **Sugestão:** suavizar: "padrão **compatível com** triagem + tratamento
     precoce funcionando" (evitar afirmação causal direta).

---

## `pezinho.qmd` (Teste do pezinho)

1. **"escopo `painel_pezinho`" / "pipeline isolado"** (linhas 30–31, 36, 119).
   "pipeline" e "escopo" são jargão de engenharia de dados.
   - **Sugestão:** "analisadas **em separado** e **nunca somadas** às taxas de
     EIM" — reservar `escopo = painel_pezinho` para a documentação técnica. O
     callout da linha 33 já traduz bem; padronizar o texto corrido no mesmo tom.

2. **Siglas em rajada:** "PNTN", "IDP/SCID", "TREC", "TRE" (linhas 27, 30, 106).
   Várias sem expansão na primeira menção.
   - **Sugestão:** expandir cada uma uma vez: "Programa Nacional de Triagem
     Neonatal (**PNTN**)" (já expandido na linha 27 — bom); "imunodeficiências
     primárias / imunodeficiência combinada grave (**IDP/SCID**)"; "triagem por
     **TREC** (um marcador molecular usado no teste)".

3. **"Portaria GM/MS 7.293/2025"** (linha 27). Citada como fato. Conforme a
   convenção do projeto, número/data de portaria exige `[VERIFICAR]`.
   - **Sugestão:** confirmar em DOU/gov.br e, até lá, marcar `[VERIFICAR]`; o
     rodapé da linha 124 já remete a `painel_pezinho_normativo.md` — garantir
     que o número esteja validado lá.

4. **"não contamina nenhuma taxa de EIM"** (linha 103). "contamina" é informal;
   a ideia é boa mas o verbo destoa do tom.
   - **Sugestão:** "**não entra** em nenhuma taxa de EIM".

5. **"TETO"** (nota da tabela tradicional, linha 55; limitações, linha 122).
   Mesmo ponto das outras páginas — caixa alta sem glosa.
   - **Sugestão:** "Biotinidase, codificada em E88.9, é um **teto inespecífico**
     (o código agrega outros distúrbios)".

6. **Afirmação que pede ressalva:** "Toxoplasmose congênita... maior detecção
   hospitalar... coerente com tratamento neonatal prolongado" (linhas 104–105).
   Interpretação razoável, mas convém lembrar que **detecção hospitalar alta**
   pode também refletir codificação/gravidade, não só incidência.
   - **Sugestão:** "...reflete o **tratamento neonatal prolongado** (múltiplas
     internações por criança), e não deve ser lido como incidência".

---

## Padrões transversais a corrigir em todas as páginas

1. **Expandir toda sigla na primeira ocorrência de cada página:** AIH, DO, TRE,
   PNTN, IDP/SCID, TREC, SIA-PA, SIH-RD, SIM-DO, SINASC, NV, UF, LGPD.

2. **Substituir "pessoa-anos" nas legendas de mapa** por "por 100 mil habitantes
   (padronizada por idade e sexo)"; guardar pessoa-anos para nota técnica.

3. **Termos em caixa alta ("TETO", "proxy") sempre com glosa** na primeira
   aparição de cada página.

4. **Remover referências internas ao projeto HS / hidradenite** do texto
   público (aparecem em `index` e `sim_eim`); são relevantes só para a
   documentação de método.

5. **Suavizar afirmações causais** derivadas de dado ecológico ("funcionando",
   "coerente com") para "compatível com" / "sugere" — mantendo a leitura, sem
   afirmar causalidade.

6. **Nomes de variáveis brutas** (`pa_idade`, `diag_princ`, `diagsec1–9`,
   `causabas`) só entre parênteses ou em nota, nunca como sujeito da frase
   voltada ao gestor.

7. **Link para o glossário** no menu do site e na primeira menção de cada termo
   técnico por página.
