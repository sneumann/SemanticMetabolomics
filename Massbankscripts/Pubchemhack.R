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