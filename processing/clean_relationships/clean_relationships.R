library(tidyverse)
library(data.table)
library(xlsx)

# Load necessary information----------------------------------------------------

# Load synonyms
interactome <- fread("interactome/file")
syns <- fread("/synonyms/file")

# Create quick relationships function
make_rellys <- function(x, y) {paste(sort(c(x, y)), collapse = " ")}

# Write pre-processing function-------------------------------------------------

# Replace synonyms with UniProt IDs, remove self-binding events, unique relationships, and save output. 
process_clean <- function(df) {
  df %>%
    select(Term1, Term2) %>%
    mutate(
      Term1 = map_chr(Term1, function(x) {
        test = syns %>% filter(Synonyms == x) %>% select(Protein) %>% unlist()
        if (length(test) != 1) {browser()} else {return(test)}
      }),
      Term2 = map_chr(Term2, function(x) {
        test = syns %>% filter(Synonyms == x) %>% select(Protein) %>% unlist()
        if (length(test) != 1) {browser()} else {return(test)}
      })
    ) %>%
    filter(Term1 != Term2) %>%
    mutate(ID = map2_chr(Term1, Term2, make_rellys)) %>%
    select(ID) %>% 
    unique() %>%
    mutate(
      Term1 = map_chr(ID, function(x) {strsplit(x, " ") %>% unlist() %>% head(1)}),
      Term2 = map_chr(ID, function(x) {strsplit(x, " ") %>% unlist() %>% tail(1)}),
    )
}

#####################
## BENCHMARK STUDY ##
#####################

#-------------------------------------------------------------------------------
# CO-OCCURRENCE
#-------------------------------------------------------------------------------

fread("extracted/cooccurrence") %>%
  filter(!is.na(`Sentence Position in R`)) %>%
  process_clean() %>%
  fwrite("binary/cooccurrence", quote = F, row.names = F)

#-------------------------------------------------------------------------------
# RELATED TERM
#-------------------------------------------------------------------------------

fread("extracted/cooccurrence") %>%
  filter(!is.na(`Sentence Position in R`) & `Relational Terms` != "") %>%
  process_clean() %>%
  fwrite("binary/relatedterm", quote = F, row.names = F)

#-------------------------------------------------------------------------------
# FIXED VERB
#-------------------------------------------------------------------------------

fread("extracted/fixedterm") %>%
  filter(`Fixed Term` != "") %>%
  process_clean() %>%
  fwrite("binary/fixedterm",
         quote = F, row.names = F)

#-------------------------------------------------------------------------------
# PUBMED MINER 
#-------------------------------------------------------------------------------

# Naive 0.5
fread("extracted/pubmedmineR") %>%
  mutate(Score = ifelse(is.na(Score), 0, Score)) %>%
  filter(Score >= 0.5) %>%
  rename(Term1 = Biomolecule1, Term2 = Biomolecule2) %>%
  process_clean() %>%
  fwrite("binary/PubmedMiner",
         quote = F, row.names = F)

#-------------------------------------------------------------------------------
# BERTs
#-------------------------------------------------------------------------------

read.xlsx("extracted/BERT.xlsx", 1) %>%
  filter(`True.Positive` >= 0.5) %>%
  select(Entity1, Entity2) %>% 
  rename(Term1 = Entity1, Term2 = Entity2) %>%
  process_clean() %>%
  fwrite("binary/BERT",
         quote = F, row.names = F)

#-------------------------------------------------------------------------------
# REACH/TRIPS
#-------------------------------------------------------------------------------

fread("extracted/reach") %>%
  mutate(
    Term1 = map_chr(Biomolecule1, function(x) {strsplit(x, "|", fixed = T) %>% unlist() %>% head(2) %>% tail(1)}),
    Term2 = map_chr(Biomolecule2, function(x) {strsplit(x, "|", fixed = T) %>% unlist() %>% head(2) %>% tail(1)})
  ) %>%
  filter(Term1 %in% poss_prots & Term2 %in% poss_prots) %>%
  mutate(ID = map2_chr(Term1, Term2, make_rellys)) %>%
  select(ID, Term1, Term2) %>%
  fwrite("binary/reach",
         quote = F, row.names = F)

#-------------------------------------------------------------------------------
# BioGPT
#-------------------------------------------------------------------------------

# Read BioGPT, assign labels
biogpt_annots <- data.frame(Response = read_file("extracted/BioGPT") %>%
                              strsplit("\n", fixed = T) %>%
                              unlist()) %>%
  mutate(
    Yes = stringr::str_count(Response, "Yes. | yes | Yes | Yes, | yes. |Yes "),
    No = stringr::str_count(Response, "No. | no | No | No, | no. |No "),
    Annotation = ifelse(Yes > No, "True Positive", "True Negative")
  ) 

fread("data/LLM_sentences") %>%
  mutate(Annotations = biogpt_annots$Annotation) %>%
  filter(Annotations != "True Negative") %>%
  select(PMID, Entity1, Entity2, Annotations) %>%
  rename(Term1 = Entity1, Term2 = Entity2) %>%
  process_clean() %>%
  fwrite("binary/BioGPT",
         quote = F, row.names = F)

#-------------------------------------------------------------------------------
# SOLAR
#-------------------------------------------------------------------------------

fread("extracted/SOLAR") %>%
  mutate(
    Response = map_chr(Response, function(x) {
      Yes <- stringr::str_count(x, "Yes. | yes | Yes | Yes, | yes.|Yes ")
      No <- stringr::str_count(x, "No. | no | No | No, | no.|No ")
      return(ifelse(Yes > No, "Yes", "No"))
    })
  ) %>%
  group_by(PMID, Entity1, Entity2, Response) %>%
  summarise(Count = n()) %>% 
  ungroup() %>%
  pivot_wider(id_cols = c(PMID, Entity1, Entity2), values_from = Count, values_fill = 0, names_from = Response) %>%
  mutate(Consensus = ifelse(Yes > 0, "Yes", "No")) %>%
  filter(Consensus == "Yes") %>%
  rename(Term1 = Entity1, Term2 = Entity2) %>%
  process_clean() %>%
  fwrite("binary/SOLAR",
         quote = F, row.names = F)

#-------------------------------------------------------------------------------
# Gemini
#-------------------------------------------------------------------------------

fread("extracted/gemini") %>%
  filter(Response == "Yes") %>%
  mutate(
    Term1 = map_chr(ID, function(x) {strsplit(x, " & ", fixed = T) %>% unlist() %>% head(1)}),
    Term2 = map_chr(ID, function(x) {strsplit(x, " & ", fixed = T) %>% unlist() %>% tail(1)})
  ) %>%
  process_clean() %>%
  fwrite("binary/gemini",
         quote = F, row.names = F)

