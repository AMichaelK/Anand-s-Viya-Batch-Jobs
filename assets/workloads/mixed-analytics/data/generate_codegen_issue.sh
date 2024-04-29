#!/bin/bash


INPUTDIR="data"
INPUTFILE="in.sas7bdat.gz"
OUTPUTFILE="in.sas7bdat"


if [[ $# -eq 0 ]]; then
  echo "This program stages input data for codegen_issue.sas program"
  echo "please provide the target suiteloc/input directory to stage input data"
  echo "this code will copy a single file in.sas7bdat to the target directory"
  exit 0
fi

if [[ ! -d "$1" ]]; then
  echo "Directory '$1' does not exists. Please check the path and try again"
  exit 1
fi

OUTDIR=$1

echo "Unzipping file to $OUTDIR/$OUTPUTFILE"
gunzip -c $INPUTDIR/$INPUTFILE > $OUTDIR/$OUTPUTFILE

echo "Done"

