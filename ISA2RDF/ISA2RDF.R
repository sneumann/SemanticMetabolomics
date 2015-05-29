##This R-script is a simple tool to convert ISAtab files to RDF files
 
##Load "rrdf"
library(rrdf)
library(tools)

##Install "Risa" if not installed yet and load it
if(!("Risa" %in% rownames(installed.packages()))){
	source("http://bioconductor.org/biocLite.R")
	biocLite("Risa")
}

library(Risa)



#dirName <- "./MTBLS-Dateien/MTBLS17"


##Find all URIs
isaTab2RDF <- function(ontModel, dirName){
	ISAtab.object <- readISAtab(path = dirName, verbose = TRUE)
	investigationLabel <- basename(dirName)
	investigation <- paste0("http://msbi.ipb-halle.de/rdf/ontologydata/metabolights/investigation:", investigationLabel)
	studyLabels <- ISAtab.object@study.identifiers
	studies <- paste0("http://msbi.ipb-halle.de/rdf/ontologydata/metabolights/study:", studyLabels)


	##Everything about investigations
	add.triple(ontModel,investigation, "http://www.w3.org/1999/02/22-rdf-syntax-ns#type", "http://msbi.ipb-halle.de/rdf/ontology/metabolights#investigation")
	add.data.triple(ontModel, investigation, "http://www.w3.org/2000/01/rdf-schema#label", investigationLabel)

	##Everything about the studies
	for(i in 1:length(studies)){
			add.triple(ontModel, studies[i], "http://www.w3.org/1999/02/22-rdf-syntax-ns#type", "http://msbi.ipb-halle.de/rdf/ontology/metabolights#study")
			add.triple(ontModel, investigation, "http://msbi.ipb-halle.de/rdf/ontology/metabolights#has_study", studies[i])
			add.triple(ontModel, studies[i], "http://msbi.ipb-halle.de/rdf/ontology/metabolights#is_study_of", investigation)
			add.data.triple(ontModel, studies[i], "http://www.w3.org/2000/01/rdf-schema#label", studyLabels[i])
			
			assaylist <- ISAtab.object@assay.filenames.per.study
			
			##Everything about the assays and metabolite assignment files which are part of the current study
			for(j in 1:length(assaylist[[studyLabels[i]]])){
				##Label is concatenation of investigation, study followed by number 
				assayLabel <- paste0(investigationLabel, "_", studyLabels[i], "_", j)
				assay <- paste0("http://msbi.ipb-halle.de/rdf/ontologydata/metabolights/assay:",assayLabel)
				
				add.data.triple(ontModel, assay, "http://www.w3.org/2000/01/rdf-schema#label", assayLabel)
				add.data.triple(ontModel, assay, "http://msbi.ipb-halle.de/rdf/ontology/metabolights#measurement_type", ISAtab.object@assay.measurement.types[j])
				add.data.triple(ontModel, assay, "http://msbi.ipb-halle.de/rdf/ontology/metabolights#technology_type", ISAtab.object@assay.technology.types[j])
				add.data.triple(ontModel, assay, "http://msbi.ipb-halle.de/rdf/ontology/metabolights#has_file_name", assaylist[[studyLabels[i]]][[j]])
				
				add.triple(ontModel, assay, "http://www.w3.org/1999/02/22-rdf-syntax-ns#type", "http://msbi.ipb-halle.de/rdf/ontology/metabolights#assay")
				add.triple(ontModel, studies[i], "http://msbi.ipb-halle.de/rdf/ontology/metabolights#has_assay", assay)
				add.triple(ontModel, assay, "http://msbi.ipb-halle.de/rdf/ontology/metabolights#is_assay_of", studies[i])
				
				##Metabolite assignment file
				maf_File <- ISAtab.object@assay.files[[j]][1,"Metabolite Assignment File"]
				if(file.exists(paste0(dirName,"/",maf_File))){
					mafLabel <- paste0(investigationLabel, "_", studyLabels[i], "_", j)
					maf <- paste0("http://msbi.ipb-halle.de/rdf/ontologydata/metabolights/metabolite_assignment_file:", mafLabel)
					
					add.data.triple(ontModel, maf, "http://www.w3.org/2000/01/rdf-schema#label", mafLabel)
					add.triple(ontModel, assay, "http://msbi.ipb-halle.de/rdf/ontology/metabolights#has_metabolite_assignment_file", maf)
					add.triple(ontModel, maf, "http://msbi.ipb-halle.de/rdf/ontology/metabolights#is_metabolite_assignment_file_of", assay)
					add.triple(ontModel, maf, "http://www.w3.org/1999/02/22-rdf-syntax-ns#type", "http://msbi.ipb-halle.de/rdf/ontology/metabolights#metabolite_assignment_file")
					
					maf_File <- ISAtab.object@assay.files[[j]][1,"Metabolite Assignment File"]
					maf_File_Type <- file_ext(maf_File)
					
					chebisubs <- vector()
					
					if(maf_File_Type == "tsv"){
						chebisubs <- read.table(paste0(dirName,"/",maf_File),header=TRUE,colClasses="character")[,"database_identifier"]
					}
					
					if(maf_File_Type == "csv"){
						chebisubs <- read.table(paste0(dirName,"/",maf_File),header=TRUE,colClasses="character")[,"identifier"]
					}
					
					
					
					if(any(chebisubs != "")){
						chebiIndex <- grep("^CHEBI:([[:digit:]]){1,}$",chebisubs)
						chebiNums <- sub(":","_",chebisubs[chebiIndex])
						for(k in 1:length(chebiNums)){
							chebiLink <- paste0("http://purl.obolibrary.org/obo/", chebiNums[k])
							add.triple(ontModel, maf, "http://msbi.ipb-halle.de/rdf/ontology/metabolights#describes_metabolite", chebiLink)
							add.triple(ontModel, chebiLink, "http://msbi.ipb-halle.de/rdf/ontology/metabolights#is_described_in", maf)
						}
					}
				}
			}
	}
}

##Create new rdf store
ontModel_ISA  <- new.rdf(ontology=TRUE)
summarize.rdf(ontModel_ISA)

for(ISAFolder in list.files("MTBLS-Dateien/", full.names=TRUE)[-c(1,23,35,45)]){
	isaTab2RDF(ontModel_ISA, ISAFolder)
}
	
save.rdf(ontModel_ISA, file = "wer.rdf", format="RDF/XML")
save.rdf(ontModel_ISA, file = "wer.n3", format="N3")