# setup.R
# make sure any needed packages are loaded
# Jim Lutz  "Tue Sep 12 15:46:11 2017"

# clean up leftovers before starting
l_obj=ls(all=TRUE)
l_obj = c(l_obj, "l_obj") # be sure to include l_obj
rm(list = l_obj)
# clear the plots
if(!is.null(dev.list())){
  dev.off(dev.list()["RStudioGD"])
}
# clear history
cat("", file = "nohistory")
loadhistory("nohistory")
# clear the console
cat("\014")

# only works if have internet access
update.packages(checkBuilt=TRUE)

sessionInfo() 
  # R version 3.4.1 (2017-06-30)
  # Platform: x86_64-pc-linux-gnu (64-bit)
  # Running under: Ubuntu 16.04.3 LTS

# install the RSmap tools
# https://pythonhosted.org/Smap/en/2.0/R_access.html
# https://github.com/SoftwareDefinedBuildings/smap/blob/master/R/RSmap_1.0.tar.gz
if(!require(RCurl)){install.packages("RCurl")}
library(RCurl)
if(!require(RJSONIO)){install.packages("RJSONIO")}
library(RJSONIO)


# work with tidyverse
# http://tidyverse.org/
# needed libxml2-dev installed
if(!require(tidyverse)){install.packages("tidyverse")}
library(tidyverse)

# work with stringr
if(!require(stringr)){install.packages("stringr")}
library(stringr)


# work with data.tables
#https://github.com/Rdatatable/data.table/wiki
#https://www.datacamp.com/courses/data-analysis-the-data-table-way
if(!require(data.table)){install.packages("data.table")}
library(data.table)

# work with ggplot2
if(!require(ggplot2)){install.packages("ggplot2")}
library(ggplot2)


# change the default background for ggplot2 to white, not gray
theme_set( theme_bw() )

# generic plot scaling methods
# if(!require(scales)){install.packages("scales")}
# library(scales)

