# =============================================================================
# 01_diagnose_rounds.R
# Project : Global Findex — harmonised OIC panel of religion-based financial
#           exclusion
# Purpose : Step-1 diagnostic, run BEFORE any harmonisation code is written.
#           Establishes, from the data itself:
#             (1) whether the 2011 file already carries an ISO3 code
#                 (inventory shows a variable spelled `ecnmycode`);
#             (2) the universe of the barriers battery in 2011 and 2014,
#                 which the published instruments do not document;
#             (3) whether "was asked the battery" coincides with
#                 account_fin == 0, i.e. the World Bank's published denominator;
#             (4) how the 2024 file is coded (labelled strings vs numeric);
#             (5) the behaviour of the sampling weight within each economy.
#
# LICENCE NOTE: this script writes AGGREGATE TABLES ONLY — counts, frequencies
# and per-economy totals. No row-level microdata is written to disk at any
# point. Every file in OUT_DIR is safe to share and to deposit.
#
# Author : A. Benkaddour
# Created: 2026-08-16
# R      : base R; data.table used only if installed (for speed)
# =============================================================================

## ---- 0. Configuration -------------------------------------------------------

PROJ_ROOT <- "D:/findex-oic"                       # <- edit if the project moves
RAW_DIR   <- file.path(PROJ_ROOT, "raw")
OUT_DIR   <- file.path(PROJ_ROOT, "docs", "diagnostics")

# If a round's folder contains more than one .csv, the script stops rather than
# guessing. Resolve it by naming the correct file here, e.g.
#   FILE_OVERRIDE <- list(`2024` = "D:/findex-oic/raw/.../findex_microdata_2025_labelled_update112425.csv")
FILE_OVERRIDE <- list()

ROUNDS <- c(2011L, 2014L, 2017L, 2021L, 2024L)

dir.create(OUT_DIR, recursive = TRUE, showWarnings = FALSE)

has_dt <- requireNamespace("data.table", quietly = TRUE)
message("data.table available: ", has_dt)

log_lines <- character(0)
say <- function(...) {
  txt <- paste0(...)
  message(txt)
  log_lines <<- c(log_lines, txt)
}

wr <- function(df, name) {
  utils::write.csv(df, file.path(OUT_DIR, name), row.names = FALSE, na = "")
  say("  written: ", name, "  (", nrow(df), " rows)")
}

## ---- 1. Locate one file per round, by path pattern, never by ordering -------

all_csv <- list.files(RAW_DIR, pattern = "\\.csv$", recursive = TRUE,
                      full.names = TRUE, ignore.case = TRUE)
if (!length(all_csv)) stop("No .csv found under ", RAW_DIR)

# The round year is read from the World Bank folder token WLD_<year>_FINDEX.
# It is never taken from the file name (the 2024 file name contains 2025 and a
# date stamp) and never from the order in which files are listed.
round_from_path <- function(p) {
  m <- regmatches(p, regexpr("WLD_[0-9]{4}_FINDEX", p, ignore.case = TRUE))
  if (!length(m)) return(NA_integer_)
  as.integer(sub("^WLD_([0-9]{4})_FINDEX$", "\\1", m, ignore.case = TRUE))
}
csv_round <- vapply(all_csv, round_from_path, integer(1), USE.NAMES = FALSE)

files_tbl <- data.frame(
  round     = csv_round,
  path      = all_csv,
  size_mb   = round(file.info(all_csv)$size / 1024^2, 2),
  stringsAsFactors = FALSE
)

unmatched <- files_tbl[is.na(files_tbl$round), ]
if (nrow(unmatched)) {
  say("NOTE: ", nrow(unmatched), " csv file(s) carry no WLD_<year>_FINDEX token ",
      "and are ignored. Listed in 01_files_located.csv with round = NA.")
}

round_file <- setNames(rep(NA_character_, length(ROUNDS)), as.character(ROUNDS))
for (r in ROUNDS) {
  key <- as.character(r)
  if (!is.null(FILE_OVERRIDE[[key]])) {
    round_file[key] <- FILE_OVERRIDE[[key]]
    next
  }
  cand <- files_tbl$path[!is.na(files_tbl$round) & files_tbl$round == r]
  if (length(cand) == 0L) {
    stop("Round ", r, ": no file found under ", RAW_DIR)
  } else if (length(cand) > 1L) {
    stop("Round ", r, ": ", length(cand), " candidate files found. ",
         "Set FILE_OVERRIDE[['", r, "']] to the correct one.\n  ",
         paste(cand, collapse = "\n  "))
  }
  round_file[key] <- cand
}
files_tbl$selected <- files_tbl$path %in% round_file
wr(files_tbl, "01_files_located.csv")

## ---- 2. Target-schema map, confirmed against the instruments ----------------
# concept  : the harmonised concept
# variable : the variable name in THAT round's file
# Sources  : Questionnaire{2011,2014,2017,2021,2024}.pdf, Glossary2017.pdf,
#            Glossary2024.pdf. See docs/religion_variable_confirmation.csv.

mp <- function(round, concept, variable)
  data.frame(round = round, concept = concept, variable = variable,
             stringsAsFactors = FALSE)

map <- rbind(
  # ---------------- 2011 ----------------
  mp(2011, "barrier_item",   paste0("q10", letters[1:7])),
  mp(2011, "religion_item",  "q10f"),                 # Q10 F
  mp(2011, "account_any",    "account"),
  mp(2011, "gate_account",   c("q1a", "q1b")),        # bank / post office
  mp(2011, "debit_card",     "q3a"),
  mp(2011, "mobile_use",     c("q15a1a", "q15a1b", "q15a1c")),
  mp(2011, "demog",          c("female", "age", "educ", "inc_q")),
  mp(2011, "weight",         "wgt"),
  mp(2011, "pop_adult",      "pop_adult"),
  mp(2011, "economy",        "economy"),
  mp(2011, "economy_code",   "ecnmycode"),            # NB spelling
  mp(2011, "region",         "regionwb"),
  # ---------------- 2014 ----------------
  mp(2014, "barrier_item",   paste0("q8", letters[1:9])),
  mp(2014, "religion_item",  "q8e"),                  # Q8 E
  mp(2014, "account_any",    "account"),
  mp(2014, "account_fin",    "account_fin"),
  mp(2014, "account_mob",    "account_mob"),
  mp(2014, "debit_card",     "q2"),
  mp(2014, "card_own_name",  "q3"),
  mp(2014, "demog",          c("female", "age", "educ", "inc_q")),
  mp(2014, "weight",         "wgt"),
  mp(2014, "pop_adult",      "pop_adult"),
  mp(2014, "economy",        "economy"),
  mp(2014, "economy_code",   "economycode"),
  mp(2014, "region",         "regionwb"),
  # ---------------- 2017 ----------------
  mp(2017, "barrier_item",   paste0("fin11", letters[1:8])),
  mp(2017, "religion_item",  "fin11e"),               # FIN11 E
  mp(2017, "account_any",    "account"),
  mp(2017, "account_fin",    "account_fin"),
  mp(2017, "account_mob",    "account_mob"),
  mp(2017, "debit_card",     "fin2"),
  mp(2017, "card_own_name",  "fin3"),
  mp(2017, "mobileowner",    "mobileowner"),
  mp(2017, "digital_pay",    c("pay_onlne", "pay_onlne_mobintbuy")),
  mp(2017, "demog",          c("female", "age", "educ", "inc_q", "emp_in")),
  mp(2017, "weight",         "wgt"),
  mp(2017, "pop_adult",      "pop_adult"),
  mp(2017, "economy",        "economy"),
  mp(2017, "economy_code",   "economycode"),
  mp(2017, "region",         "regionwb"),
  # ---------------- 2021 ----------------
  mp(2021, "barrier_item",   paste0("fin11", letters[1:8])),
  mp(2021, "religion_item",  "fin11e"),               # FIN11 E
  mp(2021, "unbanked_extra", "fin11_1"),
  mp(2021, "account_any",    "account"),
  mp(2021, "account_fin",    "account_fin"),
  mp(2021, "account_mob",    "account_mob"),
  mp(2021, "debit_card",     "fin2"),
  mp(2021, "mobileowner",    "mobileowner"),
  mp(2021, "internet",       "internetaccess"),
  mp(2021, "digital_pay",    "anydigpayment"),
  mp(2021, "urban",          "urbanicity_f2f"),
  mp(2021, "demog",          c("female", "age", "educ", "inc_q", "emp_in")),
  mp(2021, "weight",         "wgt"),
  mp(2021, "pop_adult",      "pop_adult"),
  mp(2021, "economy",        "economy"),
  mp(2021, "economy_code",   "economycode"),
  mp(2021, "region",         "regionwb"),
  # ---------------- 2024 ----------------
  # NB: NO religion item exists in 2024. fin11e means "family member already
  # has an account" in this round. Confirmed in Glossary2024.pdf.
  mp(2024, "barrier_item",   paste0("fin11", letters[1:6])),
  mp(2024, "unbanked_extra", c("fin11_0", "fin11_1", "fin11_2")),
  mp(2024, "account_any",    "account"),
  mp(2024, "account_fin",    "account_fin"),
  mp(2024, "account_mob",    "account_mob"),
  mp(2024, "dig_account",    "dig_account"),
  mp(2024, "debit_card",     "fin2"),
  mp(2024, "internet",       "internet_use"),
  mp(2024, "digital_pay",    "anydigpayment"),
  mp(2024, "urban",          "urbanicity"),
  mp(2024, "demog",          c("female", "age", "educ", "inc_q", "emp_in")),
  mp(2024, "weight",         "wgt"),
  mp(2024, "pop_adult",      "pop_adult"),
  mp(2024, "economy",        "economy"),
  mp(2024, "economy_code",   "economycode"),
  mp(2024, "region",         "regionwb")
)

## ---- 3. Helpers -------------------------------------------------------------

read_round <- function(path) {
  nas <- c("", "NA", ".", " ", "#NULL!")
  if (has_dt) {
    d <- tryCatch(
      data.table::fread(path, na.strings = nas, showProgress = FALSE,
                        data.table = FALSE, encoding = "UTF-8"),
      error = function(e)
        data.table::fread(path, na.strings = nas, showProgress = FALSE,
                          data.table = FALSE))
  } else {
    d <- utils::read.csv(path, stringsAsFactors = FALSE, na.strings = nas,
                         check.names = FALSE)
  }
  names(d) <- tolower(trimws(names(d)))
  d
}

freq_tab <- function(x, round, variable) {
  if (is.factor(x)) x <- as.character(x)
  t  <- table(x, useNA = "always")
  nm <- names(t); nm[is.na(nm)] <- "<NA: not in file / not asked / not answered>"
  data.frame(round = round, variable = variable, value = nm,
             n = as.integer(t), stringsAsFactors = FALSE)
}

peek <- function(x, k = 12) {
  u <- unique(x); u <- u[seq_len(min(k, length(u)))]
  paste(as.character(u), collapse = " | ")
}

`%||%` <- function(a, b) if (is.null(a) || !length(a)) b else a

## ---- 4. Per-round diagnostics ----------------------------------------------

presence  <- list(); types <- list(); freqs <- list()
universe  <- list(); uni_econ <- list(); wgt_aud <- list(); econ_cov <- list()
uni_marg  <- list()

for (r in ROUNDS) {
  key  <- as.character(r)
  say("\n=== ROUND ", r, " ==========================================")
  d    <- read_round(round_file[key])
  say("  rows: ", format(nrow(d), big.mark = " "), "   cols: ", ncol(d))

  m_r  <- map[map$round == r, ]

  ## 4a. presence of every expected variable ---------------------------------
  pres <- data.frame(
    round     = r,
    concept   = m_r$concept,
    variable  = m_r$variable,
    present   = m_r$variable %in% names(d),
    stringsAsFactors = FALSE
  )
  presence[[key]] <- pres
  miss <- pres$variable[!pres$present]
  if (length(miss)) say("  EXPECTED BUT ABSENT: ", paste(miss, collapse = ", "))

  vars_ok <- pres$variable[pres$present]

  ## 4b. storage type and a peek at the values (detects 2024 labelling) ------
  types[[key]] <- data.frame(
    round        = r,
    variable     = vars_ok,
    class        = vapply(vars_ok, function(v) class(d[[v]])[1], character(1)),
    n_distinct   = vapply(vars_ok, function(v) length(unique(d[[v]])), integer(1)),
    n_missing    = vapply(vars_ok, function(v) sum(is.na(d[[v]])), integer(1)),
    first_values = vapply(vars_ok, function(v) peek(d[[v]]), character(1)),
    stringsAsFactors = FALSE, row.names = NULL
  )

  ## 4c. full frequency tables, NA kept explicit ------------------------------
  freq_vars <- pres$variable[pres$present &
                 pres$concept %in% c("barrier_item", "religion_item",
                                     "unbanked_extra", "account_any",
                                     "account_fin", "account_mob", "dig_account",
                                     "debit_card", "card_own_name", "gate_account",
                                     "mobile_use", "mobileowner", "internet",
                                     "digital_pay", "urban", "demog", "region")]
  freqs[[key]] <- do.call(rbind, lapply(freq_vars,
                     function(v) freq_tab(d[[v]], r, v)))

  ## 4d. THE UNIVERSE AUDIT ---------------------------------------------------
  b_vars <- m_r$variable[m_r$concept == "barrier_item"]
  b_vars <- b_vars[b_vars %in% names(d)]
  if (length(b_vars)) {
    B          <- d[, b_vars, drop = FALSE]
    n_answered <- rowSums(!is.na(B))
    asked_any  <- n_answered > 0L
    asked_all  <- n_answered == length(b_vars)

    # Every variable that could plausibly define the routing rule is crossed
    # with "was asked". For 2017 the documented gate is FIN3 (card in own
    # name), not FIN2, so card_own_name must be present here; for 2011 the
    # gate is Q1A/Q1B. Omitting them would hide the rule we are looking for.
    gate_concepts <- c("account_any", "account_fin", "account_mob",
                       "debit_card", "card_own_name", "gate_account")
    gate_vars <- m_r$variable[m_r$concept %in% gate_concepts]
    gate_vars <- gate_vars[gate_vars %in% names(d)]

    X <- data.frame(round = r, asked_any = asked_any, asked_all = asked_all,
                    stringsAsFactors = FALSE)
    # NA must become a literal level: aggregate() silently DROPS rows whose
    # `by` variables are NA, which would understate the joint table wherever a
    # gate variable is itself routed (e.g. fin3 in 2017, q3 in 2014).
    for (v in gate_vars) {
      X[[v]] <- as.character(d[[v]])
      X[[v]][is.na(X[[v]])] <- "<NA>"
    }

    # AGGREGATE ONLY — the row-level frame X is never written to disk
    ag <- aggregate(list(n = rep(1L, nrow(X))), by = as.list(X), FUN = sum)
    universe[[key]] <- ag[order(-ag$n), ]

    # Easier-to-read margins: "was asked" against ONE gate variable at a time
    marg <- do.call(rbind, lapply(gate_vars, function(v) {
      t <- table(asked_any, as.character(d[[v]]), useNA = "ifany")
      nm <- colnames(t); nm[is.na(nm)] <- "<NA>"
      data.frame(round = r, gate_variable = v,
                 gate_value = rep(nm, each = nrow(t)),
                 asked_any  = rep(rownames(t), times = ncol(t)),
                 n = as.integer(t), stringsAsFactors = FALSE)
    }))
    uni_marg[[key]] <- marg

    econ_v <- m_r$variable[m_r$concept == "economy"]
    if (length(econ_v) && econ_v %in% names(d)) {
      e <- as.character(d[[econ_v]])
      uni_econ[[key]] <- data.frame(
        round        = r,
        economy      = sort(unique(e)),
        n_total      = as.integer(tapply(asked_any, e, length)[sort(unique(e))]),
        n_asked_any  = as.integer(tapply(asked_any, e, sum)[sort(unique(e))]),
        n_asked_all  = as.integer(tapply(asked_all, e, sum)[sort(unique(e))]),
        stringsAsFactors = FALSE, row.names = NULL
      )
    }
    say("  battery items: ", paste(b_vars, collapse = ", "))
    say("  asked (>=1 item answered): ", sum(asked_any), " of ", nrow(d),
        "  (", round(100 * mean(asked_any), 1), "%)")
  } else {
    say("  no barrier items located in this round")
  }

  ## 4e. weights --------------------------------------------------------------
  w_v <- m_r$variable[m_r$concept == "weight"]
  e_v <- m_r$variable[m_r$concept == "economy"]
  p_v <- m_r$variable[m_r$concept == "pop_adult"]
  if (length(w_v) && w_v %in% names(d) && length(e_v) && e_v %in% names(d)) {
    w <- suppressWarnings(as.numeric(as.character(d[[w_v]])))
    e <- as.character(d[[e_v]]); eu <- sort(unique(e))
    pa <- if (length(p_v) && p_v %in% names(d))
            suppressWarnings(as.numeric(as.character(d[[p_v]]))) else rep(NA_real_, nrow(d))
    wgt_aud[[key]] <- data.frame(
      round             = r,
      economy           = eu,
      n                 = as.integer(tapply(w, e, length)[eu]),
      n_missing_wgt     = as.integer(tapply(w, e, function(z) sum(is.na(z)))[eu]),
      sum_wgt           = as.numeric(tapply(w, e, function(z) sum(z, na.rm = TRUE))[eu]),
      min_wgt           = as.numeric(tapply(w, e, function(z) min(z, na.rm = TRUE))[eu]),
      max_wgt           = as.numeric(tapply(w, e, function(z) max(z, na.rm = TRUE))[eu]),
      pop_adult_distinct= as.integer(tapply(pa, e, function(z) length(unique(z)))[eu]),
      pop_adult_value   = as.numeric(tapply(pa, e, function(z) z[1])[eu]),
      stringsAsFactors = FALSE, row.names = NULL
    )
    wgt_aud[[key]]$ratio_sumwgt_over_n <-
      wgt_aud[[key]]$sum_wgt / wgt_aud[[key]]$n
  }

  ## 4f. economy identifiers --------------------------------------------------
  c_v <- m_r$variable[m_r$concept == "economy_code"]
  if (length(e_v) && e_v %in% names(d)) {
    code <- if (length(c_v) && c_v %in% names(d))
              as.character(d[[c_v]]) else rep(NA_character_, nrow(d))
    ec <- unique(data.frame(round = r,
                            economy = as.character(d[[e_v]]),
                            code    = code,
                            stringsAsFactors = FALSE))
    ec$code_is_iso3_like <- grepl("^[A-Za-z]{3}$", ec$code)
    econ_cov[[key]] <- ec[order(ec$economy), ]
    say("  economies: ", length(unique(ec$economy)),
        " | code variable: ",
        if (length(c_v) && c_v %in% names(d)) c_v else "<none>",
        " | ISO3-shaped: ", sum(ec$code_is_iso3_like), "/", nrow(ec))
  }

  rm(d); invisible(gc())
}

## ---- 5. Cross-round checks --------------------------------------------------

say("\n=== CROSS-ROUND CHECKS ==================================")

econ_all <- do.call(rbind, econ_cov)

# 5a. Does the 2011 code variable already give a usable ISO3?
e11 <- econ_all[econ_all$round == 2011, ]
e17 <- econ_all[econ_all$round == 2017, ]
if (nrow(e11) && nrow(e17)) {
  by_code <- sum(toupper(e11$code) %in% toupper(e17$code), na.rm = TRUE)
  by_name <- sum(tolower(trimws(e11$economy)) %in% tolower(trimws(e17$economy)))
  say("  2011 economies: ", nrow(e11))
  say("  2011 codes matching a 2017 code: ", by_code, " / ", nrow(e11))
  say("  2011 names matching a 2017 name: ", by_name, " / ", nrow(e11))
  say("  -> if the code match is near-complete, the planned manual name")
  say("     matching for 2011 is unnecessary. Record the outcome in the log.")
  e11$code_matches_2017 <- toupper(e11$code) %in% toupper(e17$code)
  e11$name_matches_2017 <- tolower(trimws(e11$economy)) %in% tolower(trimws(e17$economy))
  wr(e11[order(e11$code_matches_2017, e11$economy), ], "08b_2011_code_match.csv")
}

## ---- 6. Write outputs -------------------------------------------------------

say("\n=== OUTPUTS =============================================")
wr(do.call(rbind, presence), "02_variable_presence.csv")
wr(do.call(rbind, types),    "03_variable_types_and_values.csv")
wr(do.call(rbind, freqs),    "04_frequencies_key_vars.csv")
# The joint universe table has round-specific gate columns, so it is written
# one file per round rather than stacked.
for (key in names(universe))
  wr(universe[[key]], paste0("05_battery_universe_", key, ".csv"))
wr(do.call(rbind, uni_marg), "05b_universe_margins.csv")
wr(do.call(rbind, uni_econ), "06_universe_by_economy.csv")
wr(do.call(rbind, wgt_aud),  "07_weights_audit.csv")
wr(econ_all,                 "08_economy_coverage.csv")

writeLines(c(log_lines, "", "--- sessionInfo ---",
             capture.output(sessionInfo())),
           file.path(OUT_DIR, "09_diagnostic_log.txt"))

say("\nDone. All outputs are aggregate tables in:")
say("  ", OUT_DIR)
say("\nRead them in this order:")
say("  03_variable_types_and_values.csv  -> is 2024 labelled or coded?")
say("  05b_universe_margins.csv          -> the 2011 and 2014 universes,")
say("                                       and whether 'asked' == account_fin==0")
say("  05_battery_universe_<round>.csv   -> the same, full joint table")
say("  08b_2011_code_match.csv           -> is `ecnmycode` a usable ISO3?")
say("  07_weights_audit.csv              -> does sum(wgt) equal n per economy?")

# =============================================================================
# Deliberately NOT computed here: any rate, share or trend in the religion
# item. The denominator has not yet been decided, and computing a headline
# number before that decision is what the decisions log exists to prevent.
# =============================================================================
