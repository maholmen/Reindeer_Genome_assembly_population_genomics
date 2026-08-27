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

my_colors <- c("#F5C710", "#009e73", "#0072b2", "#D55E00", "#cc79a7", "#56b4e9")

boxplot_theme <- function() {
  list(
    scale_fill_manual(values = my_colors),
    theme_minimal(base_family = "sans"),
    theme(
      legend.position  = "none",
      axis.title.y     = element_text(size = 9, family = "sans"),
      axis.text.y      = element_text(size = 8, family = "sans"),
      axis.text.x      = element_text(size = 8, family = "sans"),
      axis.line        = element_line(linewidth = 0.5),
      axis.ticks       = element_line(linewidth = 0.5),
      panel.grid.major = element_line(linewidth = 0.5, color = "grey90"),
      panel.grid.minor = element_blank(),
      panel.background = element_rect(fill = "white", color = NA),
      plot.margin      = unit(c(2, 2, 2, 2), "mm")
    ),
    scale_y_continuous(n.breaks = 10),
    xlab("")
  )
}


p3 <- ggplot(roh_all, aes(x = FID, y = FROH_500, fill = FID)) +
  geom_boxplot(
    alpha = 0.8,
    color = "black",
    linewidth = 0.5,
    width = 0.8,
    outlier.shape = NA
  ) +
  geom_jitter(
    aes(fill = FID),
    shape = 21,
    color = "black",
    size = 1.5,
    stroke = 0.3,
    width = 0.15
  ) +
  coord_cartesian(ylim = c(0, 0.34)) +
  ylab(expression(F[ROH] >= 500 ~ Kb)) +
  boxplot_theme()

p4 <- ggplot(roh_all, aes(x = FID, y = FROH_1mb, fill = FID)) +
  geom_boxplot(
    alpha = 0.8,
    color = "black",
    linewidth = 0.5,
    width = 0.8,
    outlier.shape = NA
  ) +
  geom_jitter(
    aes(fill = FID),
    shape = 21,
    color = "black",
    size = 1.5,
    stroke = 0.3,
    width = 0.15
  ) +
  coord_cartesian(ylim = c(0, 0.34)) +
  ylab(expression(F[ROH] >= 1 ~ Mb)) +
  boxplot_theme()

p5 <- ggplot(roh_all, aes(x = FID, y = FROH_4mb, fill = FID)) +
  geom_boxplot(
    alpha = 0.8,
    color = "black",
    linewidth = 0.5,
    width = 0.8,
    outlier.shape = NA
  ) +
  geom_jitter(
    aes(fill = FID),
    shape = 21,
    color = "black",
    size = 1.5,
    stroke = 0.3,
    width = 0.15
  ) +
  coord_cartesian(ylim = c(0, 0.044)) +
  ylab(expression(F[ROH] >= 4 ~ Mb)) +
  boxplot_theme()

p6 <- ggplot(roh_all, aes(x = FID, y = FROH_8mb, fill = FID)) +
  geom_boxplot(
    alpha = 0.8,
    color = "black",
    linewidth = 0.5,
    width = 0.8,
    outlier.shape = NA
  ) +
  geom_jitter(
    aes(fill = FID),
    shape = 21,
    color = "black",
    size = 1.5,
    stroke = 0.3,
    width = 0.15
  ) +
  coord_cartesian(ylim = c(0, 0.044)) +
  ylab(expression(F[ROH] >= 8 ~ Mb)) +
  boxplot_theme()

combinel_plot_2 <- (p3 | p4) / (p5 | p6)

ggsave(
  "figure4.pdf",
  plot = combinel_plot_2,
  width = 175,
  height = 170,
  units = "mm",
  device = cairo_pdf
)

ggsave(
  "FIGURE_4.jpg",
  plot = combinel_plot_2,
  width = 175,
  height = 170,
  units = "mm",
  dpi = 600
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
