##This function gets the Chebi ID from a Pubchem CID
##It just scrapes for the title of the corresponding Pubchem-Site
##It's terribly stupid, but it works faster than asking CTS.

.pubchem2chebi <- function(PCID){
	require(httr)
	PCsite <- GET(paste0("https://pubchem.ncbi.nlm.nih.gov/summary/summary.cgi?cid=",PCID))
	start <- regexpr("<title>CHEBI:", PCsite, fixed=TRUE)[1]
	end <- regexpr(" - PubChem</title>", PCsite, fixed=TRUE)[1]
	if((start > -1) && (end > -1)){
		result <- substr(PCsite,start+7,end-1)
	}else{
		result <- NA
	}
	return(result)
}


Record2CHEBIrdf <- function(record, checkex = FALSE){
	require(RMassBank)
	require(RCurl)
	
	onlrecord <- paste0("http://www.massbank.jp/SVN/OpenData/record/",basename(dirname(record)),"/",basename(record))
	
	if(!url.exists(record) && checkex){
		##Try to find out the URL of the record in Opendata
		if(!url.exists(onlrecord) && checkex){
			warning("The record isn't available in Massbank Opendata and local URIs will be returned")
		}
	}
	
	w <- parseMassBank(record)
	Links <- w@compiled_ok[[1]][['CH$LINK']]
	ChebLinkIndex <- which(regexpr("CHEBI", Links, fixed=TRUE) == 1)
	chebLink <- ""
	if(length(ChebLinkIndex > 1)){
		chebLink <- paste0("https://www.ebi.ac.uk/chebi/searchId.do?chebiId=CHEBI:",substring(Links[[ChebLinkIndex]], 6))
	}
	
	if(chebLink == ""){
		InchiKeyLinkIndex <- which(regexpr("INCHIKEY", Links, fixed=TRUE) == 1)
		if(length(InchiKeyLinkIndex > 1)){
			CTSREC <- getCtsRecord(substring(Links[[InchiKeyLinkIndex]], 10))
			CTSTYPES <- CTS.externalIdTypes(CTSREC)
			if("ChEBI" %in% CTSTYPES)
			{
				chebID <- CTS.externalIdSubset(CTSREC,"ChEBI")
				chebID <- chebID[[which.min(nchar(chebID))]]
			} else{
				return(NULL)
			}
			chebLink <- paste0("http://bio2rdf.org/chebi:",chebID)
		}
	}
	retmat <- matrix(c(onlrecord,"http://localhost:8890/DAV/definitions/is_record_of",chebLink),1,3)
	colnames(retmat) <- c("Subject", "Predicate", "Object")
	
	###Get the Instrument
	
	
	
	return(retmat)
}

##Extract Everything:
EXTRACT <- function(record, checkex = FALSE){
	require(RMassBank)
	require(RCurl)
	
	w <- parseMassBank(record)
	Links <- w@compiled_ok[[1]][['CH$LINK']]
	ACCES <- w@compiled_ok[[1]][['ACCESSION']]
	
	##CLASSES (except peak, comes later)
	RECRD <- paste0("http://www.ipb-halle.de/ontologydata/record:",ACCES)
	ASSAY <- paste0("http://www.ipb-halle.de/ontologydata/assay:",ACCES)
	SPCTR <- paste0("http://www.ipb-halle.de/ontologydata/spectrum:",ACCES)
		InchKeyIndex <- which(regexpr("INCHIKEY", Links, fixed=TRUE) == 1)
		if(length(InchKeyIndex) > 0){
	INCHK <- substring(Links[[InchiKeyLinkIndex]], 10)
	CHENT <- paste0("http://www.ipb-halle.de/ontologydata/chemical-entity:",INCHK)
		} else{
			return(NULL)
		}
		
	##PROPERTIES (between classes)
	DESCR <- "http://www.ipb-halle.de/ontology/mbco#describes"
	IDESC <- "http://www.ipb-halle.de/ontology/mbco#is-described-by"
	OUTPU <- "http://www.ipb-halle.de/ontology/mbco#has-output"
	IOUTP <- "http://www.ipb-halle.de/ontology/mbco#is-output-of"
	IDENT <- "http://www.ipb-halle.de/ontology/mbco#identifies"
	IIDEN <- "http://www.ipb-halle.de/ontology/mbco#is-identified-by"
	CPEAK <- "http://www.ipb-halle.de/ontology/mbco#contains-peak"
	IPEAK <- "http://www.ipb-halle.de/ontology/mbco#is-peak-of"
	
	##PROPERTIES (to strings, ints, etc.)
	MZ <- "http://www.ipb-halle.de/ontology/mbco#has-mz"
	INT <- "http://www.ipb-halle.de/ontology/mbco#has-int"
	RELINT <- "http://www.ipb-halle.de/ontology/mbco#has-rel-int"
	ACCESSION <- "http://www.ipb-halle.de/ontology/mbco#has-accession"
	MSTYPE <- "http://www.ipb-halle.de/ontology/mbco#ms-type"
	IONMODE <- "http://www.ipb-halle.de/ontology/mbco#ion-mode"
	HASNAME <- "http://www.ipb-halle.de/ontology/mbco#name"
	HASFORMULA <- "http://www.ipb-halle.de/ontology/mbco#has-formula"
	HASSMILES <- "http://www.ipb-halle.de/ontology/mbco#has-smiles"
	
	##Generate Classes in the triple store and their relations + Accession(always the same)
	TRIPLIST <- list()
	TRIPLIST[[1]] <- c(RECRD,DESCR,ASSAY)
	TRIPLIST[[2]] <- c(RECRD,ACCESSION,ACCES)
	TRIPLIST[[3]] <- c(ASSAY,IDESC,RECRD)
	TRIPLIST[[4]] <- c(ASSAY,OUTPU,SPCTR)
	TRIPLIST[[5]] <- c(SPCTR,IOUTP,ASSAY)
	TRIPLIST[[6]] <- c(SPCTR,IDENT,CHENT)
	TRIPLIST[[7]] <- c(CHENT,IIDEN,SPCTR)
	
	Currnum <- 7
	
	##PEAKS
	peaks <- w@compiled_ok[[1]][["PK$PEAK"]]
	PEAKNAMES <- list()
	for(i in 1:nrow(peaks)){
		PEAKNAMES[[i]] <- paste0("http://www.ipb-halle.de/ontologydata/peak:",ACCES,"-",peaks[i,1])
		Currnum <- Currnum + 1
		TRIPLIST[[Currnum]] <- c(SPCTR,CPEAK,PEAKNAMES[[i]])
		Currnum <- Currnum + 1
		TRIPLIST[[Currnum]] <- c(PEAKNAMES[[i]],IPEAK,SPCTR)
		##Add Peak m/z, intensity, rel. intensity
		Currnum <- Currnum + 1
		TRIPLIST[[Currnum]] <- c(PEAKNAMES[[i]],MZ,peaks[i,1])
		Currnum <- Currnum + 1
		TRIPLIST[[Currnum]] <- c(PEAKNAMES[[i]],INT,peaks[i,2])
		Currnum <- Currnum + 1
		TRIPLIST[[Currnum]] <- c(PEAKNAMES[[i]],RELINT,peaks[i,3])
	}
	
	##ASSAY PART
	MS <- w@compiled_ok[[1]][["AC$MASS_SPECTROMETRY"]]
	if(!is.na(MS$MS_TYPE)){
		Currnum <- Currnum + 1
		TRIPLIST[[Currnum]] <- c(ASSAY,MSTYPE,MS$MS_TYPE) 
	}
	if(!is.na(MS$ION_MODE)){
		Currnum <- Currnum + 1
		TRIPLIST[[Currnum]] <- c(ASSAY,IONMODE,MS$ION_MODE) 
	}
	
	if(length(ChebLinkIndex > 1)){
		chebLink <- paste0("https://www.ebi.ac.uk/chebi/searchId.do?chebiId=CHEBI:",substring(Links[[ChebLinkIndex]], 6))
	}
	
	##CHEMICAL ENTITY PART
	NAME <- w@compiled_ok[[1]][["CH$NAME"]][[1]]
	Currnum <- Currnum + 1
	TRIPLIST[[Currnum]] <- c(CHENT,HASNAME,NAME)
	TRIPLIST[[Currnum]] <- c(CHENT,HASFORMULA,FORMULA)
	TRIPLIST[[Currnum]] <- c(CHENT,HASSMILES,SMILES)
	
	if(chebLink == ""){
		InchiKeyLinkIndex <- which(regexpr("INCHIKEY", Links, fixed=TRUE) == 1)
		if(length(InchiKeyLinkIndex > 1)){
			CTSREC <- getCtsRecord(substring(Links[[InchiKeyLinkIndex]], 10))
			CTSTYPES <- CTS.externalIdTypes(CTSREC)
			if("ChEBI" %in% CTSTYPES)
			{
				chebID <- CTS.externalIdSubset(CTSREC,"ChEBI")
				chebID <- chebID[[which.min(nchar(chebID))]]
			} else{
				return(NULL)
			}
			chebLink <- paste0("http://bio2rdf.org/chebi:",chebID)
		}
	}
	retmat <- matrix(c(onlrecord,"http://localhost:8890/DAV/definitions/is_record_of",chebLink),1,3)
	colnames(retmat) <- c("Subject", "Predicate", "Object")
	
	###Get the Instrument
	
	
	
	return(retmat)
}



##Execute from parent folder of Opendata

mat <- lapply(list.files("OpenData/IPB_Halle/",full.names=TRUE), Record2CHEBIrdf)
for(i in length(mat):1){
	if(is.null(mat[[i]])){
		mat[[i]] <- NULL
	}
}
require(rrdf)
ret <- new.rdf()
for(i in 1:length(mat)){
	add.triple(ret, mat[[i]][1],mat[[i]][2],mat[[i]][3])
}
save.rdf(ret, "triple.xml","RDF/XML")