# Codebook — Islamic banking regime, framework, and market share

Compiled 2026-08-16. Revised 2026-08-16 (level correction applied; Sierra Leone re-sourced; third rank inversion recorded). Two datasets, both keyed to fifteen frontier economies and four survey rounds.

---

## 1. `ib_regime_framework_15_economies.csv`

128 cells: 15 economies (Cameroon, Chad, Gabon = COBAC; Benin, Burkina Faso, Mali, Niger, Senegal, Togo = BCEAO; Albania, Guinea, Mauritania, Sierra Leone, Tajikistan, Uganda, Uzbekistan) × 4 rounds × 2 variables.

### Timing rule

Every cell is coded as at **31 December of the year preceding the round**.

| round_year | as_of_date |
|---|---|
| 2011 | 2010-12-31 |
| 2014 | 2013-12-31 |
| 2017 | 2016-12-31 |
| 2021 | 2020-12-31 |

Rationale: Findex fieldwork falls in different months across countries within a single round. A fieldwork-anchored rule would code the same law differently for two countries in the same round. A uniform year-end rule that precedes the outcome excludes reverse causality by construction rather than by assumption.

### Variables

**`ib_legal_framework`** — 1 if a law or regulation *dedicated* to Islamic banking was in force at `as_of_date`; 0 otherwise.

A single article inside a general banking statute does not qualify. This threshold is applied identically to Albania (UBA under Law 9662/2006) and Guinea (Article 80 of the banking law); both are 0. Report the sensitivity at 1 for Guinea in one line — the cell is constant across all four rounds, so country fixed effects absorb it entirely and the main specification is unaffected.

**`ib_regime`** — 2 = a standalone licensed Islamic bank; 1 = only an Islamic window or dedicated branch; 0 = neither.

Counted only if it appears in the banking supervisor's licence register. Islamic leasing companies and Islamic microfinance institutions are out of scope (Tajikistan: Asr Leasing 2013, Alif Capital 2014). The broader alternative — any institution offering a compliant account, closer to Findex's definition of an account — cannot be applied uniformly: bank licence registers exist for all nine regulators, microfinance registers do not, and a rule applied only to well-documented countries produces a variable whose coverage tracks state administrative capacity.

### Known limitation, stated not hidden

**Value 1 is unobservable where no dedicated framework exists.** An Islamic window is not a separately licensed entity in such jurisdictions and cannot appear in any register. Value 2 is observable in all cases, framework or not — Albania, Guinea and Mauritania before 2018 are all correctly captured at 2.

The variable therefore under-counts in one category and in a known direction. This affects Cameroon, Gabon and Chad in all four rounds, and Benin, Burkina Faso, Mali and Togo in the first three. Cameroonian institutions are documented as offering Islamic products from at least 2015, outside any register.

### Status field

- `verified` (126) — observed in a named primary source at or nearest the reference date.
- `bracketed` (2) — Sierra Leone `ib_regime`, rounds 2011 and 2021 only.

**Sierra Leone was re-sourced on 2026-08-16.** The earlier coding rested on a commercial banking-directory website, which the coding rules class as a last resort. It now rests on two primary documents:

- Bank of Sierra Leone, *Financial Stability Report 2017*, sections 2.1.1–2.1.2 and Table 7, pp. 21–22. Table 7 gives the number of commercial banks for every year from 2012 to 2017 (13, 13, 13, 13, 13, 14) alongside community banks, insurers, bureaux, MFIs and FSAs.
- Bank of Sierra Leone, *Financial Stability Report 2025*, p. 7: thirteen commercial banks, two state-owned, two domestic-private, nine foreign-owned.

A full-text search of both reports — 59 and 72 pages — returns **zero** occurrences of *Islamic*, *Shari*, *sukuk*, *takaful* or *interest-free*. A financial stability review that enumerates every class of institution in the system and never once uses the vocabulary is strong system-level evidence of absence.

It is not a named per-institution roster, so:

| round | as_of | status | why |
|---|---|---|---|
| 2011 | 2010-12-31 | `bracketed` | Table 7 begins at 2012; the historical narrative runs only to 2001 |
| 2014 | 2013-12-31 | `verified`, confidence medium | covered by Table 7 |
| 2017 | 2016-12-31 | `verified`, confidence medium | covered by Table 7 |
| 2021 | 2020-12-31 | `bracketed` | falls between the two reports, both silent |

**The Wayback route is abandoned.** An archived HTML page carries no page number and no publication date of record, and the coding rules require both. Two dated Financial Stability Reports are the stronger source and they are now in hand. Nothing further is outstanding for 2014 and 2017; 2011 and 2021 stay bracketed, disclosed, and do not block publication.

### Divergence between the two variables

Six of fifteen economies break the assumption that framework and regime move together:

| economy | law | first licence | gap |
|---|---|---|---|
| Uganda | 2016 | 2023 | +7 years |
| Tajikistan | 2014 | 2019 | +5 |
| Cameroon | 2022 | activity from 2015 | −7 |
| Mauritania | 2018 | 1985 | −33 |
| Albania | none | 1990s | no framework, decades of activity |
| Guinea | none | 1983 | idem |

Studies that use the presence of Islamic finance regulation as a proxy for its availability mismeasure in both directions, by up to seven years one way and thirty-three the other. **Keep the two variables separate. Do not combine them into a single index.**

---

## 2. `ifsb_ib_share_all_editions.csv`

126 rows: Islamic banking share of total domestic banking assets, by jurisdiction, from four IFSB Islamic Financial Services Industry Stability Reports.

| period | edition | chart | page |
|---|---|---|---|
| 2012E | IFSI SR 2013 | Chart 1.1.1 | 22 |
| 1H2014 | IFSI SR 2015 | Chart 1.1.1.3 | 24 |
| 1H2017 | IFSI SR 2018 | Chart 1.1.2 | 28 |
| 2021 | IFSI SR 2022 | Chart 1.2.1 | 25 |

### `value_source` — provenance, never mix without a flag

- `chart_data_label_verified` (36) — read from numeric labels printed on the bars. 2021 edition only; it is the only edition that labels its bars.
- `body_text` (16) — stated as a number in the surrounding prose.
- `measured_from_bar_geometry` (65) — bar length measured in pixels against the axis. Uncertainty ≈ 0.2 pp.
- `below_measurement_floor` (9) — bar renders at the minimum stroke width; not resolvable even at 600 dpi. `ib_share_pct` is empty and `upper_bound_pct` carries the bound (0.2 for 2012E, 0.25 for 1H2014).

### Validation of the measurement method

The method was checked against every printed value available in the same chart.

- 1H2014, ten anchors excluding Brunei and Kuwait: mean bias **−0.13 pp**, sd 0.02. A small, highly consistent downward offset, now **corrected** — see below.
- 1H2017, four anchors: within 0.15 pp, no systematic direction. **No correction applied.**
- 2012E: no anchors, and since 1H2017 shows no bias the offset is a property of the 1H2014 chart rather than of the method. **No correction applied**; extending it to a period with no anchors would be a guess.

### The level correction, and why it was applied

`ib_share_pct` holds the raw transcription. `ib_share_pct_corrected` adds +0.13 pp to the twelve `measured_from_bar_geometry` rows of 1H2014 and equals the raw value everywhere else. `correction_applied_pp` records what was added. **Analysis uses the corrected column; the deposit keeps both.**

The reason is not precision. Within 1H2014 the thirty-four frame economies split into five whose value was measured (Egypt, Indonesia, Algeria, Azerbaijan, Lebanon) and seven whose value was printed in the prose (Saudi Arabia, Malaysia, UAE, Bangladesh, Jordan, Pakistan, Türkiye). The five sit 0.13 pp below the seven for reasons of provenance alone. That is a **within-period, between-country** offset: it is not constant within a country, so country fixed effects do not absorb it, and it would enter a panel as if it were real cross-country variation.

The correction matters most where values are small. Lebanon moves from 0.30 to 0.43 — a 43% relative change — and the small values are where the African frame members sit.

Iran and Sudan are measured at 100.0 in this period and are **capped at 100.0** rather than corrected to 100.13.

### Two source conflicts to disclose

1. **Brunei and Kuwait, 1H2014.** Prose says 41.0 and 38.0; the bars measure 45.1 and 40.9. The file keeps the printed values, because a number printed by the source outranks a number recovered from its rendering.

   Rank order does not adjudicate here: Saudi Arabia (51.3) sits above both and Yemen (27.4) below both, so prose and measurement imply the same ordering. The discrepancy is 4.1 and 2.9 pp, an order of magnitude beyond the 0.2 pp measurement uncertainty, which is why both are excluded from the bias anchors. The gap is either an internal inconsistency in the source or a rendering artefact specific to those two bars; it cannot be resolved from the published document. Footnote it.
2. **Senegal, 1H2017 = 5.0, not 3.0.** The 2018 report states 5% in the text describing the four newly added jurisdictions. Senegal is flat at 5.0 in both 1H2017 and 2021 — it does not grow. Any earlier file carrying 3.0 must be discarded.

### Near-ties at measurement resolution, 1H2017

Three pairs are transcribed with a value that inverts the chart's own rank order, each by 0.2 pp:

| chart rank | | value | | chart rank | | value |
|---|---|---|---|---|---|---|
| 14 | Pakistan | 11.5 | < | 15 | Oman | 11.7 |
| 18 | Afghanistan | 5.4 | < | 19 | Indonesia | 5.6 |
| 29 | Lebanon | 0.5 | < | 30 | Sri Lanka | 0.7 |

Turkey (rank 20, 5.4) ties Afghanistan at measurement resolution. Rank order in the file is the chart's own order and is authoritative where it conflicts with the measured value. **Do not build on differences smaller than 0.3 pp among these six jurisdictions.**

### `bar_crosses_15pct`

1 if the share exceeds 15%, matching the IFSB's own threshold for domestic systemic importance. Derived from `ib_share_pct`; 0 where the value is empty.

---

## Superseded

Any earlier version of the share file carrying 3.0 for Senegal in 1H2017, or 56.0 / 31.9 / 23.0 / 21.2 / 16.8 / 15.2 for Brunei / Malaysia / UAE / Jordan / Palestine / Oman in 2021, contains eight transcription errors. Delete or rename it so it cannot be picked up by mistake.
