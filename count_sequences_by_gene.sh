#!/bin/bash

# === Configuration ===
results_dir="cds_results"
output_file="cds_gene_counts.tsv"

echo -e "Species\tGene\tNumSequences" > "$output_file"

# Loop through each species directory
for species_dir in "$results_dir"/*; do
  species=$(basename "$species_dir")

  # Loop through each gene FASTA file
  for fasta_file in "$species_dir"/*_CDS.fasta; do
    [ -e "$fasta_file" ] || continue  # skip if no files

    gene=$(basename "$fasta_file" | sed -E "s/^${species}_//; s/_CDS\.fasta//")
    count=$(grep -c "^>" "$fasta_file")

    echo -e "${species}\t${gene}\t${count}" >> "$output_file"
  done
done

echo "✅ Sequence counts written to: $output_file"

