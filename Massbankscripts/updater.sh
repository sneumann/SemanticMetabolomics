#!/bin/bash

shopt -s nullglob
threads=12
password=$(cat pass.txt)
#path to the R script
scriptname=Extract.R
#path to the massbank OD folder
foldername="./record"
download=false
massbank=false
install=false

while getopts "f:dimat:hp:t:" opt; do
case $opt in
h)
echo -e "Help:\n -f set the folder for the Massbank script [./record]\n -d just download new files without installing them\n -m just run the Massbank script\n -i just reinstall all files into the Virtuso instance\n -a do a complete update (--> same as -d -i -m)\n -t number of threads in Virtuso to integrate the new data [12]\n -p Enter Virtuoso passwort, otherwise this script will phrase pass.txt located in the scripts folder\n -h shows this help" >&2
exit 1
;;
\?)
echo "Invalid option: -$OPTARG" >&2
exit 1
;;
:)
echo "Option -$OPTARG requires an argument." >&2
exit 1
;;
f)
foldername=$OPTARG
;;
d)
download=true
;;
i)
install=true
;;
m)
massbank=true
;;
a)
download=true
install=true
massbank=true
;;
t)
threads=$OPTARG
;;
p)
passwort=$OPTARG
;;
esac
done

if [ "$download" = "true" ] ; then
    echo "Getting path of molecule.ttl"
    mol_fname=`curl -s ftp://ftp.ebi.ac.uk/pub/databases/chembl/ChEMBL-RDF/latest/ --list-only | grep  molecule.ttl`
    #echo "ftp://ftp.ebi.ac.uk/pub/databases/chembl/ChEMBL-RDF/latest/$mol_fname"

    #Get chembl
    rm -rf chembl_latest_molecule.ttl.gz
    rm -rf cco_latest.ttl.gz
    timestamp=$(date +%Y_%m_%d_%H_%M)
    echo "Downloading files"
    echo "Chembl"
    curl "ftp://ftp.ebi.ac.uk/pub/databases/chembl/ChEMBL-RDF/latest/$mol_fname" > chembl_${timestamp}_molecule.ttl.gz
    curl "ftp://ftp.ebi.ac.uk/pub/databases/chembl/ChEMBL-RDF/latest/cco.ttl.gz" > cco_${timestamp}.ttl.gz
    ln -s chembl_${timestamp}_molecule.ttl.gz chembl_latest_molecule.ttl.gz
    ln -s cco_${timestamp}.ttl.gz cco_latest.ttl.gz
    gunzip chembl_latest_molecule.ttl.gz
    gunzip cco_latest.ttl.gz
    #Get chebi
    echo "Chebi"
    rm -rf chebi_latest.owl
    curl "ftp://ftp.ebi.ac.uk/pub/databases/chebi/ontology/chebi.owl" > chebi_${timestamp}.owl
    ln -s chebi_${timestamp}.owl chebi_latest.owl
    #Get massbank records
    echo "Massbank"
    svn checkout "http://www.massbank.jp/SVN/OpenData/record/"

fi

if [ "$massbank" = "true" ] ; then
    echo "Running Massbank Script - $scriptname"
    #Run R-Script

    #/usr/bin/env Rscript ...
    echo "Rscript $scriptname -f $foldername"
    #Resulting N3 is in ./Opendata_full.N3

fi

if[ "$install" = "true" ] ; then
    echo "Installing new data into Virtuoso"

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

fi

