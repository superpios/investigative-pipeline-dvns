# DVNS Investigative Pipeline (coordinator)

Pipeline automatica end-to-end che collega i tre componenti investigativi:

```
Explorer (relations) → Leads Generator (piste conservative) → Alert Engine (ranking + storico)
```

**Filosofia vincolante**  
Ogni output è un *segnale quantitativo che merita verifica umana*.  
Nessuna conclusione automatica di illecito, spreco, frode o responsabilità individuale.

Collegato a:
- [investigative-explorer-dvns](https://github.com/superpios/investigative-explorer-dvns)
- [investigative-leads-generator](https://github.com/superpios/investigative-leads-generator)
- [investigative-alert-engine](https://github.com/superpios/investigative-alert-engine)
- [DoveVannoINostriSoldi](https://github.com/Italian-Builders-Org/DoveVannoINostriSoldi)

---

## Perché questo approccio (24/7 senza PC acceso)

| Requisito | Soluzione |
|-----------|-----------|
| PC sempre acceso | **No** — GitHub Actions su repo pubblico |
| Costo | **0 €** (minuti illimitati su public repos) |
| Accessibile dal mondo | Artifact + branch `data` / GitHub Pages |
| Deterministico / fail-closed | Ereditato dai tre motori originali |
| Auditabile | Log GHA + `scripts/audit_output.py` + manifest |

Alternative complementari (dopo ranking):
- Chiamata on-demand a **Groq** sulle top 5–10 piste per bozza di verifica (solo quando vuoi).
- Cloudflare Workers / Pages per esporre il feed statico.

---

## Uso locale (smoke test con fixture)

```bash
git clone <questo-repo> dvns-pipeline
cd dvns-pipeline
chmod +x scripts/run_pipeline.sh
./scripts/run_pipeline.sh --fixture
```

Output in `output/ranked/ranked_leads.json` e `output/ranked/feed.md`.

Per dati reali dell’Explorer:

```bash
./scripts/run_pipeline.sh
# oppure
RELATIONS_DIR=/path/to/explorer/data/relations ./scripts/run_pipeline.sh
```

---

## Uso su GitHub Actions (produzione)

1. Crea un repository pubblico (es. `superpios/dvns-pipeline` o aggiungi i file a uno esistente).
2. Copia il contenuto di questa cartella.
3. Abilita Actions.
4. Il workflow `.github/workflows/pipeline.yml`:
   - gira **ogni giorno alle 03:00 UTC** (cron)
   - può essere lanciato manualmente (`workflow_dispatch`)
   - supporta `use_fixture_data=true` per smoke test
   - carica artifact `dvns-ranked-<run_id>`
   - opzionalmente pubblica `data/ranked/` sul branch main

Nessun secret obbligatorio per il ciclo base (solo dati pubblici).

---

## Cosa produce

| File | Descrizione |
|------|-------------|
| `ranked_leads.json` | Lista ordinata per `priority_score` (0–100) |
| `feed.md` | Report leggibile |
| `history/run_<data_through>.json` | Snapshot per calcolo persistenza |
| `leads/manifest.json` | Stato esecuzione generator (ok/failed, hash input) |

Ogni pista contiene sempre: `id`, `title`, `observed_facts`, `sources`, `period`, `rule_id`, `why_worth_checking`, `what_cannot_be_claimed`, `disclaimer`, `priority_score`, `priority_reasons`, `rank_position`.

---

## Validazione e audit (eseguiti in sandbox)

Vedi `docs/AUDIT.md` per il report completo.

Sintesi dei test eseguiti su questo pacchetto (30 ago 2026):

| Test | Esito |
|------|-------|
| Adapt Explorer → CSV generator | PASS (3 file) |
| Apply rules (fixture) | PASS → 3 piste (REGOLA-001/002/003) |
| Ranking + history | PASS → ranked_leads.json |
| Determinismo (2 run, stesso SHA-256) | PASS |
| Fail-closed (input vuoto → exit 1 + manifest) | PASS |
| Schema obbligatorio + disclaimer | PASS |
| Nessuna etichetta valutativa proibita | PASS |

**Nota ranking**: le euristiche di score leggono i `observed_facts`. Con le regole attuali REGOLA-002 (9 affidamenti) ottiene score > 0; REGOLA-001/003 possono restare a 0 se le keyword non matchano — comportamento conservativo documentato in `ranking_v0.1.yaml`.

---

## Prossimi passi consigliati

1. Validare manualmente ≥ 20–30 piste su dati reali prima di considerare le regole “stabili”.
2. Collegare il feed al sito dovevannoinostrisoldi.com (pagina sola lettura + disclaimer).
3. Opzionale: job post-ranking che invia le top N a Groq per bozza di verifica (API key in secrets).
4. Integrazione futura con segnalazioni cittadine (stesso CIG/ente/nominativo).

---

## Licenza

I tre motori originali sono AGPL-3.0.  
Questo coordinator (workflow + script di orchestrazione) è rilasciato sotto la stessa licenza per coerenza, salvo diversa indicazione nei file.

---

## Disclaimer

Questo non dimostra alcun illecito. Indica solo concentrazioni quantitative che meritano verifica umana.  
I dati trattati sono pubblici; nessun dato personale non già pubblicato nelle fonti ufficiali viene introdotto dalla pipeline.
