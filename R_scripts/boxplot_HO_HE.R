library(dplyr)
library(ggplot2)
library(ggpubr)
library(RColorBrewer)


setwd("~/00 Population genetics/Publication MAC = 2/heterozygosity")

# Loop and create one file

folder_path <- "~/00 Population genetics/Publication MAC = 2/heterozygosity"

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
library(tidyr)

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

my_colors <- c("#f0c571", "#36b700", "#0b81a2", "#e25759", "#7e4794","#59a89c")


p1 <- ggplot(data, aes(x = box, y = value, fill = FID)) +
  geom_boxplot(alpha = 0.6, outlier.shape = NA, width = 0.9) +
  geom_jitter(aes(color = FID), width = 0.1, alpha = 0.5, size = 1.5) +
  scale_fill_manual(values = my_colors) +
  scale_color_manual(values = my_colors) +
  theme_minimal() +
  xlab("") +
  ylab("Fraction of heterozygosity in segregating SNPs") + 
  theme(legend.position = "none", 
        axis.title.y = element_text(size=12), 
        axis.text.y = element_text(size=12)
  ) + 
  stat_compare_means(
    comparisons = list(c("FI HE", "FI HO"), c("FR HE", "FR HO"), c("VA HE", "VA HO"),
                       c("LO HE", "LO HO"), c("RH HE", "RH HO"), c("IC HE", "IC HO")),
    method = "t.test",
    label = "p.signif", 
    step.increase = 0.00,
    size = 6
  )  + 
  scale_y_continuous(n.breaks = 10)



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


#### Barplot of Ho-He
p2 <- ggplot(data_summary, aes(x = FID, y = HoHe_mean)) + 
  geom_col(width = 0.6) + 
  theme_minimal() + 
  coord_cartesian(ylim = c(0.001, 0.007)) +
  xlab("") +
  ylab("H\u1D52 - H\u1D49") + 
  theme(
    axis.title.y = element_text(size=12), 
    axis.text.y = element_text(size=12), 
    axis.text.x = element_text(size=11)
  ) +
  scale_y_continuous(n.breaks = 10)


## combined plot 
library(patchwork)

# combine plots next to each other
combined_plot <- (p2 | p1) + 
  plot_layout(widths = c(1,4))
combined_plot

ggsave(
  filename = "combined_plot.png",
  plot = combined_plot,
  width = 10,      # width in inches
  height = 6,      # height in inches
  dpi = 300        # resolution in dots per inch
)
