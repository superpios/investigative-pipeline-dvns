Investigative Pipeline · DVNS

Pipeline automatica end-to-end che collega i tre componenti investigativi:

Explorer → Leads Generator → Alert Engine

Produce un feed prioritizzato di piste conservative a partire dalle relazioni documentate sui dati pubblici di DoveVannoINostriSoldi.

Ogni output è un segnale quantitativo che merita verifica umana.
Nessuna conclusione automatica di illecito, spreco, frode o responsabilità individuale.

Componenti collegati

Componente

Ruolo

investigative-explorer-dvns

Relazioni documentate da dati pubblici

investigative-leads-generator

Piste conservative (regole dichiarative, fail-closed)

investigative-alert-engine

Ranking, storico e feed prioritizzato

Cosa fa

1.  Adatta le tabelle di relazione dell’Explorer
2.  Applica le regole del Leads Generator
3.  Esegue il ranking dell’Alert Engine
4.  Aggiorna lo storico e pubblica il feed (ranked_leads.json, feed.md)

Il ciclo è deterministico e fail-closed: stesso input → stesso output; input non validi interrompono la pipeline senza inventare risultati.

Uso locale

git clone https://github.com/superpios/investigative-pipeline-dvns.git

cd investigative-pipeline-dvns

bash scripts/run_pipeline.sh --fixture

Output in output/ranked/.

Per dati reali dell’Explorer:

bash scripts/run_pipeline.sh

# oppure

RELATIONS_DIR=/path/to/explorer/data/relations bash scripts/run_pipeline.sh

Dipendenze: Python 3.11+, pyyaml, pandas.

GitHub Actions

Il workflow .github/workflows/pipeline.yml:

-   gira ogni giorno alle 03:00 UTC
-   può essere avviato manualmente (workflow_dispatch)
-   supporta smoke test con dati di esempio (use_fixture_data=true)
-   carica gli artifact della run
-   opzionalmente aggiorna data/ranked/ su main

Nessun secret obbligatorio per il ciclo base (solo dati pubblici).

Avvio manuale

1.  Tab Actions → DVNS Investigative Pipeline → Run workflow
2.  Smoke test: use_fixture_data = true
3.  Dati reali: use_fixture_data = false

Output

File

Descrizione

ranked_leads.json

Piste ordinate per priority_score (0–100)

feed.md

Report leggibile

history/run_.json

Snapshot per il calcolo della persistenza

leads/manifest.json

Stato dell’esecuzione del generatore

Ogni pista include sempre: id, title, observed_facts, sources, period, rule_id, why_worth_checking, what_cannot_be_claimed, disclaimer, priority_score, priority_reasons, rank_position.

Principi

-   Solo dati pubblici, con fonte e limiti visibili
-   Nessuna etichetta valutativa (illecito, frode, spreco, responsabilità)
-   Nessun totale o collegamento non supportato dagli atti/dati sorgente
-   Fail-closed su input mancanti o non validi

Licenza

GNU Affero General Public License v3.0 — allineata ai componenti collegati.
Questo coordinator (workflow + script di orchestrazione) è rilasciato sotto la stessa licenza per coerenza, salvo diversa indicazione nei file.

---

## Disclaimer

Questo non dimostra alcun illecito. Indica solo concentrazioni quantitative che meritano verifica umana.  
I dati trattati sono pubblici; nessun dato personale non già pubblicato nelle fonti ufficiali viene introdotto dalla pipeline.
