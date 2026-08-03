# Plot seperate K's in pdf's 
setwd("/mnt/project/CWD_reindeer/maholmen_phd/population_genomics/admixture")
# ---- Okabe-Ito palette ----
okabe_ito <- c(
  "#0072B2", "#D55E00", "#009E73",
  "#CC79A7", "#E69F00", "#56B4E9"
)

okabe <- function(n) okabe_ito[1:n]

for (K in 1:6){

  pdf(paste0("admixture_plot_K", K, ".pdf"),
      useDingbats = FALSE,
      width = (175 / 25.4) , height = ( 100 / 25.4))

  # ---- improve margins ----
  par(mar = c(8,4,2,1))
  tbl = read.table(paste0("input_admixture.", K, ".Q"))

  fam <- read.table("input_admixture.fam", header = FALSE)
  colnames(fam) <- c("FID", "IID", "PID", "MID", "SEX", "PHENO")

  pop_id <- fam[,1:2]
  data <- cbind(pop_id, tbl)

  # ---- set population order ----
  data$FID <- factor(data$FID, levels = c("FI","FR","VA","LO","RH","IC"))
  data <- data[order(data$FID), ]


  Q_cols <- grep("^V", names(data))

  # ---- plotting ----
  bp <- barplot(
    t(as.matrix(data[, Q_cols])),
    col = okabe(K),
    border = NA,
    space = 0.2,
    xlab = "",
    ylab = "Ancestry proportion",
    xaxt = "n"
  )

  # ---- find boundaries ----
  pop_labels <- data$FID
  breaks <- which(pop_labels[-1] != pop_labels[-length(pop_labels)])

  line_pos <- (bp[breaks] + bp[breaks + 1]) / 2

  # thinner lines (journal style)
  abline(v = line_pos, lwd = 1)

  # ---- compute midpoints for labels ----
  mid_pos <- (c(min(bp), line_pos) + c(line_pos, max(bp))) / 2

  # ---- add labels ----
  axis(1,
       at = mid_pos,
       labels = levels(data$FID),
       tick = FALSE,
       las = 1,
       cex.axis = 1)


  text(
    x = max(bp) + 5,   # slightly to the right of the last bar
    y = 0.5,           # middle of y-axis (adjust if needed)
    labels = paste0("K = ",K),
    xpd = TRUE,        # allows drawing outside plot region
    cex = 1,
    srt = -90
  )

  dev.off()

# plot main figure with K=2 and K=3 together and manipulate colors to look nicer 
# ---- libraries ----
library(dplyr)

# ---- Okabe-Ito palette ----
okabe_ito <- c(
  "#0072B2", "#D55E00", "#009E73",
  "#CC79A7", "#E69F00", "#56B4E9"
)

okabe <- function(n) okabe_ito[1:n]

# ---- create Figure 2 ----
pdf("Figure2.pdf",
    useDingbats = FALSE,
    width = 175/25.4, height = 120/25.4)


layout(matrix(c(1,2), nrow = 2), heights = c(1,1))
par(mar = c(2.5,6,1.5,2))
#par(mar = c(bottom, left, top, right))

# ---- loop over K values ----
for (K in c(2,3)) {

  # ---- read data ----
  tbl <- read.table(paste0("input_admixture.", K, ".Q"))

  fam <- read.table("input_admixture.fam", header = FALSE)
  colnames(fam) <- c("FID", "IID", "PID", "MID", "SEX", "PHENO")

  pop_id <- fam[,1:2]
  data <- cbind(pop_id, tbl)

  # ---- set population order ----
  data$FID <- factor(data$FID, levels = c("FI","FR","VA","LO","RH","IC"))
  data <- data[order(data$FID), ]

  # ---- identify Q columns ----
  Q_cols <- grep("^V", names(data))

  # FIX COLOR CONSISTENCY (ICELAND FIRST)
  Q_mat <- as.matrix(data[, Q_cols])

  ic_idx <- data$FID == "IC"

  # average ancestry proportions in Iceland
  ic_means <- colMeans(Q_mat[ic_idx, , drop = FALSE])

  # sort clusters so Iceland-dominant cluster is first
  new_order <- order(ic_means, decreasing = TRUE)

  Q_mat <- Q_mat[, new_order]
  data[, Q_cols] <- Q_mat


  # ---- plotting ----
  bp <- barplot(
    t(as.matrix(data[, Q_cols])),
    col = okabe(K),
    border = NA,
    space = 0.2,
    xlab = "",
    ylab = "Ancestry proportion",
    xaxt = "n"
  )


  usr <- par("usr")   # get plot coordinates

  text(
    x = usr[1] - (usr[2] - usr[1]) * 0.2,  
    y = usr[4] + 0.1,                      
    labels = ifelse(K == 2, "A", "B"),
    font = 1,
    xpd = TRUE,
    cex = 1.2
  )



  # ---- find population boundaries ----
  pop_labels <- data$FID
  breaks <- which(pop_labels[-1] != pop_labels[-length(pop_labels)])
  line_pos <- (bp[breaks] + bp[breaks + 1]) / 2

  abline(v = line_pos, lwd = 1)

  # ---- add population labels ----
  mid_pos <- (c(min(bp), line_pos) + c(line_pos, max(bp))) / 2

  axis(1,
       at = mid_pos,
       labels = levels(data$FID),
       tick = FALSE,
       las = 1,
       cex.axis = 1)

  text(
    x = max(bp) + 5,
    y = 0.5,
    labels = paste0("K = ", K),
    xpd = TRUE,
    srt = -90,
    cex = 1
  )
}

dev.off()
