#!/bin/bash

# this script will take NCBI gene names and use efetch to query their protein IDs, using a list of species. 
# It will then use efetch to download the cds sequences for each NCBI sample.
# The output directories will be organized by species and then gene.

# the script was developed for use on mtDNA sequences for population level phylogeographic analysis but could be adopted for other genes by name.
# already-downloaded genes will be skipped.
# produces a "fetch_log.txt" 

set +e  # continue on error
set -u  # exit on unset vars

# -------- Configuration --------
genes=(ATP6 ATP8 COX1 COX2 COX3 CYTB ND1 ND2 ND3 ND4 ND4L ND5 ND6)
species_file="${1:-species_list.txt}"
output_root="cds_results"
log_file="fetch_log.txt"
dry_run=false

# ---- Handle --dry-run flag ----
if [[ "${1:-}" == "--dry-run" ]]; then
  dry_run=true
  echo "🧪 Dry run mode — no FASTA will be saved"
fi

# ---- Read species file safely ----
species_list=()
while IFS= read -r line || [[ -n "$line" ]]; do
  [[ -z "$line" ]] && continue
  species_list+=("$line")
done < "$species_file"

# ---- Logging ----
echo "🗓 $(date): Run started" > "$log_file"

# ---- Helper: Check if file has ≥5 sequences ----
file_exists_and_valid() {
  [[ -f "$1" && $(grep -c "^>" "$1") -ge 5 ]]
}

# -------- Main Loop --------
for species in "${species_list[@]}"; do
  echo "🔍 Starting $species" | tee -a "$log_file"
  species_underscore="${species// /_}"
  outdir="${output_root}/${species_underscore}"
  mkdir -p "$outdir"

  for gene in "${genes[@]}"; do
    outfile="${outdir}/${species_underscore}_${gene}_CDS.fasta"
    idfile="${outdir}/${species_underscore}_${gene}_CDS.ids.txt"

    # ✅ Skip if both already downloaded and valid
    if file_exists_and_valid "$outfile" && [[ -s "$idfile" ]]; then
      echo "   ⏩ $gene — already exists and valid" | tee -a "$log_file"
      continue
    fi

    echo "🔬 Searching gene: $gene"

    # 🧬 Get protein IDs
    protein_ids=($(esearch -db protein -query "\"$species\"[Organism] AND $gene[Gene]" | efetch -format acc))

    if (( ${#protein_ids[@]} < 5 )); then
      echo "   ⚠️ Skipping $gene — only ${#protein_ids[@]} protein records" | tee -a "$log_file"
      continue
    fi

    echo "${protein_ids[@]}" > "$idfile"
    echo "   💾 Saved ${#protein_ids[@]} protein IDs to $idfile"

    if $dry_run; then
      echo "   🧪 Would fetch sequences for $gene ($species)"
      continue
    fi

    tmpfile=$(mktemp)
    success=0

    for pid in "${protein_ids[@]}"; do
      echo "   ➡️ Fetching $pid"
      fasta=$(efetch -db protein -id "$pid" -format fasta_cds_na 2>/dev/null)

      if [[ -z "$fasta" || "$fasta" != ">"* ]]; then
        echo "     ⚠️ Invalid or missing CDS for $pid"
        continue
      fi

      fasta_clean=$(echo "$fasta" | awk -v sp="$species_underscore" -v gene="$gene" -v pid="$pid" '
        /^>/ {print ">" sp "_" pid "_" gene}
        !/^>/ {print}
      ')

      echo "$fasta_clean" >> "$tmpfile"
      ((success++))
    done

    if [[ -s "$tmpfile" ]]; then
      mv "$tmpfile" "$outfile"
      echo "   ✅ Saved $success sequences to $outfile" | tee -a "$log_file"
    else
      echo "   ❌ No valid sequences saved for $gene" | tee -a "$log_file"
      rm -f "$tmpfile"
    fi
  done

  echo "✅ Finished $species" | tee -a "$log_file"
done

echo "🎉 Done. See $log_file for details."

