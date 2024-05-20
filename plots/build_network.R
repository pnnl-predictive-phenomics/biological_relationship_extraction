library(tidyverse)
library(data.table)
library(xlsx)
library(igraph)
library(visNetwork)
library(DirectedClustering)
library(sna)
library(xlsx)

#' @param ProteinList1 Vector of binary interactors where the first interactor is in Interactor1.
#'    For example, if the interation is ERK-MEK, then ERK should be in the same position
#'    of one list as MEK is in the other. Required.
#' @param ProteinList2 Vector of binary interactors where the second interactor is in Interactor2.
#'    For example, if the interation is ERK-MEK, then ERK should be in the same position
#'    of one list as MEK is in the other. Required.
#' @param ColorDF Color nodes (if necessary). Default is NULL.
#' @param GetAdjacency True/False to instead return an adjacency matrix. 
build_network <- function(ProteinList1, ProteinList2, ColorDF = NULL, GetAdjacency = FALSE) {
  
  # Check parameters
  if (length(ProteinList1) != length(ProteinList2)) {
    stop("ProteinList1 must be the same length as ProteinList2.")
  }
  
  # Make interactions data.table
  inters <- data.frame(A = ProteinList1, B = ProteinList2)
  
  # Make a truth matrix
  uniqueProteins <- unique(c(ProteinList1, ProteinList2)) %>% sort()
  mat <- matrix(0, nrow = length(uniqueProteins), ncol = length(uniqueProteins))
  colnames(mat) <- uniqueProteins
  row.names(mat) <- uniqueProteins
  
  # Now, iterate through each relationship
  for (row in 1:nrow(inters)) {
    ent1 <- inters$A[row]
    ent2 <- inters$B[row]
    mat[ent1, ent2] <- 1
    mat[ent2, ent1] <- 1
  }
  
  if (GetAdjacency) {return(mat)}
  
  # Print out connectedness and clustering coefficient
  message(paste0("The connectedness is: ", connectedness(mat)))
  message(paste0("The clustering coefficient is: ", ClustF(mat)$GlobalCC))
  message(paste0("Average connections per node is: ", mean(apply(mat, 2, sum))))
  
  # Make graph
  net <- graph_from_adjacency_matrix(mat, mode = "upper", weighted = TRUE)
  
  # Print out number of components, average component size
  message(paste0("The number of components is: ", clusters(net)$no))
  message(paste0("Average component size is: ", mean(clusters(net)$csize)))
  
  net <- toVisNetworkData(net)
  
  # Make edges black
  net$edges$color <- "black"
  
  # Add colors 
  if (!is.null(ColorDF)) {
    colnames(ColorDF) <- c("id", "color")
    net$nodes <- dplyr::left_join(net$nodes, ColorDF)
  } 

  # Return graph
  visNetwork(nodes = net$nodes, edges = net$edges) %>%
    visIgraphLayout()

}