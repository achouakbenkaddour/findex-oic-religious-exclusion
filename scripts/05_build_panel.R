# =============================================================================
# 05_build_panel.R
# Project : Global Findex — harmonised OIC panel
# Purpose : Build LAYER 1 (individual level), write it to disk, and audit it.
#
# LICENCE. Layer 1 contains harmonised individual records derived from Findex
# microdata. Findex terms forbid redistribution, so everything this script
# writes to clean/ is LOCAL ONLY and is never deposited, never attached to a
# preprint, and never uploaded. The deposited output is layer 2, built later
# from this file. The audit tables written to docs/ are aggregates and are
# safe to share.
#
# Run as: Rscript scripts/05_build_panel.R
# =============================================================================

PROJ_ROOT <- "D:/findex-oic"
source(file.path(PROJ_ROOT, "scripts", "03_harmonise_round.R"))

CLEAN_DIR <- file.path(PROJ_ROOT, "clean")
DOCS_DIR  <- file.path(PROJ_ROOT, "docs")
AUDIT_DIR <- file.path(DOCS_DIR, "diagnostics")
dir.create(CLEAN_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(AUDIT_DIR, showWarnings = FALSE, recursive = TRUE)

EXP_ROWS <- c(`2011`=149761, `2014`=146688, `2017`=154923, `2021`=143887, `2024`=144090)

## ---- 1. build ---------------------------------------------------------------

message("Building layer 1 ...")
panel <- harmonise_all()
lg    <- attr(panel, "harmonise_log")

message("\nPanel: ", format(nrow(panel), big.mark = " "), " rows x ",
        ncol(panel), " columns")

## ---- 2. stacking audit ------------------------------------------------------

cat("\n=== STACKING AUDIT ===\n")
ok <- TRUE
say <- function(label, cond, detail = "") {
  if (isTRUE(cond)) cat(sprintf("  OK    %s\n", label))
  else { ok <<- FALSE; cat(sprintf("  ALERT %s   %s\n", label, detail)) }
}

n_by_round <- table(panel$round)
for (r in names(EXP_ROWS))
  say(paste("round", r, "row count"), n_by_round[[r]] == EXP_ROWS[[r]],
      sprintf("got %d, expected %d", n_by_round[[r]], EXP_ROWS[[r]]))
say("total rows", nrow(panel) == sum(EXP_ROWS),
    sprintf("got %d, expected %d", nrow(panel), sum(EXP_ROWS)))
say("no source variable silently missing", !any(lg$action == "SOURCE_MISSING"),
    paste(unique(lg$target[lg$action == "SOURCE_MISSING"]), collapse = ", "))
say("iso3 never missing", !anyNA(panel$iso3))
say("no legacy ISO3 codes", !any(panel$iso3 %in% c("ZAR","KSV","ROM","WBG")))
say("barrier_religion present in 2011-2021 and absent in 2024",
    all(tapply(!is.na(panel$barrier_religion), panel$round, any)[1:4]) &&
      !any(!is.na(panel$barrier_religion[panel$round == 2024])))
say("barrier_religion only inside the battery universe",
    all(is.na(panel$barrier_religion[panel$asked_barriers != 1])))

fem <- tapply(panel$is_female, panel$round, mean, na.rm = TRUE)
cat("\n  female share by round: ",
    paste(sprintf("%s=%.3f", names(fem), fem), collapse = "  "), "\n")
say("female share 0.50-0.56 in every round", all(fem > 0.50 & fem < 0.56))

## ---- 3. audit tables (aggregates — safe to share) ---------------------------

# 3a. per round x target: coverage
tg  <- setdiff(names(panel), "round")
cov <- do.call(rbind, lapply(sort(unique(panel$round)), function(r) {
  s <- panel[panel$round == r, ]
  data.frame(round = r, target = tg,
             n            = nrow(s),
             n_non_missing= vapply(tg, function(v) sum(!is.na(s[[v]])), integer(1)),
             pct_missing  = round(100 * vapply(tg, function(v) mean(is.na(s[[v]])), numeric(1)), 2),
             n_distinct   = vapply(tg, function(v) length(unique(s[[v]])), integer(1)),
             stringsAsFactors = FALSE, row.names = NULL)
}))
write.csv(cov, file.path(AUDIT_DIR, "11_panel_coverage.csv"), row.names = FALSE, na = "")

# 3b. economy x round: sample sizes and battery universe
ec <- aggregate(cbind(n = rep(1L, nrow(panel)),
                      n_asked = ifelse(is.na(panel$asked_barriers), 0L, panel$asked_barriers)),
                by = list(round = panel$round, iso3 = panel$iso3), FUN = sum)
ec <- ec[order(ec$iso3, ec$round), ]
write.csv(ec, file.path(AUDIT_DIR, "12_economy_round_sizes.csv"), row.names = FALSE, na = "")

# 3c. the harmonisation log itself
write.csv(lg, file.path(DOCS_DIR, "harmonise_log.csv"), row.names = FALSE, na = "")

cat("\n  written: docs/diagnostics/11_panel_coverage.csv\n")
cat("  written: docs/diagnostics/12_economy_round_sizes.csv\n")
cat("  written: docs/harmonise_log.csv\n")

## ---- 4. write layer 1 (LOCAL ONLY) -----------------------------------------

f_rds <- file.path(CLEAN_DIR, "panel_individual_layer1.rds")
saveRDS(panel, f_rds, compress = "xz")
cat(sprintf("\n  written: clean/panel_individual_layer1.rds  (%.1f MB)\n",
            file.info(f_rds)$size / 1024^2))

writeLines(c(
  "DO NOT DISTRIBUTE",
  "",
  "clean/panel_individual_layer1.rds contains harmonised individual records",
  "derived from Global Findex microdata. The Findex terms of use forbid",
  "redistribution of the microdata, and that restriction carries over to any",
  "individual-level derivative.",
  "",
  "This file is a local working object. It is not deposited, not attached to",
  "the preprint, and not uploaded anywhere. The citable output is the",
  "economy-year aggregate layer, built from this file by a later script.",
  "",
  paste("Built:", Sys.time()),
  paste("Rows:", nrow(panel), " Columns:", ncol(panel))
), file.path(CLEAN_DIR, "README_DO_NOT_DISTRIBUTE.txt"))
cat("  written: clean/README_DO_NOT_DISTRIBUTE.txt\n")

cat(if (ok) "\n=== stacking audit clean ===\n"
    else    "\n=== STACKING AUDIT RAISED ALERTS — resolve before proceeding ===\n")
