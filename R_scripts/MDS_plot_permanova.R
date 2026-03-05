# load library
library(tidyverse)
library(readr)
library(dplyr)
library(ggplot2)
library(vegan)

setwd("~/00 Population genetics/Publication MAC = 2/MDS")
############################################ With Iceland ##########################################################
#Read files
MDS <- read_table("MDS_plot.mds.mod",col_names = TRUE)

mds_data <- MDS

#add population names
mds_data$Population <- sub("^([A-Za-z]+).*", "\\1", mds_data$FID)

# Then map specific codes
mds_data$Population[mds_data$Population == "s"] <- "FI"
mds_data$Population[mds_data$Population == "mt"] <- "FI"
mds_data$Population[mds_data$Population == "ICXX"] <- "IC"

# Create a distance matrix from C1 and C2
dist_matrix <- dist(mds_data[, c("C1", "C2")], method = "euclidean")

# Run PERMANOVA
adonis_result <- adonis2(dist_matrix ~ Population, data = mds_data, permutations = 999)

# Show result
print(adonis_result)


# Assuming `mds_data` has: FID, C1, C2, Population

# Convex hull calculation
hull_data <- mds_data %>%
  group_by(Population) %>%
  slice(chull(C1, C2))

# Extract permanova values
F_value <- round(adonis_result$F[1], 3)
R2_value <- round(adonis_result$R2[1], 3)
p_value <- adonis_result$`Pr(>F)`[1]

# Format p-value for clarity
p_label <- ifelse(p_value < 0.001, "< 0.001", round(p_value, 3))

# Create a label string
permanova_label <- paste0("PERMANOVA\nF = ", F_value,
                          "\nR\u00B2 = ", R2_value,
                          "\np = ", p_label)

mds_data$Population <- factor(mds_data$Population, levels = c("FI",
                                                              "FR", 
                                                              "VA", 
                                                              "LO", 
                                                              "RH",
                                                              "IC"))
hull_data$Population <- factor(hull_data$Population, levels = levels(mds_data$Population))


colors <- c("#f0c571", "#36b700", "#0b81a2", "#e25759", "#7e4794","#59a89c")

#PLOT

p<- ggplot(mds_data, aes(x = C1, y = C2, color = Population)) +
  geom_point(size = 2.5 , alpha = 0.9) +
#  stat_ellipse(type = "t", level = 0.95, linetype = "dashed") +
#  geom_polygon(data = hull_data, aes(x = C1, y = C2, fill = Population),
 #              alpha = 0.2, color = NA, show.legend = FALSE) +
  annotate("text", x = 0.06 , y = 0.02, 
           label = permanova_label,
           size = 3.5) +
  theme_minimal() +
  labs(title = "",
       x = "MDS1",
       y = "MDS2") +
  scale_color_manual(name = "", values = colors, 
                     #labels = c("FI" = "Filefjell", "FR" = "Fram", "LO" = "Lom", "VA" = "V\u00E5g\u00E5", "IC"="Iceland", "RH"="Riast-Hylling"),
                     guide = guide_legend(ncol = 3)) +
  scale_fill_manual(values = colors) +
  theme(
    legend.position = "right",
    legend.direction = "horizontal",
    panel.background = element_rect(fill = "white", color = NA),         # grid area
#    plot.background = element_rect(fill = "#F6F6EE", color = NA),        # outer background
#    legend.background = element_rect(fill = "#F6F6EE", color = NA),      # legend box
#    legend.key = element_rect(fill = "#F6F6EE", color = NA),              # key boxes
    axis.title = element_text(size = 12),
    axis.text = element_text(size = 12),
    legend.title = element_text(size = 12),
    legend.text = element_text(size = 12)
    
  ) +
  guides(color = guide_legend(ncol = 1))
  
print(p)

ggsave("mds_plot_with_ICELAND.png", plot = p, width = 6, height = 5, dpi = 300)
#ggsave("mds_plot_without_ICELAND.eps", plot = p, width = 6, height = 6, device = cairo_ps)



####################################################################################

# Convert to a standard data frame
adonis_df <- as.data.frame(adonis_result)

# Add term names as a column (rownames are terms like "Model", "Residual")
adonis_df <- adonis_df %>%
  rownames_to_column(var = "Term")
write_csv(adonis_df, "permanova_results_with_ICELAND.csv")




###### pair-wise permanova #########

# Define populations
pop_levels <- c("FI", "FR", "LO", "RH", "VA", "IC")

# Generate all pairwise combinations
pair_combos <- combn(pop_levels, 2, simplify = FALSE)

# Perform adonis2 for each pair using lapply
pairwise_results <- lapply(pair_combos, function(pops) {
  # Subset data and distance matrix
  subset_idx <- mds_data$Population %in% pops
  sub_data <- droplevels(mds_data[subset_idx, ])
  dist_sub <- as.dist(as.matrix(dist_matrix)[subset_idx, subset_idx])
  
  # Run PERMANOVA
  result <- adonis2(dist_sub ~ Population, data = sub_data, permutations = 999)
  return(result)
})

# Name the list elements for clarity
names(pairwise_results) <- sapply(pair_combos, function(p) paste0(p[1], "_vs_", p[2]))

# Print results
for (name in names(pairwise_results)) {
  cat("\n====", name, "====\n")
  print(pairwise_results[[name]])
}

# Extract results into a single data frame
result_df <- do.call(rbind, lapply(names(pairwise_results), function(name) {
  res <- pairwise_results[[name]]
  
  # Get the first row (Population effect)
  row <- res[1, , drop = FALSE]
  
  # Add comparison name as a column
  row$Comparison <- name
  
  # Reorder columns: Comparison first
  row <- row[, c(ncol(row), 1:(ncol(row)-1))]
  
  return(row)
}))

# Write to CSV
write.csv(result_df, "pairwise_permanova_results_with_ICELAND.csv", row.names = FALSE)


############################################ With Iceland ##########################################################
#Read files
MDS <- read_table("MERGED_3_FILTERED.PLINK_FILTERED.LINKAGE_PRUNED.NOandIC.mds.mod",col_names = TRUE)

mds_data <- MDS

#add population names
mds_data$Population <- sub("^([A-Za-z]+).*", "\\1", mds_data$FID)

# Then map specific codes
mds_data$Population[mds_data$Population == "s"] <- "FI"
mds_data$Population[mds_data$Population == "mt"] <- "FI"
mds_data$Population[mds_data$Population == "ICXX"] <- "IC"

# Create a distance matrix from C1 and C2
dist_matrix <- dist(mds_data[, c("C1", "C2")], method = "euclidean")

# Run PERMANOVA
adonis_result <- adonis2(dist_matrix ~ Population, data = mds_data, permutations = 999)

# Show result
print(adonis_result)


# Assuming `mds_data` has: FID, C1, C2, Population

# Convex hull calculation
hull_data <- mds_data %>%
  group_by(Population) %>%
  slice(chull(C1, C2))

# Extract permanova values
F_value <- round(adonis_result$F[1], 3)
R2_value <- round(adonis_result$R2[1], 3)
p_value <- adonis_result$`Pr(>F)`[1]

# Format p-value for clarity
p_label <- ifelse(p_value < 0.001, "< 0.001", round(p_value, 3))

# Create a label string
permanova_label <- paste0("PERMANOVA\nF = ", F_value,
                          "\nR\u00B2 = ", R2_value,
                          "\np = ", p_label)

mds_data$Population <- factor(mds_data$Population, levels = c("FI", "RH", "FR", "LO", "VA", "IC"))
hull_data$Population <- factor(hull_data$Population, levels = levels(mds_data$Population))


colors <- c(
  "#E16A86", # pink
  "#009ADE",  # blue
  "#B88A00",  # mustard
  "#50A315",  # green
  "#C86DD7",  # purple
  "#00AD9A"   # teal
)


#PLOT

p<- ggplot(mds_data, aes(x = C1, y = C2, color = Population)) +
  geom_point(size = 2.5 , alpha = 0.9) +
  #  stat_ellipse(type = "t", level = 0.95, linetype = "dashed") +
  #  geom_polygon(data = hull_data, aes(x = C1, y = C2, fill = Population),
  #              alpha = 0.2, color = NA, show.legend = FALSE) +
  annotate("text", x = 0.075 , y = 0.02, 
           label = permanova_label,
           size = 3.5) +
  theme_minimal() +
  labs(title = "",
       x = "MDS1",
       y = "MDS2") +
  scale_color_manual(name = "", values = colors, 
                     labels = c("FI" = "Filefjell", "FR" = "Fram", "LO" = "Lom", "VA" = "V\u00E5g\u00E5", "IC"="Iceland", "RH"="Riast-Hylling"),
                     guide = guide_legend(ncol = 3)) +
  scale_fill_manual(values = colors) +
  theme(
    legend.position = "bottom",
    legend.direction = "horizontal",
    panel.background = element_rect(fill = "white", color = NA),         # grid area
    #    plot.background = element_rect(fill = "#F6F6EE", color = NA),        # outer background
    #    legend.background = element_rect(fill = "#F6F6EE", color = NA),      # legend box
    #    legend.key = element_rect(fill = "#F6F6EE", color = NA),              # key boxes
    axis.title = element_text(size = 8),
    axis.text = element_text(size = 8),
    legend.title = element_text(size = 8),
    legend.text = element_text(size = 12)
    
  ) 

print(p)

ggsave("mds_plot_with_ICELAND.png", plot = p, width = 6, height = 6, dpi = 300)
ggsave("mds_plot_with_ICELAND.eps", plot = p, width = 6, height = 6, device = cairo_ps)

# Convert to a standard data frame
adonis_df <- as.data.frame(adonis_result)

# Add term names as a column (rownames are terms like "Model", "Residual")
adonis_df <- adonis_df %>%
  rownames_to_column(var = "Term")
write_csv(adonis_df, "permanova_results_with_ICELAND.csv")




################### pair-wise permanova ##############

# Define populations
pop_levels <- c("FI", "FR", "LO", "RH", "VA", "IC")

# Generate all pairwise combinations
pair_combos <- combn(pop_levels, 2, simplify = FALSE)

# Perform adonis2 for each pair using lapply
pairwise_results <- lapply(pair_combos, function(pops) {
  # Subset data and distance matrix
  subset_idx <- mds_data$Population %in% pops
  sub_data <- droplevels(mds_data[subset_idx, ])
  dist_sub <- as.dist(as.matrix(dist_matrix)[subset_idx, subset_idx])
  
  # Run PERMANOVA
  result <- adonis2(dist_sub ~ Population, data = sub_data, permutations = 999)
  return(result)
})

# Name the list elements for clarity
names(pairwise_results) <- sapply(pair_combos, function(p) paste0(p[1], "_vs_", p[2]))

# Print results
for (name in names(pairwise_results)) {
  cat("\n====", name, "====\n")
  print(pairwise_results[[name]])
}

# Extract results into a single data frame
result_df <- do.call(rbind, lapply(names(pairwise_results), function(name) {
  res <- pairwise_results[[name]]
  
  # Get the first row (Population effect)
  row <- res[1, , drop = FALSE]
  
  # Add comparison name as a column
  row$Comparison <- name
  
  # Reorder columns: Comparison first
  row <- row[, c(ncol(row), 1:(ncol(row)-1))]
  
  return(row)
}))

# Write to CSV
write.csv(result_df, "pairwise_permanova_results_with_ICELAND.csv", row.names = FALSE)
