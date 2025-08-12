# Macrogenetics
This repository contains the scripts needed to download population-level sampling of mtDNA or nucDNA genes for a list of species in .fasta format with NCBI e-utilities and align them with a codon-based aligner. You will need to have [NCBI e-utilities](https://www.ncbi.nlm.nih.gov/books/NBK179288/) installed in your PATH, as well as the [MACSE](https://www.agap-ge2pop.org/macsee-pipelines/) alignment software. The alignment scripts assume you are using SLURM on an HPC system. 

## All scripts should be run in the same directory, which is also where the output directories will be written

fetch_mtDNA_cds_species.sh - For each species in the list (a sample species_list.txt is given here, you will have to write this on your own for your analyses), this script will search NCBI for any protein ID associated with a given gene name, and download its coding sequence. The result is a database of multi-sequence fasta files. By default, the script will not download a gene sequence when there is <5 samples per gene.

It's best to run the fetch_mtDNA_cds_species.sh script serially, as an array gunks up the NCBI server and you end up missing a lot of sequences. So the best thing to do is sign into your HPC or remote computer, cd to the fetch working directory, open a screen session, and do 'bash fetch_mtDNA_cds_species.sh', and ctl+A ct1+D to detatch from the screen session.

Then when all the sequences are donwloaded in the cds_results/ directory, run:

        bash submit_macse_array.sh
        
                This contains the call to run_macse_array.sh and will auto-count the number of jobs for the array based on the number of .fasta files.

To check if this worked, cd into macse_aligned directory and run: find . -type d -empty
This will list out any empty directories that may have been missed by the array, and you can run macse individually on those.
