setwd("/mnt/project/CWD_reindeer/maholmen_phd/population_genomics/FST_permutation")

library(dplyr)
library(ggplot2)


files <- list.files(pattern = "perm_results", full.names = TRUE)

# read files into list
df_list <- lapply(files, read.table, header = TRUE)

# extract pair names from filenames
for (i in seq_along(df_list)) {
  pair <- gsub("perm_results|\\.txt", "", basename(files[i]))
  pair <- sub("^\\.", "", pair)
  df_list[[i]]$pair <- pair
}

# combine into one dataframe
df <- bind_rows(df_list)


# IMPORTANT: replace numbers with your real FST values
obs_fst <- data.frame(
  pair = unique(df$pair),
  fst_obs = NA
)

rm(pair)


# list all log files
log_files <- list.files(pattern = "\\.log$", full.names = TRUE)

# extract pair name + fst
obs_list <- lapply(log_files, function(file) {

  # read file
  lines <- readLines(file)

  # find weighted FST line
  fst_line <- grep("Weighted Fst estimate:", lines, value = TRUE)

  # extract value
  fst_value <- as.numeric(sub(".*: ", "", fst_line))

  # extract pair name from filename
  pair <- basename(file)
  pair <- sub("\\.fst\\.log$", "", pair)   # remove suffix

  return(data.frame(pair = pair, fst_obs = fst_value))
})

# combine
obs_fst <- bind_rows(obs_list)

# check
print(obs_fst)


df <- df %>%
  left_join(obs_fst, by = "pair")


pvals <- df %>%
  group_by(pair) %>%
  summarise(
    p_value = mean(fst >= fst_obs),
    mean_perm = mean(fst),
    sd_perm = sd(fst),
    .groups = "drop"
  )

# view results
print(pvals)

# save results
write.table(pvals,
          "FST_permutation_summary.txt",
           quote = FALSE,
           row.names = FALSE,
          sep = "\t")



# make sure order is nice
df$pair <- factor(df$pair, levels = sort(unique(df$pair)))


desired_order <- c(
  "FI_FR", "FI_LO", "FI_RH", "FI_VA",
  "FR_RH", "LO_FR", "VA_FR", "VA_LO",
  "VA_RH", "LO_RH",
  "FI_IC", "FR_IC", "LO_IC", "RH_IC", "VA_IC"
)

# apply ordering
df$pair <- factor(df$pair, levels = desired_order)


plot_all <- ggplot(df, aes(x = fst)) +
  geom_histogram(bins = 30, fill = "grey80", color = "white") +
  geom_vline(aes(xintercept = fst_obs), color = "red", linewidth = 0.6, linetype = "dashed") +
  facet_wrap(~pair, ncol = 3, scales = "free") +
  labs(
    title = "Permutation tests of pairwise FST",
    x = "",
    y = "Count"
  ) +
  theme_minimal() +
  theme(
    strip.text = element_text(size = 8),
    plot.title = element_text(hjust = 0.5)
  ) +
  coord_cartesian(expand = FALSE)

ggplot(df, aes(x = fst)) +
  geom_histogram(bins = 25, fill = "grey75", color = "white") +
  geom_vline(aes(xintercept = fst_obs, color = "Observed FST"),
             linewidth = 0.6,
             linetype = "dashed") +
  scale_color_manual(values = c("Observed FST" = "red"), name = "") +
  facet_wrap(~pair, ncol = 3, scales = "free_x") +
  labs(
    title = "Permutation tests of pairwise FST",
    x = "FST",
    y = "Count"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    strip.text = element_text(size = 9, face = "bold"),
    plot.title = element_text(hjust = 0.5),
    legend.position = "top",
    panel.spacing = unit(1, "lines"),
    plot.margin = margin(t = 15, r = 15, b = 15, l = 15),

  ) +
  scale_x_continuous(labels = function(x) sprintf("%.3f", x))

# show plot
print(plot_all)


ggsave("FST_permutation_all_pairs.png",
       plot = plot_all,
       width = 12,
       height = 10,
       dpi = 300)
