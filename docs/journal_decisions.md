# Decisions log — Findex-OIC panel

Every entry is dated and written when the decision was taken, not reconstructed afterwards.
Entries are never deleted; superseded ones carry a pointer to the entry that replaced them.


## 2026-08-15 — File discovery
Round files carry inconsistent names (micro_WORLD.csv, micro_world.csv,
micro_world_139countries.csv, findex_microdata_2025_labelled_update112425.csv)
and inconsistent folder depth (four rounds extract to a doubled directory,
2021 does not).
DECISION: files are located by recursive pattern search, never by hard-coded
name or path.
REASON: any script keyed to a fixed name breaks silently on the next round.

## 2026-08-15 — Column growth across rounds
Column counts: 53 (2011), 86 (2014), 105 (2017), 128 (2021), 199 (2024).
DECISION: harmonisation maps each round onto a fixed target schema; variables
absent in a round are recorded as NA with an explicit availability flag.
REASON: the instrument expanded over time; treating absence as missing data
would confuse "not asked" with "not answered".

## 2026-08-15 — No economy code in 2011
The 2011 file has `economy` but no `economycode`; all later rounds have both.
DECISION: ISO3 codes for 2011 are assigned by matching economy names against
the 2014 file, and every unmatched name is resolved manually and logged.
REASON: the country identifier must be consistent across rounds or the panel
cannot be stacked.

## 2026-08-15 — Economy coverage is not constant
Economies per round: 144, 142, 144, 139, 140 — non-monotonic.
DECISION: the panel is unbalanced by construction. The analysis frame is
defined by an explicit rule, and coverage is reported per round.
REASON: silently restricting to economies present in all rounds would drop
countries rather than observations, and would bias toward long-covered ones.

## 2026-08-15 — 2024 file is value-labelled
DECISION: to verify. If labels are text rather than codes, recoding for 2024
differs from the other rounds and must be handled separately.
REASON: mixing labelled and coded values silently produces wrong recodes.

## 2026-08-15 — Round year parsed from path, not from file order

An earlier version of the discovery script matched files to rounds by pairing
the alphabetical order of `list.files()` with a hard-coded year vector. This
happened to give the right answer, but would have failed silently if a file were
added, renamed or moved, misattributing one round's data to another.
DECISION: the round year is extracted from the file path with a regular
expression on the `WLD_<year>_FINDEX` pattern, and the parsed years are printed
and checked before any file is read.
REASON: a silent misalignment between round and data would invalidate every
result downstream and would be almost undetectable after the fact.

## 2026-08-15 — Variable meanings taken from questionnaires, never from names

Column names alone do not establish what a variable measures, who was asked it,
how the answers are coded, or how non-response is distinguished from a negative
answer. This matters most for the religion-based exclusion variable, which is
the study's central measure and is asked only of respondents without an account.
DECISION: for every variable entering the harmonised schema, the question
wording, the routing (who was asked), the response coding and the treatment of
"don't know" and "refused" are read from the round's questionnaire and recorded
in `docs/variable_crosswalk.csv`. No variable is recoded on the basis of its
name or of its coding in another round.
REASON: guessing the coding of the central variable would produce results that
look plausible and are wrong.

## 2026-08-15 — Source documentation downloaded

Questionnaires and survey methodology documents for all five rounds were
downloaded from the World Bank Microdata Library on 15 August 2026 and stored in
`docs/questionnaires/`, renamed to a consistent `<round>_questionnaire.pdf` and
`<round>_methodology.pdf` pattern.
DECISION: harmonisation begins with the 2011 and 2021 rounds — the two extremes
of the instrument's evolution, 2011 being the sparsest (53 variables, no economy
code) and 2021 the most recent round whose coding matches the 2017 and 2024
files. The intermediate rounds are mapped only after these two are reconciled.
REASON: if the mapping holds at both ends of the instrument's development, the
rounds in between are unlikely to introduce a problem that has not already been
met.

---

# 2026-08-15 · step 1: outcome variable identified

## D-01 | Identification rule for all variables
**Decision.** No variable is mapped onto the target schema on the basis of its name. Every mapping is confirmed against the round's own questionnaire, glossary or methodology document, and the confirming document is recorded.
**Evidence that the rule was necessary.** `fin11e` denotes *"Because of religious reasons"* in 2017 and 2021, but denotes *"Reason for no account: family member already has one"* in 2024 (Glossary2024). A name-based merge would have produced a silently wrong series across the two most recent rounds.
**Status.** Binding for the whole pipeline.

---

## D-02 | Outcome variable, confirmed by round

| Round | Variable | Question | Item | Battery size | Confirming document |
|---|---|---|---|---|---|
| 2011 | `q10f` | Q10 | F | 7 (A–G) | Questionnaire2011.pdf |
| 2014 | `q8e` | Q8 | E | 9 (A–I) | Questionnaire2014.pdf |
| 2017 | `fin11e` | FIN11 | E | 8 (A–H) | Questionnaire2017.pdf |
| 2021 | `fin11e` | FIN11 | E | 8 (A–H) | Questionnaire2021.pdf |
| 2024 | **none** | — | — | 6 (A–F) | Questionnaire2024.pdf + Glossary2024.pdf |

The item letter moves between rounds (F in 2011, E from 2014 onward). Positional inference across rounds is therefore prohibited.
**Recorded in.** `docs/religion_variable_confirmation.csv`, `docs/barrier_battery_composition.csv`.

---

## D-03 | The religious-reasons item is discontinued in the 2024/2025 round
**Finding.** The string "religio" does not occur in Questionnaire2024.pdf, Glossary2024.pdf or Methodology2024.pdf. The 2024 barriers battery is defined in Glossary2024 as: `fin11a` too far, `fin11b` fees too expensive, `fin11c` lack documentation, `fin11d` lack money, `fin11e` family member already has one, `fin11f` lack trust. Two items present in 2017 and 2021 were removed: *religious reasons* and *no need for financial services*.
**Verification method.** Full-text extraction of all three 2024 documents followed by case-insensitive search; corroborated by reading the variable definitions in Glossary2024 for `fin11_0`, `fin11_1`, `fin11a`–`fin11f`, `fin11_2`.
**Status.** Confirmed.

---

## D-04 | Analysis window
**Decision.** The outcome panel covers four rounds: 2011, 2014, 2017, 2021. The 2024 round is still harmonised, audited and included in the deposited dataset, but carries no religion outcome; it supplies account ownership, mobile money and digital-payment series as context.
**Consequence.** The paper's window is stated as 2011–2021 in the title or abstract, so that no reader infers an outcome for 2024.
**Alternatives rejected.** (a) Dropping 2024 entirely — forfeits the most recent round in a dataset intended for reuse. (b) Substituting a proxy outcome for 2024 — not the same construct; would break the series.
**Date.** 2026-08-15.

---

## D-05 | Universe of the barriers battery — documented rounds
- **2017.** Asked when NOT(`FIN1`==1 OR `FIN3`==1): no financial-institution account **and** no debit card connected to an account in the respondent's own name.
- **2021.** Asked when NOT(`FIN1`==1 OR `FIN2`==1): no financial-institution account **and** no debit card (name on the account not required).

**Break recorded.** The two rules are not equivalent. A respondent holding a debit card that is not in their own name is routed into the battery in 2017 but not in 2021. The 2017 universe is therefore broader. Since 2017→2021 is the contrast that carries most of the digital-expansion argument, the magnitude of this difference must be measured, not assumed negligible.
**Also recorded.** In both rounds, "don't know" and "refused" on the gating questions route the respondent *into* the battery. The battery universe therefore contains respondents whose account status is not established.

---

## D-06 | Universe of the barriers battery — undocumented rounds (open)
- **2011.** The published instrument contains no skip pattern of any kind. The universe of Q10 is undocumented.
- **2014.** Q8 carries an asterisk; the footnote states: *"Question may be skipped if previous answer reveals that it is not relevant. The questionnaire that includes the skip pattern is available on request."*

**Action.** (a) Request the skip-pattern versions from the World Bank for both rounds. (b) In parallel, determine both universes empirically from the joint missingness pattern of the barrier items against `account`, `account_fin` and the debit-card variable. Whichever arrives first, the other is used as a cross-check, and any disagreement is logged.
**Status.** Open.

---

## D-07 | Denominator — evidence recorded, decision deferred
The World Bank publishes the indicator on two bases (Glossary2017): *"% age 15+"* and *"% without a financial institution account, age 15+"*. Glossary2024 states that country averages shown as a share of adults without an account *"are calculated excluding mobile money accounts."*

**Implication.** The official conditional base is `account_fin == 0`, not `account == 0`. Holders of a mobile money account but no financial-institution account remain in the denominator. Using `account == 0` would exclude precisely the mobile-money adopters whose behaviour the research question concerns.

**To verify before adopting.** Whether `account_fin == 0` coincides exactly with "was routed into the battery". If it does not, the published indicator implicitly treats structurally-unasked respondents as "no", and that imputation must be documented rather than inherited.
**Status.** Evidence recorded; formal decision taken at the denominator stage.

---

## D-08 | Battery-length instability as a threat to the trend
Battery length is 7 (2011), 9 (2014), 8 (2017), 8 (2021). Item composition also changes: "cannot get an account" appears only in 2014; "no need for financial services" appears in 2014–2021 but not 2011.

**Risk.** In a rotated yes/no battery, endorsement of any single item depends on how many alternatives are read. Part of any observed decline in religion endorsement may be an instrument artefact rather than a behavioural change.
**Planned mitigation.** (a) Report religion as a share of all reasons endorsed, alongside the raw rate. (b) Re-estimate on the item set common to all four rounds. Both reported as robustness, not relegated to a footnote.

---

## D-09 | Asymmetry in where religion is offered as a reason
No mobile-money barriers battery in any round offers a religious item: 2021 FIN13_1 has six items (agent distance, cost, documentation, insufficient funds, uses an agent, no own phone); 2024 FIN14A–E has five (agent distance, cost, documentation, insufficient funds, safety concern). The 2021 dormant-account battery FIN10_1 likewise has none.

**Implication for interpretation.** A respondent who objects to conventional banks on religious grounds and then adopts mobile money leaves the battery universe. Measured religious exclusion falls without the objection having changed. The paper must present this as a property of the instrument, and interpret the decomposition
`(religion-citing / all adults) = (unbanked share) × (religion-citing / unbanked)`
so that the coverage component and the composition component are separated.

---

## D-10 | Availability of the remaining target-schema variables

| Concept | Availability | Note |
|---|---|---|
| FI account | all rounds | `account_fin` is the comparable spine; 2011 `account` has no mobile-money component and is **not** comparable to later `account` |
| Mobile money account | 2014–2024 | not asked in 2011 |
| Digital payments | `anydigpayment` 2021, 2024; `pay_onlne` 2017; nothing derived 2014 | either reconstruct from components or accept a shorter series |
| Mobile phone ownership | `mobileowner` 2017, 2021 only | absent in 2024 |
| Internet | `internetaccess` 2021; `internet_use` 2024 | different constructs — kept in separate columns, never merged |
| Urban/rural | `urbanicity_f2f` 2021 (face-to-face samples only); `urbanicity` 2024 | not usable as a panel-wide control |
| Sex, age, education, income quintile | all rounds | `educ` category counts to be verified per round |
| Employment | `emp_in` 2017–2024 | |
| Weight | `wgt` all rounds; `pop_adult` all rounds | see D-11 |

**Also recorded.** In 2011 several questions, including the mobile-phone usage items `q15a1a`–`q15a1c`, carry the footnote *"Question omitted in high income economies."* These are therefore missing for the high-income OIC members (Gulf states, Brunei). They are not used as a mobile-money proxy.

---

## D-11 | Weighting — constraint recorded, decision deferred
Methodology2017 and Methodology2024 both state that `wgt` is constructed to make the sample nationally representative **within each economy**. It carries no cross-economy information.

**Consequence.** Any OIC-wide aggregate requires rescaling by `pop_adult`. A population-weighted aggregate will be dominated by Indonesia, Pakistan, Bangladesh and Nigeria; an economy-equal average answers a different question.
**Rule adopted now.** The weighting choice is made and written into this log *before* any outcome is computed, and both weighted variants are reported in the descriptives.
**Status.** Constraint recorded; choice made at the estimation stage.

---

## D-12 | Comparability risk in the key contrast
With the outcome ending in 2021, the digital-expansion argument rests mainly on 2017→2021. The 2021 round was fielded predominantly by telephone under COVID conditions, with a different mode and sample frame, and `urbanicity_f2f` is populated only for face-to-face samples.

**Planned handling.** 2011→2017 and 2017→2021 are treated as separate contrasts rather than as one trend, and a check is run on whether the mode change alone could generate the observed movement. This is addressed in the design, not only in the limitations section.

---

## D-13 | Scope limit on the Islamic-finance channel
Findex contains no individual-level measure of Islamic financial services. That channel enters only as a country-year covariate (IFSB PSIFIs). With four rounds and the OIC economies that survive the frame rule, the country-year panel is small.
**Consequence.** To be decided at the analysis-frame stage whether the Islamic-finance channel is a headline claim or a descriptive overlay. Recorded now so that the choice is not made implicitly by the estimation code.

---

## D-14 | Files added to docs/
- `docs/religion_variable_confirmation.csv` — outcome variable per round with item wording, battery size, universe rule and confirming source document.
- `docs/barrier_battery_composition.csv` — full item map of the barriers battery across all five rounds.

---

# 2026-08-16 · step-1 diagnostic run

## D-15 | The 2011 file DOES carry an ISO3 code — planned manual name matching is cancelled
The 2011 file contains `ecnmycode` (not `economycode`), populated for all 144 economies, all ISO3-shaped. The problem recorded earlier as "2011 has `economy` but no `economycode`" was a variable-name spelling issue in the source file, not a missing variable.

**Match against 2017:** 129 of 144 codes match directly. Of the 15 that do not, 11 are economies simply not surveyed in 2017 (Angola, Burundi, Comoros, Djibouti, Jamaica, Oman, Qatar, Sudan, Swaziland, Syrian Arab Republic, Yemen). Only **four** are genuine code changes:

| Economy | 2011 & 2014 | 2017 onward |
|---|---|---|
| Congo, Dem. Rep. | `ZAR` | `COD` |
| Kosovo | `KSV` | `XKX` |
| Romania | `ROM` | `ROU` |
| West Bank and Gaza | `WBG` | `PSE` |

**Decision.** Economies are joined on ISO3, never on `economy` name, with a four-row recode applied to the 2011 and 2014 files. The break is between 2014 and 2017, not specific to 2011.
**Cancelled.** The planned manual resolution of unmatched 2011 economy names.

---

## D-16 | Never join on economy names — the name field is encoding-damaged
`economy` in the 2014 and 2021 files contains non-ASCII characters that do not survive a default read on a Windows French locale: "Côte d'Ivoire" and "Türkiye" both read as mojibake. The ISO3 codes (`CIV`, `TUR`) are unaffected.
**Decision.** All merges use ISO3. `economy` is retained as a label only and is refreshed from a single canonical round rather than carried per round.
**Also recorded.** Economy labels drift independently of codes: Turkey → Türkiye → Turkiye; Vietnam → Viet Nam; Czech Republic → Czechia; Swaziland → Eswatini; Macedonia, FYR → North Macedonia. Another reason names cannot be a key.

---

## D-17 | The universe of the barriers battery, established empirically
Source: `docs/diagnostics/05b_universe_margins.csv`. "Asked" = at least one barrier item non-missing.

| Round | n asked | Respondents with no FI account who were NOT asked | Respondents WITH an FI account who WERE asked |
|---|---|---|---|
| 2011 | 74,751 | 866 of 75,185 (`account`==2) | 0 (`account`==1 → asked in 0 cases) |
| 2014 | 68,015 | 0 of 64,277 (`account_fin`==2) | 3,738 |
| 2017 | 68,386 | 0 of 61,998 (`account_fin`==0) | 6,388 |
| 2021 | 54,805 | 0 of 49,497 (`account_fin`==0) | 5,308 |
| 2024 | 22,273 | 25,845 of 48,118 | 0 |

**Finding 1 — the 2011 and 2014 universes are now resolved without the World Bank skip-pattern documents.**
- 2011: no respondent with `account`==1 was asked (0 of 74,138), and no respondent with `q3a`==1 (has a debit card) was asked (0 of 50,457). Respondents answering "don't know" to `account` were asked (432 of 438). The 2011 gate therefore has the same shape as the documented 2021 gate: no account **and** no debit card, with DK/Refused routed in.
- 2014: every respondent with `account_fin`==2 was asked, with no exceptions, and no respondent with `q3`==1 (card in own name) was asked.

**Finding 2 — in every round from 2014 to 2021, the battery universe is strictly LARGER than `account_fin`==0.** Between 3,738 and 6,388 respondents per round were asked why they have no account and are nevertheless coded as account owners. This is consistent with the construction of `account_fin`, which classifies respondents as account owners when they report receiving wages, government transfers or agricultural payments into an account even after answering "no" to FIN1. These respondents denied having an account to the interviewer, gave reasons, and were then reclassified by the derived variable.

**Consequence for the denominator.** The World Bank's published base (`account_fin`==0) contains no structurally unasked respondents, so the official indicator is internally consistent. But it discards 5–9% of the respondents who actually answered the question. The choice is therefore not between a right and a wrong denominator but between two defensible populations, and it must be stated:
- **`account_fin`==0** — comparable to published World Bank figures.
- **"was asked"** — the population that actually answered the question.

**Decision deferred to the denominator stage, but the diagnostic is now sufficient to make it. Both are to be reported.**

**Finding 3 — the 2024 battery was fielded in a subset of economies only.** 46 of 140 economies have zero respondents asked, including all high-income economies and several large African samples (Kenya, Ghana, Tanzania, Uganda, Nigeria partial). Recorded for completeness; it does not affect the outcome panel, which ends in 2021.

---

## D-18 | Suspected coding flip in `female` between 2017 and 2021 — HIGH PRIORITY, unresolved
Glossary2024 defines `female` as **=1 if the respondent is female, =2 if male**. The share coded 1 by round:

| Round | share coded 1 |
|---|---|
| 2011 | 45.9% |
| 2014 | 46.9% |
| 2017 | 46.0% |
| 2021 | 53.2% |
| 2024 | 52.5% |

A seven-point jump in the female share between two rounds of the same survey is not credible. Read with the 2024 definition, the coding is almost certainly **1=male, 2=female in 2011–2017 and 1=female, 2=male in 2021–2024**.

**Risk.** Harmonising `female` on its name alone would invert the sex coefficient for three of the four outcome rounds — a sign error running through every table in the paper, with no error message.
**Action.** Confirm against the variable codebooks for 2011, 2014, 2017 and 2021 before writing `harmonise_round()`. Until confirmed, `female` is recoded per round to an explicit `sex` variable with documented levels, never carried through under its original name.
**Status.** Open. Blocking for the demographic block of the crosswalk.

---

## D-19 | Value coding of the barrier items and demographics
- Barrier items are coded 1=yes, 2=no, 3=don't know, 4=refused in every round. DK and Refused are retained as distinct codes in the harmonised file and are **not** collapsed into "no"; the collapse, if any, is made at the analysis stage and stated there.
- `account` and `account_fin` change coding between rounds: **1/2 in 2011 and 2014, 0/1 from 2017**. Recode per round; never stack on the raw values.
- `educ` is 1–3 substantive with 4=DK and 5=refused in 2011–2021, and 1–3 with missing set to NA in 2024. Recode 4 and 5 to NA in the earlier rounds so the variable means the same thing in all five.
- `inc_q` is a within-economy quintile, 1–5, comparable as-is.
- **Out-of-range value found:** `q8e` (2014) contains a single observation coded **22**. Set to NA and log it.
- `age` is top-coded differently: values run to 99 in 2011–2021 and to 100 in 2024 (279 cases). Verify whether 99 is a missing code in the earlier rounds before using age continuously.

---

## D-20 | Weighting — the constraint is now measured, not assumed
`docs/diagnostics/07_weights_audit.csv`: in every round, `sum(wgt)` within an economy equals the economy's sample size `n` (median ratio exactly 1.0000, no missing weights anywhere), and `pop_adult` is constant within economy. This confirms `wgt` carries no cross-economy information whatsoever.

**Rule adopted.** Any statistic pooled across economies uses `wgt * pop_adult / n_economy`. Any statistic reported for a single economy uses `wgt` alone. The two are labelled distinctly in every table so that a population-weighted OIC figure is never confused with an economy-average one.
**Two anomalies logged:** China 2014 (`sum(wgt)/n` = 1.1225) and United Kingdom 2011 (0.9949). Every other economy-round is 1.0000. The China 2014 cell is flagged for a sensitivity check.

---

## D-21 | Analysis frame — the balanced OIC panel is 34 economies
Source: `docs/oic_frame_coverage.csv`. Against the 57 OIC member states, using the four rounds that carry the religion item:

| Rounds available | Members |
|---|---|
| 4 (balanced frame) | **34** |
| 3 | 7 — Bahrain, Côte d'Ivoire, Kuwait, Morocco, Turkmenistan, Tunisia, Yemen |
| 2 | 4 — Comoros, Iran, Mozambique, Sudan |
| 1 | 7 — Djibouti, Gambia, Libya, Oman, Qatar, Somalia, Syria |
| 0 | 5 — Brunei, Guinea-Bissau, Guyana, Maldives, Suriname |

**Proposed rule (to be confirmed at the analysis-frame stage):** the primary frame is the 34 economies present in all four rounds — 136 economy-round cells — with the unbalanced set reported as a robustness check, and the balanced/unbalanced difference quantified rather than asserted to be immaterial.

**Precision caveat recorded now.** The number of respondents actually asked the battery is small in several frame members: Malaysia falls to 87 in 2021, United Arab Emirates to 134 in 2017, Kazakhstan and Saudi Arabia to 218 in 2021, Türkiye to 263. At n≈90 a country-level rate has a standard error of roughly 3 percentage points before any design effect. Country-year point estimates for these economies cannot support fine-grained claims and are not to be interpreted individually.

---

## D-22 | Correction to the diagnostic script
The first version of `01_diagnose_rounds.R` built the joint universe table with `aggregate()`, which silently drops rows whose grouping variables are NA. Where a gate variable is itself routed (`fin3` in 2017, `q3` in 2014), the joint tables `05_battery_universe_*.csv` therefore understated the totals — the 2014 table summed to 17,817 of 146,688 rows. The one-variable margins in `05b_universe_margins.csv` used `table(useNA="ifany")` and were correct throughout; every finding above rests on `05b`.
**Fixed** in the current script by converting NA to a literal level before aggregation. Re-run to regenerate the joint tables; no conclusion changes.

---

# 2026-08-16 · sex coding resolved, crosswalk built

## D-18 (REVISED) | `female` coding flip — CONFIRMED, no longer suspected
> Revises D-18 above, which recorded the same pattern as suspected but unconfirmed.
Source: `docs/diagnostics/10_female_coding_check.csv`. Calibrated on 2024, where Glossary2024 documents 1 = female.

| Round | code 1 share | code 1 mean age | code 1 in labour force | code 2 in labour force | Female code |
|---|---|---|---|---|---|
| 2011 | 45.9% | 39.92 | — | — | **2** |
| 2014 | 47.0% | 41.27 | — | — | **2** |
| 2017 | 46.0% | 41.54 | 73.3% | 53.7% | **2** |
| 2021 | 53.2% | 41.19 | 57.4% | 75.9% | **1** |
| 2024 | 52.5% | 43.08 | 51.1% | 69.7% | **1** (documented) |

**Three independent signals agree.**
1. *Labour force.* The male–female participation gap is 19.6 points (2017), 18.4 (2021) and 18.6 (2024) — stable, and of the expected sign — only if the female code is 2 in 2017 and 1 in 2021 and 2024.
2. *Mean age.* The female group is the older group in every round, as expected in a 15+ population: code 2 in 2011, 2014, 2017; code 1 in 2021, 2024.
3. *Sex composition.* Once recoded, the female share is 54.1, 53.1, 54.0, 53.2, 52.5 — flat across fifteen years. Read naively from the variable name it would have been 45.9, 46.9, 46.0, 53.2, 52.5, an implausible seven-point jump between two consecutive rounds.

**Conclusion.** `female` is coded **1=male, 2=female in 2011, 2014 and 2017**, and **1=female, 2=male in 2021 and 2024**. The flip occurs between 2017 and 2021.

**Decision.** The harmonised target is renamed **`is_female`** (1=female, 0=male) with a per-round recode, so that the raw variable is never carried through under its original name and no downstream code can silently inherit the wrong convention. This is the same defence adopted for `fin11e` in D-01.

**Impact avoided.** A name-based merge would have inverted the sex coefficient in three of the four outcome rounds — a sign error running through every table, with no error message and no failing test.
**Status.** Closed. The demographic block of the crosswalk is unblocked.

---

## D-23 | Variable crosswalk built — `docs/variable_crosswalk.csv`
30 target variables × 5 rounds = 150 mapping rows. Each row carries the source variable, its raw value coding, an explicit R recode expression, a status, and the document the mapping was confirmed against.

**Status values and their meaning.**
- `available` (107) — mapped and comparable.
- `not_asked` (29) — the concept does not exist in that round's instrument. Distinct from item non-response; must enter the panel as a structural NA and be reported as such.
- `not_comparable` (7) — a variable exists but measures a different construct. `regionwb` (category labels change every round) and 2017 `pay_onlne` (online payment only, narrower than `anydigpayment`). These are deliberately **not** mapped onto a common target.
- `derived` (5) — `asked_barriers`, computed from the battery itself.
- `proxy` (1) — 2011 `account` standing in for `account_fin`, admissible only because mobile money was not measured in 2011.
- `partial` (1) — 2021 `urbanicity_f2f`, populated for face-to-face samples only.

**Rules embedded in the crosswalk.**
- Joins are on `iso3`, never on `economy`; four legacy codes are recoded in 2011 and 2014 (D-15, D-16).
- Barrier items are recoded 1→1, 2→0, and **3 (DK) and 4 (Refused) → NA**, never to 0.
- `account_mob` structural NA stays NA. Recoding it to 0 would convert "not asked in this economy" into "does not have a mobile money account".
- `internet_access` (2021) and `internet_use` (2024) remain separate targets and are never merged.
- `barrier_trust`, `barrier_money` and `barrier_family` change letter position in 2024 relative to 2011–2021; the crosswalk maps by concept, and the letter shift is recorded in the note field.

**Next.** `harmonise_round()` is written to consume this file rather than hard-coding names, so that every mapping decision lives in one auditable table and any change to the crosswalk propagates without editing code.

---

# 2026-08-16 · denominator, frame, comparison group, layer 2

## D-24 | Denominator — DECIDED
**Decision.** Both bases are computed and reported. The primary base is **adults with no financial-institution account** (`account_fin == 0`), which is the World Bank's published base (Glossary2017, Glossary2024). The robustness base is **the population actually routed into the barriers battery**, which per D-17 is 3,738 to 6,388 respondents per round larger.
**Rationale.** The primary base makes every figure directly comparable with published Findex indicators, which a reader of an OIC panel will want to check against. The robustness base is the population that actually answered the question and is reported alongside so that the 5–9% reclassified by the derived variable are visible rather than silently dropped.
**Implementation.** `relig_A_*` (primary) and `relig_B_*` (robustness) in the layer-2 file, each with n, a design-based standard error and a design effect.

---

## D-25 | Analysis frame — DECIDED
**Decision.** The primary estimating sample is the **34 OIC economies present in all four outcome rounds** (136 economy-year cells, 92,961 respondents asked). The unbalanced set is estimated as a robustness check and the difference between the two is quantified in the paper rather than asserted to be immaterial.
**Rationale.** A fixed composition means any movement over time is not a composition effect. The unbalanced set adds Morocco, Tunisia, Côte d'Ivoire, Yemen and others, and is reported precisely because its composition changes.
**Implementation.** `in_balanced_oic_frame` flags the 34. No cell is ever deleted from the deposited file; the frame is applied at estimation.
**Precision caveat carried forward from D-21.** Malaysia 2021 (n=87), United Arab Emirates 2017 (134), Kazakhstan and Saudi Arabia 2021 (218), Türkiye 2021 (263). Country-year point estimates for these cells are not interpreted individually.

---

## D-26 | Comparison group — DECIDED
**Decision.** Non-OIC economies **matched on World Bank income group and region**. 45 non-OIC economies have at least 100 respondents asked in all four rounds, so a matched pool exists.
**Rationale.** Income and region are the two most obvious alternative explanations for any OIC/non-OIC difference. Matching on both means the comparison is not simply a poverty or geography contrast wearing a religious label.
**Sequencing.** The match itself is constructed at the analysis stage, after World Bank income classifications are merged from WDI. The layer-2 file carries `is_oic` and the region field the match will use; it does not hard-code a matched set, so the matching rule stays visible and revisable.

---

## D-27 | Layer 2 built — `deposit/findex_layer2_economy_year.csv`
The deposited, citable output. Economy-year aggregates only; no individual records; unaffected by the Findex redistribution restriction.

**Standard errors** are design-based: `se = sqrt(deff * p(1-p)/n)` with the Kish design effect `deff = n * sum(w^2) / (sum w)^2`. This is the formula the Findex methodology notes use for their own published margins of error, so the uncertainty reported here is constructed the same way as the uncertainty the World Bank reports.

**Decomposition identity.** The file carries the identity that separates the two mechanisms discussed in D-09:

`relig_all_p = unbanked_answered_share x relig_A_p`

the unconditional rate equals the coverage component times the composition component. It is verified to hold to machine precision in every cell, which means any movement in the unconditional rate can be attributed to one component or the other rather than argued about.

**Definitional choice recorded.** `relig_all_p` counts, in its numerator, only respondents who are unbanked on the primary base *and* cite religion, and excludes from its denominator respondents whose religion answer is unknown. Both choices are made so the identity is exact rather than approximate; the alternative (counting religion citations from the wider battery universe) leaves a residual of up to 3 percentage points that would then have to be explained in every table.

**2024** appears in the file with all context indicators populated and all religion fields empty by construction, per D-03 and D-04.

---

# 2026-08-16 · first descriptive result

## D-28 | First descriptive result, and the diagnostic that qualifies it

**Layer 2 verified.** 709 economy-year cells, 40 fields. The decomposition identity holds to 1.11e-16. Design effects range 1.00 to 2.63, median 1.377 — the sampling design roughly doubles the variance relative to simple random sampling, so unadjusted standard errors would have been understated by about 17%.

### The headline decomposition, balanced OIC frame, population-weighted

| | 2011 | 2014 | 2017 | 2021 | 2011→2021 |
|---|---|---|---|---|---|
| coverage component: unbanked share | 0.745 | 0.679 | 0.598 | 0.595 | **−0.150** |
| composition component: religion \| unbanked | 0.061 | 0.093 | 0.079 | 0.091 | **+0.030** |
| unconditional: product | 0.046 | 0.063 | 0.049 | 0.054 | **+0.009** |

Financial coverage improved substantially. The share of the unbanked citing religion did not fall — it rose — and the unconditional rate rose with it. 25 of the 34 frame economies rose; the direction survives excluding Indonesia, Pakistan, Bangladesh and Nigeria, and survives economy-equal weighting (0.085 → 0.107).

**Read naively, the answer to the research question is: no, expansion did not reduce religion-based exclusion; measured exclusion rose.** The diagnostics below show why that sentence cannot be written as it stands.

### The diagnostic that qualifies it: every barrier rose

Population-weighted, balanced OIC frame, primary base:

| item | 2011 | 2014 | 2017 | 2021 |
|---|---|---|---|---|
| too far | 0.226 | 0.248 | 0.211 | 0.290 |
| too expensive | 0.291 | 0.284 | 0.249 | 0.378 |
| documentation | 0.224 | 0.219 | 0.203 | 0.281 |
| lack of trust | 0.130 | 0.135 | 0.130 | 0.191 |
| not enough money | 0.749 | 0.678 | 0.629 | 0.701 |
| family has account | 0.138 | 0.204 | 0.235 | 0.264 |
| **religion** | **0.061** | **0.093** | **0.079** | **0.091** |
| sum of the 7 common items | 1.819 | 1.862 | 1.737 | **2.196** |
| **religion / sum** | **0.034** | **0.050** | **0.045** | **0.042** |

Total endorsement rises 26% between 2017 and 2021. Every item moves up together. Normalised by total endorsement, religion peaks in **2014** and drifts **downward** thereafter. The raw rise and the normalised path tell different stories, and the difference is concentrated in 2021.

### The non-OIC comparison makes the 2021 round harder to defend

45 non-OIC economies with at least 100 respondents asked in all four rounds:

| | 2011 | 2014 | 2017 | 2021 |
|---|---|---|---|---|
| OIC religion rate | 0.061 | 0.093 | 0.079 | 0.091 |
| non-OIC religion rate | 0.033 | 0.034 | 0.047 | **0.096** |
| OIC religion / sum | 0.034 | 0.050 | 0.045 | 0.042 |
| non-OIC religion / sum | 0.020 | 0.020 | 0.024 | **0.043** |

By 2021 the two groups have converged. The non-OIC 2021 figure is driven by India (0.142), China (0.068), Brazil (0.132), the Philippines (0.140), Colombia (0.119) and Madagascar (0.205). Values of that size are not credible as genuine religious objection to conventional banking in Brazil, Colombia, the Philippines or China. Total endorsement also rises in the non-OIC group (+15% from 2017 to 2021), so the elevation is not OIC-specific.

**Conclusion recorded.** The 2021 round shows a general upward shift in barrier endorsement across items and across country groups, consistent with the mode change flagged in D-12 (predominantly telephone fielding under COVID conditions). The 2021 religion figure cannot carry the weight of a headline claim.

### What survives

1. Financial coverage in the OIC frame improved markedly, 2011 to 2021: the unbanked share fell 15 percentage points.
2. Over the same period there is **no evidence of a decline** in religion-based exclusion on any measure — raw, normalised, conditional or unconditional.
3. The cleanest window is **2011 to 2017**, where the mode is constant. Over it, the OIC normalised religion share rose from 0.034 to 0.045 while the non-OIC share rose only from 0.020 to 0.024. Coverage expanded; the religious barrier did not recede with it.
4. Any statement about 2017 to 2021 must be accompanied by the total-endorsement series, so that the reader can see that the religion item moved with everything else rather than on its own.

**Action.** The share-of-all-reasons normalisation planned in D-08 as a robustness check is promoted to a **co-primary measure**, reported beside the raw rate in every table. The total-endorsement series is reported as a diagnostic column, not relegated to an appendix.

---

## D-29 | Design challenge recorded: OIC membership is a weak proxy for the mechanism (OPEN)
> **Resolved later the same day — see D-29 (RESOLVED) below.** Both entries are kept so the reasoning is traceable.

The theoretically relevant variable is the Muslim share of the adult population, or individual religious affiliation. Findex measures neither. OIC membership is an institutional grouping that maps onto the mechanism imperfectly in both directions: Albania and Azerbaijan are OIC members with highly secular financial cultures, while India, Ethiopia, Tanzania and Kenya are non-members with very large Muslim populations. India alone contributes the single largest share of the non-OIC 2021 religion figure.

**Consequence.** An OIC versus matched non-OIC contrast risks being a comparison of institutional membership rather than of the mechanism under study, and matching on income group and region (D-26) does not address it, because Muslim population share is not correlated with either in a way that matching would absorb.

**Options to be decided.**
1. Retain OIC as the institutional frame — it is the policy-relevant grouping and the one the IFSB PSIFIs data is organised around — and add Muslim population share (Pew Research religious composition data) as a continuous country-level covariate. The OIC dummy then tests institutional membership and the share tests the mechanism, separately.
2. Replace the OIC frame with a Muslim-population-share frame, keeping OIC only as a robustness split.
3. Retain the OIC frame unchanged and treat the mismatch as a stated limitation.

**Status.** Open. This decision affects the covariate merge and must be taken before the IFSB, IMF FAS, WDI and WGI merge is specified.

---

# 2026-08-16 · estimand and specification settled

## D-29 (RESOLVED) | OIC frame retained; Muslim population share added as the mechanism variable
> **Partly overtaken by D-43.** The assumption below that the Islamic-finance channel is too static for a within-country regressor holds for `ib_regime` and fails for `ib_legal_framework`.
**Decision.** Option 1. The OIC frame is kept — it is the policy-relevant grouping and the one the IFSB PSIFIs data is organised around — and the Muslim share of the adult population (Pew Research religious composition) is merged as a country-level covariate.

**Qualification that changes how it is used.** Under country fixed effects, which the panel design requires, both the OIC dummy and Muslim share are absorbed: they are time-invariant. Neither can be a main effect in the primary specification. Muslim share therefore enters **only as an interaction** with the time-varying mechanism variables (Islamic-finance depth from IFSB PSIFIs, mobile money and digital payment penetration). The OIC dummy survives only in a pooled between-country specification reported as a secondary table.
**Status.** Closed.

---

## D-30 | Estimand — religion's relative salience within the battery, not its raw level
**Problem.** D-28 established that the 2021 round lifts every barrier item together (+26% in the OIC frame, +15% in the non-OIC group), consistent with the mode change in D-12. Raw levels are therefore not comparable across the 2017/2021 boundary.

**Decision.** The primary outcome is **religion's share of total barrier endorsement** — the religion item divided by the sum of the items common to all four rounds. Any shift that scales all items proportionally, whether from acquiescence, interviewer mode or translation, cancels in this ratio. The raw conditional rate remains a co-reported measure, and the total-endorsement series is reported as a visible diagnostic column in every table, not in an appendix.

**Consequence for the claim.** The paper does not claim to measure the level of religious exclusion over time. It claims to measure whether religion became more or less salient relative to other reported barriers, as coverage expanded. That is a narrower claim and the data can carry it.

---

## D-31 | What the paper does NOT do
Recorded so that these omissions are deliberate rather than discovered by a referee.

- **No OIC versus matched non-OIC headline contrast.** The non-OIC group is contaminated by economies with very large Muslim populations — India alone is the largest single contributor to the non-OIC 2021 religion figure — and matching on income and region does not absorb this. The non-OIC group is retained for one purpose only: as a **placebo showing that the 2021 instrument shift is global rather than OIC-specific**. That is its most informative use.
- **No urban/rural control.** Available in at most one usable round (D-10).
- **No internet covariate.** `internetaccess` exists in 2021 only and `internet_use` in 2024 only, and they are different constructs.
- **No individual-level causal claim.** Individual covariates are used for a descriptive profile of who cites religion. The mechanism is country-level and is estimated at country-year level.
- **No 2024 outcome.** The item was discontinued (D-03).

---

## D-32 | Specification and its honest limits
> **Refined by D-43**, which counts the identifying switches and shows that ten of the fifteen fall at the contaminated 2017→2021 boundary.
**Primary.** Country-year panel, 34 OIC economies x 4 rounds = 136 cells. Country fixed effects and round fixed effects. Identifying variation is the within-country change in Islamic-finance depth and digital penetration. Standard errors clustered by country.

**Limit recorded now, before estimation.** 34 clusters is below the range where cluster-robust standard errors are reliable. Inference uses the **wild cluster bootstrap**; asymptotic cluster-robust p-values are not reported as primary. With 34 country effects and 4 round effects, roughly 98 degrees of freedom remain, so the covariate set is kept deliberately small.

**Framing.** Results are reported as conditional associations. The design is repeated cross-sections with an outcome observed only for a conditionally selected subsample, and no part of it supports a causal claim. This was already stated in the project constraints and is repeated here so that no table is written as though it were otherwise.

---

# 2026-08-16 · Islamic banking regime coding rules

## D-33 | Timing rule — CONFIRMED, and it was already binding
The rule was fixed when the coding template was created: every cell is coded **as of 31 December of the year before the round**. The `as_of_date` column carries it row by row (2010-12-31, 2013-12-31, 2016-12-31, 2020-12-31).

**Tajikistan 2014 is therefore 0 on both variables.** Law No. 1108 was adopted 26 July 2014 and entered into force 5 August 2014, after the 2013-12-31 reference date.

**Why the rule, and not fieldwork date.** Findex fieldwork months differ across economies within the same round. A fieldwork-date rule would code the same law differently for two countries in the same round, purely because one was surveyed in March and the other in November. The year-end rule is uniform, predetermined, and rules out reverse causality by construction. That it costs Tajikistan a cell over two months is the price of a rule that cannot be argued with case by case — which is the point of having one.

**Status.** Closed. No cell is re-argued on timing.

---

## D-34 | Scope of `ib_regime` — banking supervisor's register only
**Decision.** An institution counts only if it appears in the **banking supervisor's register of licensed institutions**. Islamic leasing companies, credit-only microfinance providers and capital-market entities are out of scope.

**Tajikistan consequence.** Asr Leasing (Islamic leasing, 2013) and Alif Capital (Islamic microfinance, 2014) are excluded. Tajikistan's `ib_regime` becomes 2 only from the 2019 licence to Tawhidbank, so the 2017 cell stays 0.

**Why this line and not a broader one.** The broader alternative — count anything offering a Sharia-compliant account, which would follow the Findex account definition more closely — cannot be applied uniformly. Bank licensing registers exist for all nine regulators in the source list; microfinance registers do not, and product-level information for small institutions is undocumented across most of the 34 economies. A rule that can only be applied to the countries with good documentation produces a variable whose coverage correlates with state capacity.

**Stated limitation.** The variable measures Sharia-compliant provision **in the licensed banking sector**. Non-bank provision is out of scope and the variable therefore under-counts, in a known direction, uniformly. This is stated in the paper rather than left for a referee to find.

---

## D-35 | `ib_legal_framework` — a dedicated instrument, not an enabling clause
**Decision.** `ib_legal_framework` = 1 only where a **dedicated** Islamic banking law, act, or central bank regulation exists. A single enabling article inside a general banking law is **0**.

**Guinea = 0 in all four rounds.** Provision rests on Article 80 of the general banking law alone. Baldé (2025, RAFI 9(1), 51–67) documents the absence of a dedicated instrument, of sukuk regulation and of specialised supervision, with the sector at 2.3% of banking assets in 2022.

**Guinea `ib_regime` = 2 in all four rounds.** Banque Islamique de Guinée, founded 1983, appears as entry 04 in the BCRG register of licensed banks.

**The decisive argument is consistency, not Guinea.** Albania was already coded 0 on exactly this fact pattern: United Bank of Albania operates under general law 9662/2006 with no dedicated Islamic banking text. Coding Guinea 1 would mean the same criterion produces two different codes. The criterion governs; the country does not.

**Sensitivity.** A robustness run with Guinea at 1 is reported. It cannot change the primary specification: Guinea's value is constant across all four rounds, so country fixed effects absorb it entirely. The choice affects only the between-country and heterogeneity-split uses.

---

## D-36 | The framework/regime dissociation is a result, not a coding nuisance
> **Extended by D-41.** The pattern below was drawn from the first sixteen economies; the completed thirty-four add Saudi Arabia, Egypt and Azerbaijan, all with standalone licensed Islamic banks in every round and no dedicated instrument in three or four of them.
Six of the fifteen economies checked so far break the assumption that legal framework and actual provision move together:

| | dedicated law | first licence | gap |
|---|---|---|---|
| Uganda | 2016 | 2023 | +7 years |
| Tajikistan | 2014 | 2019 | +5 |
| Cameroon | 2022 | activity since 2015 | −7 |
| Mauritania | 2018 | 1985 | −33 |
| Albania | none | 1990s | law never arrived |
| Guinea | none | 1983 | law never arrived |

Two economies have operated Islamic banks for decades with no dedicated instrument at all.

**Consequence for the literature.** Studies that proxy Islamic finance *availability* with the existence of Islamic finance *regulation* are mismeasuring in both directions, and the error is not small: seven years in one direction, thirty-three in the other. The two variables are kept separate throughout and never collapsed into a single "Islamic finance" indicator.

**Where this belongs.** This is a finding of the measurement paper (paper 1 in `research_agenda_note_20260816.md`), not a footnote in the substantive paper.

---

## D-37 | Sierra Leone — recorded as low confidence, not as zero
> **SUPERSEDED BY D-39 (same day).** Retained because the reasoning that led to the low-confidence flag is part of the record; the coding it describes is no longer current.
`ib_legal_framework` = 0 is firm: the IsDB issued a 2026 consultancy tender for the Bank of Sierra Leone covering gap analysis of existing law and drafting of a full prudential package including licensing, capital adequacy and window requirements. Nothing that exists is drafted.

`ib_regime` = 0 is **low confidence**. No Islamic bank or window was found; no explicit denial was found either. Absence of evidence is not evidence of absence — the same error identified for Mauritania, which appears in the IFSB 2024 chart at 43.7% and in none of the earlier ones.

**Action before publication.** Check the Bank of Sierra Leone list of licensed banks for each reference year via the Wayback Machine, which archives bsl.gov.sl/banks.html from 2012. The cell keeps its low-confidence flag until that check is done.

---

# 2026-08-16 · corrections and re-sourcing

## D-38 | Level correction applied to 1H2014 measured values
`ib_share_pct_corrected` = `ib_share_pct` + 0.13 pp for the twelve `measured_from_bar_geometry` rows of 1H2014, and equal to the raw value everywhere else. `correction_applied_pp` records the addition. Iran and Sudan, measured at 100.0, are capped rather than corrected to 100.13.

**Reason — not precision, comparability.** Within 1H2014 the frame splits by provenance: five economies measured from bar geometry (Egypt, Indonesia, Algeria, Azerbaijan, Lebanon) and seven read from the prose (Saudi Arabia, Malaysia, UAE, Bangladesh, Jordan, Pakistan, Türkiye). The measured five sit 0.13 pp below the printed seven for reasons of extraction method alone. That offset is **within-period and between-country**: it is not constant within a country, so country fixed effects do not absorb it, and it would enter the panel as apparent cross-country variation.

The correction bites hardest where values are small — Lebanon moves 0.30 → 0.43, a 43% relative change — and small values are where the African frame members sit.

**Not extended to 2012E.** The 1H2017 anchors show no systematic bias, so the offset belongs to the 1H2014 chart, not to the method. Applying it to a period with no anchors would be a guess.

**Raw column retained.** The deposit keeps what was measured; the analysis uses the corrected column.

---

## D-39 | Sierra Leone re-sourced from the Bank of Sierra Leone Financial Stability Reports
The earlier coding rested on a commercial banking-directory website — a last-resort source under the coding rules. It now rests on two primary documents:

- *Financial Stability Report 2017*, sections 2.1.1–2.1.2 and Table 7, pp. 21–22: the number of institutions of every class for each year 2012–2017 (commercial banks 13, 13, 13, 13, 13, 14).
- *Financial Stability Report 2025*, p. 7: thirteen commercial banks, two state-owned, two domestic-private, nine foreign-owned.

Full-text search of both reports, 59 and 72 pages, returns **zero** occurrences of *Islamic*, *Shari*, *sukuk*, *takaful* or *interest-free*.

| round | status | reason |
|---|---|---|
| 2014 | `verified`, medium | reference year covered by Table 7 |
| 2017 | `verified`, medium | reference year covered by Table 7 |
| 2011 | `bracketed` | Table 7 starts at 2012; narrative ends at 2001 |
| 2021 | `bracketed` | falls between the two reports, both silent |

Confidence is **medium, not high**, because the evidence is system-level — a bank count for the year plus complete silence on Islamic finance in a full stability review — and not a named per-institution roster. The distinction is recorded rather than smoothed over.

Bracketed cells fall from four to two, and every remaining one rests on primary sources on both sides.

**The Wayback route is abandoned, on grounds of source quality rather than difficulty.** An archived HTML page carries no page number and no publication date of record; the coding rules require both. Two dated Financial Stability Reports are the stronger source.

---

## D-40 | Third rank inversion recorded, and a justification corrected
**Lebanon (rank 29, 0.5) and Sri Lanka (rank 30, 0.7) in 1H2017** invert the chart's own order by 0.2 pp. Found by an automated rank-versus-value check; it was absent from the near-ties list, which had recorded only Pakistan/Oman and Afghanistan/Indonesia/Türkiye. Six jurisdictions in 1H2017 are now flagged, and chart rank order is authoritative wherever it conflicts with the measured value.

**Brunei and Kuwait, 1H2014 — reasoning replaced.** The note claimed the chart's rank order matched the measurement rather than the prose. It does not adjudicate: Saudi Arabia (51.3) sits above both and Yemen (27.4) below both, so both readings imply the same ordering. The decision to keep the printed values stands on its own ground — a number printed by the source outranks a number recovered from its rendering — and the 4.1 and 2.9 pp discrepancies, an order of magnitude beyond the 0.2 pp measurement uncertainty, are why both are excluded from the bias anchors.

A correct decision resting on a reason that does not hold is still a defect, and it is the kind a referee finds.

---

# 2026-08-16 · Islamic banking coding completed for all 34 economies

## D-41 | Islamic banking coding complete for all 34 economies — `docs/ib_regime_framework_34_economies.csv`
272 rows: 34 economies × 4 rounds × 2 variables. 261 `verified`, 10 `bracketed`, 1 `open`, none `lead_only`. Every valued cell carries a citation and a coding date.

Five economies show an in-window change in `ib_legal_framework` among the eighteen coded last: Nigeria (CBN NIFI Framework, 13.01.2011), Iraq (Law No. 43 of 2015), Algeria (Règlement 20-02, 15.03.2020), Saudi Arabia (SAMA Circular 41042498, 12.02.2020) and Türkiye (BDDK Tebliğ, RG 30888, 14.09.2019). The handoff had anticipated three; Saudi Arabia and Türkiye were found in the coding.

---

## D-42 | Correction: the IFSB-share inference over-coded three cells
When the eighteen-economy template was pre-filled, `ib_regime = 2` was assigned wherever the IFSB recorded a positive share of domestic banking assets, on the reasoning that a measurable share cannot exist without licensed Islamic banks.

**That inference separates 2 from 0. It does not separate 2 from 1.** A market served entirely by Islamic windows of conventional banks produces a measurable share and no standalone licensed Islamic bank. In markets with a dedicated licensing regime for windows, the distinction is observable, and the share cannot make it.

Three cells were corrected against the banking register, per D-34:

| cell | was | now | evidence |
|---|---|---|---|
| Afghanistan 2017 | 2 | **1** | Islamic Bank of Afghanistan licensed 2018-04-09, after the 2016-12-31 reference date; windows permitted from 2015 |
| Kyrgyz Republic 2017 | 2 | **1** | EcoIslamicBank transformed 2017-06-22 (NBKR licence 040), after 2016-12-31; windows from 2009 |
| Azerbaijan 2014 | 2 | **1** | the 1.0% IFSB share derives from the International Bank of Azerbaijan's *window*, not a standalone bank |

The error was mine, introduced in the pre-fill; the coder identified it and flagged rather than silently changed the cells, which is the correct handling of someone else's verified rows.

**Rule now explicit.** The IFSB share may establish `ib_regime ≥ 1`. It may never establish 2 on its own. Where the value 2 matters, the banking register decides.

The correction *increases* identifying variation: Afghanistan and the Kyrgyz Republic move from 1/1/2/2 to 1/1/1/2, so their regime change now coincides with the last round rather than the third.

---

## D-43 | Which variable can carry the specification — the answer is the opposite of what was expected

| variable | economies varying within country |
|---|---|
| `ib_regime` | **5** of 34 — AFG, AZE, KGZ, NGA, TJK |
| `ib_legal_framework` | **15** of 34 |

D-29 assumed the Islamic-finance channel would be too static for a within-country regressor and relegated it to a heterogeneity split. That holds for `ib_regime`, which varies in five economies and stays a split. It does **not** hold for `ib_legal_framework`, which varies in fifteen.

**But fifteen switches are not fifteen events.** Six of them — Benin, Burkina Faso, Mali, Niger, Senegal, Togo — are one instrument: BCEAO Instruction 002-03-2018 of 21 March 2018, applying simultaneously across the West African monetary union. For identification these six are one shock, not six.

**And the timing is worse than the count.** Ten of the fifteen switches fall at the 2017→2021 boundary: the six BCEAO economies, plus Mauritania, Algeria, Saudi Arabia and Türkiye. That is precisely the boundary D-28 established as contaminated by the change to telephone fielding, and D-30 responded to by making the outcome a within-battery ratio.

Only **five** switches fall inside the mode-stable 2011–2017 window: Afghanistan, Iraq, Nigeria, Tajikistan and Uganda.

**Consequence for the specification.** The framework channel is estimated on roughly five independent regulatory events in the clean window, and on a further set at a boundary where the instrument itself moved. It is reported as a descriptive association with the number of identifying switches stated in the table, not as an effect. The BCEAO bloc is never counted as six independent observations; a specification treating the monetary union as one cluster is reported alongside.

Recorded before estimation so that no specification is chosen after seeing which one gives a result.

---

## D-44 | Two borderline judgements, both creating variation in the same round
Two of the five in-window framework changes rest on a judgement at the D-35 threshold, and both fall in 2021.

**Türkiye.** Between the repeal of the 1983 Special Finance Houses decree and the BDDK Tebliğ of 14.09.2019, participation banks were one of three statutory bank categories inside general Banking Law 5411, with no dedicated chapter. More than Guinea's single article, less than Jordan's chapter. The conservative rule gives 0 before 2019, so Türkiye switches at 2021. **Coded 1 in all four rounds instead, the switch disappears.**

**Saudi Arabia.** SAMA's Shariah Governance Framework of 12.02.2020 is a central bank instrument issued specifically for Islamic banking, which satisfies D-35 as written. It is a governance instrument rather than a licensing or prudential one, and Saudi Arabia has no Islamic banking statute at all. **Coded 0 throughout instead, the switch disappears.**

Two borderline calls both producing variation in the final round is a pattern a referee will notice. Both are reported as sensitivities in the same line, and the main result is shown with and without them.

---

## D-45 | Open items carried into the paper
- **West Bank and Gaza 2011, `ib_legal_framework`** — `bracketed`. Decree-Law 9/2010 was signed 08.11.2010 and enters into force on publication in *al-Waqāʾiʿ al-Filasṭīniyya*; the gazette date could not be established. Fifty-three days separate signature from the 2010-12-31 reference date. If publication fell after it, the cell is 0.
- **Azerbaijan 2011, `ib_regime`** — `open`. No source covers the CBA register at 2010-12-31. Not coded 0 (D-39).
- **Lebanon 2011 and Iraq 2011, `ib_regime`** — rest partly on last-resort sources, flagged in `note`, confidence medium.
- **Egypt 2021, `ib_legal_framework`** — coded 0. Law 194/2020 contains Islamic-banking provisions including a CBE Supreme Sharia Advisory Board; if those form a dedicated chapter the cell moves to 1.
- **Reliability check not yet run.** Rules §8 requires re-coding a random 20 cells at least a week later without consulting the first pass, and reporting the agreement rate.
