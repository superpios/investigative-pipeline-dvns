# Validazione Generator — materiale per re-review #190

Stato: **pronto per coda di review**. Nessun sign-off richiesto in questo file.  
Nessun output va presentato come «verificato dal progetto».

Data del dossier: 2026-09-06.

## Pointer

| Componente | Riferimento |
|------------|-------------|
| Explorer relations | `investigative-explorer-dvns` `data/relations/` (main) |
| `explorer_sha` nel feed | `58864b7ac0efe75e3228944e2e33b2cffc4a8279d284284c10fd84ca1eb3d459` |
| Generator regole | `investigative-leads-generator` `rules/rules_v0.1.yaml` |
| Pipeline feed | `investigative-pipeline-dvns` `data/ranked/ranked_leads.json` |
| `data_through` | 2026-08-12 |
| `snapshot_created_at` | 2026-09-05 |
| `ranking_version` | 0.1 |

## Mapping Explorer → motore (REGOLA-002)

File: `awards__affidamenti_diretti.csv`  
Adapter: `scripts/adapt_explorer.py`

| Campo regola | Colonna Explorer | Nota |
|--------------|------------------|------|
| awardee | `subject_key` | Testo fonte, nessuna risoluzione omonimi |
| entity_id | `ipa` se valorizzato, altrimenti `object_key` | Es. `m_inf`, `aifa_rm`, `m_dg` |
| award_date | `period` | Primi 10 caratteri, data ISO |
| procedure_type | implicito | Il file è già perimetro «affidamenti diretti» |
| source_url | `source_url` | URL atto di trasparenza |
| source_record_id | `source_record_id` | Hash riga Explorer |

Soglia dichiarata: **≥ 8** affidamenti diretti, stessa coppia aggiudicatario×ente, **12 mesi mobili**.  
Finestra usata nel feed: 2025-08-12 … 2026-08-12.

REGOLA-001 legge `persona_incarico_ente__incarichi_nominativi_shard.csv` (`person_name=subject_key`, `entity_id=ipa\|object_key`, `year=period[:4]`), soglia ≥ 5 enti nello stesso anno.  
REGOLA-003 legge `cig_ente__affidamenti_diretti.csv`.  
REGOLA-004 è `enabled: false`.

## Piste reali emesse (3)

Conteggio indipendente sullo stesso CSV Explorer, stessa finestra: 1642 righe, 626 coppie, **3 coppie ≥ 8**. Coincidono col feed.

| id | Ente | Aggiudicatario | N | Date distinte | data_quality |
|----|------|----------------|---|----------------|--------------|
| LEAD-REGOLA-002-4458183d69 | MIT (`m_inf`) | INFRASTRUTTURE MILANO CORTINA 2020-2026 S.P.A. | 12 | 1 | weak |
| LEAD-REGOLA-002-d38732c5f5 | AIFA (`aifa_rm`) | DOTT.SSA RAFFAELLA CUGINI | 10 | 1 | weak |
| LEAD-REGOLA-002-fe86830e40 | Ministero della Giustizia (`m_dg`) | ING. GIOVANNI MALESCI | 9 | 6 | weak |

Score feed: 15.0 / 10.5 / 8.2. Solo ranking quantitativo sulla concentrazione.

`data_quality: weak` sulle prime due: molti record con la **stessa** `award_date` (`2026-01-01`). È un limite della fonte/estrazione, non una prova di reiterazione calendaria.

Ogni pista nel JSON porta già `why_worth_checking`, `what_cannot_be_claimed`, `disclaimer`, URL fonte.

## Campione negativo (vicino alla soglia)

Coppia **non** emessa.

| Aggiudicatario | Ente | N nella finestra | Soglia | Esito |
|----------------|------|------------------|--------|--------|
| SCUOTTO IMPIANTI ELETTRICI E TECNOLOGICI S.R.L. | MIC (`m_bac`) | 6 | 8 | nessuna pista |

Esempio atto: `https://trasparenza.cultura.gov.it/archivio105_procedure-dal-01012024_0_32331_566_1.html`  
Date osservate sulla chiave esatta: 2025-10-07 … 2025-12-11.

Coppia a **7**: nessuna nella finestra.  
Non si allarga il campione abbassando la soglia.

## Regole a zero (stesso run)

| Regola | Soglia | Piste | Lettura |
|--------|--------|-------|---------|
| REGOLA-001 | ≥ 5 enti / anno | 0 | Lo shard incarichi non ha prodotto 5 enti distinti sullo stesso nome normalizzato nell’anno di calendario |
| REGOLA-003 | ≥ 2 soggetti / CIG | 0 | Il file CIG-ente non ha soddisfatto la condizione così com’è scritta |
| REGOLA-004 | — | — | Disabilitata, nessuna calibrazione |

Zero piste ≠ regola rotta. Non si attiva 004 in questa review.

## Cosa questo dossier non sostiene

- Illecito, spreco, nepotismo, irregolarità di gara.
- Identità anagrafica (omonimi non risolti).
- Somma con OpenCivitas, SIOPE, PNRR o annualità diverse.
- Qualità o esito dei contratti.
- Che `data_quality: weak` sia un indizio di condotta.

Formula vincolante (già in ogni pista):  
*Questo non dimostra alcun illecito. Indica solo una concentrazione che merita verifica.*

## Fuori perimetro fino al sign-off #190

- Link da dovevannoinostrisoldi.com  
- Issue #193 (soglie Alert Engine, feed pubblico DVNS)  
- Sezione `/report` o testi generativi sul prodotto  
- Cambio soglie 002/001/003
