#!/bin/bash

OUTPUTFILE="customer_50mil_1.dat"
COUNT=50000000


if [[ $# -eq 0 ]]; then
  echo "This program stages input data for dim_50mil.sas program"
  echo "please provide the target suiteloc/input directory to stage input data"
  echo "this code will copy a single file customer_50mil_1.dat to the target directory"
  exit 0
fi

if [[ ! -d "$1" ]]; then
  echo "Directory '$1' does not exists. Please check the path and try again"
  exit 1
fi

OUTDIR=$1


if [[ -f "$OUTDIR/$OUTPUTFILE" ]]; then
  echo "The file $OUTDIR/$OUTPUTFILE exists. Delete the file if you need to regenerate the data"
  exit 0
fi

# Generate File
echo "Generating $OUTDIR/$OUTPUTFILE"
for ((n=0;n<=$COUNT;n++)); do
  printf '%12.0f           0           0MThomas Keefer                           Thomas                        Keefer                        11SEP1967    3841                         US                                                                                                                                                   Clayton                       1123    Emerson  Road                                \n' "$n" 
done | dd of=$OUTDIR/$OUTPUTFILE

# Copy Customer Type Data
cp data/customer_type_1.dat $OUTDIR

echo "Done"
