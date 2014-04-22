##This function gets the Chebi ID from a Pubchem CID
##This is terribly stupid, but I needed a quick solution

pubchem2chebi <- function(PCID){
	require(httr)
	PCsite <- GET(paste0("https://pubchem.ncbi.nlm.nih.gov/summary/summary.cgi?cid=",PCID))
	start <- regexpr("<title>CHEBI:", PCsite, fixed=TRUE)[1]
	end <- regexpr(" - PubChem</title>", PCsite, fixed=TRUE)[1]
	return(as.numeric(substr(PCsite,start+13,end-1)))
}

pubchem2chebi(440064)