sample_count <- read.table("MERGED_3_FILTERED_MAC_10%_BED.SCOUNT.scount", header = FALSE)
colnames(sample_count) <- c("FID", "IID", "HOM_REF_CT", "HOM_ALT_SNP_CT", "HET_SNP_CT",
                       "DIPLOID_TRANSITION_CT", "DIPLOID_TRANSVERSION_CT",
                       "DIPLOID_NONSNP_NONSYMBOLIC_CT", "DIPLOID_SINGLETON_CT", 
                       "HAP_REF_INCL_FEMALE_Y_CT", "HAP_ALT_INCL_FEMALE_Y_CT", 
                       "MISSING_INCL_FEMALE_Y_CT")

# test difference in mean (ANOVA)
model <- aov(HET_SNP_CT ~ FID, data = sample_count)
summary(model)
tukey_result <- TukeyHSD(model)
tukey_df <- as.data.frame(tukey_result$FID)
write.csv(tukey_df, "tukey_results_FID.csv", row.names = TRUE)

# make summary table on mean and SD
library(dplyr)

summary_table <- sample_count %>%
                group_by(FID) %>%
                summarise(
                  mean_value = mean(HET_SNP_CT, na.rm = TRUE),
                  sd_value   = sd(HET_SNP_CT, na.rm = TRUE)
                )


write.csv(summary_table, "summary_by_FID.csv", row.names = FALSE)
