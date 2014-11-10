
##Extract Everything:
EXTRACT <- function(record){
	require(RMassBank)
	require(RCurl)
	
	w <- parseMassBank(record)
	Links <- w@compiled_ok[[1]][['CH$LINK']]
	ACCES <- w@compiled_ok[[1]][['ACCESSION']]
	onlrecord <- paste0("http://www.massbank.jp/SVN/OpenData/record/",basename(dirname(record)),"/",basename(record))
	
	##CLASSES (except peak, comes later)
	RECRD <- paste0("http://www.ipb-halle.de/ontologydata/record:",ACCES)
	ASSAY <- paste0("http://www.ipb-halle.de/ontologydata/mass_spectrometry_assay:",ACCES)
	SPCTR <- paste0("http://www.ipb-halle.de/ontologydata/mass_spectrum:",ACCES)
		InchKeyIndex <- which(regexpr("INCHIKEY", Links, fixed=TRUE) == 1)
		if(length(InchKeyIndex) > 0){
	INCHK <- substring(Links[[InchKeyIndex]], 10)
	CHENT <- paste0("http://www.ipb-halle.de/ontologydata/chemical_entity:",ACCES,"_",INCHK)
		} else{
			return(NULL)
		}
	

	
	
	##PROPERTIES (between classes)
	DESCR <- "http://www.ipb-halle.de/ontology/mbco#describes"
	IDESC <- "http://www.ipb-halle.de/ontology/mbco#is_described_by"
	OUTPU <- "http://www.ipb-halle.de/ontology/mbco#has_output"
	IOUTP <- "http://www.ipb-halle.de/ontology/mbco#is_output_of"
	IDENT <- "http://www.ipb-halle.de/ontology/mbco#identifies"
	IIDEN <- "http://www.ipb-halle.de/ontology/mbco#is_identified_by"
	CPEAK <- "http://www.ipb-halle.de/ontology/mbco#has_constituent"
	IPEAK <- "http://www.ipb-halle.de/ontology/mbco#constituates"
	#CHEBI <- "http://www.ipb-halle.de/ontology/mbco#is_peak_of"
	
	##PROPERTIES (to strings, ints, etc.)
	MZ <- "http://www.ipb-halle.de/ontology/mbco#encodes_mz"
	INT <- "http://www.ipb-halle.de/ontology/mbco#has_intensity"
	RELINT <- "http://www.ipb-halle.de/ontology/mbco#has_rel_intensity"
	ACCESSION <- "http://www.ipb-halle.de/ontology/mbco#has_accession"
	MSTYPE <- "http://www.ipb-halle.de/ontology/mbco#ms_type"
	IONMODE <- "http://www.ipb-halle.de/ontology/mbco#ion_mode"
	HASNAME <- "http://www.ipb-halle.de/ontology/mbco#name"
	HASFORMULA <- "http://www.ipb-halle.de/ontology/mbco#has_formula"
	HASSMILES <- "http://www.ipb-halle.de/ontology/mbco#has_smiles"
	RECLINK <- "http://www.ipb-halle.de/ontology/mbco#hyperlink_record"
	
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
	TRIPLIST[[9]] <- c(RECRD, "a" , "http://www.ipb-halle.de/ontology/mbco#record")
	TRIPLIST[[10]] <- c(ASSAY, "a" , "http://www.ipb-halle.de/ontology/mbco#mass_spectrometry_assay")
	TRIPLIST[[11]] <- c(SPCTR, "a" , "http://www.ipb-halle.de/ontology/mbco#mass_spectrum")
	TRIPLIST[[12]] <- c(CHENT, "a" , "http://www.ipb-halle.de/ontology/mbco#chemical_entity")
	
	
	
	Currnum <- 12
	
	##PEAKS
	peaks <- w@compiled_ok[[1]][["PK$PEAK"]]
	PEAKNAMES <- list()
	for(i in 1:nrow(peaks)){
		##Find out peakname
		PEAKNAMES[[i]] <- paste0("http://www.ipb-halle.de/ontologydata/peak:",ACCES,"_",peaks[i,1])
		
		##Write Class
		Currnum <- Currnum + 1
		TRIPLIST[[Currnum]] <- c(PEAKNAMES[[i]], "a", "http://www.ipb-halle.de/ontology/mbco#peak")
		
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
for(i in list.files("OpenData/IPB_Halle",full.names=TRUE)){
	EXTLIST <- EXTRACT(i)
	for(j in 1:length(EXTLIST)){
		if(regexpr("http", EXTLIST[[j]][3], fixed=TRUE) == 1){
			add.triple(ret, EXTLIST[[j]][1],EXTLIST[[j]][2],EXTLIST[[j]][3])
		} else{
			add.data.triple(ret, EXTLIST[[j]][1],EXTLIST[[j]][2],EXTLIST[[j]][3])
		}	
			
	}
}
save.rdf(ret, "IPB_full.N3","N3")


ret2 <- new.rdf()
for(i in list.files("OpenData/UFZ",full.names=TRUE)[1:200]){
	EXTLIST <- EXTRACT(i)
	if(!is.null(EXTLIST)){
		for(j in 1:length(EXTLIST)){
			if(regexpr("http", EXTLIST[[j]][3], fixed=TRUE) == 1){
				add.triple(ret2, EXTLIST[[j]][1],EXTLIST[[j]][2],EXTLIST[[j]][3])
			} else{
				add.data.triple(ret2, EXTLIST[[j]][1],EXTLIST[[j]][2],EXTLIST[[j]][3])
			}	
		}
	}
}
