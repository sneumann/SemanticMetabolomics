# this R-skript is a simple tool to convert ISAtab files to RDF files
 
# load "rrdf"
library(rrdf)

# install and load "Risa"
source("http://bioconductor.org/biocLite.R")
biocLite("Risa")
library(Risa)

# to handle RDF triples, we first need a triple store
# so we create a new one
ontModel  <- new.rdf(ontology=TRUE)
summarize.rdf(ontModel)

 #function.isa2rdf <- function(working.directory){ die Schleife war dafür gedacht,alle Ordner durchzugehen in denen die ISA-Dateien sind
# than read ISAtab's and create an ISAtab object
ISAtab.object <- readISAtab(path = getwd(), verbose = TRUE)

# and add triples:
# - investigation
add.triple(ontModel,
           subject=paste0("http://www.ipb-halle.de/data/metabolights/investigation:", ISAtab.object@investigation.filename),
           predicate="rdfs:a",
           object="http://www.ipb-halle.de/data/metabolights/investigation"
          )

# - study
add.triple(ontModel,
           subject=paste0("http://www.ipb-halle.de/data/metabolights/study:", ISAtab.object@study.filenames),
           predicate="rdfs:a",
           object="http://www.ipb-halle.de/data/metabolights/study"
          )

# - assay
add.triple(ontModel,
           subject=paste0("http://www.ipb-halle.de/data/metabolights/assay:", ISAtab.object@assay.filenames),
           predicate="rdfs:a",
           object="http://www.ipb-halle.de/data/metabolights/assay"
)

# which study belongs to the investigation and vice versa
# - filename <-> filenames
add.triple(ontModel,
           subject=paste0("http://www.ipb-halle.de/data/metabolights/investigation:", ISAtab.object@investigation.filename),
           predicate="http://www.ipb-halle.de/ontology/metabolights/relate_to_study",
           object=paste0("http://www.ipb-halle.de/data/metabolights/study:", ISAtab.object@study.filenames)
          )
add.triple(ontModel,
           subject=paste0("http://www.ipb-halle.de/data/metabolights/study:", ISAtab.object@study.filenames),
           predicate="http://www.ipb-halle.de/ontology/metabolights/relate_to_investigation",
           object=paste0("http://www.ipb-halle.de/data/metabolights/investigation:", ISAtab.object@investigation.filename)
          )
# - identifier <-> identifiers
add.triple(ontModel,
           subject=paste0("http://www.ipb-halle.de/data/metabolights/investigation:", ISAtab.object@investigation.identifier),
           predicate="http://www.ipb-halle.de/ontology/metabolights/relate_to_study",
           object=paste0("http://www.ipb-halle.de/data/metabolights/study:", ISAtab.object@study.identifiers)
)
add.triple(ontModel,
           subject=paste0("http://www.ipb-halle.de/data/metabolights/study:", ISAtab.object@study.identifiers),
           predicate="http://www.ipb-halle.de/ontology/metabolights/relate_to_investigation",
           object=paste0("http://www.ipb-halle.de/data/metabolights/investigation:", ISAtab.object@investigation.identifier)
)
# - title <-> titles
add.triple(ontModel,
           subject=paste0("http://www.ipb-halle.de/data/metabolights/investigation:", ISAtab.object@investigation.file$V2[8]),
           predicate="http://www.ipb-halle.de/ontology/metabolights/relate_to_study",
           object=paste0("http://www.ipb-halle.de/data/metabolights/study:", ISAtab.object@study.titles)
)
add.triple(ontModel,
           subject=paste0("http://www.ipb-halle.de/data/metabolights/study:", ISAtab.object@study.titles),
           predicate="http://www.ipb-halle.de/ontology/metabolights/relate_to_investigation",
           object=paste0("http://www.ipb-halle.de/data/metabolights/investigation:", ISAtab.object@investigation.file$V2[8])
)

# which assay belongs to the study and vice versa
# - filenames <-> filenames
add.triple(ontModel,
           subject=paste0("http://www.ipb-halle.de/data/metabolights/study:", ISAtab.object@study.filenames),
           predicate="http://www.ipb-halle.de/ontology/metabolights/relate_to_assay",
           object=paste0("http://www.ipb-halle.de/data/metabolights/assay:", ISAtab.object@assay.filenames)
          )
add.triple(ontModel,
           subject=paste0("http://www.ipb-halle.de/data/metabolights/assay:", ISAtab.object@assay.filenames),
           predicate="http://www.ipb-halle.de/ontology/metabolights/relate_to_study",
           object=paste0("http://www.ipb-halle.de/data/metabolights/study:", ISAtab.object@study.filenames)
          )
# - identifiers <-> filenames
add.triple(ontModel,
           subject=paste0("http://www.ipb-halle.de/data/metabolights/study:", ISAtab.object@study.identifiers),
           predicate="http://www.ipb-halle.de/ontology/metabolights/relate_to_assay",
           object=paste0("http://www.ipb-halle.de/data/metabolights/assay:", ISAtab.object@assay.filenames)
)
add.triple(ontModel,
           subject=paste0("http://www.ipb-halle.de/data/metabolights/assay:", ISAtab.object@assay.filenames),
           predicate="http://www.ipb-halle.de/ontology/metabolights/relate_to_study",
           object=paste0("http://www.ipb-halle.de/data/metabolights/study:", ISAtab.object@study.identifiers)
)
# - titles <-> filenames
add.triple(ontModel,
           subject=paste0("http://www.ipb-halle.de/data/metabolights/study:", ISAtab.object@study.titles),
           predicate="http://www.ipb-halle.de/ontology/metabolights/relate_to_assay",
           object=paste0("http://www.ipb-halle.de/data/metabolights/assay:", ISAtab.object@assay.filenames)
)
add.triple(ontModel,
           subject=paste0("http://www.ipb-halle.de/data/metabolights/assay:", ISAtab.object@assay.filenames),
           predicate="http://www.ipb-halle.de/ontology/metabolights/relate_to_study",
           object=paste0("http://www.ipb-halle.de/data/metabolights/study:", ISAtab.object@study.titles)
)

# which sample belongs to the study and vice versa
# - filenames <-> sample name
for( sample in 1:nrow(ISAtab.object@study.files[[ISAtab.object@study.identifiers]]["Sample Name"]) ){ 
  add.triple(ontModel,
             subject=paste0("http://www.ipb-halle.de/data/metabolights/study:", ISAtab.object@study.filenames),
             predicate="http://www.ipb-halle.de/ontology/metabolights/relate_to_sample",
             object=paste0("http://www.ipb-halle.de/data/metabolights/sample:", ISAtab.object@study.files[[ISAtab.object@study.identifiers]][sample,"Sample Name"])
            )
  add.triple(ontModel,
             subject=paste0("http://www.ipb-halle.de/data/metabolights/sample:", ISAtab.object@study.files[[ISAtab.object@study.identifiers]][sample,"Sample Name"]),
             predicate="http://www.ipb-halle.de/ontology/metabolights/relate_to_study",
             object=paste0("http://www.ipb-halle.de/data/metabolights/study:", ISAtab.object@study.filenames)
            )
}

# - identifier <-> sample name
for( sample in 1:nrow(ISAtab.object@study.files[[ISAtab.object@study.identifiers]]["Sample Name"]) ){ 
  add.triple(ontModel,
             subject=paste0("http://www.ipb-halle.de/data/metabolights/study:", ISAtab.object@study.identifiers),
             predicate="http://www.ipb-halle.de/ontology/metabolights/relate_to_sample",
             object=paste0("http://www.ipb-halle.de/data/metabolights/sample:", ISAtab.object@study.files[[ISAtab.object@study.identifiers]][sample,"Sample Name"])
  )
  add.triple(ontModel,
             subject=paste0("http://www.ipb-halle.de/data/metabolights/sample:", ISAtab.object@study.files[[ISAtab.object@study.identifiers]][sample,"Sample Name"]),
             predicate="http://www.ipb-halle.de/ontology/metabolights/relate_to_study",
             object=paste0("http://www.ipb-halle.de/data/metabolights/study:", ISAtab.object@study.identifiers)
  )
}
# - title <-> sample name
for( sample in 1:nrow(ISAtab.object@study.files[[ISAtab.object@study.identifiers]]["Sample Name"]) ){ 
  add.triple(ontModel,
             subject=paste0("http://www.ipb-halle.de/data/metabolights/study:", ISAtab.object@study.titles),
             predicate="http://www.ipb-halle.de/ontology/metabolights/relate_to_sample",
             object=paste0("http://www.ipb-halle.de/data/metabolights/sample:", ISAtab.object@study.files[[ISAtab.object@study.identifiers]][sample,"Sample Name"])
  )
  add.triple(ontModel,
             subject=paste0("http://www.ipb-halle.de/data/metabolights/sample:", ISAtab.object@study.files[[ISAtab.object@study.identifiers]][sample,"Sample Name"]),
             predicate="http://www.ipb-halle.de/ontology/metabolights/relate_to_study",
             object=paste0("http://www.ipb-halle.de/data/metabolights/study:", ISAtab.object@study.titles)
  )
}

# which sample belongs to the assay and vice versa
# - filenames <-> sample name
for( sample in 1:nrow(ISAtab.object@assay.files[[ISAtab.object@assay.filenames]]["Sample Name"]) ){ 
  add.triple(ontModel,
             subject=paste0("http://www.ipb-halle.de/data/metabolights/assay:", ISAtab.object@assay.filenames),
             predicate="http://www.ipb-halle.de/ontology/metabolights/relate_to_sample",
             object=paste0("http://www.ipb-halle.de/data/metabolights/sample:", ISAtab.object@assay.files[[ISAtab.object@assay.filenames]][sample,"Sample Name"])
  )
  add.triple(ontModel,
             subject=paste0("http://www.ipb-halle.de/data/metabolights/sample:", ISAtab.object@assay.files[[ISAtab.object@assay.filenames]][sample,"Sample Name"]),
             predicate="http://www.ipb-halle.de/ontology/metabolights/relate_to_assay",
             object=paste0("http://www.ipb-halle.de/data/metabolights/assay:", ISAtab.object@assay.filenames)
  )
}

# which metabolite assignment file belongs to the assay and vice versa
# - maf filename
maf <- ISAtab.object@assay.files[[1]][1,"Metabolite Assignment File"]
metabolite <- read.table(file=maf, header=TRUE)

# - filename <-> maf
add.triple(ontModel,
           subject=paste0("http://www.ipb-halle.de/data/metabolights/assay:", ISAtab.object@assay.filenames),
           predicate="http://www.ipb-halle.de/ontology/metabolights/relate_to_maf",
           object=paste0("http://www.ipb-halle.de/data/metabolights/maf:", maf)
)
add.triple(ontModel,
           subject=paste0("http://www.ipb-halle.de/data/metabolights/maf:", maf),
           predicate="http://www.ipb-halle.de/ontology/metabolights/relate_to_assay",
           object=paste0("http://www.ipb-halle.de/data/metabolights/assay:", ISAtab.object@assay.filenames)
)

# which metabolite attribute belongs to the sample and vice versa
metabolite.sample <- ISAtab.object@assay.files[[ISAtab.object@assay.filenames]]["Sample Name"] # which samples are in the file
# - database_identifier (chebi) <-> sample name
metabolite.database_identifier <- grep(pattern="CHEBI",metabolite$database_identifier) # which attribute value exists
for( value in metabolite.database_identifier ){
  for( sample in metabolite.sample[[1]] ){
    if( metabolite[value,sample]!=0){
      add.triple(ontModel,
                 subject=paste0("http://www.ipb-halle.de/data/metabolights/sample:", sample),
                 predicate="http://www.ipb-halle.de/ontology/metabolights/relate_to_x-chebi",
                 object=paste0("http://bio2rdf.org/chebi:", sub(".*:", "", metabolite$database_identifier[value]))
                )
      add.triple(ontModel,
                 subject=paste0("http://bio2rdf.org/chebi:", sub(".*:", "", metabolite$database_identifier[value])),
                 predicate="http://www.ipb-halle.de/ontology/metabolights/x-chebi_relate_to",
                 object=paste0("http://www.ipb-halle.de/data/metabolights/sample:", sample)
                )      
    }
  }
}

# - chemical_formula <-> sample name
metabolite.chemical_formula <- which(metabolite$chemical_formula!="") # which attribute value exists
for( value in metabolite.chemical_formula ){
  for( sample in metabolite.sample[[1]] ){
    if( metabolite[value,sample]!=0){
      add.data.triple(ontModel,
                 subject=paste0("http://www.ipb-halle.de/data/metabolights/sample:", sample),
                 predicate="http://www.ipb-halle.de/ontology/metabolights/relate_to_chem-formula",
                 data=paste0(metabolite$chemical_formula[value])
      )    
    }
  }
}

# - smiles <-> sample name
metabolite.smiles <- which(metabolite$smiles!="") # which attribute value exists
for( value in metabolite.smiles ){
  for( sample in metabolite.sample[[1]] ){
    if( metabolite[value,sample]!=0){
      add.data.triple(ontModel,
                 subject=paste0("http://www.ipb-halle.de/data/metabolights/sample:", sample),
                 predicate="http://www.ipb-halle.de/ontology/metabolights/relate_to_smiles",
                 data=paste0(metabolite$smiles[value])
      )   
    }
  }
}

# - inchi <-> sample name
metabolite.inchi <- which(metabolite$inchi!="") # which attribute value exists
for( value in metabolite.inchi ){
  for( sample in metabolite.sample[[1]] ){
    if( metabolite[value,sample]!=0){
      add.data.triple(ontModel,
                 subject=paste0("http://www.ipb-halle.de/data/metabolights/sample:", sample),
                 predicate="http://www.ipb-halle.de/ontology/metabolights/relate_to_inchi",
                 data=paste0(metabolite$inchi[value])
      )    
    }
  }
}

# - metabolite_identification <-> sample name
metabolite.metabolite_identification <- which(metabolite$metabolite_identification!="") # which attribute value exists
for( value in metabolite.metabolite_identification ){
  for( sample in metabolite.sample[[1]] ){
    if( metabolite[value,sample]!=0){
      add.data.triple(ontModel,
                 subject=paste0("http://www.ipb-halle.de/data/metabolights/sample:", sample),
                 predicate="http://www.ipb-halle.de/ontology/metabolights/relate_to_metabolite-ident",
                 data=paste0(metabolite$metabolite_identification[value])
      )     
    }
  }
}
summarize.rdf(ontModel)
#return(ontModel)

#}

 #ontModel <- function.isa2rdf(getwd())
# save the store
save.rdf(ontModel2, file = "wer.rdf", format="RDF/XML")
save.rdf(ontModel2, file = "wer.xml", format="N3")