# =============================================================================
# 07_validate_regime_coding.R
# Project : Global Findex — harmonised OIC panel
# Purpose : What R CAN do for the hand-coded Islamic banking regime variable.
#
# R cannot read a central bank annual report and decide whether a licensed
# Islamic bank existed on 31 December 2016. No package does that, and no
# machine-readable database of Islamic banking regimes by country-year exists.
# The judgement is yours.
#
# What R can do is everything around it: fetch the source documents, refuse
# to accept an undocumented cell, catch the errors hand-coding actually makes,
# and check your own consistency. That is what this script does.
#
# Run as: Rscript scripts/07_validate_regime_coding.R
# =============================================================================

if (!exists("PROJ_ROOT")) PROJ_ROOT <- "D:/findex-oic"
DOCS <- file.path(PROJ_ROOT, "docs")
SRC  <- file.path(PROJ_ROOT, "raw", "islamic_finance")
dir.create(SRC, recursive = TRUE, showWarnings = FALSE)

CODING <- file.path(DOCS, "islamic_banking_regime.csv")

## ---- 1. fetch the source documents -----------------------------------------
# The IFSB Islamic Financial Services Industry Stability Report carries, in
# every annual edition, a chart of Islamic banking's share of total domestic
# banking assets across roughly 35 jurisdictions, and flags those above the
# 15% systemic-significance threshold. That series is the backbone.
# Older editions are on the IFSB publications archive; add their URLs here as
# you find them, so the download is reproducible instead of manual.

IFSI <- c(
  "2025" = "https://www.ifsb.org/wp-content/uploads/2025/05/IFSI-Stability-Report-May-2025.pdf",
  "2024" = "https://www.ifsb.org/wp-content/uploads/2024/09/IFSB-Stability-Report-2024-8.pdf"
  # add 2013-2023 editions from https://www.ifsb.org/publication/
)

fetch_sources <- function(urls = IFSI, dir = SRC) {
  for (y in names(urls)) {
    f <- file.path(dir, paste0("IFSI_Stability_Report_", y, ".pdf"))
    if (file.exists(f)) { message("have ", basename(f)); next }
    ok <- tryCatch({ download.file(urls[[y]], f, mode = "wb", quiet = TRUE); TRUE },
                   error = function(e) { message("FAILED ", y, ": ", conditionMessage(e)); FALSE })
    if (ok) message("downloaded ", basename(f))
  }
  # checksums, to the same standard as the Findex sources
  fs <- list.files(dir, pattern = "\\.pdf$", full.names = TRUE)
  if (length(fs) && requireNamespace("digest", quietly = TRUE)) {
    ck <- data.frame(file = basename(fs),
                     sha256 = vapply(fs, function(p) digest::digest(file = p, algo = "sha256"),
                                     character(1)),
                     downloaded_on = as.character(Sys.Date()),
                     stringsAsFactors = FALSE, row.names = NULL)
    write.csv(ck, file.path(DOCS, "checksums_islamic_finance.csv"), row.names = FALSE)
    message("checksums written")
  }
}

## ---- 2. validate the coding file -------------------------------------------

validate_coding <- function(path = CODING) {
  if (!file.exists(path)) stop("Not found: ", path,
    "\nCopy islamic_banking_regime_TEMPLATE.csv to islamic_banking_regime.csv first.")
  d <- read.csv(path, stringsAsFactors = FALSE, na.strings = c("", "NA"),
                fileEncoding = "UTF-8-BOM")
  fail <- character(0)
  say <- function(l, ok, detail = "") {
    cat(sprintf("  %-5s %s   %s\n", if (isTRUE(ok)) "OK" else "FAIL", l, detail))
    if (!isTRUE(ok)) fail <<- c(fail, l)
  }

  cat("\n=== STRUCTURE ===\n")
  say("136 rows", nrow(d) == 136, paste("got", nrow(d)))
  say("34 economies x 4 rounds",
      length(unique(d$iso3)) == 34 && all(table(d$iso3) == 4))
  say("no duplicated economy-round", !any(duplicated(d[, c("iso3", "round")])))

  cat("\n=== COMPLETENESS ===\n")
  n_done <- sum(!is.na(d$ib_regime))
  cat(sprintf("       coded: %d of 136 (%.0f%%)\n", n_done, 100 * n_done / 136))
  open <- d[is.na(d$ib_regime), c("iso3", "round")]
  if (nrow(open)) {
    cat("       still open:\n")
    print(open, row.names = FALSE, max = 60)
  }

  cat("\n=== VALUE DOMAINS ===\n")
  say("ib_regime in {0,1,2}", all(is.na(d$ib_regime) | d$ib_regime %in% 0:2),
      paste(setdiff(unique(d$ib_regime), c(NA, 0:2)), collapse = ", "))
  say("ib_legal_framework in {0,1}",
      all(is.na(d$ib_legal_framework) | d$ib_legal_framework %in% 0:1))

  cat("\n=== DOCUMENTATION (the column the whole variable rests on) ===\n")
  coded <- !is.na(d$ib_regime)
  nosrc <- coded & (is.na(d$source_citation) | is.na(d$source_url) |
                    is.na(d$source_consulted_on))
  say("every coded cell has a citation, a URL and a date", !any(nosrc),
      if (any(nosrc)) paste(nrow(d[nosrc, ]), "cells coded without a full source") else "")
  if (any(nosrc)) print(d[nosrc, c("iso3", "round", "ib_regime")], row.names = FALSE)

  cat("\n=== INTERNAL CONSISTENCY ===\n")
  # a standalone Islamic bank without any legal framework is possible but rare;
  # flag it so it is a considered judgement rather than a slip
  odd <- coded & !is.na(d$ib_legal_framework) & d$ib_regime == 2 & d$ib_legal_framework == 0
  say("no unexplained 'standalone bank, no framework'",
      !any(odd & is.na(d$coder_note)),
      "these need a coder_note explaining the combination")

  # regimes rarely revert; a fall in level is possible but should be justified
  d2 <- d[order(d$iso3, d$round), ]
  rev <- unlist(lapply(split(d2, d2$iso3), function(s) {
    v <- s$ib_regime; if (all(is.na(v))) return(NULL)
    if (any(diff(v[!is.na(v)]) < 0)) s$iso3[1] else NULL }))
  say("no unexplained regime reversals", !length(rev),
      if (length(rev)) paste("check:", paste(rev, collapse = ", ")) else "")

  cat("\n=== IDENTIFYING VARIATION (the point of the exercise) ===\n")
  chg <- vapply(split(d, d$iso3), function(s) {
    v <- s$ib_regime[!is.na(s$ib_regime)]; length(unique(v)) > 1 }, logical(1))
  n_chg <- sum(chg)
  cat(sprintf("       economies changing regime across rounds: %d of 34\n", n_chg))
  if (n_chg >= 8)
    cat("       -> enough within-country variation. Usable as a regressor under country fixed effects.\n")
  else
    cat("       -> too little within-country variation. Country fixed effects would absorb it.\n",
        "      Use it as a heterogeneity split instead, as anticipated in D-29.\n")

  cat(sprintf("\n=== %d checks failed ===\n", length(fail)))
  invisible(d)
}

## ---- 3. run ----------------------------------------------------------------
# run_all() is what you call. Sourcing this file only DEFINES the functions;
# it does not execute them. That is normal R behaviour and catches everyone once.

run_all <- function() {
  fetch_sources()
  if (file.exists(CODING)) validate_coding()
  else message("\nNo islamic_banking_regime.csv yet.\n",
               "Copy docs/islamic_banking_regime_TEMPLATE.csv to\n",
               "docs/islamic_banking_regime.csv, code some cells, then call validate_coding().")
  invisible(NULL)
}

if (!interactive()) {
  run_all()                      # Rscript scripts/07_validate_regime_coding.R
} else {
  message("\n07_validate_regime_coding.R loaded. Nothing has run yet.\n",
          "Call one of:\n",
          "  run_all()          # fetch the sources, then validate\n",
          "  fetch_sources()    # download IFSB reports + write checksums\n",
          "  validate_coding()  # check docs/islamic_banking_regime.csv\n")
}
