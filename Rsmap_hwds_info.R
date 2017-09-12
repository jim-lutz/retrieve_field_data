fn_script <- "Rsmap_hwds_info.R"
# attempt to build monitoring system info from smap.lbl.gov
# Jim Lutz
# "Thu Feb 13 09:05:49 2014"
# "Mon Apr 28 15:49:57 2014"

# set packages & etc
source("setup.R")

# set up paths to working directories
source("setup_wd.R")

# RSmap functions
source("functions.R")


# create a connection to smap.lbl.gov
RSmap("http://smap.lbl.gov/backend")
logwarn('connection to smap.lbl.gov')


# test house
# from http://hwds2.lbl.gov/plot/
# Metadata/SourceName    HWDS_h3 (beagle2)
# Path    /hwds_test/0x3443/sensorA
#  110783 points

where = as.character("Path = '/hwds_test/0x3443/sensorA'")
# get an one entire data stream for this query


testdata <- get_datastream(where)

# turn the data stream time and values into a data.table
dt_sensorA_ID <- dt_datastream(testdata)

# get the uuid from the data stream
uuid <- get_datastream_uuid(where)

# summary info about data stream
str(summary(dt_sensorA_ID$value))
nrow(dt_sensorA_ID)
min(dt_sensorA_ID$value)
max(dt_sensorA_ID$value)
as.numeric(names(sort(table(dt_sensorA_ID$value),decr=TRUE))[1]) # hackish version of mode
# counts of values
setkey(dt_sensorA_ID,value)
dt_sensorA_ID[,list(n=length(time)),by=value]

# find earliest & latest dates
setkey(dt_sensorA_ID,time)
dt_sensorA_ID$time[1]
dt_sensorA_ID$time[nrow(dt_sensorA_ID)]

# one house for testing
testhouse <- "HWDS_h10 (beagle22)"
# testtags <- RSmap.tags(paste("Metadata/SourceName = ","'",testhouse,"'",sep=""))
# str(testtags)

# make a data.table of sensorIDs by mote, port
dt_smp <- sensorID_moteID_port(testhouse)
str(dt_smp)

# take a look at the list of sensorIDs
dt_smp[,list(sensorID),by=list(mote,port)]

# make a data.table of flow|temp and uuid by mote, port 
dt_ftmp <- flowtemp_moteID_port(testhouse)
str(dt_ftmp)


# merge sensorIDs onto flow temps
dt_ftsmp <- merge(dt_ftmp, dt_smp[,list(sensorID),by=list(mote,port)])



!!!!!!!!!!!!!!!!!!!!!!


# see what we got
date_time=as.POSIXct(last_rec[[1]]$time/1000,origin="1970-01-01")
sensorID=as.character(last_rec[[1]]$value)

date_time <- with(latest_record[[1]], {# work with the last record
    date_time=as.POSIXct(time/1000,origin="1970-01-01")
                #data.table(time=as.POSIXct(time/1000,origin="1970-01-01"),value=value) # convert to POSIXct time
    }
)

latest_record[[1]]$time


# make a list of all the houses
# cut & paste from http://hwds2.lbl.gov
houses <- c("HWDS_h1", "HWDS_h1 (beaglebone)", "HWDS_h10 (beagle22)", "HWDS_h11 (beagle11)", "HWDS_h13 (beagle16)", 
            "HWDS_h14 (beagle3)", "HWDS_h16 (beagle15)", "HWDS_h17 (beagle12)", "HWDS_h18 (beagle20)", 
            "HWDS_h19 (beagle10)", "HWDS_h2", "HWDS_h20 (beagle4)", "HWDS_h21 (beagle19)", "HWDS_h22 (beagle17)", 
            "HWDS_h24 (beagle18)", "HWDS_h3", "HWDS_h3 (beagle2)", "HWDS_h35 (beagle13)", "HWDS_h4 (beagle5)", 
            "HWDS_h5 (beagle23)", "HWDS_h5 (beagle9)", "HWDS_h6 (beagle14)", "HWDS_h7 (beagle6)", "HWDS_h9 (beagle8)")


# apply the path_uuid function to each house in the houses list.
dt_all_spu <- data.table(ldply(houses,path_uuid))
# 24 warnings
# RSmap.tags: no tags found for streams where Metadata/SourceName = 'hwds_h1 (beaglebone)'

# list of unique source names
setkey(dt_all_spu,sourcenames)
dt_all_spu[,list(n=length(paths)),
           by=sourcenames]

# try to get the sensorIDs
dt_all_spu[grep("sensor",paths),]

start_date = as.numeric(ymd("2013-08-01", tz = "America/Los_Angeles"))*1000
end_date = as.numeric(ymd("2014-08-01", tz = "America/Los_Angeles"))*1000
sensorID <- RSmap.data_uuid("d98519ac-e8c9-5c33-8160-0c1ca4801e2c",start_date,end_date)
str(sensorID)
sensorID[1]

max(sensorID$value)

# now save to a csv file
# make the file name
fn_dt_all_spu = paste(wd_data,"dt_all_spu.csv",sep="")
write.csv(dt_all_spu,file=fn_dt_all_spu, row.names = FALSE)

