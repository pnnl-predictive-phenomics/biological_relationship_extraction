library(tidyverse)
library(data.table)
library(stringr)
library(pubmed.mineR)

################################################################################
## Pulls and formats sentences that need to be tested by BERT models
################################################################################

#' @param data A data.frame with sentences where terms co-occur. Need Term1, Term2, PMID,
#'     and file, which is the file path. 
#' @param padding The number of words of padding on other end of each term.
#' @param max_characters The maximum number of permitted characters. If the extracted 
#'    region is larger than this value, it is tossed. 
format_sentences <- function(data, padding = 5, max_characters = 250) {
  
  # Get co-occurrence location
  co_occur <- do.call(rbind, lapply(1:nrow(data), function(row) {
    
    if (row %% 50 == 0) {message(row)}
    
    # Load paper and get sentence
    abs <- read_file(data$file[row]) 
    
    # Get data and clean up terms 
    term1_c <- gsub("[^[:alnum:] ]", "", data$Term1[row])
    term1 <- term1_c %>% strsplit(" ") %>% unlist() %>% paste0(collapse = "_")
    term2_c <- gsub("[^[:alnum:] ]", "", data$Term2[row]) 
    term2 <- term2_c %>% strsplit(" ") %>% unlist() %>% paste0(collapse = "_")
    
    # Tokenize sentences
    Sentence <- SentenceToken(abs)[data$`Sentence Position in R`[row]] 
    
    # Clean up sentences 
    Sentence <- Sentence %>% 
      gsub(pattern = "[^[:alnum:] ]", replacement = "") %>% 
      trimws(which = "both") %>%
      gsub(pattern = term1_c, replacement = term1) %>%
      gsub(pattern = term2_c, replacement = term2)
    
    # Split sentence
    splitSent <- strsplit(Sentence, " ") %>% unlist()
    term1_pos <- which(unlist(lapply(splitSent, function(x) {grepl(term1, x, ignore.case = TRUE)})) == TRUE)
    term2_pos <- which(unlist(lapply(splitSent, function(x) {grepl(term2, x, ignore.case = TRUE)})) == TRUE)
    
    # Given the checks before this point, these two terms must co-occur somewhere
    if (length(term1_pos) == 0 | length(term2_pos) == 0) {
      message("An unexpected error occurred.")
      return(NULL)
    }
    
    # Identify the first closest two terms 
    closest_terms <- expand.grid(term1_pos, term2_pos) %>%
      mutate(
        Distance = abs(Var2 - Var1),
        Selected = Distance == min(Distance)
      ) %>%
      filter(Selected) %>%
      head(1)
    
    # Make sure Protein1 is before Protein2, as these BERT models are weak betas that can't handle much 
    if (closest_terms$Var1 > closest_terms$Var2) {
      pos1 <- closest_terms$Var1
      pos2 <- closest_terms$Var2
      t1 <- term1
      t2 <- term2
      closest_terms$Var1 <- pos2
      closest_terms$Var2 <- pos1
      term1 <- t2
      term2 <- t1
    }
    
    # Extract two terms and padding 
    index1 <- closest_terms$Var1 - padding
    if (index1 < 1) {index1 <- 1}
    index2 <- closest_terms$Var2 + padding
    if (index2 > length(splitSent)) {index2 <- length(splitSent)}
    
    # Extract sentences
    the_sent <- splitSent[index1:index2] %>% paste0(collapse = " ")
    
    # Replace terms 
    the_sent <- gsub(pattern = term1, replacement = " @PROTEIN$1 ", the_sent, ignore.case = T)
    the_sent <- gsub(pattern = term2, replacement = " @PROTEIN$2 ", the_sent, ignore.case = T)
    the_sent <- the_sent %>% trimws()
    the_sent <- str_squish(the_sent)
    
    if (nchar(the_sent) > max_characters) {
      return(NULL)
    }
    
    # Remove cases with lots of non-specific masking 
    if (str_count(the_sent, "@PROTEIN\\$1") > 1 | str_count(the_sent, "@PROTEIN\\$2") > 1) {
      return(NULL)
    }
    
    # Last test 
    if ( (grepl("@PROTEIN$1", the_sent, fixed = T) == FALSE) |
         (grepl("@PROTEIN$2", the_sent, fixed = T) == FALSE) ) {return(NULL)}
    
    return(
      data.frame(
        PMID = data$PMID[row],
        Entity1 = data$Term1[row],
        Entity2 = data$Term2[row],
        Term1 = "@PROTEIN$1",
        Term2 = "@PROTEIN$2",
        Chars = nchar(the_sent),
        Sentence = the_sent
      )
    )
    
  }))
  
  return(co_occur)
  
}