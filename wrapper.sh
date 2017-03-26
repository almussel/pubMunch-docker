#!/usr/bin/env bash

set -e

workdir=/work
optdir=/opt
numPMIDs=9999999
test=false

while getopts u:p:t option
do
        case "${option}"
        in
                u) synapseUsername=${OPTARG};;
                p) synapsePassword=${OPTARG};;
                t) test=true;;
        esac
done

if [ test ]
  then
    numPMIDs=20
fi

mirror=$(python -c "from urllib2 import urlopen; import json; print json.load( urlopen('http://www.apache.org/dyn/closer.lua?path=$path&asjson=1'))['preferred']")
wget -O /work/pubMunch/external/pdfbox-app-2.0.5.jar ${mirror}pdfbox/2.0.5/pdfbox-app-2.0.5.jar

wget -O /work/pubMunch/external/docx2txt-1.4.txt https://sourceforge.net/projects/docx2txt/files/latest/download

synapse login -u $synapseUsername -p $synapsePassword --rememberMe

# Download data from Synapse to /workdir/pubMunch/data
mkdir $workdir/pubMunch/data
synapse get -r syn8520180 --downloadLocation $workdir/pubMunch/data

mkdir $workdir/Crawl $workdir/CrawlText

# Pubmed API url: Retrieve all articles that mention "brca" in the title or abstract
pubmedURL="https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&tool=retrPubmed&email=maximilianh@gmail.com&term=brca%2A[Title/Abstract]&retstart=0&retmax="$numPMIDs

# Retrieve list of papers from PubMed
wget -O $workdir/pubmedResponse.xml $pubmedURL

# Extract PMIDs from xml response
python $optdir/getpubs.py $workdir/pubmedResponse.xml > $workdir/allPmids.txt

# Download list of previously crawled PMIDs from synapse
# TODO
#synapse get syn... --downloadLocation $workdir
touch $workdir/crawledPmids.txt

# Determine which PMIDs are new since the last run
sort -i $workdir/allPmids.txt
sort -i $workdir/crawledPmids.txt
grep -F -x -v -f $workdir/crawledPmids.txt $workdir/allPmids.txt > $workdir/Crawl/pmids.txt

# Crawl the new PMIDs
$workdir/pubMunch/pubCrawl2 -du $workdir/Crawl

# Convert crawled papers to text
$workdir/pubMunch/pubConvCrawler $workdir/Crawl $workdir/CrawlText

# Find mutations in crawled papers
$workdir/pubMunch/pubFindMutations $workdir/CrawlText $workdir/mutations.tsv

# Download previously found mutations
# TODO
#synapse get syn... --downloadLocation $workdir
touch $workdir/foundMutations.tsv
echo "this is a header line\n" > $workdir/foundMutations.tsv 

cat $workdir/foundMutations.tsv  <(tail -n +2 $workdir/mutations.tsv) > $workdir/all_mutations.tsv

# 
echo "Matching mutations to BRCA variants"
if [ test ]
  then
    synapse get syn8532322 --downloadLocation /work
fi
gunzip $workdir/CrawlText/0_00000.articles.gz
python $optdir/pubs_json.py $workdir/all_mutations.tsv $workdir/CrawlText/0_00000.articles > $workdir/brca_pubs.json

echo "Uploading mutations and pmids"
# Upload new list of PMIDs and mutations
mv $workdir/Crawl/pmids.txt $workdir/crawledPmids.txt
mv $workdir/all_mutations.tsv $workdir/foundMutations.tsv
synapse add $workdir/crawledPmids.txt --parentId=syn8506589
synapse add $workdir/foundMutations.tsv --parentId=syn8506589

