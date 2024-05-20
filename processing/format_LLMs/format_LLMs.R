library(data.table)
library(tidyverse)

# ID function
make_ID <- function(term1, term2) {
  paste0(sort(c(term1, term2)), collapse = " & ")
}

# Load Synonyms
syns <- fread("synonyms")

fread("BERT_File") %>%
  mutate(
    ID1 = map_chr(Entity1, function(x) {syns[syns$Synonyms == x, "Protein"] %>% unlist()}),
    ID2 = map_chr(Entity2, function(x) {syns[syns$Synonyms == x, "Protein"] %>% unlist()}),
  ) %>%
  mutate(
    Sentence = map_chr(Query, function(x) {strsplit(x, "Context: ") %>% unlist() %>% tail(1)}),
    Sentence = pmap_chr(list(Sentence, Entity1, ID1, Entity2, ID2), function(sent, e1, i1, e2, i2) {
      sent %>% 
        gsub(pattern = paste0("\\b", e1, "\\b"), replacement = i1) %>%
        gsub(pattern = paste0("\\b", e2, "\\b"), replacement = i2)
    }),
    ID = map2_chr(ID1, ID2, make_ID)
  ) %>%
  group_by(ID) %>%
  summarise(Sentences = paste0(Sentence, collapse = ". ")) %>%
  mutate(
    ID1 = map_chr(ID, function(x) {strsplit(x, " & ", fixed = T) %>% unlist() %>% head(1)}),
    ID2 = map_chr(ID, function(x) {strsplit(x, " & ", fixed = T) %>% unlist() %>% tail(1)}),
    Query = paste0("Context: ", Sentences, ". Question: Based solely on the provided context does ",
                   ID1, " interact with ", ID2, "? Answer with a 'yes' or 'no'.")) %>%
  fwrite("LLM_File")
    