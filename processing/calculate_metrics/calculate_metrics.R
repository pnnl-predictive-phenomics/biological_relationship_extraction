library(tidyverse)
library(data.table)

## GENERAL USE FUNCTIONS ##

# Make ID 
make_ID <- function(term1, term2) {
  paste0(sort(c(term1, term2)), collapse = " ")
}

# Calculate stats
#' @param truth A data.frame with the unique relationship column (Relationship) and
#'   its truth annotation (Annotation) as either "True Positive" or "True Negative"
#' @param prediction A list of predicted Relationships listed as TP 
calc_stats <- function(truth, prediction) {
  
  pre_res <- truth %>%
    mutate(Prediction = ifelse(Relationship %in% prediction, "True Positive", "True Negative"),
           Classification = ifelse(Annotation == Prediction, Annotation, 
                            ifelse(Annotation == "True Positive", "False Negative", "False Positive"))) %>%
    dplyr::select(Classification) %>%
    table(., dnn = "Classification") %>% 
    data.frame() %>%
    mutate(Classification = as.character(Classification))
  
  if ("True Positive" %in% pre_res$Classification == FALSE) {pre_res <- rbind(pre_res, c("True Positive", 0))}
  if ("True Negative" %in% pre_res$Classification == FALSE) {pre_res <- rbind(pre_res, c("True Negative", 0))}
  if ("False Positive" %in% pre_res$Classification == FALSE) {pre_res <- rbind(pre_res, c("False Positive", 0))}
  if ("False Negative" %in% pre_res$Classification == FALSE) {pre_res <- rbind(pre_res, c("False Negative", 0))}
  
  math_list <- as.numeric(pre_res$Freq)
  names(math_list) <- pre_res$Classification
  
 res <- c(
    "TP" = as.character(math_list["True Positive"]),
    "FP" = as.character(math_list["False Positive"]), 
    "FN" = as.character(math_list["False Negative"]),
    "TN" = as.character(math_list["True Negative"]),
    "TPR" = math_list["True Positive"] / (math_list["True Positive"] + math_list["False Negative"]),
    "FNR" = math_list["False Negative"] / (math_list["True Positive"] + math_list["False Negative"]),
    "TNR" = math_list["True Negative"] / (math_list["True Negative"] + math_list["False Positive"]),
    "FPR" = math_list["False Positive"] / (math_list["True Negative"] + math_list["False Positive"]),
    "Disagreements" = math_list["False Positive"] + math_list["False Negative"],
    "BA" = ((math_list["True Positive"] / (math_list["True Positive"] + math_list["False Negative"])) +
      (math_list["True Negative"] / (math_list["True Negative"] + math_list["False Positive"]))) / 2
  )
 
 return(res)
 
}