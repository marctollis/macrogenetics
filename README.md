# Macrogenetics

This repository contains the scripts that will download population-level phylogeographic sampling of mtDNA or nucDNA genes for a list of species in .fasta format with NCBI e-utilities and align them with a codon-based aligner. You will need to have [NCBI e-utilities](https://www.ncbi.nlm.nih.gov/books/NBK179288/) installed in your PATH, as well as the [MACSE](https://www.agap-ge2pop.org/macsee-pipelines/) alignment software. The alignment scripts assume you are using SLURM on an HPC system, and makes use of SLURM arrays in the alignment step.

## All scripts should be run in the same directory, which is also where the output directories will be written.

fetch_mtDNA_cds_species.sh - For each species in the list (a sample species_list.txt is given here, you will have to write this on your own for your analyses), this script will search NCBI for any protein ID associated with a given gene name, and download its coding sequence. Edit line 15 of the script in a text editor to include the gene names (by default, there are 13 protein-coding mitochondrial genes provided). The result is a database of multi-sequence fasta files, organized by species and then by gene. By default, the script will not download a gene sequence when there is <5 samples per gene. The script will skip species for which there is already data.

It's best to run the fetch_mtDNA_cds_species.sh script serially, as an array gunks up the NCBI server and you end up missing a lot of sequences. So the best thing to do is sign into your HPC or remote computer, cd to the fetch working directory, open a screen session, and do 'bash fetch_mtDNA_cds_species.sh', and ctl+A ct1+D to detatch from the screen session.

You can use the [count_sequences_by_gene.sh](https://github.com/marctollis/macrogenetics/blob/main/count_sequences_by_gene.sh) script which will summarize the genes and number of sequences downloaded for each species.

Then when all the sequences are downloaded in the cds_results/ directory, run:

        bash submit_macse_array.sh
        
                This contains the call to run_macse_array.sh and will auto-count the number of jobs for the array based on the number of .fasta files.

To check if this worked, cd into macse_aligned directory and run: find . -type d -empty
This will list out any empty directories that may have been missed by the array, and you can run macse individually on those.

We chose MACSE as an aligner since it creates codon-based alignments, which are more robust for many downstream population genetics analyses. Something like MAFFT done serially could theoretically be much quicker, but we still think a MACSE SLURM array is worth it. For a recent analysis of a few thousand species, 99.999% of the MACSE alignments finished within a few minutes, and the largest and most complex ones finshed within a few short hours.

After MACSE finishes aligning, you can use the [mtDNA_sumstats.R](https://github.com/marctollis/macrogenetics/blob/main/mtDNA_sumstats.R) script to estimate population summary statistics and output a .csv file for downstream analyses.
