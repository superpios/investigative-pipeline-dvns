# Audit report — DVNS Investigative Pipeline

**Data audit:** 2026-08-30  
**Ambiente:** sandbox Linux, Python 3.11+, cloni shallow ufficiali dei tre repo  
**Fixture:** `testdata/relations/` (dati sintetici costruiti per attivare REGOLA-001/002/003)

## 1. Componenti sotto test

| Componente | Repo | Ref |
|------------|------|-----|
| Explorer relations | superpios/investigative-explorer-dvns | main (depth 1) |
| Leads Generator | superpios/investigative-leads-generator | main (depth 1) |
| Alert Engine | superpios/investigative-alert-engine | main (depth 1) |
| Coordinator | questo pacchetto | — |

Script effettivamente eseguiti:
- `leads/scripts/adapt_explorer.py`
- `leads/scripts/apply_rules.py` + `rules/rules_v0.1.yaml`
- `alert/scripts/rank_leads.py` + `rules/ranking_v0.1.yaml`
- `alert/scripts/export_feed.py`
- `coordinator/scripts/audit_output.py`

## 2. Catena eseguita (sandbox)

```
testdata/relations/*.csv
        │
        ▼ adapt_explorer.py
work/input/{incarichi,affidamenti_diretti,cig_enti}.csv
        │
        ▼ apply_rules.py
work/leads/leads_v0.1.json  (3 piste) + manifest.json (status=ok)
        │
        ▼ rank_leads.py
work/ranked/ranked_leads.json + history/run_2025-08-15.json
        │
        ▼ export_feed.py
work/ranked/feed.md
```

### Risultati fixture

| Rule | Lead ID | Titolo (estratto) | priority_score |
|------|---------|-------------------|----------------|
| REGOLA-001 | LEAD-REGOLA-001-d5dfcc9955 | Nominativo presente in 6 incarichi su enti diversi – anno 2025 | 0.0* |
| REGOLA-002 | LEAD-REGOLA-002-f6d2b63bce | Aggiudicatario riceve 9 affidamenti diretti … | 18.2 |
| REGOLA-003 | LEAD-REGOLA-003-12104d4b44 | CIG collegato a 3 enti distinti senza spiegazione … | 0.0* |

\* Score 0: l’euristica di ranking cerca keyword specifiche nei `observed_facts` (“incarichi”, “affidamenti diretti”, …). REGOLA-001 formula i fatti come “Numero di enti distinti: 6” → non matcha la keyword “incarichi” al conteggio. Comportamento **conservativo** e deterministico; non è un bug del ranking v0.1.

## 3. Checklist di conformità

| Controllo | Esito | Note |
|-----------|-------|------|
| Determinismo (stesso input → stesso SHA-256 ranked) | **PASS** | 2 run indipendenti, hash identico |
| Fail-closed su input vuoto/mancante | **PASS** | exit 1 + `manifest.json` status failed |
| Schema obbligatorio piste ranked | **PASS** | tutti i campi richiesti presenti |
| Disclaimer obbligatorio su ogni pista | **PASS** | contiene “non dimostra alcun illecito” / “merita verifica” |
| Nessuna etichetta valutativa proibita | **PASS** | no frode/corruzione/colpevole/… |
| Ordine rank = score desc + tie-break | **PASS** | |
| History snapshot nominato con `data_through` | **PASS** | `run_2025-08-15.json` |
| Zero leads = esito valido (non errore) | **PASS** | documentato nei README originali |

## 4. Limiti consapevoli (non regressioni)

1. **Ranking v0.1** usa euristiche testuali sui `observed_facts`. Per alzare gli score di REGOLA-001/003 servirà allineare le frasi dei fatti alle keyword del ranking (o estendere `extract_count_from_facts`) — solo dopo validazione manuale ≥ 20 piste reali.
2. **REGOLA-004** resta disabilitata nei rules originali fino a calibrazione.
3. I CSV di relazione reali dell’Explorer sono grandi (~26 MB solo incarichi). Su Actions pubblici il download shallow + elaborazione è fattibile; se i timeout diventano un problema, passare a parquet o a snapshot pre-filtrati.
4. GitHub Actions scheduled ha precisione ±15–30 min; accettabile per un ciclo giornaliero investigativo.
5. Workflow disabilitati dopo 60 giorni di inattività sul repo: un commit periodico o un ping esterno evita lo spegnimento.

## 5. Raccomandazioni operative

1. Prima di affidarsi al cron giornaliero: lanciare 2–3 run manuali su dati live e validare ≥ 20–30 piste a mano.
2. Pubblicare `ranked_leads.json` + `feed.md` in sola lettura (GitHub Pages o artifact) con disclaimer in evidenza.
3. Non attivare nuove regole senza aggiornare `docs/REGOLE_SEGNALAZIONE.md` e test quantitativi anti-falsi-positivi.
4. Per bozze di verifica LLM: job opzionale post-ranking → top N → Groq (secret), mai sull’intero dataset grezzo.

## 6. Conclusione

La pipeline end-to-end **funziona**, è **deterministica**, **fail-closed** e **conforme** ai principi dichiarati dai tre motori.  
Il coordinator (workflow + `run_pipeline.sh` + audit) è pronto per uso su repo pubblico senza PC sempre acceso.

**Stato:** GO per smoke test e validazione umana; NON ancora “regole stabili in produzione” fino a validazione manuale su dati reali.
