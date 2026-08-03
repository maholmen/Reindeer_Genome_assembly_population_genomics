library(ggplot2)
library(ggpubr)
library(RColorBrewer)
library(tidyr)
library(dplyr)
library(patchwork)
setwd("~/00 Population genetics/REVISION/Heterozygosity")

# Loop and create one file

folder_path <- "~/00 Population genetics/REVISION/Heterozygosity"

files <- list.files(path = folder_path, pattern = "\\.txt$", full.names = TRUE)

data_list <- lapply(files, function(f) {
  read.table(f, header = TRUE, sep = "\t")
})

names(data_list) <- basename(files)

data <- do.call(rbind, lapply(files, function(f) {
  read.table(f, header = TRUE, sep = "\t")
}))

# Calculate Ho-He

data$HoHe <- data$HO - data$HE

################# create box plot ##################
# pivot
class(data)


data <- pivot_longer(
  data,
  cols = c(HO, HE),
  names_to = "type",
  values_to = "value"
)


# create a additional column to seperate observed and expected values 
data$box <- paste(data$FID, data$type)

data$box <- factor(data$box,
                   levels = c("FI HE",
                              "FI HO", 
                              "FR HE", 
                              "FR HO",
                              "VA HE", 
                              "VA HO", 
                              "LO HE", 
                              "LO HO", 
                              "RH HE",
                              "RH HO", 
                              "IC HE", 
                              "IC HO"))



###### barplot of differences ###########

data_summary <- data %>%
  group_by(FID) %>%
  summarise(HoHe_mean = mean(HoHe, na.rm = TRUE), 
            HoHe_sd = sd(HoHe, na.rm = TRUE))



data_summary$FID <- factor(data_summary$FID,
                   levels = c("FI",
                              "FR", 
                              "VA", 
                              "LO", 
                              "RH",
                              "IC"))



################# for publication ##############################

my_colors <- c("#F5C710", "#009e73", "#0072b2", '#D55E00', "#cc79a7","#56b4e9")
p1 <- ggplot(data, aes(x = box, y = value, fill = FID)) +
  geom_boxplot(alpha = 0.6, outlier.shape = NA, width = 0.9,
               linewidth = 0.2) +                              
  geom_jitter(aes(color = FID), width = 0.1, alpha = 0.5, size = 1) +
  scale_fill_manual(values = my_colors) +
  scale_color_manual(values = my_colors) +
  theme_minimal(base_family = "sans") +
  xlab("") +
  ylab("Fraction of heterozygotes in segregating SNPs") +
  theme(
    legend.position  = "none",
    axis.title.y     = element_text(size = 8, family = "sans"),
    axis.text.y      = element_text(size = 7, family = "sans"),
    axis.text.x      = element_text(size = 7, family = "sans"),
    axis.line        = element_line(linewidth = 0.5),
    axis.ticks       = element_line(linewidth = 0.5),
    panel.grid.major = element_line(linewidth = 0.5, color = "grey90"),
    panel.grid.minor = element_blank(),
    panel.background = element_rect(fill = "white", color = NA),
    plot.margin      = unit(c(2, 2, 2, 2), "mm")
  ) +
  stat_compare_means(
    comparisons = list(c("FI HE", "FI HO"), c("FR HE", "FR HO"), c("VA HE", "VA HO"),
                       c("LO HE", "LO HO"), c("RH HE", "RH HO"), c("IC HE", "IC HO")),
    method = "t.test",
    label = "p.signif",
    paired = TRUE,
    step.increase = 0.00,
    size = 3.5                                                 # 10 pt ??? 3.5 in geom units
  ) +
  scale_y_continuous(n.breaks = 10)



p2 <- ggplot(data_summary, aes(x = FID, y = HoHe_mean, fill = FID)) +
  geom_col(width = 0.6, linewidth = 0.5) +                    # 0.5 pt border
  theme_minimal(base_family = "sans") +                        # base font
  coord_cartesian(ylim = c(0.001, 0.007)) +
  xlab("") +
  ylab("H\u1D52 - H\u1D49") +
  theme(
    axis.title.y     = element_text(size = 8, family = "sans"),
    axis.text.y      = element_text(size = 7, family = "sans"),
    axis.text.x      = element_text(size = 7, family = "sans"),
    axis.line        = element_line(linewidth = 0.5),          # 0.5 pt axis line
    axis.ticks       = element_line(linewidth = 0.5),          # 0.5 pt ticks
    panel.grid.major = element_line(linewidth = 0.5, color = "grey90"),
    panel.grid.minor = element_blank(),
    panel.background = element_rect(fill = "white", color = NA),
    legend.position  = "none",                                 # FID already on x-axis
    plot.margin      = unit(c(5, 5, 5, 5), "mm")
  ) +
  scale_y_continuous(n.breaks = 10) +
  scale_fill_manual(values = my_colors)

print(p2)
print(p1)


combined_plot <- (p1 | p2) + 
  plot_layout(widths = c(4, 1)) +
  plot_annotation(tag_levels = "A") &
    theme(
      plot.tag  = element_text(size = 10, family = "sans", face = "plain"),
      plot.margin = unit(c(1, 1, 1, 1), "mm")    # reduce margin on each panel
    )


combined_plot

ggsave(
  filename = "combined_plot4.pdf",
  plot = combined_plot,
  width = 175,        # double column mm
  height = 100,        # height in mm
  units = "mm",
  device = cairo_pdf  # embeds fonts per guidelines
)
