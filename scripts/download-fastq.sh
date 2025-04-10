#!/bin/bash

# Set options
set -euo pipefail

# Run from the directory where this file lives
cd "$(dirname "${BASH_SOURCE[0]}")"

# Set variables
STUDY_ID="SRP255885"
DATA_PATH="../data/raw/fastq/${STUDY_ID}"
FQ_FILE1="SRR11518889_1.fastq.gz"
FQ_FILE2="SRR11518889_2.fastq.gz"
FQ_FILE_PATH1="ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR115/089/SRR11518889/${FQ_FILE1}"
FQ_FILE_PATH2="ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR115/089/SRR11518889/${FQ_FILE2}"
TRIMMED_DIR="../data/trimmed/SRP255885"
REPORTS_DIR="../reports/fastp"

# Create directory for raw fastq data
mkdir -p $DATA_PATH
mkdir -p $TRIMMED_DIR $REPORTS_DIR

# Download the fastq data
if [ ! -e "$DATA_PATH/$FQ_FILE1" ]; then

	echo "Downloading ${FQ_FILE1}"
	
	# Download data from ebi
	curl --output $DATA_PATH/$FQ_FILE1 --url $FQ_FILE_PATH1
fi

if [ ! -e "$DATA_PATH/$FQ_FILE2" ]; then

	echo "Downloading ${FQ_FILE1}"
	
	# Download data from ebi
	curl --output $DATA_PATH/$FQ_FILE2 --url $FQ_FILE_PATH2
fi

# Calculate number of lines in .fastq.gz files
OUTPUT_LINES1=`gunzip -c $DATA_PATH/$FQ_FILE1 | wc -l` 
echo "The number of lines in ${FQ_FILE1} is: ${OUTPUT_LINES1}"

OUTPUT_LINES2=`gunzip -c $DATA_PATH/$FQ_FILE2 | wc -l` 
echo "The number of lines in ${FQ_FILE2} is: ${OUTPUT_LINES2}"

fastp \
	--in1 $DATA_PATH/$FQ_FILE1 \
	--in2 $DATA_PATH/$FQ_FILE2 \
	--out1 $TRIMMED_DIR/$FQ_FILE1 \
	--out2 $TRIMMED_DIR/$FQ_FILE2 \
	--html "${REPORTS_DIR}/SRP255885_report.html"

