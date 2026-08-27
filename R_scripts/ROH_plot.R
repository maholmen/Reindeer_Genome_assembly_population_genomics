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


# ROH above 4Mb plot:
library(stringr)
library(dplyr)
library(ggplot2)

roh_4000_hom <- read.table("4000.NORWEGIAN_and_ICELAND.hom", header = TRUE)
roh_4000_hom$CHR_number <- str_extract(roh_4000_hom$CHR, "(?<=chromosome_)[0-9]+")

roh_plot_df <- roh_4000_hom %>%
  mutate(CHR = as.integer(CHR_number))

chromosome_length <- read.delim("chromosome_contig_length.txt", header = F, sep = " ")
chromosome_length_f <- chromosome_length[1:36, ]    
chromosome_length_filtered <- chromosome_length_f[-c(34, 35), ]
rm(chromosome_length, chromosome_length_f)
chromosome_length_filtered$chr_name <- sub("^>", "", chromosome_length_filtered$V1)
chromosome_length_filtered$chr_len <- chromosome_length_filtered$V2
chromosome_length_filtered$CHR <- as.integer(str_extract(chromosome_length_filtered$chr_name, "(?<=chromosome_)\\d+"))
chr_info <- chromosome_length_filtered[, -c(1, 2)]

chr_info_ROH <- chr_info %>%
  mutate(
    # ensure length is double (not integer)
    chr_len = as.numeric(chr_len)
  ) %>%
  arrange(CHR) %>%
  mutate(
    chr_start_genome = lag(cumsum(chr_len), default = 0),
    chr_mid          = chr_start_genome + chr_len / 2
  )


roh_genome <- roh_plot_df %>%
  inner_join(chr_info_ROH, by = "CHR")


fam <- read.table("MERGED_3_FILTERED_MAC.PLINK_FILTERED.fam", header = FALSE)

all_ids <- fam[, c(1, 2)]
colnames(all_ids) <- c("FID", "IID")

# Ensure start <= end (safe guard)
roh_genome_2 <- roh_genome %>%
  mutate(
    start_bp = pmin(POS1, POS2),
    end_bp   = pmax(POS1, POS2)
  ) %>%
  # Now shift to genome-wide coordinates using chr_start_genome from chr_info
  mutate(
    x_start = chr_start_genome + start_bp,
    x_end   = chr_start_genome + end_bp
  )

roh_genome_2 <- all_ids %>%
  left_join(roh_genome_2, by = c("FID", "IID"))


gap <- 1e6   # gap size in base pairs

roh_genome_2 <- roh_genome_2 %>%
  mutate(
    x_start_gap = x_start + (CHR - 1) * gap,
    x_end_gap   = x_end   + (CHR - 1) * gap
  )

chr_info_gap <- chr_info_ROH %>%
  mutate(
    chr_start_genome_gap = chr_start_genome + (CHR - 1) * gap,
    chr_mid_gap = chr_mid + (CHR - 1) * gap
  )


genome_end <- 2368204912 + 38281903

p_roh_genome <- ggplot(roh_genome_2, aes(y = IID)) +
  geom_segment(
    aes(x = x_start_gap, xend = x_end_gap, yend = IID, color = factor(CHR)),
    linewidth = 1, lineend = "round"
  ) +
  geom_vline(
    aes(xintercept = chr_start_genome_gap),
    data = chr_info_gap,
    linewidth = 0.5,
    color = "grey70"
  ) +
  scale_x_continuous(
    breaks = chr_info_gap$chr_mid_gap,
    labels = chr_info_gap$CHR,
    expand = expansion(mult = c(0.00, 0.00))
  ) +
  scale_y_discrete(drop = FALSE) +
  coord_cartesian(xlim = c(0, genome_end)) +
  theme_minimal() +
  theme(
    legend.position = "none",
    
    # REMOVE GRID
    panel.grid.major.x = element_blank(),
    panel.grid.minor.x = element_blank(),
    panel.grid.major.y = element_line(color = "grey90"),
    panel.grid.minor.y = element_blank(),
    
    # AXIS STYLE FOR BETTER VISIBILITY
    axis.text.x = element_text(size = 12, face = "bold"),
    axis.title.y = element_text(size = 12), 
    axis.text.y = element_blank(),
    axis.ticks.y = element_blank()
    
  ) +
  xlab("Chromosome") +
  ylab("Individual (IID)") + 
  facet_wrap(~ FID, scales = "free_y", ncol = 1)

p_roh_genome

ggsave("ROH_frequency_above4Mb.png", plot = p_roh_genome,  
       width = 12,      # width in inches
       height = 10,      # height in inches
       dpi = 300 )
