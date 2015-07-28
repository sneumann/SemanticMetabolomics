#!/bin/bash
shopt -s nullglob
threads=12
password=cat pass.txt
#path to the R script
scriptname=Extract.R
#path to the massbank OD folder
foldername="./"

mol_fname=`curl -s ftp://ftp.ebi.ac.uk/pub/databases/chembl/ChEMBL-RDF/latest/ --list-only | grep  molecule.ttl`
#echo "ftp://ftp.ebi.ac.uk/pub/databases/chembl/ChEMBL-RDF/latest/$mol_fname"

#Get chembl
rm -rf chembl_latest_molecule.ttl.gz
rm -rf cco_latest.ttl.gz
timestamp=$(date +%Y_%m_%d_%H_%M)
curl "ftp://ftp.ebi.ac.uk/pub/databases/chembl/ChEMBL-RDF/latest/$mol_fname" > chembl_${timestamp}_molecule.ttl.gz
curl "ftp://ftp.ebi.ac.uk/pub/databases/chembl/ChEMBL-RDF/latest/cco.ttl.gz" > cco_${timestamp}.ttl.gz
ln -s chembl_${timestamp}_molecule.ttl.gz chembl_latest_molecule.ttl.gz
ln -s cco_${timestamp}.ttl.gz cco_latest.ttl.gz
gunzip chembl_latest_molecule.ttl.gz
gunzip cco_latest.ttl.gz
#Get chebi
rm -rf chebi_latest.owl
curl "ftp://ftp.ebi.ac.uk/pub/databases/chebi/ontology/chebi.owl" > chebi_${timestamp}.owl
ln -s chebi_${timestamp}.owl chebi_latest.owl
#Get massbank records
svn checkout "http://www.massbank.jp/SVN/OpenData/record/"

#Run R-Script

#/usr/bin/env Rscript ...
echo "Rscript $scriptname -f $foldername"
#Resulting N3 is in ./Opendata_full.N3

echo "SPARQL CLEAR GRAPH <www.massbank.jp>;" | isql-v -P "$password"
echo "SPARQL CLEAR GRAPH <www.ebi.ac.uk/chebi/>;" | isql-v -P "$password"
echo "SPARQL CLEAR GRAPH <www.ebi.ac.uk/chembl/>;" | isql-v -P "$password"


echo "ld_dir('.', 'chembl_latest_molecule.ttl' , 'www.ebi.ac.uk/chembl/');" | isql-v -P "$password"
echo "ld_dir('.', 'cco_latest.ttl' , 'www.ebi.ac.uk/chembl/');" | isql-v -P "$password"
echo "ld_dir('.', 'chebi_latest.owl' , 'www.ebi.ac.uk/chebi/');" | isql-v -P "$password"
echo "ld_dir('.', 'massbank_latest.ttl' , 'www.massbank.jp');" | isql-v -P "$password"

for i in 1 .. $threads
do
	echo "rdf_loader_run();" | isql-v -P "$password"
done

