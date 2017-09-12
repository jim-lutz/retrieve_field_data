#functions.R
# smap R functions for hwds field monitoring

get_dt_mote <- function(ll_data) {
    # function to build one data table from all the uuids in one mote
    # input is a ll_data Rsmap data structure
    
    # get data.tables for
    # "flowA"     "tempA"     "sensorA"   "flowB"     "tempB"     "sensorB"   "batt_volt"
    dt_flowA <- get_dt_uuid(1,ll_data)
    dt_tempA <- get_dt_uuid(2,ll_data)
    dt_sensorA <- get_dt_uuid(3,ll_data)
    dt_flowB <- get_dt_uuid(4,ll_data)
    dt_tempB <- get_dt_uuid(5,ll_data)
    dt_sensorB <- get_dt_uuid(6,ll_data)
    dt_batt_volt <- get_dt_uuid(7,ll_data)
    
    # merge the data.tables into one by time keeping all records
    dt_mote <- merge(dt_flowA,dt_tempA,by="time",all=TRUE)
    dt_mote <- merge(dt_mote,dt_tempA,by="time",all=TRUE)
    dt_mote <- merge(dt_mote,dt_sensorA,by="time",all=TRUE)
    dt_mote <- merge(dt_mote,dt_flowB,by="time",all=TRUE)
    dt_mote <- merge(dt_mote,dt_tempB,by="time",all=TRUE)
    dt_mote <- merge(dt_mote,dt_sensorB,by="time",all=TRUE)
    dt_mote <- merge(dt_mote,dt_batt_volt,by="time",all=TRUE)
    
    # add a datatime field
    dt_mote[,datetime:=readUTCmilliseconds(time)]
    
    return(dt_mote)
    
}




get_dt_uuid <- function(uuid_num,ll_data) {
    # function to return one uuid from a ll_data Rsmap data structure as a data.table
    # uuid_num is a number corresponding to 
    # "flowA"     "tempA"     "sensorA"   "flowB"     "tempB"     "sensorB"   "batt_volt"
    
    eval(parse( text = paste0("data.table(",
                              "time = ll_data[[uuid_num]][[1]]$time,",
                              eval(datastreams[uuid_num])," = ll_data[[uuid_num]][[1]]$value)" 
                                )
                )
        )
    
}



get_mote_data <- function (moteID) {
    # function to get all data streams from one moteID
    # returns ll_data as a list of 7 lists of 3 lists each
    
    datastreams = c("flowA", "tempA", "sensorA", "flowB", "tempB", "sensorB", "batt_volt")
    # need to get sensorID also because sensors were sometimes switched out
    
    # make list of paths to get datastreams
    where_paths = paste0("Path = '/hwds_test/0x",moteID,"/",datastreams,"'")
    
    # default start & end times
    start = writeUTCmilliseconds("2013-06-01")
    end   = writeUTCmilliseconds("2014-06-01")
    limit = 60*60*24*365 # seconds in a year 31536000 save for production
    
    # getting all data streams for one mote 
    ll_data <- llply(.data=where_paths, .fun=RSmap.data,  start=start, end=end, limit=limit, .progress="text")
    
    return(ll_data)
}



get_smap_data_timeperiod <- function (dt_tp,uuids,mote) {
    # function to print one mote's four data streams for one timeperiod
    # dt_tp = data.frame of type dt_timeperiods
    # uuids = list of uuids in flowA,flowB,tempA,tempB order
    # mote = moteID associated with the uuids
    
    # get starting & ending times, dates from dt_tp
    start<-as.numeric(dt_tp$start)
    stop<-as.numeric(dt_tp$stop)
    date1 <- substr(dt_tp$begin,1,10)
    date2 <- substr(dt_tp$end,1,10)
    
    # get the mote's data for the time period
    dt_mote <- get_smap_data(uuids, start, stop)
    
    # save to file as csv
    fn_mote <- paste0(wd_data,"mote_",mote,"_",date1,"_",date2,".csv")
    write.csv(dt_mote,file=fn_mote,row.names=FALSE)
    
}



get_smap_data <- function(uuids, start, stop){
    # function to get 4 data streams (from one mote)
    # returns data.table of data
    # uuids = list of uuids as characters in flowA,flowB,tempA,tempB order
    # start = UTCms of start of data
    # stop = UTCms of end of data
    
    smap <- RSmap.data_uuid(uuids, start, stop) # get the RSmap data streams
    
    dt_motedata <- data.table(  # turn into a data.table 
        UTCms = smap[[1]]$time, # same time across all datastreams from one mote
        datetime = as.character(as.POSIXct(smap[[1]]$time/1000,origin="1970-01-01")), # convert to POSIXct time save as character
        flowA = smap[[1]]$value, # depends on path sort resulting in this order
        flowB = smap[[2]]$value, 
        tempA = smap[[3]]$value, 
        tempB = smap[[4]]$value
    )
    
    return(dt_motedata)
    
}





# for debugging get_motes
# sourcename = 'HWDS_h16 (beagle15)'
# get_motes(sourcename)

uuid_dates <- function (data) {
    # given a single Smap data stream return uuid, first_date, last_date, still_live
    
    # get the uuid
    uuid <- data[[1]]$uuid
    
    # turn a single Smap data stream into a data.table
    dt_data <- dt_datastream(data)
    
    # first date
    first_date <- dt_data[1,]$time
    
    # last date
    last_date <- dt_data[nrow(dt_data),]$time
    
    # still live (reporting within last 10 minutes)
    still_live <- as.numeric( Sys.time()-last_date, units="mins" ) < 10
    
    data.frame(uuid, first_date, last_date, still_live)
}

get_motes <- function (sourcename) {
    # function to return the moteIDs for a specific house, identified by sourcname
    where = paste("Metadata/SourceName = '",sourcename,"'",sep="")
    
    # get all the tags for that houseID
    tags <- RSmap.tags(where)
    
    # lapply to get Paths
    tag.paths <- lapply(tags, function(tag){ tag$Path } )
    
    # keep only the sensor,flow & temp paths
    paths <- unlist(tag.paths)
    paths <- paths[grep("hwds_test.*/(flow|temp|sensor)",paths)]
    
    # get the moteID, houseID & SourceNames for this house
    moteID <- unique(regmatches(paths,regexpr("[0-9a-f]{4}",paths)))
    houseID <- str_extract(sourcename,perl("h[0-9]{1,2}"))
    dt_mote <-data.table(moteID=moteID,houseID=houseID,SourceName=sourcename)
    
    setkey(dt_mote,moteID)
    
    return(dt_mote)
}




# function to get an entire data stream for analysis
get_datastream <- function(where){
    # where is a ArchiverQuery selector for finding time series
    
    # default start & end times
    start = writeUTCmilliseconds("2013-06-01")
    end   = writeUTCmilliseconds("2014-06-01")
    
    # a years worth of seconds
    limit = 60*60*24*365
    
    # only want one data stream
    streamlimit=1
    
    data <- RSmap.data(where, start, end, limit, streamlimit)
    
    return(data)
}


dt_datastream <- function(RSmap_single_stream){
    # function to convert a single stream of RSmap data into a data.table
    
    # convert time from numeric to POSIXct. 
    time <- RSmap_single_stream[[1]]$time/1000
    time <- as.POSIXct(time,origin="1970-01-01", tz="America/Los_Angeles")
    
    # values
    value <- RSmap_single_stream[[1]]$value
    
    # make a data.table
    dt_RSmap_ss <- data.table(time=time,value=value)
    
    return(dt_RSmap_ss)
}


get_datastream_uuid <- function(where){
    # function to get the uuid from a single stream of RSmap data
    # where is a ArchiverQuery selector for finding one time series
    
    # get all the tags for that SourceName
    tags <- RSmap.tags(where)
    
    
    uuid <- tags[[1]]$uuid
    
    return(uuid)
    
}

readUTCmilliseconds <-function(UTCtime){
    # function to translate UTC milliseconds to something human readable
    
    # default to Pacific time
    tz = "America/Los_Angeles"
    
    # first convert to POSIXlt
    POSIXltime <- as.POSIXlt(UTCtime/1000,origin="1970-01-01", tz=tz )
    
    # then convert to formatted character string
    return(as.character(POSIXltime,usetz=TRUE))
    
}


writeUTCmilliseconds <-function(datetime){
    # function to translate from human readable to UTC milliseconds
    # assumes %Y-%M-%D %H:%M:%s
    
#     # find datetime and timezone
#     mtz = regexpr("[A-Z]{3}",datetime,perl=TRUE)
#     tz = regmatches(datetime,mtz)
#     datetime2 = force_tz(ymd_hms(datetime),tzone=tz)
#     tz

    # default to Pacific time
    tz = "America/Los_Angeles"
    
    # convert to POSIXct format
    UTCtime <- as.POSIXct(datetime, tz=tz)
    
    # numeric and to milliseconds
    UTCmilliseconds <- as.numeric(UTCtime)*1000
    
    return(UTCmilliseconds)
    
}



# function to get sensorID from last record in series matching a path
# smap_sensor_path <- "/hwds_test/0x34ca/sensorB" # use this for debugging function
get_sensorID <- function (smap_sensor_path) {
    # path must be for a sensor, no error checking for that yet.
    
    # get the last record in the series for that path
    last_rec <- RSmap.latest(paste("Path = ", "'", smap_sensor_path, "'",sep=""))
    
    # sensorID is the value in this data series
    sensorID=as.character(last_rec[[1]]$value)
    
    return(sensorID)
}

# function to get sensorIDs, moteIDs, and ports for one SourceName from hwds2.lbl.gov
#SourceName="HWDS_h10 (beagle22)"  # use for debuggng the function
#sensorID_moteID_port(SourceName)
sensorID_moteID_port <- function (SourceName) {
    
    # get all the tags for that SourceName
    tags <- RSmap.tags(paste("Metadata/SourceName = ","'",SourceName,"'",sep=""))
    
    # lapply to get Paths
    tag.paths <- lapply(tags, function(tag){ tag$Path } )
    
    # make a data.table, include sourcenames
    dt_smp <- data.table( cbind( sourcenames=SourceName, paths=unlist(tag.paths) ) )
    
    # restrict to sensors only
    dt_smp <- dt_smp[grep("hwds_test.*/sensor",paths),]
    
    # convert paths to character strings
    dt_smp[,paths:=as.character(paths)]
    
    # get the sensorIDs
    # mutate is a plyr command to add new field
    dt_smp <- ddply(dt_smp, .(paths), mutate, sensorID=get_sensorID(paths) )
    
    # has to be a data.table for next steps
    dt_smp <- data.table(dt_smp)
    
    # add fields for mote and port[A|B] to the source,path,uuid data.table
    dt_smp[,mote:=regmatches(paths,regexpr("0x[0-9a-f]{4}",paths))]
    dt_smp[,port:=substr(paths, nchar(paths), nchar(paths)) ]
    
    setkeyv(dt_smp,c("mote","port"))
    
    return(dt_smp)
}


# function to get sensor(flow|temp) and uuid, moteIDs, and ports for one SourceName from hwds2.lbl.gov
#SourceName="HWDS_h10 (beagle22)"  # use for debuggng the function
#flowtemp_moteID_port(SourceName)
flowtemp_moteID_port <- function (SourceName) {
    
    # get all the tags for that SourceName
    tags <- RSmap.tags(paste("Metadata/SourceName = ","'",SourceName,"'",sep=""))
    
    # lapply to get Paths
    tag.paths <- lapply(tags, function(tag){ tag$Path } )
    
    # make a data.table sourcenames and paths
    dt_ftmp <- data.table( cbind( sourcenames=SourceName, paths=unlist(tag.paths) ) )
    
    # restrict to flow and temp only
    dt_ftmp <- dt_ftmp[grep("hwds_test.*/(flow|temp)",paths),]
    
    # convert paths to character strings
    dt_ftmp[,paths:=as.character(paths)]
    
    # add fields for mote and port[A|B] to the source,path,uuid data.table
    dt_ftmp[,mote:=regmatches(paths,regexpr("0x[0-9a-f]{4}",paths))]
    dt_ftmp[,port:=substr(paths, nchar(paths), nchar(paths)) ]
    
    setkeyv(dt_ftmp,c("mote","port"))
    
    return(dt_ftmp)
}




sum_flow_1day <- function(flows,houses,dates) {
    # returns the sum of a flow type for one day, one house(WH),
    
    # get uuid for flow
    flow_uuid = as.character(dt_WH_uuids[house==houses,][value==flows,uuid])
    
    # get a data.table of flow for that day
    dt_flow <- get_1day_uuid_data(dates, flow_uuid)
    
    # sum positive values
    sum_flow <- sum(dt_flow[value>0,]$value)
    
    return(sum_flow)
    
}




# function to get one day's uuid data as a data.table from hwds2 given uuid & date
get_1day_uuid_data <- function (smap_date, snap_uuid) {
    # should put some checks on date and uuid format here sometime
    
    # set the start and end dates to capture everything
    days_start = ymd(smap_date, tz = "America/Los_Angeles") # So far the sites are all in California
    days_end = days_start + days(1)
    start <- as.numeric(days_start)*1000 # The timestamp of the first record in (milli)seconds, inclusive
    end <- as.numeric(days_end)*1000 # The timestamp of the last record, exclusive
    
    # get the data
    days_data <- RSmap.data_uuid(snap_uuid,start,end)
    
    # return the uuid data as data.table
    # days_data[[1]]
    
    dt_uuid <- with(days_data[[1]], # work with the uuid data
                    # turn into a data.table 
                    data.table(time=as.POSIXct(time/1000,origin="1970-01-01"),value=value) # convert to POSIXct time
    )
        
    return(dt_uuid)
}


# function to get metadata tags for one house from hwds2.lbl.gov
# use next line for debuggng the function
#house="HWDS_h10 (beagle22)"
path_uuid <- function (house) {
    # returns a data.table of house,path,uuid for temps & flows & sensors only
    tags <- RSmap.tags(paste("Metadata/SourceName = ","'",house,"'",sep=""))
    
    # lapply to get Path & uuid
    tag.paths <- lapply(tags, function(tag) tag$Path )
    tag.uuids <- lapply(tags, function(tag) tag$uuid )
    
    # make a data.table, include sourcenames
    dt_spu <- data.table( cbind( sourcenames=house, paths=unlist(tag.paths), uuids=unlist(tag.uuids) ) )
    
    # restrict to temps & flows & sensors
    dt_spu <- dt_spu[grep("hwds_test.*/(temp|flow|sensor)",paths),]
    setkey(dt_spu,paths)
    
    return(dt_spu)
}


# returns a vector containing the min and max time of the data
getExtents <- function(d){
    ex <- lapply(d, function(el){
        c(min(el$time), max(el$time))
    })
    ex <- unlist(ex)
    c(min(ex), max(ex))
}



uuid_times <- function (uuid) {
    # returns the start and stop time of data in uuid
    
    # set extreme start and end dates to capture everything
    start <- as.numeric(strptime("1-1-2012", "%m-%d-%Y"))*1000
    end <- as.numeric(strptime("12-31-2014", "%m-%d-%Y"))*1000
    
    # get first record
    ds1 <- RSmap.data_uuid(uuid, start, end, limit=1)
    start_time=ds1[[1]]$time
    
    # find last record
    dsz <- RSmap.latest(paste("uuid = ","'",uuid,"'",sep=""),limit=-1)
    last_time=dsz[[1]]$time
    
    
    # in milliseconds UTC
    #times <- c(ds1[[1]]$time, dsz[[1]]$time)
    #times <- c(start, dsz[[1]]$time)
    #times <- c(start, end)
    dt_times <- data.frame(uuid=uuid, start_time=start_time, last_time=last_time)
    
    return(dt_times)
}
