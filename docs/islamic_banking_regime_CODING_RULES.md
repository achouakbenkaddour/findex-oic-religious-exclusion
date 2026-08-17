# Coding rules — `islamic_banking_regime.csv`
**Purpose.** A hand-coded Islamic banking regime variable covering all 136 cells of the balanced OIC frame (34 economies x 4 outcome rounds), replacing the continuous PSIFIs depth measure which covers 0, 13, 14 and 15 of the 34 economies in 2011, 2014, 2017 and 2021 respectively.

## Timing rule
Each cell is coded **as of 31 December of the year before the Findex round** (`as_of_date`). Coding a predetermined state rules out the possibility that the regime responded to the same conditions that produced the outcome. Apply the rule even where it feels conservative; a rule applied inconsistently is worse than a conservative one.

## `ib_regime` — three levels
| value | meaning |
|---|---|
| 0 | No licensed Islamic banking activity in the jurisdiction |
| 1 | Islamic windows only — conventional banks offering Sharia-compliant products, no standalone licensed Islamic bank |
| 2 | At least one standalone licensed Islamic bank |

Code what the regulator permitted and what existed on `as_of_date`, not what was announced or planned. A licence granted in March 2018 does not affect the 2017 round.

## `ib_legal_framework` — binary
1 if a dedicated Islamic banking law, act, or central bank regulation existed on `as_of_date`; 0 otherwise. A country may have 1 here and 0 on `ib_regime` (framework enacted, no bank yet operating) — that combination is informative and should not be smoothed away.

## Sources, in order of preference
1. Central bank licensing registers and annual reports (primary; cite the page).
2. IFSB membership records and country reports, with the date of accession.
3. IMF Article IV staff reports and Financial Sector Assessment Programs.
4. World Bank / IsDB Islamic finance country reports.

Secondary compilations and news articles are last resort and must be flagged in `coder_note`.

## Documentation requirements
Every non-empty `ib_regime` needs `source_type`, `source_citation`, `source_url` and `source_consulted_on`. A cell without a source is not coded; leave it blank rather than guessing, and list it as an open item. The credibility of a hand-coded variable rests entirely on this column being complete.

Where the correct code is genuinely ambiguous, record the ambiguity in `coder_note` and code the more conservative value (the lower level). Do not resolve ambiguity silently.

## Validation against PSIFIs
`psifis_available` flags the 15 economies with PSIFIs banking data in 2021. After coding, regress or cross-tabulate `ib_regime` against the Islamic banking asset share from `IFSB-DataHub/clean/master_panel.rds` for those economies. A hand-coded variable that tracks the measured depth where both exist is validated; one that does not is a finding in itself and must be reported.

## Reliability
Code the 136 cells once, then re-code a random 20 cells at least a week later without consulting the first pass, and report the agreement rate. If a second coder is available, use one. An unreported reliability check is not a check.
