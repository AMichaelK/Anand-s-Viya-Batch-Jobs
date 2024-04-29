#!/bin/bash


INPUTDIR="data"


if [[ $# -eq 0 ]]; then
  echo "This program stages input data for hist_clm.sas program"
  echo "please provide the target suiteloc/input directory to stage input data"
  echo "this code will copy a 11 files (1.6GB) hxx[(1-7)pjbc,dp(eac,h1c,jcc)],rtmscnts to the target directory"
  exit 0
fi

if [[ ! -d "$1" ]]; then
  echo "Directory '$1' does not exists. Please check the path and try again"
  exit 1
fi

OUTDIR=$1

FILES=( "hxx1pjbc" "hxx2pjbc" "hxx3pjbc" "hxx4pjbc" "hxx5pjbc" "hxx6pjbc" "hxx7pjbc" "hxxdpeac" "hxxdph1c" "hxxdpjcc" ) 
for f in ${FILES[@]}; do
  echo "Unzipping file to $OUTDIR/$f"
  gunzip -c $INPUTDIR/$f.gz > $OUTDIR/$f
done

cp $INPUTDIR/rtmscnts $OUTDIR/rtmscnts

echo "Done"

