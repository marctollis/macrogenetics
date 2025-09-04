library(ape)
library(pegas)
library(dplyr)

setwd("/scratch/mt2245/fetch_mtDNA")
input_dir <- "macse_aligned_results"

results <- data.frame()
species_dirs <- list.dirs(input_dir, recursive = FALSE)

for (species_path in species_dirs) {
  species <- basename(species_path)
  fasta_files <- list.files(species_path, pattern = "_CDS_aligned_cleaned_NT\\.fasta$", full.names = TRUE)
  
  for (fasta_file in fasta_files) {
    gene <- sub("_CDS_aligned\\.fasta$", "", sub(paste0("^", species, "_"), "", basename(fasta_file)))
    
    if (!file.exists(fasta_file) || file.info(fasta_file)$size == 0) {
      message("⚠️ Skipping missing or empty file: ", fasta_file)
      next
    }
    
    dna <- tryCatch(read.dna(fasta_file, format = "fasta"), error = function(e) return(NULL))
    if (is.null(dna) || nrow(dna) < 5) {
      message("⚠️ Could not read or too few sequences: ", fasta_file)
      next
    }
    
    # Filter sequences with >75% Ns or gaps
    mat <- as.character(as.matrix(dna))
    seq_missing <- rowMeans(mat == "-" | mat == "n")
    keep_seqs <- seq_missing < 0.75
    if (sum(keep_seqs) < 5) {
      message("⚠️ Too few sequences after filtering: ", fasta_file)
      next
    }
    dna <- dna[keep_seqs, ]
    
    # Filter sites with >50% Ns or gaps
    mat <- as.character(as.matrix(dna))
    site_missing <- colMeans(mat == "-" | mat == "n")
    keep_sites <- site_missing < 0.5
    if (sum(keep_sites) < 100) {
      message("⚠️ Too few informative sites: ", fasta_file)
      next
    }
    dna <- as.DNAbin(mat[, keep_sites, drop = FALSE])
    
    # Compute basic summary statistics
    pi <- nuc.div(dna)
    theta <- theta.s(dna)
    segsites <- length(seg.sites(dna))
    haps <- haplotype(dna)
    hap_div <- hap.div(haps)
    num_haps <- nrow(haps)
    tajd <- tajima.test(dna)$D
    HapsPerSeq <- ifelse(nrow(dna) > 0, round(num_haps / nrow(dna), 5), NA)
    SegSitesPerSite <- ifelse(ncol(dna) > 0, round(segsites / ncol(dna), 5), NA)
    
    # Add to results
    results <- rbind(results, data.frame(
      Species = species,
      Gene = gene,
      NumSeqs = nrow(dna),
      Length = ncol(dna),
      SegSites = segsites,
      SegSitesPerSite = SegSitesPerSite,
      NumHaps = num_haps,
      HapDiv = round(hap_div, 5),
      HapsPerSeq = HapsPerSeq,
      Pi = round(pi, 5),
      ThetaW = round(theta, 5),
      TajD = round(tajd, 3),
      stringsAsFactors = FALSE
    ))
    
    message("✅ Processed ", species, " — ", gene)
  }
}

write.csv(results, "mtDNA_summary_stats.csv", row.names = FALSE)
message("✅ Results saved to mtDNA_summary_stats.csv")


# boxplots to compare diversity across genes

#library(tidyr)
#library(ggplot2)
#library(dplyr)

# Select and reshape the data
#plot_data <- results %>%
#  select(Species, Pi, ThetaW, HapDiv, TajD, SegSitesPerSite, HapsPerSeq) %>%
#  pivot_longer(cols = -Species, names_to = "Statistic", values_to = "Value")

# Plot faceted boxplots
#ggplot(plot_data, aes(x = Species, y = Value)) +
#  geom_boxplot(fill = "lightgreen") +
#  facet_wrap(~Statistic, scales = "free_y") +
#  theme_minimal() +
#  labs(title = "PopGen Summary Statistics on mtDNA by Species",
#       x = "Species", y = "Value") +
#  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# ggsave('mtDNA_summstats+figure.pdf', width = 12, units = 'in')

# Histogram of Tajima's D and pi across all alignments
library(ggplot2)

# Tajima's D
ggplot(results, aes(x = TajD)) +
  geom_histogram(fill = "lightblue", color = "black", bins = 30) +
  theme_minimal() +
  labs(title = "Distribution of Tajima's D Across Genes",
       x = "Tajima's D", y = "Count")
# Nucleotide diversity (π)
ggplot(results, aes(x = Pi)) +
  geom_histogram(fill = "lightcoral", color = "black", bins = 30) +
  theme_minimal() +
  labs(title = "Distribution of Nucleotide Diversity (π)",
       x = "π", y = "Count")
# Correlation matrix among summary stats (e.g., TajD, Pi, ThetaW, HapDiv)
stats_df <- results %>%
  select(Pi, ThetaW, TajD, HapDiv, SegSitesPerSite, HapsPerSeq) %>%
  na.omit()

# Correlation plot
ggcorrplot::ggcorrplot(cor(stats_df), lab = TRUE, lab_size = 3, type = "lower")


# Example: test correlation between π and Tajima's D
cor.test(results$Pi, results$TajD, use = "complete.obs")

# Example: linear model of TajD ~ Pi + Gene + Species (mixed model might be better)
lm_model <- lm(TajD ~ Pi + ThetaW + HapDiv, data = results)
summary(lm_model)

# Boxplots of TajD by Gene
ggplot(results, aes(x = Gene, y = TajD)) +
  geom_boxplot(fill = "lightgreen") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  labs(title = "Tajima's D by Gene")

# Or by Gene
ggplot(results, aes(x = Gene, y = Pi)) +
  geom_boxplot(fill = "orange") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  labs(title = "Nucleotide Diversity (π) by Gene")

