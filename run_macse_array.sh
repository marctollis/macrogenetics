#!/bin/bash
#SBATCH --job-name=macse_align
#SBATCH --output=logs/macse_align_%A_%a.out
#SBATCH --error=logs/macse_align_%A_%a.err
#SBATCH --array=1-1  # This will be updated automatically by pre-run script
#SBATCH --cpus-per-task=4
#SBATCH --time=04:00:00
#SBATCH --mem=8G

# Load module or activate environment
source ~/.bash_profile


# Create logs/ directory if not present
mkdir -p logs

# Get list of all .fasta input files (1 per gene per species)
INPUT_LIST="macse_input_list.txt"
FILE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$INPUT_LIST")

# Parse paths
GENE_FILE=$(basename "$FILE")
GENE_NAME="${GENE_FILE%_CDS.fasta}"
SPECIES_DIR=$(basename "$(dirname "$FILE")")

# Define paths
OUT_DIR="macse_aligned_results/${SPECIES_DIR}"
mkdir -p "$OUT_DIR"

NT_OUT="${OUT_DIR}/${GENE_NAME}_CDS_aligned_cleaned_NT.fasta"
AA_OUT="${OUT_DIR}/${GENE_NAME}_CDS_aligned_cleaned_AA.fasta"

# Skip if already aligned and cleaned
if [[ -s "$NT_OUT" && -s "$AA_OUT" ]]; then
  echo "✅ Skipping $GENE_FILE — already aligned and exported"
  exit 0
fi

# Run MACSE alignment
java -jar ~/tools/macse_v2.07.jar -prog alignSequences -seq "$FILE" -out_NT "${OUT_DIR}/${GENE_NAME}_raw_NT.fasta" -out_AA "${OUT_DIR}/${GENE_NAME}_raw_AA.fasta"

# Run MACSE export (clean ! and stop codons)
java -jar ~/tools/macse_v2.07.jar -prog exportAlignment \
  -align "${OUT_DIR}/${GENE_NAME}_raw_NT.fasta" \
  -codonForInternalStop NNN \
  -codonForFinalStop NNN \
  -codonForInternalFS NNN \
  -charForRemainingFS - \
  -out_NT "$NT_OUT" \
  -out_AA "$AA_OUT"
