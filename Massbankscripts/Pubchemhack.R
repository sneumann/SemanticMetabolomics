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


Record2CHEBIrdf <- function(record){
	require(RMassBank)
	require(RCurl)
	
	if(!url.exists(record)){
		##Try to find out the URL of the record in Opendata
		onlrecord <- paste0("http://www.massbank.jp/SVN/OpenData/record/",dirname(record),"/",basename(record))
		if(!url.exists(onlrecord)){
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
			print(substring(Links[[InchiKeyLinkIndex]], 10))
			CTSREC <- getCtsRecord(substring(Links[[InchiKeyLinkIndex]], 10))
			CTSTYPES <- CTS.externalIdTypes(CTSREC)
			if("ChEBI" %in% CTSTYPES)
			{
				chebID <- CTS.externalIdSubset(CTSREC,"ChEBI")
				chebID <- chebID[[which.min(nchar(chebID))]]
			}
			chebLink <- paste0("https://www.ebi.ac.uk/chebi/searchId.do?chebiId=",chebID)
		}
	}
	retvec <- c(record,"is record of",chebLink)
	names(retvec) <- c("Subject", "Predicate", "Object")
	return(retvec)
}

Record2CHEBIrdf("http://www.massbank.jp/SVN/OpenData/record/IPB_Halle/PB000166.txt")
