#!/usr/bin/env python3
# =============================================================================
# verificar_download.py — Confere o disco contra o manifesto (integridade por tamanho)
# Relata por base × ano: esperados, completos, faltantes, tamanho divergente, .part
# pendentes. Saída também em <raiz>/logs/verificacao_<data>.tsv (por arquivo faltante).
# Uso: python3 verificar_download.py [--raiz ~/Documentos/ronald/datasus_raw]
# =============================================================================
import argparse, collections, csv, datetime, os

ap = argparse.ArgumentParser()
ap.add_argument("--raiz", default=os.path.expanduser("~/Documentos/ronald/datasus_raw"))
ap.add_argument("--manifesto", default="")
a = ap.parse_args()
man = a.manifesto or os.path.join(a.raiz, "manifest", "manifesto_atual.tsv")

res = collections.defaultdict(lambda: collections.Counter())
pend = []
with open(man) as f:
    for r in csv.DictReader(f, delimiter="\t"):
        k = (r["base"], int(r["ano"]))
        fp = os.path.join(a.raiz, r["destino"], r["arquivo"])
        esperado = int(r["tamanho"])
        res[k]["esperados"] += 1
        res[k]["gb"] += esperado
        if os.path.exists(fp):
            if os.path.getsize(fp) == esperado:
                res[k]["completos"] += 1
                continue
            res[k]["divergentes"] += 1; st = "divergente"
        else:
            res[k]["faltantes"] += 1; st = "faltante"
        if os.path.exists(fp + ".part"):
            res[k]["parciais"] += 1
        pend.append((r["base"], r["destino"], r["arquivo"], esperado, st))

print(f"{'base':8s} {'ano':>4s} {'esper':>6s} {'compl':>6s} {'falta':>6s} {'diverg':>6s} {'.part':>6s} {'GB':>7s}")
tot = collections.Counter()
for (b, ano), c in sorted(res.items()):
    print(f"{b:8s} {ano:4d} {c['esperados']:6d} {c['completos']:6d} {c['faltantes']:6d} {c['divergentes']:6d} {c['parciais']:6d} {c['gb']/1e9:7.1f}")
    tot.update(c)
print(f"{'TOTAL':8s} {'':4s} {tot['esperados']:6d} {tot['completos']:6d} {tot['faltantes']:6d} {tot['divergentes']:6d} {tot['parciais']:6d} {tot['gb']/1e9:7.1f}")
out = os.path.join(a.raiz, "logs", f"verificacao_{datetime.date.today():%Y%m%d}.tsv")
os.makedirs(os.path.dirname(out), exist_ok=True)
with open(out, "w") as f:
    f.write("base\tdestino\tarquivo\ttamanho_esperado\tsituacao\n")
    for p in pend:
        f.write("\t".join(map(str, p)) + "\n")
print(f"pendentes: {len(pend)} → {out}")
