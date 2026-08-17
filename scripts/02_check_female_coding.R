# =============================================================================
# 02_check_female_coding.R
# Project : Global Findex — harmonised OIC panel
# Purpose : Settle the coding of `female` empirically, in one pass.
#
# Logic   : Glossary2024 documents 2024 as 1 = female, 2 = male. The 2024 round
#           is therefore a CALIBRATION ANCHOR: whatever pattern the known-female
#           group shows in 2024 (lower labour-force participation, higher mean
#           age) identifies the female code in the other rounds.
#           `emp_in` exists in 2017, 2021 and 2024; mean age is available in all
#           five rounds and corroborates.
#
# Output  : docs/diagnostics/10_female_coding_check.csv  (aggregate only)
# =============================================================================

PROJ_ROOT <- "D:/findex-oic"
RAW_DIR   <- file.path(PROJ_ROOT, "raw")
OUT_DIR   <- file.path(PROJ_ROOT, "docs", "diagnostics")
dir.create(OUT_DIR, recursive = TRUE, showWarnings = FALSE)

ROUNDS  <- c(2011L, 2014L, 2017L, 2021L, 2024L)
has_dt  <- requireNamespace("data.table", quietly = TRUE)

round_from_path <- function(p) {
  m <- regmatches(p, regexpr("WLD_[0-9]{4}_FINDEX", p, ignore.case = TRUE))
  if (!length(m)) return(NA_integer_)
  as.integer(sub("^WLD_([0-9]{4})_FINDEX$", "\\1", m, ignore.case = TRUE))
}
all_csv <- list.files(RAW_DIR, pattern = "\\.csv$", recursive = TRUE,
                      full.names = TRUE, ignore.case = TRUE)
csv_round <- vapply(all_csv, round_from_path, integer(1), USE.NAMES = FALSE)

read_round <- function(path) {
  nas <- c("", "NA", ".", " ", "#NULL!")
  d <- if (has_dt)
    data.table::fread(path, na.strings = nas, showProgress = FALSE, data.table = FALSE)
  else
    utils::read.csv(path, stringsAsFactors = FALSE, na.strings = nas, check.names = FALSE)
  names(d) <- tolower(trimws(names(d)))
  d
}

out <- list()
for (r in ROUNDS) {
  p <- all_csv[!is.na(csv_round) & csv_round == r]
  if (length(p) != 1L) { message("Round ", r, ": expected 1 file, found ", length(p)); next }
  d <- read_round(p[1])
  if (!"female" %in% names(d)) next

  f   <- suppressWarnings(as.integer(as.character(d$female)))
  age <- suppressWarnings(as.numeric(d$age)); age[age >= 99] <- NA   # drop top code
  emp <- if ("emp_in" %in% names(d)) suppressWarnings(as.integer(as.character(d$emp_in))) else rep(NA_integer_, nrow(d))
  # "in the workforce" is coded 1 in 2021/2024 and 1 in 2017 (0 = out)
  in_wf <- ifelse(is.na(emp), NA, as.integer(emp == 1L))

  for (v in sort(unique(f[!is.na(f)]))) {
    k <- which(f == v)
    out[[length(out) + 1L]] <- data.frame(
      round            = r,
      female_code      = v,
      n                = length(k),
      share_of_round   = round(length(k) / sum(!is.na(f)), 4),
      mean_age         = round(mean(age[k], na.rm = TRUE), 2),
      labour_force_pct = if (all(is.na(in_wf[k]))) NA_real_
                         else round(100 * mean(in_wf[k], na.rm = TRUE), 2),
      stringsAsFactors = FALSE)
  }
  rm(d); invisible(gc())
}

res <- do.call(rbind, out)
utils::write.csv(res, file.path(OUT_DIR, "10_female_coding_check.csv"),
                 row.names = FALSE, na = "")
print(res, row.names = FALSE)

cat("\n---------------------------------------------------------------\n")
cat("How to read this.\n")
cat("In 2024 the glossary states 1 = female. Note that round's female code:\n")
cat("it will show the LOWER labour_force_pct and the HIGHER mean_age.\n")
cat("Whichever code shows that same pattern in 2017 and 2021 is the female\n")
cat("code in those rounds. share_of_round then extends the reading to 2011\n")
cat("and 2014, which have no emp_in.\n")
cat("If the code carrying the female pattern is NOT the same number in every\n")
cat("round, the coding flipped and `female` must be recoded per round.\n")
cat("---------------------------------------------------------------\n")
