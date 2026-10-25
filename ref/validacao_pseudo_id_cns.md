# Validação do pseudo-ID contra o CNS criptografado (25/10/2026)

Scripts: `scripts/pacientes_cns_apac.R` (pacientes reais pelo CNS) e
`scripts/validar_pseudo_id_cns.R` (comparação). Tabelas: `manifest/sia_pacientes_cns.csv`,
`manifest/sia_pacientes_cns_vs_pseudo.csv`, `manifest/validacao_pseudo_id_cns.csv`.

## O que foi feito

- As APAC de medicamentos (AM) e de laudos diversos (AD) do SIA, 2010–2026, trazem o Cartão
  Nacional de Saúde do paciente **criptografado**, estável entre meses, anos e arquivos.
- Cada APAC do PA foi ligada à AM/AD pelo número da autorização: **98,1%** dos 2,1 milhões de
  registros de APAC de EIM, praticamente 100% em PE. Só 448 das 19,4 milhões de APAC têm mais de
  um CNS.
- O pseudo-ID (`pseudo_id_motor.R`) foi aplicado **aos mesmos registros** (APAC da camada core
  ligadas a um CNS) e comparado com o número de CNS distintos.

## Resultado

| | |
|---|---|
| O intervalo do pseudo-ID contém o número verdadeiro | 18 de 27 subgrupos |
| Erro absoluto mediano da estimativa central | 16,7% |
| Brasil | a central **superestima** em todos os 7 grupos (+7% a +45%). O verdadeiro fica perto do **limite inferior** (chave frouxa: −4% a +5% em 6 dos 7) |
| PE | erros nos dois sentidos. Na fibrose cística, o pseudo-ID **subestima** (772 verdadeiros, acima até do limite superior, 681) |

Exemplos (2010–2025, pacientes com APAC):

| Grupo | Verdadeiro (CNS) | Pseudo-ID (inferior / central / superior) |
|---|---|---|
| Fibrose cística, Brasil | 11.528 | 9.065 / 12.371 / 15.375 |
| PKU, Brasil | 3.994 | 4.011 / 5.801 / 6.932 |
| MPS, Brasil | 1.206 | 1.268 / 1.615 / 1.901 |
| Fibrose cística, PE | 772 | 439 / 604 / 681 |
| MPS, PE | 124 | 105 / 145 / 162 |

## Leitura

- **Em escala nacional, o pseudo-ID separa demais a mesma pessoa.** A mesma pessoa aparece com
  município, raça/cor ou idade inconsistentes entre registros e vira dois pacientes. O limite
  inferior (sexo × município × ano de nascimento ±1) é a melhor aproximação.
- **Em PE, o pseudo-ID junta pessoas diferentes.** O município do paciente nas APAC do CEAF de
  PE sai quase sempre como Recife. Pacientes diferentes com o mesmo sexo e o mesmo ano de
  nascimento colapsam numa só chave, e o número fica subestimado. É o problema já conhecido do
  município da APAC em PE, agora medido.
- **Consequência:** para quem tem APAC, o número de pacientes passa a ser o **número de CNS
  distintos**, sem intervalo. O pseudo-ID fica só para registros sem identificador (BPA-I, até o
  BI ser baixado) e com o viés documentado acima.

## Limites

- Só cobre pacientes com APAC (medicamento do Componente Especializado ou laudo diverso). Quem é
  acompanhado só por consulta e exame (BPA-I), como no hipotireoidismo congênito, fica de fora.
  O BI, também com CNS criptografado, cobriria esses pacientes (2ª etapa, ainda não baixada).
- O CNS criptografado é pseudonimização. Uso só para contar e ligar registros; nenhuma saída o
  contém.
