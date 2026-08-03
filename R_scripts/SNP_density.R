# --------------------------
# 1. Load required packages
# --------------------------
library(dplyr)
library(ggplot2)

# --------------------------
# 2. Load SNP data
# --------------------------
snp <- read.table("MERGED_3_FILTERED_MAC.PLINK_FILTERED.bim", stringsAsFactors = FALSE)

# PLINK BIM format columns
colnames(snp) <- c("chr", "snp_id", "cm", "pos", "a1", "a2")

# --------------------------
# 3. Define window size
# --------------------------
window_size <- 1000000   # 1 Mb windows

# --------------------------
# 4. Calculate SNP density
# --------------------------
snp_density <- snp %>%
  group_by(chr, window = floor(pos / window_size)) %>%
  summarise(n_snps = n(), .groups = "drop") %>%
  mutate(
    start = window * window_size,
    end = start + window_size,
    density = n_snps / window_size
  )

# --------------------------
# 5. Quick checks
# --------------------------
summary(snp_density$density)

# --------------------------
# 6. Plot SNP density (optional but useful)
# --------------------------
ggplot(snp_density, aes(x = density)) +
  geom_histogram(bins = 50) +
  labs(title = "SNP density distribution",
       x = "SNPs per base pair",
       y = "Number of windows")

# --------------------------
# 7. Optional: check variation across chromosomes
# --------------------------
ggplot(snp_density, aes(x = as.factor(chr), y = density)) +
  geom_boxplot() +
  labs(title = "SNP density per chromosome",
       x = "Chromosome",
       y = "SNP density")




chr_summary <- snp_density %>%
  group_by(chr) %>%
  summarise(
    mean_density = mean(density),
    median_density = median(density),
    sd_density = sd(density),
    min_density = min(density),
    max_density = max(density),
    n_windows = n(),
    .groups = "drop"
  )

# View results
print(chr_summary)

# --------------------------
# 8. Save results
# --------------------------
write.table(chr_summary, "snp_density.txt",
            row.names = FALSE, col.names = TRUE, quote = FALSE)
