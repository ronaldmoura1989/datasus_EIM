# =============================================================================
# profissionais_procedimentos_recife.R — Profissionais × procedimentos (Recife)
# Quantifica os procedimentos dos pacientes EIM capturados no SIA em RECIFE
# (pa_munpcn == "261160"), agrupando por:
#   - sigtap_grupo  : grupo do procedimento (2 primeiros díg. de pa_proc_id)
#   - pa_cbocod     : CBO (especialidade/ocupação)
#   - pa_cnsmed     : CNS do profissional executante
# Filtra pa_cnsmed != "000000000000000" (remove profissionais não-identificados).
# Saída: misc/profissionais_procedimentos_recife.tsv  (NÃO vai para o relatório).
# =============================================================================

if (!exists("EIM_LOOKUP")) source(here::here("scripts", "00_setup.R"))

REC_6 <- "261160"
NAO_IDENT <- "000000000000000"

# Nomes dos 8 grupos do SIGTAP
GRUPO_NOME <- c(
  "01" = "Ações de promoção e prevenção em saúde",
  "02" = "Procedimentos com finalidade diagnóstica",
  "03" = "Procedimentos clínicos",
  "04" = "Procedimentos cirúrgicos",
  "05" = "Transplantes de órgãos, tecidos e células",
  "06" = "Medicamentos",
  "07" = "Órteses, próteses e materiais especiais",
  "08" = "Ações complementares da atenção à saúde")

# ref. N7/E6 da auditoria (avaliacao_critica_externa.md): o consolidado foi
# renomeado para sia_eim_core_limitrofe.rds (contém core+limítrofe); filtrar
# explicitamente camada=="core" — o arquivo antigo sia_eim_core.rds, apesar do
# nome, misturava as duas camadas.
sia <- readRDS(here::here("data/consolidated/sia_eim_core_limitrofe.rds")) |>
  dplyr::filter(pa_munpcn == REC_6, camada == "core")     # pacientes EIM (core) em Recife
n_total <- nrow(sia)
n_ident <- sum(sia$pa_cnsmed != NAO_IDENT, na.rm = TRUE)
message(sprintf("Recife: %d registros EIM | %d com profissional identificado (%.1f%%)",
                n_total, n_ident, 100 * n_ident / n_total))

tab <- sia |>
  dplyr::filter(!is.na(pa_cnsmed), pa_cnsmed != NAO_IDENT) |>
  dplyr::mutate(
    sigtap_grupo = stringr::str_sub(as.character(pa_proc_id), 1, 2),
    sigtap_grupo_nome = dplyr::coalesce(GRUPO_NOME[sigtap_grupo], "Outro/indefinido"),
    pa_qtdapr = suppressWarnings(as.numeric(pa_qtdapr)),
    pa_valapr = suppressWarnings(as.numeric(pa_valapr))) |>
  dplyr::group_by(sigtap_grupo, sigtap_grupo_nome, pa_cbocod, pa_cnsmed) |>
  dplyr::summarise(
    n_procedimentos  = dplyr::n(),
    qtd_aprovada     = sum(pa_qtdapr, na.rm = TRUE),
    valor_aprovado_reais = round(sum(pa_valapr, na.rm = TRUE), 2),
    .groups = "drop") |>
  dplyr::arrange(dplyr::desc(n_procedimentos))

cat(sprintf("\nLinhas (grupo×CBO×profissional): %d | profissionais distintos: %d | CBOs distintos: %d\n",
    nrow(tab), dplyr::n_distinct(tab$pa_cnsmed), dplyr::n_distinct(tab$pa_cbocod)))
cat("Por grupo SIGTAP:\n")
print(as.data.frame(tab |> dplyr::group_by(sigtap_grupo, sigtap_grupo_nome) |>
  dplyr::summarise(profissionais = dplyr::n_distinct(pa_cnsmed),
                   procedimentos = sum(n_procedimentos), .groups="drop") |>
  dplyr::arrange(dplyr::desc(procedimentos))))

out <- here::here("..", "misc", "profissionais_procedimentos_recife.tsv")
readr::write_tsv(tab, out)
message(sprintf("\n✓ TSV salvo em misc/profissionais_procedimentos_recife.tsv (%d linhas)", nrow(tab)))
