# getUUID.R
# script to pull down all the UUID datastreams and save as csv files, maybe on external harddrive if they're too big.
# Jim Lutz "Wed Sep 13 17:53:03 2017"

# get data from http://ec2-54-184-120-83.us-west-2.compute.amazonaws.com/
# use list of UUIDs from /home/jiml/HotWaterResearch/projects/HWDS monitoring/retrieve_field_data/data/DT_tags.RData

# set packages & etc
source("setup.R")


install.packages("/home/jiml/Downloads/RSmap_1.0.tar.gz", repos=NULL)
library(RSmap)

# set up paths to working directories
source("setup_wd.R")

# load the tags
load(file = paste0(wd_data,"DT_tags.RData"))

# get a list of UUIDs
UUIDs <- DT_tags$uuid

# following these instructions
# https://pythonhosted.org/Smap/en/2.0/R_access.html
RSmap("http://ec2-54-184-120-83.us-west-2.compute.amazonaws.com/backend")

## set start and end times
start <- as.numeric(strptime("4-1-2013", "%m-%d-%Y"))*1000
end <- as.numeric(strptime("6-30-2014", "%m-%d-%Y"))*1000

# try it on one UUID
data <- RSmap.data_uuid((UUIDs[200]),start,end)
str(data)

# turn it into a data.table
DT <- data.table(epochms=data[[1]]$time, value=data[[1]]$value)

# add a human readable timestamp
DT[,datetime := as.POSIXct(epochms/1000,origin="1970-01-01", tz = "America/Los_Angeles", format = "%Y-%m-%d %H:%M:%S")]
DT[,datetime := strftime(epochms/1000, format = "%Y-%m-%d %H:%M:%S", tz = "America/Los_Angeles", usetz = TRUE, origin="1970-01-01")]

# this works
as.POSIXct(DT$epochms/1000,origin="1970-01-01", tz = "America/Los_Angeles") 

