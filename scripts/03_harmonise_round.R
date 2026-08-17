# =============================================================================
# 03_harmonise_round.R
# Project : Global Findex — harmonised OIC panel of religion-based financial
#           exclusion
# Purpose : harmonise_round() — turn ONE raw round file into the target schema.
#
# DESIGN NOTE. This function hard-codes no variable names. Every mapping is
# read from docs/variable_crosswalk.csv, including the recode expression, so
# that each mapping decision lives in one auditable table that is itself a
# deposited output. Changing a mapping means editing the crosswalk, never the
# code. That is what makes the pipeline reproducible by someone else.
#
# TWO-LAYER OUTPUT (decided 2026-08-16):
#   layer 1  individual level, produced and kept LOCALLY. Findex terms forbid
#            redistribution, so this layer is never deposited.
#   layer 2  economy-year aggregates, derived from layer 1. This is the layer
#            that carries the DOI.
#   This file builds layer 1. Layer 2 is built by a later script.
#
# Author  : A. Benkaddour
# Created : 2026-08-16
# =============================================================================

## ---- configuration ---------------------------------------------------------

if (!exists("PROJ_ROOT")) PROJ_ROOT <- "D:/findex-oic"   # not overwritten when sourced
RAW_DIR   <- file.path(PROJ_ROOT, "raw")
CROSSWALK <- file.path(PROJ_ROOT, "docs", "variable_crosswalk.csv")

has_dt <- requireNamespace("data.table", quietly = TRUE)

## ---- helpers ---------------------------------------------------------------

find_round_file <- function(round, raw_dir = RAW_DIR) {
  all_csv <- list.files(raw_dir, pattern = "\\.csv$", recursive = TRUE,
                        full.names = TRUE, ignore.case = TRUE)
  tok <- regmatches(all_csv, regexpr("WLD_[0-9]{4}_FINDEX", all_csv, ignore.case = TRUE))
  yr  <- vapply(all_csv, function(p) {
    m <- regmatches(p, regexpr("WLD_[0-9]{4}_FINDEX", p, ignore.case = TRUE))
    if (!length(m)) NA_integer_
    else as.integer(sub("^WLD_([0-9]{4})_FINDEX$", "\\1", m, ignore.case = TRUE))
  }, integer(1), USE.NAMES = FALSE)
  cand <- all_csv[!is.na(yr) & yr == round]
  if (length(cand) != 1L)
    stop("Round ", round, ": expected exactly 1 file, found ", length(cand),
         if (length(cand)) paste0("\n  ", paste(cand, collapse = "\n  ")) else "")
  cand
}

read_raw <- function(path) {
  nas <- c("", "NA", ".", "#NULL!")   # no " ": fread strips white space already
  d <- if (has_dt)
    data.table::fread(path, na.strings = nas, showProgress = FALSE, data.table = FALSE)
  else
    utils::read.csv(path, stringsAsFactors = FALSE, na.strings = nas, check.names = FALSE)
  names(d) <- tolower(trimws(names(d)))
  d
}

read_crosswalk <- function(path = CROSSWALK) {
  cw <- utils::read.csv(path, stringsAsFactors = FALSE, na.strings = "",
                        colClasses = "character")
  cw$round <- as.integer(cw$round)
  need <- c("target_variable", "round", "source_variable", "recode_r", "status")
  if (!all(need %in% names(cw)))
    stop("Crosswalk is missing columns: ", paste(setdiff(need, names(cw)), collapse = ", "))
  cw
}

## ---- the function ----------------------------------------------------------

harmonise_round <- function(round,
                            crosswalk = read_crosswalk(),
                            path      = find_round_file(round),
                            verbose   = TRUE) {

  cw <- crosswalk[crosswalk$round == round, ]
  if (!nrow(cw)) stop("No crosswalk rows for round ", round)

  raw <- read_raw(path)
  n   <- nrow(raw)
  if (verbose) message("Round ", round, ": ", format(n, big.mark = " "),
                       " rows, ", ncol(raw), " raw columns")

  out <- data.frame(round = rep.int(as.integer(round), n))
  log <- list()
  note <- function(target, action, detail = "")
    log[[length(log) + 1L]] <<- data.frame(round = round, target = target,
                                           action = action, detail = detail,
                                           stringsAsFactors = FALSE)

  # ---- 1. mapped targets ---------------------------------------------------
  for (i in seq_len(nrow(cw))) {
    tg  <- cw$target_variable[i]
    st  <- cw$status[i]
    src <- cw$source_variable[i]
    rc  <- cw$recode_r[i]

    if (st %in% c("derived")) next          # handled in section 2

    # concept absent from this round -> STRUCTURAL NA, kept distinct in the log
    if (st == "not_asked" || is.na(src) || !nzchar(src)) {
      out[[tg]] <- NA
      note(tg, "structural_NA", "concept not present in this round's instrument")
      next
    }

    if (!src %in% names(raw)) {
      out[[tg]] <- NA
      note(tg, "SOURCE_MISSING",
           paste0("crosswalk expects '", src, "' but the file does not contain it"))
      warning("Round ", round, ": expected source variable '", src,
              "' for target '", tg, "' is absent from the file", call. = FALSE)
      next
    }

    x <- raw[[src]]
    val <- tryCatch(eval(parse(text = rc), envir = list(x = x), enclos = baseenv()),
                    error = function(e) {
                      warning("Round ", round, ": recode failed for '", tg, "': ",
                              conditionMessage(e), call. = FALSE); rep(NA, n) })
    if (length(val) != n)
      stop("Recode for '", tg, "' returned ", length(val), " values, expected ", n)

    out[[tg]] <- val
    note(tg, st, paste0(src, " -> ", tg))
  }

  # ---- 2. derived targets --------------------------------------------------
  # asked_barriers: was the respondent routed into the unbanked battery?
  bat <- cw$source_variable[cw$target_variable %in%
           c("barrier_far","barrier_expensive","barrier_documentation","barrier_trust",
             "barrier_money","barrier_family","barrier_no_need","barrier_cannot_get",
             "barrier_religion") & cw$status == "available"]
  bat <- bat[!is.na(bat) & nzchar(bat) & bat %in% names(raw)]
  if (length(bat)) {
    B <- raw[, bat, drop = FALSE]
    out$asked_barriers <- as.integer(rowSums(!is.na(B)) > 0L)
    out$n_barrier_items_answered <- as.integer(rowSums(!is.na(B)))
    note("asked_barriers", "derived", paste0("from ", length(bat), " raw battery items"))
  } else {
    out$asked_barriers <- NA_integer_
    out$n_barrier_items_answered <- NA_integer_
    note("asked_barriers", "structural_NA", "no battery items in this round")
  }

  # wgt_pooled: within-economy weight rescaled to adult population
  if (all(c("wgt", "pop_adult", "iso3") %in% names(out))) {
    sw <- tapply(out$wgt, out$iso3, sum, na.rm = TRUE)
    out$wgt_pooled <- out$wgt * out$pop_adult / as.numeric(sw[out$iso3])
    note("wgt_pooled", "derived", "wgt * pop_adult / sum(wgt) within economy")
  } else {
    out$wgt_pooled <- NA_real_
    note("wgt_pooled", "SOURCE_MISSING", "needs wgt, pop_adult and iso3")
  }

  attr(out, "harmonise_log")  <- do.call(rbind, log)
  attr(out, "source_file")    <- path
  attr(out, "raw_nrow")       <- n
  attr(out, "harmonised_at")  <- as.character(Sys.time())
  out
}

## ---- convenience -----------------------------------------------------------

harmonise_all <- function(rounds = c(2011L, 2014L, 2017L, 2021L, 2024L)) {
  cw <- read_crosswalk()
  ls <- lapply(rounds, function(r) harmonise_round(r, crosswalk = cw))
  targets <- unique(unlist(lapply(ls, names)))
  ls <- lapply(ls, function(d) { for (v in setdiff(targets, names(d))) d[[v]] <- NA; d[, targets] })
  panel <- do.call(rbind, ls)
  attr(panel, "harmonise_log") <- do.call(rbind, lapply(ls, attr, "harmonise_log"))
  panel
}
