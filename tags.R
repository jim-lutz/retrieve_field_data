# tags.R

# get all the tags from http://ec2-54-184-120-83.us-west-2.compute.amazonaws.com/
# Jim Lutz "Wed Sep 13 08:34:52 2017"

# set packages & etc
source("setup.R")
# some trouble w/ RCurl?


# install the RSmap tools
# https://pythonhosted.org/Smap/en/2.0/R_access.html
# https://github.com/SoftwareDefinedBuildings/smap/blob/master/R/RSmap_1.0.tar.gz
install.packages("RCurl")
install.packages("RJSONIO")

install.packages("/home/jiml/Downloads/RSmap_1.0.tar.gz", repos=NULL)
library(RSmap)

# set up paths to working directories
source("setup_wd.R")

# RSmap functions
source("functions.R")
# not sure if any of these are useful

# following these instructions
# https://pythonhosted.org/Smap/en/2.0/R_access.html
RSmap("http://ec2-54-184-120-83.us-west-2.compute.amazonaws.com/backend")

# make an empty data.table to hold all the tags
DT_tags <- data.table(NULL)

# get the tags for one Sourcename
Sourcename.tags <- RSmap.tags("Metadata/SourceName = 'HWDS_h1'")

str(Sourcename.tags)
# got something

# this is the number of UUIDs for this Sourcename
n.UUID <- length(Sourcename.tags)
# 81

# loop through all the UUIDs for this Sourcename
for( n in 1:n.UUID) {
  # flatten list of tags for UUID
  flat.tags <- unlist(Sourcename.tags[n])

  # get names of tags as a list
  tagnames <- unlist(names(flat.tags))

  # now remove the names
  names(flat.tags) <- NULL

  # build a list of commands to assign values to variables with tag names 
  text.assign <- paste0("tags$",tagnames, " <- '", flat.tags, "'")

  # initialize tags object
  tags <- NULL

  # run the list of commands to assign values to variables
  eval(parse(text=text.assign))

  # add the tags to DT_tags.
  DT_tags <- rbindlist(list(DT_tags, tags), use.names = TRUE, fill = TRUE)

}

DT_tags

str(DT_tags)
names(DT_tags)
