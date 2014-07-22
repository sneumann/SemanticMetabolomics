library(rrdf)
store <- load.rdf("example.ttl", format="TURTLE")
add.prefix(store,
	prefix="mbco",
	namespace="http://www.ipb-halle.de/ontology/mbco#"
)

add.prefix(store,
	prefix="ov",
	namespace="http://bio2rdf.org/obo_vocabulary:"
)

add.prefix(store,
	prefix="brdf",
	namespace="http://bio2rdf.org/"
)

sparql.rdf(store, paste(
	"SELECT ?subject ?object {",
	" ?subject <http://www.ipb-halle.de/ontology/mbco#is-peak-of> ?object",
	"}"
))

sparql.rdf(store, paste(
	"SELECT ?s ?o WHERE{",
	" ?s <http://www.ipb-halle.de/ontology/mbco#contains-peak> ?o.",
	" ?o <http://www.ipb-halle.de/ontology/mbco#mz> \"147.044\"",
	"}"
))

sparql.rdf(store, paste(
	"SELECT ?object WHERE{",
	" ?object <http://www.ipb-halle.de/ontology/mbco#mz> \"147.044\"",
	"}"
))

sparql.rdf(store, paste(
	"SELECT ?subject ?object WHERE{",
	" ?subject <http://bio2rdf.org/obo_vocabulary:x-chebi> ?object",
	"}"
))

sparql.rdf(store, paste(
	"SELECT ?subject ?object ?chemblid WHERE{",
	" ?subject <http://bio2rdf.org/obo_vocabulary:x-chebi> ?object.",
	"SERVICE <http://bioportal.bio2rdf.org/sparql>{",
	" ?object <http://bio2rdf.org/obo_vocabulary:x-chembl> ?chemblid.",
	"}}"
))