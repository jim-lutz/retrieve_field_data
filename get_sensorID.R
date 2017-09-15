# get_sensorID.R
# script to pull down all the datastreams associated with one sensorID and save as csv files, maybe on external harddrive if they're too big.
# Jim Lutz "Thu Sep 14 15:49:47 2017"

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

# get a list of sensorID
sensorIDs <- unique(DT_tags[!is.na(sensorID),list(sensorID)][order(sensorID)]) # 253 unique ones

# following these instructions
# https://pythonhosted.org/Smap/en/2.0/R_access.html
RSmap("http://ec2-54-184-120-83.us-west-2.compute.amazonaws.com/backend")

## set start and end times that cover the monitoring period
start <- as.numeric(strptime("3-1-2013", "%m-%d-%Y"))*1000
end <- as.numeric(strptime("6-30-2014", "%m-%d-%Y"))*1000

# test on one sensorID
this.sensorID <- sensorIDs[40]

# get the UUIDs for one sensorID

UUIDs <- DT_tags[sensorID==this.sensorID, ]$uuid  # sensorID x3255

# get the metadata for that sensorID
DT_metadata <- DT_tags[sensorID==this.sensorID]

# try it on the UUIDs for one sensorID
data <- RSmap.data_uuid(UUIDs,start,end)
str(data) # It's of list of 6 object, each of which is 3 objects, 2 numerical vectors(time,value) and 1 character (uuid)

# initialize a dummy data.table
DT_data <- data.table(epochms=0)

for(n in 1:length(data)) {
  # turn it into a data.table
  DT <- data.table(epochms=data[[1]]$time, value=data[[1]]$value)
  
  # set key
  setkey(DT,epochms)

  # get the appropriate sensortype
  this.uuid = data[[1]]$uuid
  this.sensortype = DT_metadata[uuid==this.uuid]$sensortype
  
  # rename the value
  setnames(DT,"value", this.sensortype)
  
  # merge it into the data.table
  DT_data <- merge(DT,DT_data,all=TRUE)
  
}
  
  
# add a human readable timestamp
DT[,datetime := as.POSIXct(epochms/1000,origin="1970-01-01", tz = "America/Los_Angeles", format = "%Y-%m-%d %H:%M:%S")]
DT[,datetime := strftime(epochms/1000, format = "%Y-%m-%d %H:%M:%S", tz = "America/Los_Angeles", usetz = TRUE, origin="1970-01-01")]

# this works
as.POSIXct(DT$epochms/1000,origin="1970-01-01", tz = "America/Los_Angeles") 

