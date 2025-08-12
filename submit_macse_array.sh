#!/bin/bash

# Make fresh input list
find big_cds_results/ -name '*_CDS.fasta' > macse_input_list.txt

# Count lines
N=$(wc -l < macse_input_list.txt)

# Submit job with array range
sbatch --array=1-${N} run_macse_array.sh

