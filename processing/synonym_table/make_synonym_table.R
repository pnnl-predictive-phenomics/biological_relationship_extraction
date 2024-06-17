library(tidyverse)
library(data.table)
library(UniprotR)

# Pull proteins
interactions <- fread("interactome") # Or list of proteins 

# Build the synonym table
SynTable <- data.frame(
  Protein = unique(c(interactions$ID1, interactions$ID2))
) %>%
  mutate(
    Synonyms = map_chr(Protein, function(x) {
      message(x)
      query <- tryCatch({GetNamesTaxa(x)}, error = function (e) {list()})
      if (length(query) == 0) {return(NA)}
      c(
        query$Entry,
        gsub("_CAEEL", "", query$Entry.Name), # Or _ECOLI or E. coli
        query$Gene.Names..primary.,
        query$Gene.Names..synonym.,
        query$Gene.Names..ORF.,
        gsub(pattern = "homolog", replacement = "", query$Protein.name) %>% strsplit("and") %>% unlist() %>% trimws() %>% paste0(collapse = "; ")
      ) %>% paste0(collapse = "; ")}), # _SARS2|_HUMAN
  )  

# Fix NA's 
SynTable[is.na(SynTable$Synonyms), "Synonyms"] <- c("G5EFT5; HSF1; HSF-1; heat shock transcription factor 1", "O45734; CPL-1; CPL1; cathepsin l-like",
                                                    "Q9NF14; BAT40; BATH-40; BATH40; BAT40; BTB and MATH domain-containing protein 40")

# Pivot table longer
SynTableLong <- do.call(rbind, lapply(1:nrow(SynTable), function(x) {
  data.table(
    Protein = SynTable$Protein[x],
    Synonyms = SynTable$Synonyms[x] %>% strsplit("\\(|\\)| \\)|;") %>% unlist() %>% trimws()
  )
}))

# Clean up as much as possible
SynTableLong2 <- SynTableLong %>%
  filter(Synonyms != "" & Synonyms != "NA") %>%
  mutate(Synonyms = gsub(pattern = "  ", replacement = " ", x = Synonyms, fixed = T)) %>%
  mutate(Synonyms = gsub(pattern = "protein", replacement = "", x = Synonyms, ignore.case = T) %>% trimws()) %>%
  mutate(Synonyms = ifelse(grepl("CELE_", Synonyms), strsplit(Synonyms, " ") %>% unlist() %>% tail(1), Synonyms)) %>% # or ECOLI_ for E. coli
  mutate(Synonyms = gsub(pattern = "\\[|\\]", replacement = "", Synonyms)) %>%
  unique() %>%
  mutate(Length = nchar(Synonyms)) %>%
  filter(Length > 2) %>%
  select(-Length) %>%
  unique()

# Remove options where there are more than one instances
counts <- SynTableLong2$Synonyms %>% 
  unlist() %>%
  table(dnn = "Name") %>%
  data.frame()
counts$Name <- as.character(counts$Name)

SynTableLong2 %>%
  filter(Synonyms %in% unlist(counts[counts$Freq == 1, 1])) %>%
  fwrite("synonyms.txt",
         quote = F, row.names = F, sep = "\t")

# Double check table manually 
