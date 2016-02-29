#!/bin/bash

shopt -s nullglob
threads=12
#This script is supposed to be run from /var/lib/*virtuoso*/db --> All files belong to this directory
#You can change the path by using a different directory in the install part of this script --> replace the dot with the whole path
#Do not forget to add the path to virtuoso.ini, otherwise you are not allowed to insert new data from a different path than the standart one
password=$(cat pass.txt)
#path to the R script
scriptname=Extract.R
#path to the massbank OD folder
foldername="./record"
download=false
massbank=false
install_var=false

while getopts "f:dimat:hp:t:" opt; do
case $opt in
h)
echo -e "Help:\n -f set the folder for the Massbank script [./record]\n -d just download new files without installing them\n -m just run the Massbank script\n -i just reinstall all files into the Virtuso instance\n -a do a complete update (--> same as -d -i -m)\n -t number of threads in Virtuso to integrate the new data [12]\n -p Enter Virtuoso password, otherwise this script will phrase pass.txt located in the scripts folder\n -h shows this help" >&2
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
install_var=true
;;
m)
massbank=true
;;
a)
download=true
install_var=true
massbank=true
;;
t)
threads=$OPTARG
;;
p)
password=$OPTARG
;;
esac
done

if [ "$download" = "true" ] ; then
    echo "Getting path of molecule.ttl"
    mol_fname=`curl -s ftp://ftp.ebi.ac.uk/pub/databases/chembl/ChEMBL-RDF/latest/ --list-only | grep  molecule.ttl`
    #echo "ftp://ftp.ebi.ac.uk/pub/databases/chembl/ChEMBL-RDF/latest/$mol_fname"

    #Get chembl
    rm -rf chembl_latest_molecule.ttl
    rm -rf cco_latest.ttl
    timestamp=$(date +%Y_%m_%d_%H_%M)
    echo "Downloading files"
    echo "Chembl"
    curl "ftp://ftp.ebi.ac.uk/pub/databases/chembl/ChEMBL-RDF/latest/$mol_fname" > chembl_${timestamp}_molecule.ttl.gz
    curl "ftp://ftp.ebi.ac.uk/pub/databases/chembl/ChEMBL-RDF/latest/cco.ttl.gz" > cco_${timestamp}.ttl.gz
    gunzip chembl_${timestamp}_molecule.ttl.gz
    gunzip cco_${timestamp}.ttl.gz
    ln -s chembl_${timestamp}_molecule.ttl chembl_latest_molecule.ttl
    ln -s cco_${timestamp}.ttl cco_latest.ttl
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

    echo "Rscript $scriptname -f $foldername"
    /usr/bin/env Rscript $scriptname -f $foldername
    #Resulting N3 is in ./Opendata_full.N3
    mv Opendata_full.N3 Opendata_full_${timestamp}.N3
    ln -s Opendata_full_${timestamp}.N3 massbank_latest.N3

fi

if [ "$install_var" = "true" ] ; then
    echo "Installing new data into Virtuoso"
    #If isql-v is not working for you, you should use isql-vt (make a symlink or change this script)

    echo "SPARQL CLEAR GRAPH <www.massbank.jp>;" | isql-v -U dba -P "$password"
    echo "SPARQL CLEAR GRAPH <www.ebi.ac.uk/chebi/>;" | isql-v -U dba -P "$password"
    echo "SPARQL CLEAR GRAPH <www.ebi.ac.uk/chembl/>;" | isql-v -U dba -P "$password"

    echo "rdf_load_stop();" | isql-v -U dba -P "$password"
    echo "delete from load_list where ll_state=0;" | isql-v -U dba -P "$password"
    echo "delete from load_list where ll_state=1;" | isql-v -U dba -P "$password" #this stops all rdf_loader_run instances
    echo "ld_dir('.', 'chembl_latest_molecule.ttl' , 'www.ebi.ac.uk/chembl/');" | isql-v -U dba -P "$password"
    echo "ld_dir('.', 'cco_latest.ttl' , 'www.ebi.ac.uk/chembl/');" | isql-v -U dba -P "$password"
    echo "ld_dir('.', 'chebi_latest.owl' , 'www.ebi.ac.uk/chebi/');" | isql-v -U dba -P "$password"
    echo "ld_dir('.', 'massbank_latest.N3' , 'www.massbank.jp');" | isql-v -U dba -P "$password"

    # echo "SPARQL CLEAR GRAPH <www.massbank.jp>;" | isql-v
    # echo "SPARQL CLEAR GRAPH <www.ebi.ac.uk/chebi/>;" | isql-v
    # echo "SPARQL CLEAR GRAPH <www.ebi.ac.uk/chembl/>;" | isql-v


    # echo "ld_dir('.', 'chembl_latest_molecule.ttl' , 'www.ebi.ac.uk/chembl/');" | isql-v
    # echo "ld_dir('.', 'cco_latest.ttl' , 'www.ebi.ac.uk/chembl/');" | isql-v
    # echo "ld_dir('.', 'chebi_latest.owl' , 'www.ebi.ac.uk/chebi/');" | isql-v
    # echo "ld_dir('.', 'massbank_latest.ttl' , 'www.massbank.jp');" | isql-v

     for i in 1 .. $threads
     do
         echo "rdf_loader_run();" | isql-v -U dba -P "$password" &
     done
    # for i in 1 .. $threads
    # do
    #     echo "rdf_loader_run();" | isql-v &
    # done

fi

