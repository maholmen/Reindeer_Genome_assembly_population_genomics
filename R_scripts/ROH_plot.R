# Load necessary libraries
library(ggplot2)
library(dplyr)
library(tidyr)
library(ggpubr)
library(RColorBrewer)



# === Read data ===
roh_500 <- read.table("500.NORWEGIAN_and_ICELAND.hom.indiv", header = TRUE)
roh_1mb <- read.table("1000.NORWEGIAN_and_ICELAND.hom.indiv", header = TRUE)
roh_8mb <- read.table("8000.NORWEGIAN_and_ICELAND.hom.indiv", header = TRUE)
roh_4mb <- read.table("4000.NORWEGIAN_and_ICELAND.hom.indiv", header = TRUE)

# === Calculate FROH ===
genome_kb <- 2370380044 / 1000  # adjust for your species

roh_names <- c("roh_500", "roh_1mb", "roh_4mb", "roh_8mb")

for (name in roh_names) {
  df <- get(name)
  suffix <- sub("roh_", "", name)
  
  df <- df %>%
    mutate(!!paste0("FROH_", suffix) := KB / genome_kb)
  
  assign(name, df)
}



# === Merge data sets with 500 Kb as the lowest value  ===
roh_all <- roh_500 %>%
  select(FID, IID, FROH_500) %>%
  inner_join(select(roh_1mb, IID, FROH_1mb), by = "IID") %>%
  inner_join(select(roh_4mb, IID, FROH_4mb), by = "IID") %>%
  inner_join(select(roh_8mb, IID, FROH_8mb), by = "IID") 


summary(roh_all)

# Make sure FID is a factor with your ordering
roh_all$FID <- factor(roh_all$FID,
                      levels = c("FI", "FR", "VA", "LO", "RH", "IC"))

my_colors <- c("#f0c571", "#36b700", "#0b81a2", "#e25759", "#7e4794","#59a89c")


p1 <- ggplot(roh_all, aes(x = FID, y = FROH_500, fill = FID)) +
  geom_violin(trim = T, alpha = 0.8, color = "black", linewidth = 0.6, width = 1) +
  scale_fill_manual(values = my_colors) +
  theme_minimal() +
  theme(
    legend.position = "none",
    axis.title.y = element_text(size = 12),
    axis.text.y  = element_text(size = 12),
    axis.text.x  = element_text(size = 12)
  ) +
  coord_cartesian(ylim = c(0, 0.34)) +
  scale_y_continuous(n.breaks = 10) +
  ylab(expression(F[ROH] >= 500 ~ Kb)) +
  xlab("")



p2 <- ggplot(roh_all, aes(x = FID, y = FROH_1mb, fill = FID)) +
  geom_violin(trim = T, alpha = 0.8, color = "black", linewidth = 0.6, width = 1) +
  scale_fill_manual(values = my_colors) +
  theme_minimal() +
  theme(
    legend.position = "none",
    axis.title.y = element_text(size = 12),
    axis.text.y  = element_text(size = 12),
    axis.text.x  = element_text(size = 12)
  ) +
  coord_cartesian(ylim = c(0, 0.34)) +
  scale_y_continuous(n.breaks = 10) +
  ylab(expression(F[ROH] >= 1 ~ Mb)) +
  xlab("")


p3 <- ggplot(roh_all, aes(x = FID, y = FROH_4mb, fill = FID)) +
  geom_violin(trim = T, alpha = 0.8, color = "black", linewidth = 0.6, width = 1) +
  scale_fill_manual(values = my_colors) +
  theme_minimal() +
  theme(
    legend.position = "none",
    axis.title.y = element_text(size = 12),
    axis.text.y  = element_text(size = 12),
    axis.text.x  = element_text(size = 12)
  ) +
  coord_cartesian(ylim = c(0, 0.044)) +
  scale_y_continuous(n.breaks = 10) +
  ylab(expression(F[ROH] >= 4 ~ Mb)) +
  xlab("")


p4 <- ggplot(roh_all, aes(x = FID, y = FROH_8mb, fill = FID)) +
  geom_violin(trim = T, alpha = 0.8, color = "black", linewidth = 0.6, width = 1) +
  scale_fill_manual(values = my_colors) +
  theme_minimal() +
  theme(
    legend.position = "none",
    axis.title.y = element_text(size = 12),
    axis.text.y  = element_text(size = 12),
    axis.text.x  = element_text(size = 12)
  ) +
  coord_cartesian(ylim = c(0, 0.044)) +
  scale_y_continuous(n.breaks = 10) +
  ylab(expression(F[ROH] >= 8 ~ Mb)) +
  xlab("")

library(patchwork)

# combine plots next to each other
combinel_plot <- (p1 | p2) / (p3 | p4)


ggsave(
  filename = "combined_plot_above_500.png",
  plot = combinel_plot,
  width = 9,      # width in inches
  height = 9,      # height in inches
  dpi = 300        # resolution in dots per inch
)


froh_summary <- roh_all %>%
  group_by(FID) %>%
  summarise(
    n = n(),
    across(
      starts_with("FROH_"),
      list(
        mean = ~ round(mean(.x, na.rm = TRUE), 4),
        sd   = ~ round(sd(.x, na.rm = TRUE), 4),
        min  = ~ round(min(.x, na.rm = TRUE), 4),
        max  = ~ round(max(.x, na.rm = TRUE), 4)
      ),
      .names = "{.fn}_{.col}"
    )
  )


# Export summary tables
write.csv(froh_summary, "froh_summary.csv", row.names = FALSE)
