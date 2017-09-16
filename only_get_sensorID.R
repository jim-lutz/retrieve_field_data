# only_get_sensorID.R
# script to pull down all the datastreams associated with one sensorID save as raw RSmap objects
# Jim Lutz "Fri Sep 15 16:51:25 2017"

# get data from http://ec2-54-184-120-83.us-west-2.compute.amazonaws.com/
# use metadata from /home/jiml/HotWaterResearch/projects/HWDS monitoring/retrieve_field_data/data/DT_tags.RData

# set packages & etc
source("setup.R")

install.packages("/home/jiml/Downloads/RSmap_1.0.tar.gz", repos=NULL)
library(RSmap)

# set up paths to working directories
source("setup_wd.R")

# load the tags
load(file = paste0(wd_data,"DT_tags.RData"))

# get a list of sensorID
sensorIDs <- unique(DT_tags[!is.na(sensorID),list(sensorID)][order(sensorID)]) # 253 unique ones

# find x3320
sensorIDs[sensorID=='x3320']
sensorIDs[sensorID=='x3320', which = TRUE] # 112
# 113-56 = 57? suspiciously close to where it choked the last time.

# choked, last one Sep 16 07:51 RSmap.x3331.raw.xz.RData
sensorIDs[sensorID=='x3331', which = TRUE] # 118

# following these instructions
# https://pythonhosted.org/Smap/en/2.0/R_access.html
RSmap("http://ec2-54-184-120-83.us-west-2.compute.amazonaws.com/backend")

## set start and end times that cover the monitoring period
start <- as.numeric(strptime("3-1-2013", "%m-%d-%Y"))*1000
end <- as.numeric(strptime("6-30-2014", "%m-%d-%Y"))*1000

# test on one sensorID
# this.sensorID <- sensorIDs[41]  # x3255

get.this.sensorID <- function(this.sensorID) {

  # get the UUIDs for that sensorID
  UUIDs <- DT_tags[sensorID==this.sensorID, ]$uuid  # sensorID x3255

  # get the data for those uuids
  data <- RSmap.data_uuid(UUIDs,start,end)

  # str(data) # It's of list of 6 object, each of which is 3 objects, 2 numerical vectors(time,value) and 1 character (uuid)

  # save the raw RSmap object in the by_sensorID data directory
  save(data, file = paste0(wd_data,"by_sensorID/RSmap.",this.sensorID,".raw.xz.RData"), compress = "xz")

}

# work with plyr
if(!require(plyr)){install.packages("plyr")}
library(plyr)
library(dplyr)


# now apply the function to the (remaining) list of sensorIDs
l_ply(sensorIDs[120:253]$sensorID, get.this.sensorID, .progress = "text")

# see if continues after (error in?) l_ply
time.is <- date()
cat("made it past l_ply at ", time.is)

# sensorIDs[119:253]$sensorID, latest one still Sep 16 07:51 RSmap.x3331.raw.xz.RData
# Error in value[[3L]](cond) : cURL error
# skip 55, 119

