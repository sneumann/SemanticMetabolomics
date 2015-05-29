Record2CHEBIrdf <- function(w, checkex = FALSE){
	require(RMassBank)

	Links <- w@compiled_ok[[1]][['CH$LINK']]
	ChebLinkIndex <- which(regexpr("CHEBI", Links, fixed=TRUE) == 1)
	chebLink <- ""
	
	if(length(ChebLinkIndex >= 1)){
		chebLink <- paste0("http://purl.obolibrary.org/obo/CHEBI_",substring(Links[[ChebLinkIndex]], 6))
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
			chebLink <- paste0("http://purl.obolibrary.org/obo/CHEBI_",substring(chebID,7))
		}
	}
	return(chebLink)
}


##Extract Everything:
EXTRACT <- function(record){
	require(RMassBank)
	require(RCurl)
	
	w <- parseMassBank(record)
	Links <- w@compiled_ok[[1]][['CH$LINK']]
	ACCES <- w@compiled_ok[[1]][['ACCESSION']]
	onlrecord <- paste0("http://www.massbank.jp/SVN/OpenData/record/",basename(dirname(record)),"/",basename(record))
	
	##CLASSES (except peak, comes later)
	RECRD <- paste0("http://msbi.ipb-halle.de/rdf/ontologydata/mbco/record:",ACCES)
	ASSAY <- paste0("http://msbi.ipb-halle.de/rdf/ontologydata/mbco/mass_spectrometry_assay:",ACCES)
	SPCTR <- paste0("http://msbi.ipb-halle.de/rdf/ontologydata/mbco/mass_spectrum:",ACCES)
		InchKeyIndex <- which(regexpr("INCHIKEY", Links, fixed=TRUE) == 1)
		if(length(InchKeyIndex) > 0){
	INCHK <- substring(Links[[InchKeyIndex]], 10)
	CHENT <- paste0("http://msbi.ipb-halle.de/rdf/ontologydata/mbco/chemical_entity:",ACCES,"_",INCHK)
		} else{
			return(NULL)
		}
	

	
	
	##PROPERTIES (between classes)
	DESCR <- "http://msbi.ipb-halle.de/rdf/ontology/mbco#describes"
	IDESC <- "http://msbi.ipb-halle.de/rdf/ontology/mbco#is_described_by"
	OUTPU <- "http://msbi.ipb-halle.de/rdf/ontology/mbco#has_output"
	IOUTP <- "http://msbi.ipb-halle.de/rdf/ontology/mbco#is_output_of"
	IDENT <- "http://msbi.ipb-halle.de/rdf/ontology/mbco#identifies"
	IIDEN <- "http://msbi.ipb-halle.de/rdf/ontology/mbco#identified_by"
	CPEAK <- "http://msbi.ipb-halle.de/rdf/ontology/mbco#has_constituent"
	IPEAK <- "http://msbi.ipb-halle.de/rdf/ontology/mbco#constituates"
	CHEBI <- "http://msbi.ipb-halle.de/rdf/ontology/mbco#chebi_link"
	
	##PROPERTIES (to strings, ints, etc.)
	MZ <- "http://msbi.ipb-halle.de/rdf/ontology/mbco#encodes_mz"
	INT <- "http://msbi.ipb-halle.de/rdf/ontology/mbco#has_intensity"
	RELINT <- "http://msbi.ipb-halle.de/rdf/ontology/mbco#has_rel_intensity"
	ACCESSION <- "http://msbi.ipb-halle.de/rdf/ontology/mbco#has_accession"
	MSTYPE <- "http://msbi.ipb-halle.de/rdf/ontology/mbco#ms_type"
	IONMODE <- "http://msbi.ipb-halle.de/rdf/ontology/mbco#ion_mode"
	HASNAME <- "http://msbi.ipb-halle.de/rdf/ontology/mbco#name"
	HASFORMULA <- "http://msbi.ipb-halle.de/rdf/ontology/mbco#has_formula"
	HASSMILES <- "http://msbi.ipb-halle.de/rdf/ontology/mbco#has_smiles"
	RECLINK <- "http://msbi.ipb-halle.de/rdf/ontology/mbco#hyperlink_record"
	
	##Find Chebi link
	CHEBLINK <- Record2CHEBIrdf(w)
	
	
	##Generate Classes in the triple store and their relations + Accession and link to record in opendata(always the same)
	TRIPLIST <- list()
	TRIPLIST[[1]] <- c(RECRD,DESCR,ASSAY)
	TRIPLIST[[2]] <- c(RECRD,ACCESSION,ACCES)
	TRIPLIST[[3]] <- c(RECRD,RECLINK,onlrecord)
	TRIPLIST[[4]] <- c(ASSAY,IDESC,RECRD)
	TRIPLIST[[5]] <- c(ASSAY,OUTPU,SPCTR)
	TRIPLIST[[6]] <- c(SPCTR,IOUTP,ASSAY)
	TRIPLIST[[7]] <- c(SPCTR,IDENT,CHENT)
	TRIPLIST[[8]] <- c(CHENT,IIDEN,SPCTR)
	TRIPLIST[[9]] <- c(RECRD, "http://www.w3.org/1999/02/22-rdf-syntax-ns#type" , "http://msbi.ipb-halle.de/rdf/ontology/mbco#record")
	TRIPLIST[[10]] <- c(ASSAY, "http://www.w3.org/1999/02/22-rdf-syntax-ns#type" , "http://msbi.ipb-halle.de/rdf/ontology/mbco#mass_spectrometry_assay")
	TRIPLIST[[11]] <- c(SPCTR, "http://www.w3.org/1999/02/22-rdf-syntax-ns#type" , "http://msbi.ipb-halle.de/rdf/ontology/mbco#mass_spectrum")
	TRIPLIST[[12]] <- c(CHENT, "http://www.w3.org/1999/02/22-rdf-syntax-ns#type" , "http://msbi.ipb-halle.de/rdf/ontology/mbco#chemical_entity")
	
	Currnum <- 12
	
	if(!is.null(CHEBLINK)){
		Currnum <- Currnum + 1
		TRIPLIST[[Currnum]] <- c(CHENT, CHEBI , CHEBLINK)
 	}
	
	
	
	
	##PEAKS
	peaks <- w@compiled_ok[[1]][["PK$PEAK"]]
	PEAKNAMES <- list()
	for(i in 1:nrow(peaks)){
		##Find out peakname
		PEAKNAMES[[i]] <- paste0("http://msbi.ipb-halle.de/rdf/ontologydata/mbco/peak:",ACCES,"_",peaks[i,1])
		
		##Write Class
		Currnum <- Currnum + 1
		TRIPLIST[[Currnum]] <- c(PEAKNAMES[[i]], "http://www.w3.org/1999/02/22-rdf-syntax-ns#type", "http://msbi.ipb-halle.de/rdf/ontology/mbco#peak")
		
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
	
	Currnum <- Currnum + 1
	TRIPLIST[[Currnum]] <- c(ASSAY,IONMODE,MS$ION_MODE) 
	
	if(!is.na(MS$MS_TYPE)){
		Currnum <- Currnum + 1
		TRIPLIST[[Currnum]] <- c(ASSAY,MSTYPE,MS$MS_TYPE) 
	}
	if(!is.na(MS$ION_MODE)){
		Currnum <- Currnum + 1
		TRIPLIST[[Currnum]] <- c(ASSAY,IONMODE,MS$ION_MODE) 
	}
	
	##CHEMICAL ENTITY PART
	NAME <- w@compiled_ok[[1]][["CH$NAME"]][[1]]
	FORMULA <- w@compiled_ok[[1]][["CH$FORMULA"]]
	SMILES <- w@compiled_ok[[1]][["CH$SMILES"]]
	Currnum <- Currnum + 1
	TRIPLIST[[Currnum]] <- c(CHENT,HASNAME,NAME)
	Currnum <- Currnum + 1
	TRIPLIST[[Currnum]] <- c(CHENT,HASFORMULA,FORMULA)
	Currnum <- Currnum + 1
	TRIPLIST[[Currnum]] <- c(CHENT,HASSMILES,SMILES)
	
	
	return(TRIPLIST)
}




require(rrdf)
ret <- new.rdf()
a <- 0
FILES <- list.files("Massbank OD/record",full.names=TRUE,recursive=TRUE)
pb <- txtProgressBar(min=1, max=length(FILES), title="Progress", style=3)
numpredicates <- c("http://msbi.ipb-halle.de/rdf/ontology/mbco#has_rel_intensity","http://msbi.ipb-halle.de/rdf/ontology/mbco#has_intensity","http://msbi.ipb-halle.de/rdf/ontology/mbco#encodes_mz")

for(i in FILES){
	ERROR <- 0
	tryCatch(
	    mmm <- capture.output(EXTLIST <- EXTRACT(i)),
		error = function(e){
			ERROR <<- 1
		}
	)
	if(ERROR){
		print(i)
		next
	}
	
	
	for(j in 1:length(EXTLIST)){
		if(length(EXTLIST) == 0 | is.null(EXTLIST[[j]][3])){
			a <- a + 1
			setTxtProgressBar(pb, a)
			break
		}
		
		if(regexpr("http", EXTLIST[[j]][3], fixed=TRUE) == 1){
			add.triple(ret, EXTLIST[[j]][1],EXTLIST[[j]][2],EXTLIST[[j]][3])
		} else{
			if(EXTLIST[[j]][2] %in% numpredicates){
				add.data.triple(ret, EXTLIST[[j]][1],EXTLIST[[j]][2],EXTLIST[[j]][3], type="float")
			} else{
				add.data.triple(ret, EXTLIST[[j]][1],EXTLIST[[j]][2],EXTLIST[[j]][3], type="string")
			}
		}
			
	}
	a <- a + 1
	setTxtProgressBar(pb, a)
}
close(pb)
save.rdf(ret, "Opendata_full.N3","N3")
