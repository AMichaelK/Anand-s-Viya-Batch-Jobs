#!/bin/bash


INPUTDIR="data"
INPUTFILE="pumsaxxx.txt.gz"
OUTPUTFILE_1="pumsaxxx.txt"
OUTPUTFILE_2="pumsaxca_1.txt"
COUNT=200000

if [[ $# -eq 0 ]]; then
  echo "This program generates input data for io_ca1.sas program"
  echo "please provide the target suiteloc/input directory to stage input data"
  echo "this code will create files inside input/ directory"
  exit 0
fi

if [[ ! -d "$1" ]]; then
  echo "Directory '$1' does not exists. Please check the path and try again"
  exit 1
fi

OUTDIR=$1

echo "Uncompressing $INPUTDIR/$INPUTFILE to $OUTDIR"
gunzip -c $INPUTDIR/$INPUTFILE > $OUTDIR/$OUTPUTFILE_1

if [[ -f $OUTDIR/$OUTPUTFILE_2 ]]; then
  echo "File $OUTDIR/$OUTPUTFILE_2 already exists. Delete existing file if you wish to re-generate"
  exit 0
fi

# 10000 = 2.5 GB
seq 1 $COUNT | xargs -Inone cat $OUTDIR/$OUTPUTFILE_1 >> $OUTDIR/$OUTPUTFILE_2
# make a copy for sysparm 2 and 3
cp $OUTDIR/$OUTPUTFILE_2 $OUTDIR/pumsaxca_2.txt
cp $OUTDIR/$OUTPUTFILE_2 $OUTDIR/pumsaxca_3.txt
echo "Done"

