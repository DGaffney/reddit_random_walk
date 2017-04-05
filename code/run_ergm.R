library(ergm.count)
library(latentnet)
library(statnet)
network_file_0 <-  "tergm_analysis_gml/2008-4_quarter_0.0_early_reddit.csv"
network_file_25 <- "tergm_analysis_gml/2008-4_quarter_0.25_early_reddit.csv"
network_file_50 <- "tergm_analysis_gml/2008-4_quarter_0.5_early_reddit.csv"
network_file_75 <- "tergm_analysis_gml/2008-4_quarter_0.75_early_reddit.csv"
network_file_0 <-  "tergm_analysis_gml/2009-05_month_0.0_early_reddit.csv"
network_file_25 <- "tergm_analysis_gml/2009-05_month_0.25_early_reddit.csv"
network_file_50 <- "tergm_analysis_gml/2009-05_month_0.5_early_reddit.csv"
network_file_75 <- "tergm_analysis_gml/2009-05_month_0.75_early_reddit.csv"

get_graph_weighted <- function(filename){
  nn <- network(asNetwork(read_graph(filename, format="gml")))
  mm <- as.matrix.network(nn, matrix.type="adjacency", attrname="observed")
  m <- as.network(mm, directed=TRUE, matrix.type="a", ignore.eval=FALSE, names.eval="observed")
  m %v% "political" <- nn %v% "political"
  m %v% "technology" <- nn %v% "technology"
  m %v% "general" <- nn %v% "general"
  m %v% "category" <- nn %v% "category"
  m %v% "defaultstatus" <- nn %v% "defaultstatus"
  m %v% "trafficcount" <- nn %v% "trafficcount"
  m %v% "logtrafficcount" <- nn %v% "logtrafficcount"
  m %e% "observed" <- nn %e% "observed"
  m %e% "logobserved" <- round(log(nn %e% "observed"))
  return(m)  
}
library(igraph)
library(intergraph)
graph <- get_graph_weighted(network_file_0)
detach("package:igraph")

#Weighted model (Binomial(3) is a setting you need to pay attention to, "observed" is the edge weight matrix (learn more here: https://statnet.org/trac/raw-attachment/wiki/Sunbelt2015/Valued.pdf and https://statnet.org/trac/raw-attachment/wiki/Sunbelt2013/Valued.pdf))
model.static_weighted <- ergm(graph~transitiveties+mutual+edges+absdiff("political")+absdiff("defaultstatus")+nodeicov("trafficcount")+nodeocov("trafficcount"),response="observed", reference=~Poisson)
summary(model.static_weighted)
model.static_weighted <- ergm(graph~transitiveties+mutual+edges+absdiff("political")+absdiff("defaultstatus")+nodeicov("trafficcount")+nodeocov("trafficcount"),response="observed", reference=~Binomial(3))
summary(model.static_weighted)
model.static_weighted <- ergm(graph~sum+mutual+edges+absdiff("political")+absdiff("defaultstatus")+nodeicov("logtrafficcount")+nodeocov("logtrafficcount"),response="logobserved", reference=~Binomial(3))
summary(model.static_weighted)
mcmc.diagnostics(model.static_weighted)
model.static_weighted <- ergm(graph~sum+mutual+edges+absdiff("political")+absdiff("defaultstatus")+nodeicov("logtrafficcount")+nodeocov("logtrafficcount"),response="logobserved", reference=~Poisson)
summary(model.static_weighted)
mcmc.diagnostics(model.static_weighted)


model.static_weighted <- ergm(graph~sum+mutual+edges+absdiff("political")+absdiff("defaultstatus")+nodeicov("trafficcount")+nodeocov("trafficcount"),response="observed", reference=~Binomial(3))
summary(model.static_weighted)
mcmc.diagnostics(model.static_weighted)
model.static_weighted <- ergm(graph~sum+mutual+edges+absdiff("political")+absdiff("defaultstatus")+nodeicov("trafficcount")+nodeocov("trafficcount"),response="observed", reference=~Poisson)
summary(model.static_weighted)
mcmc.diagnostics(model.static_weighted)
