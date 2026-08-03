# calcuate and plot site frequency spectrum plot (from freq command in PLINK)
freq <- read.table("stats.FREQ.frq",
                   header = TRUE,
                   fill = TRUE,
                   comment.char = "",
                   stringsAsFactors = FALSE,
                   row.names = NULL)



# Extract numeric frequencies
a1 <- as.numeric(sub(".*:", "", freq$X.ALLELE.FREQ.))
a2 <- as.numeric(sub(".*:", "", freq[,5]))

# Minor allele frequency
maf <- pmin(a1, a2)

# Plot SFS
hist(maf,
     breaks = 50,
     main = "Site Frequency Spectrum",
     xlab = "Minor Allele Frequency")


# Save plot as PNG
png("Site_Frequency_Spectrum.png", width=800, height=600)

hist(maf,
     breaks = 50,
     main = "Site Frequency Spectrum",
     xlab = "Minor Allele Frequency",
     col = "lightgrey",
     border = "black")

dev.off()
