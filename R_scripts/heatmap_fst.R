# Making heatmap of Fst values using ggplot2
setwd("~/00 Population genetics/Pulication material/FST")
# Load libraries
library(readxl)
library(ggplot2)
library(reshape2)
library(RColorBrewer)
library(scales)
library(extrafont)


# Read the Excel sheet
df <- FST_plink <- read_excel("FST_values.xlsx", 
                             sheet = "Sheet2")
df <- as.data.frame(df)

# Set row names from the first column and remove that column
rownames(df) <- df[[1]]
df <- df[, -1]

# Convert all columns to numeric
df_numeric <- as.data.frame(lapply(df, function(x) {
  if (is.character(x) || is.factor(x)) {
    as.numeric(as.character(x))
  } else {
    x
  }
}), check.names = FALSE)

rownames(df_numeric) <- rownames(df)

# Convert to matrix
mat <- as.matrix(df_numeric)

# Define colors
my_colors <- colorRampPalette(c("lightblue", "lightgreen", "pink", "orange"))(100)

#change labels
value_labels <- matrix(round(mat, 3), nrow = nrow(mat), ncol = ncol(mat))
value_labels[is.na(mat)] <- ""


# Create breaks
data_min <- min(mat, na.rm = TRUE)
data_max <- max(mat, na.rm = TRUE)
fine_breaks1 <- seq(data_min, 0.01, length.out = 40)
mid_breaks <- seq(0.01, 0.08, length.out = 20)
fine_breaks2 <- seq(0.08, data_max, length.out = 40)
breaks_custom <- unique(c(data_min, fine_breaks1[-1], mid_breaks[-1], fine_breaks2[-1], data_max))

rescaled_breaks <- rescale(breaks_custom^0.5)  # Square root transformation

# Melt the matrix for ggplot
mat_df <- melt(mat, varnames = c("Row", "Col"), value.name = "Value")
mat_df$Label <- as.vector(value_labels)

# Create the heatmap using ggplot2
ggplot(mat_df, aes(x = Col, y = Row, fill = Value)) +
  geom_tile(color = "grey90", na.rm = FALSE) +
  geom_text(aes(label = Label), color = "black", size = 4, fontface = "bold") +  # adjust size if needed
  scale_fill_gradientn(colors = my_colors,
                       values = rescaled_breaks,
                       limits = c(min(mat, na.rm = TRUE), max(mat, na.rm = TRUE)),
                       na.value = "white",
                       labels = scales::label_number(accuracy = 0.01),
                       breaks = seq(0, 0.12, by = 0.02)) +
  theme_minimal() +
  scale_y_discrete(position = "right") +
  scale_x_discrete(position = "top") +
  theme(axis.text.x = element_text(angle = 0, vjust = 0.5, size=12, color = "black"),
        axis.text.y = element_text(size = 12, color = "black"),
        legend.position = "left",
 #       panel.background = element_rect(fill = "#F6F6EE", color = NA),         
#        plot.background = element_rect(fill = "#F6F6EE", color = NA),        
 #       legend.background = element_rect(fill = "#F6F6EE", color = NA),      
  #      legend.key = element_rect(fill = "#F6F6EE", color = NA),
        legend.title = element_text(size = 12),
        legend.text = element_text(size = 12),
        legend.key.height = unit(1.5, "cm")) +       
  labs(fill = "Fst") +
  labs(x = NULL, y = NULL)


ggsave("FST_values_ALL.png", width = 9, height = 4, dpi = 300)
