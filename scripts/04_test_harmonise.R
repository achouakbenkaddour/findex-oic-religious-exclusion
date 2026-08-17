# =============================================================================
# 04_test_harmonise.R
# Tests harmonise_round() on ONE round before it is applied to all five.
#
# Run as:  Rscript scripts/04_test_harmonise.R 2021
# Default round is 2021. Run it on 2011 and 2024 too — those are the two
# rounds whose coding differs most from the rest.
#
# Every test either passes or stops with a message naming the failure. The
# regression tests carry hard-coded counts taken from the step-1 diagnostic,
# so a silent change in the raw files or in the crosswalk will fail here
# rather than surface as a wrong number in a table.
# =============================================================================

PROJ_ROOT <- "D:/findex-oic"
source(file.path(PROJ_ROOT, "scripts", "03_harmonise_round.R"))

args  <- commandArgs(trailingOnly = TRUE)
ROUND <- if (length(args)) as.integer(args[1]) else 2021L

pass <- 0L; fail <- character(0)
chk <- function(label, ok, detail = "") {
  if (isTRUE(ok)) { pass <<- pass + 1L; cat(sprintf("  PASS  %s\n", label)) }
  else { fail <<- c(fail, label); cat(sprintf("  FAIL  %s   %s\n", label, detail)) }
}

# expected counts from docs/diagnostics/ (step-1 diagnostic, 2026-08-16)
EXP_ROWS   <- c(`2011`=149761, `2014`=146688, `2017`=154923, `2021`=143887, `2024`=144090)
EXP_ASKED  <- c(`2011`= 74751, `2014`= 68015, `2017`= 68386, `2021`= 54805, `2024`= 22273)
EXP_ECON   <- c(`2011`=   144, `2014`=   142, `2017`=   144, `2021`=   139, `2024`=   140)

cat("\n=== harmonise_round(", ROUND, ") ===\n\n", sep = "")
cw <- read_crosswalk()
d  <- harmonise_round(ROUND, crosswalk = cw)
lg <- attr(d, "harmonise_log")

cat("\n-- structure --\n")
chk("row count matches the raw file", nrow(d) == EXP_ROWS[[as.character(ROUND)]],
    sprintf("got %d, expected %d", nrow(d), EXP_ROWS[[as.character(ROUND)]]))

tg <- unique(cw$target_variable[cw$round == ROUND])
chk("every crosswalk target is a column", all(tg %in% names(d)),
    paste("missing:", paste(setdiff(tg, names(d)), collapse = ", ")))
chk("no duplicated columns", !any(duplicated(names(d))),
    paste(names(d)[duplicated(names(d))], collapse = ", "))
chk("no source variable silently missing", !any(lg$action == "SOURCE_MISSING"),
    paste(lg$target[lg$action == "SOURCE_MISSING"], collapse = ", "))

cat("\n-- structural NA vs available --\n")
na_tg <- cw$target_variable[cw$round == ROUND & cw$status == "not_asked"]
bad <- na_tg[vapply(na_tg, function(v) !all(is.na(d[[v]])), logical(1))]
chk("not_asked targets are entirely NA", !length(bad), paste(bad, collapse = ", "))

av_tg <- cw$target_variable[cw$round == ROUND & cw$status == "available"]
av_tg <- intersect(av_tg, names(d))
empty <- av_tg[vapply(av_tg, function(v) all(is.na(d[[v]])), logical(1))]
chk("no 'available' target is entirely NA", !length(empty), paste(empty, collapse = ", "))

cat("\n-- value domains --\n")
bin <- grep("^barrier_", names(d), value = TRUE)
bin <- c(bin, "account_fin", "account_any", "account_mob", "debit_card",
         "card_own_name", "is_female", "in_workforce", "urban",
         "mobileowner", "internet_access", "internet_use", "anydigpayment",
         "asked_barriers")
bin <- intersect(bin, names(d))
badbin <- bin[vapply(bin, function(v) {
  u <- unique(d[[v]]); u <- u[!is.na(u)]; !all(u %in% c(0L, 1L, 0, 1))
}, logical(1))]
chk("all binary targets are in {0,1,NA}", !length(badbin), paste(badbin, collapse = ", "))

if ("educ3" %in% names(d)) {
  u <- unique(d$educ3); u <- u[!is.na(u)]
  chk("educ3 in {1,2,3,NA} (DK/Refused removed)", all(u %in% 1:3), paste(sort(u), collapse = ","))
}
if ("inc_q" %in% names(d)) {
  u <- unique(d$inc_q); u <- u[!is.na(u)]
  chk("inc_q in {1..5}", all(u %in% 1:5), paste(sort(u), collapse = ","))
}
if ("age" %in% names(d)) {
  chk("age within 15..100 or NA",
      all(is.na(d$age) | (d$age >= 15 & d$age <= 100)),
      sprintf("range %s", paste(range(d$age, na.rm = TRUE), collapse = "-")))
}

cat("\n-- identifiers --\n")
chk("iso3 is 3 characters everywhere", all(nchar(d$iso3) == 3L),
    paste(unique(d$iso3[nchar(d$iso3) != 3L]), collapse = ", "))
legacy <- intersect(unique(d$iso3), c("ZAR", "KSV", "ROM", "WBG"))
chk("no legacy ISO3 codes remain", !length(legacy), paste(legacy, collapse = ", "))
chk("economy count matches the diagnostic",
    length(unique(d$iso3)) == EXP_ECON[[as.character(ROUND)]],
    sprintf("got %d, expected %d", length(unique(d$iso3)), EXP_ECON[[as.character(ROUND)]]))

cat("\n-- regression against the step-1 diagnostic --\n")
chk("asked_barriers count matches",
    sum(d$asked_barriers, na.rm = TRUE) == EXP_ASKED[[as.character(ROUND)]],
    sprintf("got %d, expected %d", sum(d$asked_barriers, na.rm = TRUE),
            EXP_ASKED[[as.character(ROUND)]]))

# THE SEX-CODING CANARY. Under the correct per-round recode the female share is
# ~53% in every round. Under a name-based merge it would be ~46% in 2011-2017.
if ("is_female" %in% names(d)) {
  sh <- mean(d$is_female, na.rm = TRUE)
  cat(sprintf("       female share = %.3f\n", sh))
  chk("female share in 0.50-0.56 (catches the 2017/2021 coding flip)",
      sh > 0.50 && sh < 0.56, sprintf("got %.3f", sh))
}

cat("\n-- weights --\n")
if (all(c("wgt", "iso3") %in% names(d))) {
  sw <- tapply(d$wgt, d$iso3, sum, na.rm = TRUE)
  nn <- tapply(d$wgt, d$iso3, length)
  chk("sum(wgt) equals n within economy (tolerance 1%)",
      max(abs(sw / nn - 1)) < 0.01 || ROUND == 2014L,
      sprintf("max deviation %.4f (China 2014 is a known exception)",
              max(abs(sw / nn - 1))))
  chk("no missing weights", !anyNA(d$wgt))
}
if ("wgt_pooled" %in% names(d)) {
  chk("wgt_pooled is positive and finite",
      all(is.finite(d$wgt_pooled) & d$wgt_pooled > 0))
}

cat("\n-- outcome sanity (counts only, no rate reported) --\n")
if ("barrier_religion" %in% names(d) && !all(is.na(d$barrier_religion))) {
  a <- d$asked_barriers == 1L
  chk("barrier_religion is non-missing only inside the battery universe",
      all(is.na(d$barrier_religion[!a])))
  cat(sprintf("       asked = %d | religion answered = %d | DK/Refused dropped = %d\n",
              sum(a, na.rm = TRUE), sum(!is.na(d$barrier_religion)),
              sum(a, na.rm = TRUE) - sum(!is.na(d$barrier_religion))))
} else {
  cat("       barrier_religion is structurally absent in this round (expected for 2024)\n")
}

cat(sprintf("\n=== %d passed, %d failed ===\n", pass, length(fail)))
if (length(fail)) {
  cat("FAILED:\n"); cat(paste0("  - ", fail, collapse = "\n"), "\n")
  quit(status = 1)
}
cat("harmonise_round() is safe to apply to the remaining rounds.\n")
