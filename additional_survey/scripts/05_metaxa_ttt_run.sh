#!/bin/bash

############################################################################
#             Script for running metaxa2_ttt over several files
# 
# 
#   This script runs through all the output folders generated by metaxa2
# and uses metaxa2_ttt to compile a summary of the *.taxonomy.txt file. 
# You can adjust which taxa will appear and to waht depth you would like results
# 
# 
# Input file = a *.taxonomy.txt file from metaxa2
# output = a new file with the summary output
###############################################################################


#for dir in /data/andrewc/tagridzhanova_project/results/metaxa_runs/*
mkdir ./results/metaxa_summaries # make directory for outputs

cd ./results/metaxa_runs/ # go into the output folder

for dir in ./* # get list of directories in metaxa_runs folder

do
SAMPLE="${dir##*/}" # get sample ID out of directory name

cd "$dir" # move into the directory
rm reads_*level_*.txt # remove previous attempts if they exist

# run metaxa2_ttt
metaxa2_ttt -i "$SAMPLE".taxonomy.txt -o reads_"$SAMPLE" -t b,e -r 80 -m 7 -n 3

# copy the output files to the metaxa_summaries folder
cp reads_"$SAMPLE".level_5.txt ../../metaxa_summaries/

echo "$SAMPLE has been processed"
echo "-----------------------------------------------------------------------"

cd .. # return to 'metaxa_runs' directory

done

cd ../metaxa_summaries/ # change to metaxa_summaries directory

# run metaxa2_dc on all the files in this directory
metaxa2_dc reads_*.level_5.txt -o ../metaxa_level_5_combined.txt

cd ../.. # get back to project home directory