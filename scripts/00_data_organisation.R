#كود تحديد بصمة الملفات
install.packages("digest")   # مرة واحدة فقط
library(digest)

setwd("D:/findex-oic")       # عدّليه إلى مساركِ الفعلي

zips <- list.files("raw/zip", pattern = "\\.zip$", full.names = TRUE)
print(zips)                  # تأكدي من ظهور خمسة ملفات

hashes <- data.frame(
  file   = basename(zips),
  bytes  = file.size(zips),
  sha256 = sapply(zips, digest, algo = "sha256", file = TRUE)
)

print(hashes)

dir.create("docs", showWarnings = FALSE)
write.csv(hashes, "docs/checksums_findex_20260815.csv", row.names = FALSE)

#كود معرفة عدد الدول في كل ملف
for (f in csvs) {
  d  <- read.csv(f, stringsAsFactors = FALSE)
  cc <- grep("econom|country|^cn$|^code", names(d),
             ignore.case = TRUE, value = TRUE)
  cat("\n--- ", f, "\n")                       # المسار كاملاً
  cat("     rows:", nrow(d),
      "| cols:", ncol(d),
      "| economies:", if (length(cc)) length(unique(d[[cc[1]]])) else NA, "\n")
  cat("     country cols:", paste(cc, collapse = " · "), "\n")
}


#جرد المتغيّرات (الأهم، وابدئي بها)
#الهدف: العثور على متغيّر «الأسباب الدينية» في كل جولة، ورمزه، وصيغة إجاباته

csvs <- list.files("raw", pattern="\\.csv$", recursive=TRUE, full.names=TRUE)
rounds <- c(2011, 2014, 2017, 2021, 2024)

inv <- do.call(rbind, Map(function(f, r) {
  d <- read.csv(f, nrows = 5, stringsAsFactors = FALSE)
  data.frame(round = r, variable = names(d))
}, csvs, rounds))

write.csv(inv, "docs/variable_inventory.csv", row.names = FALSE)

# ابحثي عن مرشّحي المتغيّر الديني
subset(inv, grepl("relig|reason|barrier|fin11|q10", variable, ignore.case = TRUE))





#ثم افحصي المرشّحين
d21 <- read.csv(csvs[4], stringsAsFactors = FALSE)
table(d21$اسم_المتغيّر_المرشّح, useNA = "ifany")