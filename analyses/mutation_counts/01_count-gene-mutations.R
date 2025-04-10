#!/usr/bin/env Rscript

# Count the number of samples mutated for each gene in a MAF file.

# This script reads in a MAF file and writes out a table of the genes with
# mutations. The table includes the number of samples that have at least one 
# mutation in the gene, as well as the total number of mutations detected across
# all samples.

# Option descriptions:
#
# --maf :  File path to MAF file to be analyzed. Can be .gz compressed.
# --outfile : The path of the output file to create
# --vaf: Minimum variant allele fraction of mutations to include.
# --min_depth: Minimum sequencing depth to call mutations.
# --include_syn: Flag to include synonymous mutations in counts.

# Example invocation:
#
# Rscript 01_count-gene-mutations.R \
#   --maf mutations.maf.tsv.gz \
#   --outfile gene_counts.tsv

# Load packages -----------------------------------
library(optparse)

# Set up options -----------------------------------

# Create a list of options created with the `optparse` function `make_option()`
# This allow us to specify option flags (short and long), default values,
# the type of data we expect for the value, and help text.
# The option name will be the same as the long option flag.
option_list <- list(
  make_option(
    opt_str = c("--maf", "-m"),
    type = "character",
    default = NA,
    help = "File path of MAF file to be analyzed. Can be .gz compressed."
  ),
  make_option(
    opt_str = c("--outfile", "-o"),
    type = "character",
    default = "gene_counts.tsv",
    help = "File path where output table will be placed."
  ),
  make_option(
    opt_str = c("--vaf", "-v"),
    type = "numeric",
    default = 0.05,
    help = "Minimum variant allele fraction to include (default: %default)"
  ),
  make_option(
    opt_str = c("--min_depth", "-d"),
    type = "numeric",
    default = 0,
    help = "Minimum sequencing depth to include (default: %default)"
  ),
  # This option is boolean, so can be invoked with just the flag and no following value
  make_option(
    opt_str = "--include_syn",
    action = "store_true",
    default = FALSE,
    help = "Include synonymous coding mutations"
  )
)
# Parse options
opts <- parse_args(OptionParser(option_list = option_list))


# Input and option checks --------------------------------- 

# Check that the specified input files are present; 
# exit with error if not using `stop()`
if(!file.exists(opts$maf)){
  stop("The specified MAF file does not exist.")
}


# Define constants --------------------------------------

# Define the MAF `Consequence` values we are interested in and their classification
# based on definitions in http://asia.ensembl.org/Help/Glossary?id=535
syn_class <- c(
  "Silent",
  "Start_Codon_Ins",
  "Start_Codon_SNP",
  "Stop_Codon_Del",
  "De_novo_Start_InFrame",
  "De_novo_Start_OutOfFrame"
)
nonsyn_class <- c(
  "Missense_Mutation",
  "Frame_Shift_Del",
  "In_Frame_Ins",
  "Frame_Shift_Ins",
  "Splice_Site",
  "Nonsense_Mutation",
  "In_Frame_Del",
  "Nonstop_Mutation",
  "Translation_Start_Site"
)

# Main processing code -----------------------------------

# Read input MAF file
maf_df <- readr::read_tsv(opts$maf)

# Select mutations to keep based on command line option
include_class <- nonsyn_class
if(opts$include_syn){
  include_class <- c(include_class, syn_class)
}

# Process the MAF table
muts_df <- maf_df |>
  # select only the fields we need
  dplyr::select(
    Tumor_Sample_Barcode,
    Hugo_Symbol,
    Entrez_Gene_Id,
    Variant_Classification,
    Variant_Type,
    t_depth,
    t_ref_count,
    t_alt_count
  ) |>
  # Calculate VAF
  dplyr::mutate(vaf = t_alt_count / (t_ref_count + t_alt_count)) |>
  # Filter by VAF, min depth & Classification
  dplyr::filter(
    vaf >= opts$vaf,
    t_ref_count + t_alt_count >= opts$min_depth,
    Variant_Classification %in% include_class
  )

# Count mutations by sample and gene
sample_gene_counts <- muts_df |>
  dplyr::count(Tumor_Sample_Barcode, Hugo_Symbol, name = "mut_count")

# Count mutations by gene
gene_counts <- sample_gene_counts |>
  dplyr::group_by(Hugo_Symbol) |>
  dplyr::summarise(
    mutated_samples = dplyr::n(),
    total_muts = sum(mut_count)
  ) |>
  # Sort genes by sample count, then total (descending)
  dplyr::arrange(desc(mutated_samples), desc(total_muts))

  
# Write output
readr::write_tsv(gene_counts, file = opts$outfile)
