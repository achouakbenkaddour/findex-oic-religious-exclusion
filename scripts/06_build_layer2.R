# =============================================================================
# 06_build_layer2.R
# Project : Global Findex — harmonised OIC panel
# Purpose : Build LAYER 2 — economy-year aggregates. THIS is the deposited,
#           citable output. It contains no individual records and is therefore
#           unaffected by the Findex redistribution restriction.
#
# Embeds the three decisions taken 2026-08-16:
#   D-24 denominator  : BOTH bases are computed. Primary = no financial-
#                       institution account (the World Bank's published base).
#                       Robustness = the population actually asked the battery.
#   D-25 frame        : flag in_balanced_oic_frame marks the 34 OIC economies
#                       present in all four outcome rounds. Every other cell is
#                       retained and flagged, never deleted.
#   D-26 comparison   : is_oic flags membership. Matching on income group and
#                       region happens at the analysis stage, once WDI income
#                       classifications are merged; this file carries the
#                       region field the match will use.
#
# Standard errors are design-based, using the Kish design effect
#   deff = n * sum(w^2) / (sum w)^2
# which is the formula the Findex methodology documents use for their own
# published margins of error (Methodology2017 note b; Methodology2024 note c).
#
# Run as: Rscript scripts/06_build_layer2.R
# =============================================================================

if (!exists("PROJ_ROOT")) PROJ_ROOT <- "D:/findex-oic"
CLEAN_DIR   <- file.path(PROJ_ROOT, "clean")
DEPOSIT_DIR <- file.path(PROJ_ROOT, "deposit")
dir.create(DEPOSIT_DIR, showWarnings = FALSE, recursive = TRUE)

OUTCOME_ROUNDS <- c(2011L, 2014L, 2017L, 2021L)   # the religion item ends in 2021

OIC <- c("AFG","ALB","DZA","AZE","BHR","BGD","BEN","BRN","BFA","CMR","TCD","COM",
         "CIV","DJI","EGY","GAB","GMB","GIN","GNB","GUY","IDN","IRN","IRQ","JOR",
         "KAZ","KWT","KGZ","LBN","LBY","MYS","MDV","MLI","MRT","MAR","MOZ","NER",
         "NGA","OMN","PAK","PSE","QAT","SAU","SEN","SLE","SOM","SDN","SUR","SYR",
         "TJK","TGO","TUN","TUR","TKM","UGA","ARE","UZB","YEM")

panel <- readRDS(file.path(CLEAN_DIR, "panel_individual_layer1.rds"))
message("layer 1: ", format(nrow(panel), big.mark = " "), " rows")

## ---- weighted proportion with a design-based standard error ----------------

wprop <- function(y, w) {
  keep <- !is.na(y) & !is.na(w) & w > 0
  y <- y[keep]; w <- w[keep]; n <- length(y)
  if (!n) return(c(p = NA_real_, n = 0, se = NA_real_, deff = NA_real_))
  p    <- sum(w * y) / sum(w)
  deff <- n * sum(w^2) / (sum(w)^2)          # Kish; = 1 when all weights equal
  se   <- sqrt(deff * p * (1 - p) / n)
  c(p = p, n = n, se = se, deff = deff)
}

## ---- one economy-year cell -------------------------------------------------

cell <- function(d) {
  w <- d$wgt
  A <- d$account_fin == 0 & !is.na(d$account_fin)   # primary base   (D-24)
  B <- d$asked_barriers == 1 & !is.na(d$asked_barriers)  # robustness base

  # Unconditional share of ALL adults who are unbanked on the PRIMARY base AND
  # cite religion. Respondents never asked are treated as "did not cite
  # religion" (they hold an account). Respondents whose religion answer is
  # unknown (DK or Refused) are EXCLUDED from the denominator, since for them
  # the answer is genuinely unknown rather than negative.
  # The numerator is restricted to the primary base so that the decomposition
  # identity below holds exactly rather than approximately.
  valid_all <- !((A | B) & is.na(d$barrier_religion))
  y_all     <- as.integer(A & !is.na(d$barrier_religion) & d$barrier_religion == 1L)

  rA <- wprop(d$barrier_religion[A], w[A])
  rB <- wprop(d$barrier_religion[B], w[B])
  rU <- wprop(y_all[valid_all], w[valid_all])
  ub <- wprop(as.integer(A), w)                     # unbanked share, for D-17 decomposition
  # exact multiplier for the decomposition identity: the weighted share of the
  # primary base among the respondents whose religion answer is known
  uv <- wprop(as.integer(A & !is.na(d$barrier_religion))[valid_all], w[valid_all])

  other <- function(v) if (v %in% names(d)) unname(wprop(d[[v]][A], w[A])["p"]) else NA_real_
  ctx   <- function(v) if (v %in% names(d)) unname(wprop(d[[v]], w)["p"]) else NA_real_

  data.frame(
    iso3   = d$iso3[1], round = d$round[1], economy_label = d$economy_label[1],
    regionwb_raw = d$regionwb_raw[1],
    is_oic = as.integer(d$iso3[1] %in% OIC),
    pop_adult = d$pop_adult[1],
    n_total = nrow(d),
    n_unbanked_fin = sum(A), n_asked = sum(B),
    n_religion_dk_ref = sum(B & is.na(d$barrier_religion)),

    relig_A_p = unname(rA["p"]), relig_A_n = unname(rA["n"]),
    relig_A_se = unname(rA["se"]), relig_A_deff = unname(rA["deff"]),

    relig_B_p = unname(rB["p"]), relig_B_n = unname(rB["n"]),
    relig_B_se = unname(rB["se"]), relig_B_deff = unname(rB["deff"]),

    relig_all_p = unname(rU["p"]), relig_all_n = unname(rU["n"]),
    relig_all_se = unname(rU["se"]),

    unbanked_fin_share = unname(ub["p"]), unbanked_fin_se = unname(ub["se"]),
    unbanked_answered_share = unname(uv["p"]),

    far_A_p = other("barrier_far"), expensive_A_p = other("barrier_expensive"),
    documentation_A_p = other("barrier_documentation"), trust_A_p = other("barrier_trust"),
    money_A_p = other("barrier_money"), family_A_p = other("barrier_family"),
    no_need_A_p = other("barrier_no_need"),

    account_fin_p = ctx("account_fin"), account_mob_p = ctx("account_mob"),
    anydigpayment_p = ctx("anydigpayment"), mobileowner_p = ctx("mobileowner"),
    internet_access_p = ctx("internet_access"), internet_use_p = ctx("internet_use"),
    female_p = ctx("is_female"),
    stringsAsFactors = FALSE, row.names = NULL)
}

## ---- build ------------------------------------------------------------------

key <- paste(panel$iso3, panel$round, sep = "_")
l2  <- do.call(rbind, lapply(split(panel, key), cell))
l2  <- l2[order(l2$iso3, l2$round), ]
row.names(l2) <- NULL

# frame flag (D-25): OIC economies with the religion item in all four rounds
ok <- l2$is_oic == 1 & l2$round %in% OUTCOME_ROUNDS & l2$n_asked > 0
bal <- names(which(table(l2$iso3[ok]) == length(OUTCOME_ROUNDS)))
l2$in_balanced_oic_frame <- as.integer(l2$iso3 %in% bal)

# the identity behind D-17: unconditional = unbanked share x conditional share
# relig_all_p = (share of the primary base among known answers) x (rate within it)
l2$decomposition_check <- l2$unbanked_answered_share * l2$relig_A_p

message("layer 2: ", nrow(l2), " economy-year cells")
message("balanced OIC frame: ", length(bal), " economies, ",
        sum(l2$in_balanced_oic_frame == 1 & l2$round %in% OUTCOME_ROUNDS), " cells")

f <- file.path(DEPOSIT_DIR, "findex_layer2_economy_year.csv")
write.csv(l2, f, row.names = FALSE, na = "")
message("written: deposit/findex_layer2_economy_year.csv")

## ---- codebook for the deposited file ---------------------------------------

cb <- data.frame(rbind(
 c("iso3","ISO3 code; legacy 2011/2014 codes ZAR KSV ROM WBG recoded to COD XKX ROU PSE"),
 c("round","Findex round: 2011, 2014, 2017, 2021, 2024"),
 c("is_oic","1 if the economy is an OIC member state"),
 c("in_balanced_oic_frame","1 if an OIC member with the religion item in all four outcome rounds (34 economies)"),
 c("n_total","respondents in the economy-round (unweighted)"),
 c("n_unbanked_fin","respondents with no financial-institution account (unweighted)"),
 c("n_asked","respondents routed into the unbanked barriers battery (unweighted)"),
 c("n_religion_dk_ref","asked the battery but answered don't know or refused on the religion item"),
 c("relig_A_*","PRIMARY. Share citing religion among adults with no financial-institution account. p, n, design-based se, Kish deff"),
 c("relig_B_*","ROBUSTNESS. Same, among the population actually asked the battery"),
 c("relig_all_*","Share of ALL adults who are unbanked on the primary base AND cite religion. Never-asked treated as no; unknown answers excluded from the denominator"),
 c("unbanked_fin_share","weighted share with no financial-institution account"),
 c("unbanked_answered_share","weighted share of the primary base among respondents whose religion answer is known"),
 c("decomposition_check","unbanked_answered_share x relig_A_p; equals relig_all_p exactly. This is the identity that separates the coverage component from the composition component"),
 c("*_A_p","other barriers, on the primary base, for the share-of-all-reasons robustness"),
 c("account_fin_p ... internet_use_p","context indicators, weighted, whole adult sample"),
 c("relig_* in 2024","EMPTY BY CONSTRUCTION: the religious-reasons item was discontinued in the 2024 round"),
 c("weights","within-economy sampling weight wgt; sum(wgt) equals n in each economy"),
 c("standard errors","sqrt(deff * p(1-p)/n) with deff = n*sum(w^2)/(sum w)^2, the formula used in the Findex methodology notes"),
 c("licence","Derived aggregates only. No individual records. Free to deposit and cite.")
), stringsAsFactors = FALSE)
names(cb) <- c("field", "definition")
write.csv(cb, file.path(DEPOSIT_DIR, "findex_layer2_codebook.csv"), row.names = FALSE)
message("written: deposit/findex_layer2_codebook.csv")

## ---- sanity checks ----------------------------------------------------------

cat("\n=== LAYER 2 CHECKS ===\n")
ck <- function(l, ok, d = "") cat(sprintf("  %-5s %s   %s\n", if (isTRUE(ok)) "OK" else "ALERT", l, d))
ck("2024 has no religion outcome", all(is.na(l2$relig_A_p[l2$round == 2024])))
ck("all proportions within [0,1]",
   all(is.na(l2$relig_A_p) | (l2$relig_A_p >= 0 & l2$relig_A_p <= 1)))
ck("primary base is never larger than the asked base",
   all(l2$relig_A_n <= l2$relig_B_n, na.rm = TRUE),
   "if this alerts, the D-17 finding has changed")
ck("decomposition identity holds exactly",
   max(abs(l2$decomposition_check - l2$relig_all_p), na.rm = TRUE) < 1e-9,
   sprintf("max gap %.2e", max(abs(l2$decomposition_check - l2$relig_all_p), na.rm = TRUE)))
ck("design effects are >= 1", all(l2$relig_A_deff >= 0.99, na.rm = TRUE),
   sprintf("min %.3f", min(l2$relig_A_deff, na.rm = TRUE)))
cat("\nNo rate is interpreted here. Estimation is a separate script.\n")
