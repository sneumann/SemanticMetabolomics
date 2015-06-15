#! /bin/bash
shopt -s nullglob
threads=12
password=cat pass.txt
#path to the R script
scriptname=cat Extract.R
#path to the massbank OD folder
foldername=cat folderpath

mol_fname=`curl -s ftp://ftp.ebi.ac.uk/pub/databases/chembl/ChEMBL-RDF/latest/ --list-only | grep  molecule.ttl`
#echo "ftp://ftp.ebi.ac.uk/pub/databases/chembl/ChEMBL-RDF/latest/$mol_fname"

#Get chembl
curl "ftp://ftp.ebi.ac.uk/pub/databases/chembl/ChEMBL-RDF/latest/$mol_fname" > chembl_latest_molecule.ttl.gz
curl "ftp://ftp.ebi.ac.uk/pub/databases/chembl/ChEMBL-RDF/latest/cco.ttl.gz" > cco_latest.ttl.gz
gunzip chembl_latest_molecule.ttl.gz
gunzip cco_latest.ttl.gz
#Get chebi
curl "ftp://ftp.ebi.ac.uk/pub/databases/chebi/ontology/chebi.owl" > chebi_latest.owl

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

for i in 1 .. threads
do
	echo "rdf_loader_run();" | isql-v -P "$password"
done

