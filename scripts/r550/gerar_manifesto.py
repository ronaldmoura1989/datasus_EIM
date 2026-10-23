#!/usr/bin/env python3
# =============================================================================
# gerar_manifesto.py — Lista os DBC do FTP do DATASUS (2010+) com tamanho esperado
#
# Bases e diretórios FTP (dissemin/publicos):
#   SIA-PA  SIASUS/200801_/Dados          PA{UF}{AA}{MM}[a-z].dbc  (UFs grandes vêm em partes a,b,c…)
#   SIH-RD  SIHSUS/200801_/Dados          RD{UF}{AA}{MM}.dbc
#   SIM-DO  SIM/CID10/DORES               DO{UF}{AAAA}.dbc         (definitivo)
#           SIM/PRELIM/DORES              DO{UF}{AAAA}.dbc         (preliminar → subdir PRELIM)
#   SINASC  SINASC/1996_/Dados/DNRES      DN{UF}{AAAA}.dbc         (definitivo)
#           SINASC/PRELIM/DNRES           DN{UF}{AAAA}.dbc         (preliminar → subdir PRELIM)
# Ano preliminar que já tem definitivo é descartado (o definitivo prevalece).
#
# Saída: <raiz>/manifest/manifesto_<AAAAMMDD>.tsv  + link manifesto_atual.tsv
#   colunas: base  destino  ano  uf  periodo  arquivo  url  tamanho
# Uso: python3 gerar_manifesto.py [--raiz ~/Documentos/ronald/datasus_raw] [--ano-min 2010]
# =============================================================================
import argparse, datetime, ftplib, os, re, sys, time

HOST = "ftp.datasus.gov.br"
FONTES = [
    # base,     destino,          diretório FTP,                               regex,                                    tipo
    ("SIA-PA",  "SIA-PA",         "/dissemin/publicos/SIASUS/200801_/Dados",   r"^PA([A-Z]{2})(\d{2})(\d{2})([a-z]?)\.dbc$", "mensal"),
    ("SIH-RD",  "SIH-RD",         "/dissemin/publicos/SIHSUS/200801_/Dados",   r"^RD([A-Z]{2})(\d{2})(\d{2})()\.dbc$",       "mensal"),
    ("SIM-DO",  "SIM-DO",         "/dissemin/publicos/SIM/CID10/DORES",        r"^DO([A-Z]{2})(\d{4})()()\.dbc$",            "anual"),
    ("SIM-DO",  "SIM-DO/PRELIM",  "/dissemin/publicos/SIM/PRELIM/DORES",       r"^DO([A-Z]{2})(\d{4})()()\.dbc$",            "anual"),
    ("SINASC",  "SINASC",         "/dissemin/publicos/SINASC/1996_/Dados/DNRES", r"^DN([A-Z]{2})(\d{4})()()\.dbc$",          "anual"),
    ("SINASC",  "SINASC/PRELIM",  "/dissemin/publicos/SINASC/PRELIM/DNRES",    r"^DN([A-Z]{2})(\d{4})()()\.dbc$",            "anual"),
]
UFS = set("AC AL AM AP BA CE DF ES GO MA MG MS MT PA PB PE PI PR RJ RN RO RR RS SC SE SP TO".split())


def listar(ftp, d, tentativas=5):
    for t in range(tentativas):
        try:
            ftp.cwd(d)
            linhas = []
            ftp.retrlines("LIST", linhas.append)
            return linhas
        except ftplib.all_errors as e:
            print(f"  ! {d}: {e} (tentativa {t + 1})", file=sys.stderr)
            time.sleep(10 * (t + 1))
            ftp = conectar()
    raise RuntimeError(f"falha ao listar {d}")


def conectar():
    ftp = ftplib.FTP(HOST, timeout=120)
    ftp.login()
    return ftp


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--raiz", default=os.path.expanduser("~/Documentos/ronald/datasus_raw"))
    ap.add_argument("--ano-min", type=int, default=2010)
    a = ap.parse_args()

    ftp = conectar()
    linhas_out, definitivos = [], set()
    for base, destino, d, pat, tipo in FONTES:
        n = 0
        for l in listar(ftp, d):
            p = l.split()
            nome = p[-1]
            m = re.match(pat, nome, re.I)
            if not m:
                continue
            uf = m.group(1).upper()
            if uf not in UFS:
                continue
            # LIST do DATASUS no formato Windows ("data hora tamanho nome") ou Unix (tamanho em p[4])
            tamanho = int(p[2]) if p[2].isdigit() else int(p[4])
            if tipo == "mensal":
                ano, periodo = 2000 + int(m.group(2)), f"{m.group(2)}{m.group(3)}{m.group(4)}"
            else:
                ano, periodo = int(m.group(2)), m.group(2)
            if ano < a.ano_min:
                continue
            if destino.endswith("PRELIM") and (base, uf, ano) in definitivos:
                continue
            if not destino.endswith("PRELIM") and tipo == "anual":
                definitivos.add((base, uf, ano))
            url = f"ftp://{HOST}{d}/{nome}"
            linhas_out.append((base, destino, ano, uf, periodo, nome, url, tamanho))
            n += 1
        print(f"{destino:15s} {n:6d} arquivos", file=sys.stderr)
    ftp.quit()

    os.makedirs(os.path.join(a.raiz, "manifest"), exist_ok=True)
    fp = os.path.join(a.raiz, "manifest", f"manifesto_{datetime.date.today():%Y%m%d}.tsv")
    with open(fp, "w") as f:
        f.write("base\tdestino\tano\tuf\tperiodo\tarquivo\turl\ttamanho\n")
        for r in sorted(linhas_out, key=lambda r: (r[0] != "SIM-DO", r[0] != "SINASC", r[0] != "SIH-RD", r[2], r[3], r[4])):
            f.write("\t".join(map(str, r)) + "\n")
    link = os.path.join(a.raiz, "manifest", "manifesto_atual.tsv")
    if os.path.lexists(link):
        os.remove(link)
    os.symlink(os.path.basename(fp), link)
    tot = sum(r[7] for r in linhas_out) / 1e9
    print(f"✓ {len(linhas_out)} arquivos, {tot:.1f} GB → {fp}", file=sys.stderr)


if __name__ == "__main__":
    main()
