#!/bin/bash


INPUTDIR="census1_pums"
COUNT=90000

if [[ $# -eq 0 ]]; then
  echo "This program generates input data for census1.sas program"
  echo "please provide the target suiteloc directory to stage input data"
  echo "this code will create a subdirectory 'cdata' and generate files inside it"
  exit 0
fi

if [[ ! -d "$1" ]]; then
  echo "Directory '$1' does not exists. Please check the path and try again"
  exit 1
fi

OUTDIR=$1

# Delete the cdata directory first if it already exists
if [[ -d "$OUTDIR/cdata" ]]; then
  echo "The directory '$OUTDIR/cdata' already exists. Deleting the sub-directory"
  rm -rf $OUTDIR/cdata
fi

# Create a new empty output directory
echo "Creating a new empty directory '$OUTDIR/cdata'"
mkdir $OUTDIR/cdata

# to store all the PIDS of background jobs
pids=""

# Replicate data using the source
for infile in $INPUTDIR/*.txt
do
  outfile=`basename $infile`
  outfilepath="$OUTDIR/cdata/$outfile"
  echo "Creating $outfilepath count:$COUNT"

  seq 1 $COUNT | xargs -Inone cat $infile >> $outfilepath &
  # store the pid of the job
  pids="$pids $!"
done

echo "Waiting for all the jobs to finish"
wait $pids

echo "Done"

