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
# had to reinstall RSmap?

# get the tags
tags <- RSmap.tags("Metadata/SourceName = 'HWDS_h1'")

str(tags)
# got something

length(tags)
# 81

str(tags[1])
# looks like it works

# now try flattening list
flat.tags.1 <- unlist(tags[1])

str(flat.tags.1)
class(flat.tags.1)

# can get the samething this way
names(flat.tags.1)

# get the names as a list
ft1names <- unlist(names(flat.tags.1))
class(ft1names)
str(ft1names)

# now remove the names
names(flat.tags.1) <- NULL
flat.tags.1
class(flat.tags.1)
str(flat.tags.1)

# build a list of commands to assign values to variables with that name
text.assign <- paste0("tags$",ft1names, " <- '", flat.tags.1, "'")

tags <- NULL

# build list of commands to assign values to variables
eval(parse(text=text.assign))

str(tags)
class(tags)

# make an empty data.table
DT_tags <- data.table(NULL)

# add the tags to it.
DT_tags <- rbindlist(list(DT_tags, tags), use.names = TRUE, fill = TRUE)

str(DT_tags)
