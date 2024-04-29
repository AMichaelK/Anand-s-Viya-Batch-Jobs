#!/bin/bash


INPUTDIR="data"
INPUTFILE="genmod.tra.gz"
OUTPUTFILE="genmod1.tra"


if [[ $# -eq 0 ]]; then
  echo "This program stages input data for genmod.sas program"
  echo "please provide the target suiteloc/input directory to stage input data"
  echo "this code will copy a single file genmod.tra to the target directory"
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

