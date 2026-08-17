# Religion-based financial exclusion in OIC economies: a harmonised economy-year dataset from the Global Findex, 2011–2024

**Author:** Achouak Benkaddour, University of Tamanghasset, Algeria
**Version:** 1.0.0 · **Licence:** data and documentation CC BY 4.0; code MIT

---

## What this is

A harmonised economy-year dataset measuring the share of adults who remain
without a financial-institution account **for religious reasons**, built from
five rounds of the World Bank Global Findex microdata (2011, 2014, 2017, 2021,
2024) and covering all economies surveyed, with a flagged balanced frame of
34 OIC member states observed in every round where the outcome exists.

It also carries a hand-coded Islamic banking regime variable for those 34
economies, sourced to central bank and regulator documents, with a citation,
a URL and a consultation date behind every cell.

## What this is not

**These are not the Findex microdata.** The Findex terms of use forbid
redistribution of individual records, and nothing here breaches that. The
deposit contains only economy-year aggregates, the code that produced them,
the variable crosswalk, the decisions log, and SHA-256 checksums of the raw
files used. A reader who wants the microdata downloads them from the World
Bank under the World Bank's own terms; the checksums let them verify they
have the same files this pipeline was built on.

**These are not causal estimates.** The design is repeated cross-sections, not
a panel of individuals: no respondent is observed twice. The religion question
is asked only of the unbanked, so the outcome is observed on a conditionally
selected subsample. Everything computed here is a **conditional association**.
Anyone treating a coefficient from these data as an identified effect is
misreading the design, and the decisions log says so in more detail (D-24, D-26).

---

## Files

### The dataset

| File | Contents |
|---|---|
| `findex_layer2_economy_year.csv` | 709 economy-round cells, 40 fields. The citable output. |
| `findex_layer2_codebook.csv` | Field-by-field definitions. Read this first. |

Three outcome bases are reported side by side rather than one being chosen
silently:

- `relig_A_*` — **primary.** Share citing religion among adults with no
  financial-institution account. This is the World Bank's own published base.
- `relig_B_*` — **robustness.** The same share among the population actually
  routed into the barriers battery. The two bases differ by 3,738–6,388
  respondents per round; the gap is a finding, not noise (D-17).
- `relig_all_*` — the unconditional share of all adults who are both unbanked
  and cite religion.

These satisfy an exact identity, checked in code at build time:

```
relig_all_p = unbanked_answered_share × relig_A_p
```

which separates the **coverage** component (fewer people are unbanked) from
the **composition** component (of those still unbanked, more or fewer cite
religion). The distinction is the point of the exercise. Maximum deviation in
the shipped file: 1.11e-16.

Standard errors are design-based, using the Kish design effect
`deff = n · Σw² / (Σw)²` — the same formula the Findex methodology notes use
for their own published margins of error. Weights are within-economy and sum
to n; `wgt_pooled` rescales them by adult population for cross-economy pooling.

### The code

`01`–`07` run in order. `03_harmonise_round.R` hard-codes no variable names:
every mapping, including its recode expression, is read from
`variable_crosswalk.csv`. Adding a concept costs one crosswalk row per round
and no code change. Set `PROJ_ROOT` to your project directory and place the
raw Findex CSVs under `raw/`.

### The provenance

`journal_decisions.md` records 45 numbered decisions taken during
construction, each with what was decided, why, what was rejected, and what it
binds downstream. Where a judgement could reasonably have gone the other way,
the log says so. It is the longest file in this deposit and the one that makes
the rest auditable.

---

## Things a user should know before using the file

**The religious-reasons item was discontinued in 2024.** All `relig_*` fields
are empty by construction for that round. The outcome series runs 2011–2021
(D-03).

**The 2021 round shifted to telephone fielding.** Every barrier item rises
together in that round — +26% total endorsement in the OIC frame, +15% in the
non-OIC group. This is consistent with a mode effect, not with a real
simultaneous worsening of every barrier at once. Comparisons across the
2017/2021 boundary need the mode change handled explicitly (D-12, D-28).

**Battery composition is not constant.** Item counts move 7 → 9 → 8 → 8 → 6
across rounds, and which items are present changes with them (D-08). Any
share-of-all-reasons measure is affected.

**`fin11e` is not a stable name.** It denotes religious reasons in 2017 and
2021 but "a family member already has an account" in 2024. The religion
variable was identified from the questionnaires in every round, never from
variable names (D-01).

**`female` flips coding.** 1 = male in 2011–2017, 1 = female in 2021–2024.
The crosswalk handles it; anyone building from raw should not assume (D-18).

**Small cells exist.** `relig_A_n` is reported for every cell precisely so
users can filter. Some economy-rounds have very few unbanked respondents
answering the item; the design-based SE will show it, but the `n` column is
the honest first filter.

---

## Islamic banking regime variable

`ib_regime_framework_34_economies.csv` — 272 rows (34 economies × 4 rounds ×
2 variables). Coded from central bank annual reports, financial stability
reports, banking laws and official gazettes; coding rules in
`islamic_banking_regime_CODING_RULES.md`.

Each cell carries a status: `verified` (261), `bracketed` (10), `open` (1).
Bracketed means a defensible range was established but the exact year could
not be pinned to a document. Users who want only firm cells filter on
`verified`.

Two regulatory blocs are coded at bloc level because that is where the legal
authority sits: BCEAO for the six WAEMU members, and COBAC/BEAC for the three
CEMAC members.

---

## Known limitations, stated rather than buried

1. West Bank and Gaza 2011 — official gazette date not established.
2. Azerbaijan 2011 — `ib_regime` open.
3. Lebanon and Iraq 2011 — sourced to last-resort documents under the coding
   rules; weaker than the rest.
4. Egypt 2021 — legal framework judgement contestable.
5. Inter-coder reliability check on a random subsample: pending at v1.0.0.

None of these affects the Findex-derived aggregates in
`findex_layer2_economy_year.csv`, which are produced entirely by code.

---

## Citation

> Benkaddour, A. (2026). *Religion-based financial exclusion in OIC economies:
> a harmonised economy-year dataset from the Global Findex, 2011–2024*
> (Version 1.0.0) [Data set]. Zenodo. https://doi.org/[DOI]

Underlying microdata: Demirgüç-Kunt, A., Klapper, L., Singer, D., & Ansar, S.
*The Global Findex Database.* World Bank. Obtain from the World Bank under
their terms; verify against `checksums_findex_20260815.csv`.

---

## Related work by the same author

IFSB Prudential and Structural Islamic Financial Indicators, harmonised
database — https://doi.org/10.5281/zenodo.21895283
