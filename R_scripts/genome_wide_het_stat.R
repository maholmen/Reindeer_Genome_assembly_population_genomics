library(dplyr)
setwd("~/00 Population genetics/REVISION/Heterozygosity/Genome_wide")

# read heterozygosity data
het <- read.table(
  "heterozygosity_summary.txt",
  header = TRUE,
  sep = "\t"
)

het <- het %>%
  mutate(
    FID = case_when(
      grepl("^s", ID)   ~ "FI",
      grepl("^FI_", ID) ~ "FI",
      grepl("^FR_", ID) ~ "FR",
      grepl("^VA_", ID) ~ "VA",
      grepl("^LO_", ID) ~ "LO",
      grepl("^RH", ID)  ~ "RH",
      grepl("^IC", ID)  ~ "IC",
      TRUE ~ NA_character_
    )
  )

summary_table <- het %>%
  group_by(FID) %>%
  summarise(
    n = n(),
    Hets_per_kb = paste0(
      round(mean(Hets_per_kb, na.rm = TRUE), 3),
      " (",
      round(sd(Hets_per_kb, na.rm = TRUE), 3),
      ")"
    )
  )

summary_table

write.csv(
  summary_table,
  "summary_heterozygosity_kb_by_population.csv",
  row.names = FALSE
)


het %>%
  group_by(FID) %>%
  summarise(
    mean_callable = mean(Callable_bp),
    sd_callable = sd(Callable_bp)
  )

# ANOVA
model <- aov(Hets_per_kb ~ FID, data = het)
summary(model)

# Tukey post-hoc test
tukey_result <- TukeyHSD(model)

tukey_df <- as.data.frame(tukey_result$FID)

write.csv(
  tukey_df,
  "tukey_results_heterozygosity_kb.csv",
  row.names = TRUE
)

