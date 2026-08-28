# =============================================================================
# eim_lookup.R — Tabela de definição de caso dos Erros Inatos do Metabolismo (EIM)
# Projeto DATASUS-EIM. É O CORAÇÃO DO PROJETO: a definição de caso É esta lookup.
# Mapeia PREFIXOS CID-10 (formato DATASUS, SEM ponto) → subgrupo fisiopatológico,
# camada de captura e metadados (herança, triagem neonatal, PCDT do MS, traçadora).
#
# CONTRATO DE MATCH: casa por PREFIXO (str_starts), MAIS ESPECÍFICO PRIMEIRO
#   (a tabela é ordenada por desc(nchar(prefixo)); first-match vence).
#   Ex.: "E700" (PKU, core) vence "E70" (aminoacidopatia) que vence "E7" (fallback).
#
# CAMADAS (análogas ao L732 / L73x / L02x do projeto HS):
#   core      = EIM inequívoco de alta especificidade (análise primária)
#   limitrofe = EIM porém inespecífico / "não especificado" / agregador
#   envelope  = categoria que abriga TAMBÉM condição comum não-EIM (dislipidemia,
#               gota, hemocromatose, intolerância à lactose, "outros/SOE") →
#               TETO de subcodificação (bracketing), NUNCA caso confirmado.
#
# AUDITORIA DE RÓTULOS (ver ref/avaliacao_critica_externa.md §6b): os 4os caracteres
#    foram conferidos contra a estrutura da CID-10. Correções aplicadas:
#      · E80.3 NÃO é bilirrubina (é catalase/peroxidase); Gilbert = E80.4 (comum →
#        envelope), Crigler-Najjar = E80.5 (raro grave → core). Antes ambos caíam
#        no fallback E80 como "limítrofe".
#      · E85.0 e E85.2 são HEREDOFAMILIARES (→ core); antes caíam no fallback E85
#        rotulado "amiloidose adquirida". E85.3/.4/.8/.9 → envelope.
#    Pendências que permanecem [VERIFICAR] contra a tabela oficial DATASUS V2008:
#      · E88.4 (mitocondrial) — provavelmente inexistente na V2008.
#    Os CIDs marcados `pcdt_ms = TRUE` foram CONFIRMADOS na "Lista de Doenças Raras
#    no âmbito do SUS" (MS/CGRAR) — ver ref/crosswalk_lista_raras_MS.md.
#
# Versionar toda alteração em manifest/eim_lookup_versao.csv (data + hash digest):
#   mudar esta tabela muda TODOS os números do projeto.
# =============================================================================

suppressPackageStartupMessages(library(dplyr))

# -----------------------------------------------------------------------------
# 1. Tabela mestra CID → EIM
#    Colunas:
#      prefixo   : prefixo CID-10 DATASUS (sem ponto), 2–4 chars
#      subgrupo  : subgrupo fisiopatológico (unidade de estratificação analítica)
#      classe    : agrupador amplo (aminoacidopatia / lisossomica / ... )
#      camada    : core | limitrofe | envelope
#      tracadora : nome da doença-traçadora (NA se não é traçadora nominal)
#      heranca   : AR | XL | AD | mtDNA | mista | NA
#      triagem   : TRUE se coberta/prevista na triagem neonatal (PNTN/Lei 14.154)
#      pcdt_ms   : TRUE se consta na Lista de Doenças Raras do SUS (tem PCDT)
#      escopo    : "nucleo_eim" (E70–E90 stricto sensu) |
#                  "fora_capitulo_E" (EIM/triagem fora de E70–E90) |
#                  "contexto_raras" (rara não-EIM, só p/ contexto de rede)
#      obs       : notas / pendências [VERIFICAR]
# -----------------------------------------------------------------------------
EIM_LOOKUP <- tibble::tribble(
  ~prefixo, ~subgrupo,                      ~classe,            ~camada,     ~tracadora,          ~heranca, ~triagem, ~pcdt_ms, ~escopo,            ~obs,
  # ---- Aminoacidopatias aromáticas (E70) ------------------------------------
  "E700",  "aminoacidopatia_PKU",          "aminoacidopatia",  "core",      "PKU",               "AR",     TRUE,     TRUE,     "nucleo_eim",       "Fenilcetonúria clássica (MS: E70.0). Fórmula isenta de Phe.",
  "E701",  "aminoacidopatia_hiperfenil",   "aminoacidopatia",  "core",      "PKU",               "AR",     TRUE,     FALSE,    "nucleo_eim",       "Outras hiperfenilalaninemias / def. BH4.",
  "E702",  "aminoacidopatia_tirosina",     "aminoacidopatia",  "core",      "Tirosinemia",       "AR",     FALSE,    FALSE,    "nucleo_eim",       "E70.2 = distúrbios do metab. da tirosina: tirosinemia I (nitisinona/NTBC) + alcaptonúria. AUDITADO.",
  "E703",  "albinismo",                    "outros",           "limitrofe", NA,                  "mista",  FALSE,    FALSE,    "nucleo_eim",       "Albinismo — não é EIM metabólico clássico.",
  "E70",   "aminoacidopatia_aromaticos",   "aminoacidopatia",  "limitrofe", NA,                  "AR",     FALSE,    FALSE,    "nucleo_eim",       "Fallback E70 (E708/E709 não especificados).",
  # ---- BCAA, acidúrias orgânicas, FAOD (E71) --------------------------------
  "E710",  "aminoacidopatia_MSUD",         "aminoacidopatia",  "core",      "MSUD",              "AR",     TRUE,     FALSE,    "nucleo_eim",       "Doença da urina do xarope de bordo (leucinose).",
  "E711",  "acuduria_organica",            "acuduria_organica","core",      NA,                  "AR",     TRUE,     FALSE,    "nucleo_eim",       "E71.1 = outros distúrbios do metab. de BCAA: acidúrias propiônica/metilmalônica/isovalérica. AUDITADO.",
  "E713",  "faod",                         "faod",             "core",      NA,                  "AR",     TRUE,     FALSE,    "nucleo_eim",       "E71.3 = distúrbios do metab. de ácidos graxos: FAOD/carnitina/CPT — mas AGREGA TAMBÉM a adrenoleucodistrofia X (peroxissomal, XL), logo `heranca=AR` vale para a maioria, não para todos. E71.4 não existe na CID-10. AUDITADO.",
  "E71",   "aminoacidopatia_BCAA_outros",  "aminoacidopatia",  "limitrofe", NA,                  "AR",     FALSE,    FALSE,    "nucleo_eim",       "Fallback E71 (E712/E715/E718/E719).",
  # ---- Outros aminoácidos + ciclo da ureia (E72) ----------------------------
  "E720",  "transporte_aminoacidos",       "aminoacidopatia",  "core",      NA,                  "AR",     FALSE,    FALSE,    "nucleo_eim",       "Cistinúria, Hartnup, Lowe.",
  "E721",  "homocistinuria",               "aminoacidopatia",  "core",      "Homocistinuria",    "AR",     FALSE,    TRUE,     "nucleo_eim",       "Homocistinúria clássica (MS: E72.1).",
  "E722",  "ciclo_ureia",                  "ciclo_ureia",      "core",      "Ciclo_ureia",       "mista",  TRUE,     FALSE,    "nucleo_eim",       "Defeitos do ciclo da ureia (OTC é XL; ASS/ASL/CPS1/NAGS AR).",
  "E723",  "acuduria_organica",            "acuduria_organica","core",      NA,                  "AR",     TRUE,     FALSE,    "nucleo_eim",       "Metab. lisina/hidroxilisina — acidúria glutárica tipo I.",
  "E724",  "metab_ornitina",               "aminoacidopatia",  "core",      NA,                  "AR",     FALSE,    FALSE,    "nucleo_eim",       "Atrofia girata (OAT).",
  "E725",  "metab_glicina",                "aminoacidopatia",  "core",      NA,                  "AR",     FALSE,    FALSE,    "nucleo_eim",       "Hiperglicinemia não cetótica.",
  "E72",   "aminoacidopatia_outros",       "aminoacidopatia",  "limitrofe", NA,                  "AR",     FALSE,    FALSE,    "nucleo_eim",       "Fallback E72 (E728/E729).",
  # ---- Carboidratos (E73–E74) -----------------------------------------------
  "E730",  "intol_lactose_congenita",      "carboidrato",      "limitrofe", NA,                  "AR",     FALSE,    FALSE,    "nucleo_eim",       "Def. congênita de lactase (rara).",
  "E73",   "intol_lactose",                "carboidrato",      "envelope",  NA,                  NA,       FALSE,    FALSE,    "nucleo_eim",       "ENVELOPE: intolerância à lactose comum (não-EIM). E731/E738/E739.",
  "E740",  "glicogenose",                  "carboidrato",      "core",      "Pompe",             "AR",     TRUE,     TRUE,     "nucleo_eim",       "Glicogenoses; inclui POMPE=GSD II (MS: E74.0, lisossômica). [VERIFICAR separar Pompe via APAC]",
  "E741",  "metab_frutose",                "carboidrato",      "core",      NA,                  "AR",     FALSE,    FALSE,    "nucleo_eim",       "Intolerância hereditária à frutose.",
  "E742",  "galactosemia",                 "carboidrato",      "core",      "Galactosemia",      "AR",     TRUE,     FALSE,    "nucleo_eim",       "Galactosemia (GALT/GALK1/GALE).",
  "E744",  "metab_piruvato",               "mitocondrial",     "core",      NA,                  "AR",     FALSE,    FALSE,    "nucleo_eim",       "Def. piruvato desidrogenase/carboxilase (energético).",
  "E74",   "carboidrato_outros",           "carboidrato",      "limitrofe", NA,                  "AR",     FALSE,    FALSE,    "nucleo_eim",       "Fallback E74 (E743/E748/E749; CDG pode cair aqui). [VERIFICAR CDG]",
  # ---- Lipídios / esfingolipidoses (E75) ------------------------------------
  "E750",  "esfingolipidose_GM2",          "lisossomica",      "core",      "Tay-Sachs",         "AR",     FALSE,    FALSE,    "nucleo_eim",       "Gangliosidose GM2 (Tay-Sachs/Sandhoff).",
  "E751",  "esfingolipidose_GM1",          "lisossomica",      "core",      NA,                  "AR",     FALSE,    FALSE,    "nucleo_eim",       "Gangliosidose GM1.",
  "E752",  "esfingolipidose_outras",       "lisossomica",      "core",      "Gaucher_Fabry_NPC", "mista",  TRUE,     TRUE,     "nucleo_eim",       "MS: E75.2 agrega GAUCHER + FABRY(XL) + NIEMANN-PICK C. NÃO separável por CID → triangular APAC-enzima.",
  "E754",  "lipofuscinose_NCL",            "lisossomica",      "core",      NA,                  "AR",     FALSE,    FALSE,    "nucleo_eim",       "Lipofuscinose ceroide neuronal (Batten).",
  "E755",  "deposito_lipidios",            "lisossomica",      "core",      NA,                  "AR",     FALSE,    FALSE,    "nucleo_eim",       "Outros depósitos de lipídios (Wolman/CESD).",
  "E75",   "esfingolipidose_ne",           "lisossomica",      "limitrofe", NA,                  "AR",     FALSE,    FALSE,    "nucleo_eim",       "Fallback E75 (E753/E756 não especificados).",
  # ---- Mucopolissacaridoses e glicoproteínas (E76–E77) ----------------------
  "E760",  "mucopolissacaridose",          "lisossomica",      "core",      "MPS_I",             "AR",     TRUE,     TRUE,     "nucleo_eim",       "MPS I (Hurler/Scheie; MS: E76.0). Laronidase.",
  "E761",  "mucopolissacaridose",          "lisossomica",      "core",      "MPS_II",            "XL",     TRUE,     FALSE,    "nucleo_eim",       "MPS II (Hunter) — LIGADA AO X. Idursulfase. QC sexo×CID.",
  "E762",  "mucopolissacaridose",          "lisossomica",      "core",      "MPS_outras",        "AR",     TRUE,     FALSE,    "nucleo_eim",       "Outras MPS (III/IVA/VI/VII). Galsulfase (MPS VI).",
  "E763",  "mucopolissacaridose_ne",       "lisossomica",      "limitrofe", NA,                  "AR",     FALSE,    FALSE,    "nucleo_eim",       "MPS não especificada.",
  "E76",   "glicosaminoglicano_outros",    "lisossomica",      "limitrofe", NA,                  "AR",     FALSE,    FALSE,    "nucleo_eim",       "Fallback E76 (E768/E769).",
  "E770",  "glicoproteinose",              "lisossomica",      "core",      NA,                  "AR",     FALSE,    FALSE,    "nucleo_eim",       "Mucolipidose II/III (def. modificação pós-traducional).",
  "E771",  "glicoproteinose",              "lisossomica",      "core",      NA,                  "AR",     FALSE,    FALSE,    "nucleo_eim",       "Alfa-manosidose, fucosidose, aspartilglucosaminúria; CDG podem cair aqui.",
  "E77",   "glicoproteina_outros",         "lisossomica",      "limitrofe", NA,                  "AR",     FALSE,    FALSE,    "nucleo_eim",       "Fallback E77 (E778/E779).",
  # ---- Lipoproteínas (E78) — ENVELOPE: dislipidemia comum -------------------
  "E78",   "dislipidemia",                 "outros",           "envelope",  NA,                  NA,       FALSE,    FALSE,    "nucleo_eim",       "ENVELOPE: dislipidemia comum multifatorial. HF monogênica indistinguível → fora do núcleo.",
  # ---- Purinas/pirimidinas (E79) --------------------------------------------
  "E790",  "hiperuricemia",                "outros",           "envelope",  NA,                  NA,       FALSE,    FALSE,    "nucleo_eim",       "ENVELOPE: hiperuricemia/gota comum (não-EIM raro).",
  "E791",  "lesch_nyhan",                  "purina_pirimidina","core",      "Lesch_Nyhan",       "XL",     FALSE,    FALSE,    "nucleo_eim",       "Síndrome de Lesch-Nyhan (HPRT1) — LIGADA AO X.",
  "E79",   "purina_pirimidina_outros",     "purina_pirimidina","limitrofe", NA,                  "mista",  FALSE,    FALSE,    "nucleo_eim",       "Fallback E79 (def. ADA/PNP, xantinúria em E798/E799).",
  # ---- Porfirias / bilirrubina (E80) ----------------------------------------
  # AUDITADO contra a CID-10 (E80.0–E80.7, sem .8/.9). Correção: E80.3 é
  # catalase/peroxidase, NÃO bilirrubina; Gilbert é E80.4 (comum → envelope) e
  # Crigler-Najjar é E80.5 (raro grave → core). Antes ambos caíam no fallback E80.
  "E800",  "porfiria",                     "porfiria",         "core",      NA,                  "AR",     FALSE,    FALSE,    "nucleo_eim",       "Porfiria eritropoética hereditária (congênita/protoporfiria).",
  "E801",  "porfiria_cutanea_tardia",      "porfiria",         "limitrofe", NA,                  "mista",  FALSE,    FALSE,    "nucleo_eim",       "PCT — predominantemente adquirida (HCV/álcool).",
  "E802",  "porfiria_aguda",               "porfiria",         "core",      NA,                  "AD",     FALSE,    FALSE,    "nucleo_eim",       "Outras porfirias (aguda intermitente/variegata/coproporfiria).",
  "E803",  "defeito_catalase",             "outros",           "core",      NA,                  "AR",     FALSE,    FALSE,    "nucleo_eim",       "Defeitos da catalase/peroxidase (acatalasemia, Takahara). EIM real, benigno.",
  "E804",  "sindrome_gilbert",             "bilirrubina",      "envelope",  NA,                  "AR",     FALSE,    FALSE,    "nucleo_eim",       "ENVELOPE: sd. de Gilbert — benigna e COMUM (~5% da população). Nunca caso raro.",
  "E805",  "crigler_najjar",               "bilirrubina",      "core",      NA,                  "AR",     FALSE,    FALSE,    "nucleo_eim",       "Sd. de Crigler-Najjar (UGT1A1) — AR grave, kernicterus neonatal.",
  "E806",  "metab_bilirrubina_outros",     "bilirrubina",      "limitrofe", NA,                  "AR",     FALSE,    FALSE,    "nucleo_eim",       "Outros distúrbios da bilirrubina (Dubin-Johnson, Rotor) — agregador.",
  "E80",   "porfiria_bilirrubina_ne",      "porfiria",         "limitrofe", NA,                  "mista",  FALSE,    FALSE,    "nucleo_eim",       "Fallback E80 (E80.7 — bilirrubina não especificada).",
  # ---- Metais (E83) — Wilson dentro, hemocromatose fora ---------------------
  "E830",  "metab_cobre",                  "metais",           "core",      "Wilson",            "AR",     FALSE,    FALSE,    "nucleo_eim",       "Doença de Wilson (ATP7B) + Menkes (ATP7A, XL). EIM tardio tratável (quelantes).",
  "E831",  "metab_ferro",                  "metais",           "envelope",  NA,                  NA,       FALSE,    FALSE,    "nucleo_eim",       "ENVELOPE: hemocromatose HFE comum, penetrância baixa → fora do núcleo.",
  "E83",   "metab_minerais_outros",        "metais",           "limitrofe", NA,                  "mista",  FALSE,    FALSE,    "nucleo_eim",       "Fallback E83 (zinco E832, fósforo E833, cálcio E835, SOE).",
  # ---- Fibrose cística (E84) — subgrupo ISOLADO -----------------------------
  "E84",   "fibrose_cistica",              "fibrose_cistica",  "core",      "Fibrose_cistica",   "AR",     TRUE,     TRUE,     "nucleo_eim",       "Fibrose cística (MS: E84). Benchmark de EIM bem codificado. SEMPRE reportar isolada.",
  # ---- Amiloidose (E85) — heredofamiliares (E85.0/.1/.2) dentro -------------
  # AUDITADO: E85.0/.1/.2 são HEREDOFAMILIARES (core); E85.3/.4/.8/.9 são
  # adquiridas (AA, AL, senil) → envelope. Antes, E85.0 e E85.2 caíam no fallback
  # rotulado "adquirida" e ficavam fora do core indevidamente.
  "E850",  "amiloidose_familiar",          "amiloidose",       "core",      NA,                  "mista",  FALSE,    FALSE,    "nucleo_eim",       "Amiloidose heredofamiliar não neuropática (inclui febre familiar do Mediterrâneo).",
  "E851",  "amiloidose_familiar",          "amiloidose",       "core",      "PAF_TTR",           "AD",     FALSE,    TRUE,     "nucleo_eim",       "Polineuropatia amiloidótica familiar (TTR) (MS: E85.1). EIM tardio.",
  "E852",  "amiloidose_familiar",          "amiloidose",       "core",      NA,                  "mista",  FALSE,    FALSE,    "nucleo_eim",       "Amiloidose heredofamiliar não especificada.",
  "E853",  "amiloidose_adquirida",         "amiloidose",       "envelope",  NA,                  NA,       FALSE,    FALSE,    "nucleo_eim",       "ENVELOPE: amiloidose sistêmica secundária (AA) — adquirida, não-EIM.",
  "E854",  "amiloidose_adquirida",         "amiloidose",       "envelope",  NA,                  NA,       FALSE,    FALSE,    "nucleo_eim",       "ENVELOPE: amiloidose limitada a órgão — adquirida, não-EIM.",
  "E85",   "amiloidose_ne",                "amiloidose",       "envelope",  NA,                  NA,       FALSE,    FALSE,    "nucleo_eim",       "ENVELOPE: fallback E85 (E85.8/E85.9 — AL/senil, adquiridas).",
  # ---- E88 — "outros distúrbios metabólicos" (ENVELOPE + biotinidase) -------
  "E880",  "metab_proteinas_plasma",       "outros",           "limitrofe", NA,                  "mista",  FALSE,    FALSE,    "nucleo_eim",       "E88.0 = distúrbios do metab. das proteínas plasmáticas NCOP — def. de alfa-1-antitripsina cai aqui. AUDITADO.",
  "E884",  "mitocondrial",                 "mitocondrial",     "limitrofe", NA,                  "mtDNA",  FALSE,    FALSE,    "nucleo_eim",       "E88.4 (distúrbios do metab. mitocondrial) foi acrescentado em ATUALIZAÇÃO POSTERIOR da CID-10 e provavelmente NÃO existe na V2008 usada pelo DATASUS → linha possivelmente INERTE. Mitocondriais caem de fato em E88.8/E88.9 (envelope). [VERIFICAR na tabela oficial antes de remover]",
  "E889",  "def_biotinidase_envelope",     "outros",           "envelope",  "Biotinidase",       "AR",     TRUE,     TRUE,     "nucleo_eim",       "MS coloca DEF. BIOTINIDASE em E88.9 (envelope!). Triagem neonatal. Só isolável por contexto.",
  "E88",   "metab_outros_SOE",             "outros",           "envelope",  NA,                  NA,       FALSE,    FALSE,    "nucleo_eim",       "ENVELOPE máximo: outros/SOE (agrega mitocondriais/CDG não classificados).",
  "E90",   "metab_manifest_alhures",       "outros",           "envelope",  NA,                  NA,       FALSE,    FALSE,    "nucleo_eim",       "ENVELOPE: distúrbios metabólicos em doenças classificadas alhures. É código ASTERISCO — por regra da CID-10 nunca é causa básica no SIM (só manifestação).",

  # ==== EIM / doenças de triagem FORA do bloco E70–E90 =======================
  # (rastrear em diagsec* do SIH e nas linhas do SIM; reportar como subgrupos
  #  ISOLADOS no eixo triagem/política — §2.3 do plano)
  "E250",  "hiperplasia_adrenal_cong",     "endocrino_triagem","core",      "HAC",               "AR",     TRUE,     TRUE,     "fora_capitulo_E",  "Hiperplasia adrenal congênita (def. 21-OH; MS: E25.0). Triagem neonatal.",
  "E031",  "hipotireoidismo_congenito",    "endocrino_triagem","core",      "Hipotireoidismo_cong","mista",TRUE,     TRUE,     "fora_capitulo_E",  "Hipotireoidismo congênito (MS: E03.1). Triagem neonatal. Nem sempre 'metabólico' clássico.",

  # ==== Raras NÃO-EIM da lista do MS — só CONTEXTO de rede de doenças raras ===
  # (NÃO entram em nenhuma taxa de EIM; carregadas para cruzamento/benchmark)
  "G120",  "atrofia_muscular_espinhal",    "contexto_raras",   "limitrofe", "AME",               "AR",     FALSE,    TRUE,     "contexto_raras",   "AME (MS: G12.0) — capta só o tipo I (Werdnig-Hoffmann); AME II/III são G12.1 e ficam FORA. Rara não-EIM; contexto.",
  "D66",   "hemofilia_A",                  "contexto_raras",   "limitrofe", "Hemofilia_A",       "XL",     FALSE,    TRUE,     "contexto_raras",   "Hemofilia A (MS: D66). Contexto.",
  "D67",   "hemofilia_B",                  "contexto_raras",   "limitrofe", "Hemofilia_B",       "XL",     FALSE,    TRUE,     "contexto_raras",   "Hemofilia B (MS: D67). Contexto.",

  # ==== PAINEL DO PEZINHO — doenças de triagem NÃO-EIM (escopo isolado) =======
  # NUNCA entram nas taxas de EIM (escopo="painel_pezinho"). Extraídas à parte
  # (data/filtered/pezinho_eim/) para o eixo "cobertura do teste do pezinho".
  "D57",   "doenca_falciforme",            "hemoglobinopatia", "envelope",  "Doenca_falciforme", "AR",     TRUE,     TRUE,     "painel_pezinho",   "Pezinho tradicional. NÃO-EIM. Alto volume (~1M SIA/~300k AIH em 5a).",
  "D56",   "talassemia",                   "hemoglobinopatia", "core",      "Talassemia",        "AR",     TRUE,     FALSE,    "painel_pezinho",   "Pezinho tradicional. NÃO-EIM.",
  "D81",   "imunodeficiencia_comb",        "imunodeficiencia", "core",      "SCID",              "mista",  TRUE,     TRUE,     "painel_pezinho",   "Pezinho expandido (triagem TREC/SCID). NÃO-EIM.",
  "P371",  "toxoplasmose_congenita",       "congenita_infecc", "core",      "Toxo_congenita",    NA,       TRUE,     FALSE,    "painel_pezinho",   "Pezinho expandido. Usar P371 específico (P370=tétano). NÃO-EIM."
) |>
  dplyr::mutate(prefixo = toupper(prefixo)) |>
  dplyr::arrange(dplyr::desc(nchar(prefixo)), prefixo)   # MAIS ESPECÍFICO PRIMEIRO

# Marcação de ETAPA do teste do pezinho (por prefixo; ver ref/painel_pezinho_normativo.md).
# T = tradicional (PNTN); E = expandido (Lei 14.154/2021). [VERIFICAR etapas 2-5].
.PEZ_TRAD <- toupper(c("E700","E701","E031","E84","E250","E889","D57","D56"))
.PEZ_EXP  <- toupper(c("E742","E710","E711","E713","E721","E722","E720","E723","E724",
                       "E725","E75","E76","E740","D81","P371","G120"))
EIM_LOOKUP <- EIM_LOOKUP |>
  dplyr::mutate(pezinho_tradicional = prefixo %in% .PEZ_TRAD,
                pezinho_expandido   = prefixo %in% .PEZ_EXP,
                pezinho             = pezinho_tradicional | pezinho_expandido)

# -----------------------------------------------------------------------------
# 2. Conjuntos derivados (conveniência)
# -----------------------------------------------------------------------------
# Prefixos que definem o NÚCLEO EIM (E70–E90 stricto sensu), para o filtro grosso.
PREFIXOS_NUCLEO   <- EIM_LOOKUP$prefixo[EIM_LOOKUP$escopo == "nucleo_eim"]
# Prefixos EIM-relevantes (núcleo + triagem endócrina + contexto raras) — SEM o
# painel_pezinho não-EIM (que é analisado em pipeline próprio, nunca nas taxas de EIM).
PREFIXOS_TODOS    <- EIM_LOOKUP$prefixo[
  EIM_LOOKUP$escopo %in% c("nucleo_eim","fora_capitulo_E","contexto_raras")]
# Painel do pezinho: todos os CIDs de triagem (EIM + não-EIM) e só os GAPS não-EIM.
PREFIXOS_PEZINHO      <- EIM_LOOKUP$prefixo[EIM_LOOKUP$pezinho %in% TRUE]
PREFIXOS_PEZINHO_GAPS <- EIM_LOOKUP$prefixo[EIM_LOOKUP$escopo == "painel_pezinho"]
# Regex única compilada p/ FILTRO GROSSO na ingestão (SIA/SINASC nacionais).
#   modo "nucleo"  → só E70–E90 stricto sensu
#   modo "todos"   → inclui E250/E031 e raras de contexto
regex_eim <- function(modo = c("nucleo", "todos")) {
  modo <- match.arg(modo)
  pref <- if (modo == "nucleo") PREFIXOS_NUCLEO else PREFIXOS_TODOS
  paste0("^(", paste(sort(unique(pref)), collapse = "|"), ")")
}

# Traçadoras nominais e mapeamento denominador (IBGE vs SINASC) — ver §2.5/§4 do plano.
TRACADORAS <- EIM_LOOKUP |>
  dplyr::filter(!is.na(tracadora)) |>
  dplyr::transmute(tracadora, prefixo, subgrupo, heranca, triagem, pcdt_ms,
                   # denominador designado: NV (SINASC) p/ triadas; IBGE p/ demais
                   denominador = dplyr::if_else(triagem, "SINASC_nascidos_vivos", "IBGE_populacao")) |>
  dplyr::distinct()

message("eim_lookup.R carregado — ", nrow(EIM_LOOKUP), " prefixos | ",
        sum(EIM_LOOKUP$camada == "core"), " core, ",
        sum(EIM_LOOKUP$camada == "limitrofe"), " limítrofe, ",
        sum(EIM_LOOKUP$camada == "envelope"), " envelope | ",
        dplyr::n_distinct(TRACADORAS$tracadora), " traçadoras.")
