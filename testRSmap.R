# testRSmap.R
# script to see if RSmap works 

# Jim Lutz "Tue Sep 12 15:58:52 2017"

# set packages & etc
source("setup.R")

# set up paths to working directories
source("setup_wd.R")

# RSmap functions
source("functions.R")

# following these instructions
# https://pythonhosted.org/Smap/en/2.0/R_access.html
RSmap("http://www.openbms.org/backend")

start <- as.numeric(strptime("3-29-2013", "%m-%d-%Y"))*1000
end <- as.numeric(strptime("3-31-2013", "%m-%d-%Y"))*1000

oat <- list("395005af-a42c-587f-9c46-860f3061ef0d",
            "9f091650-3973-5abd-b154-cee055714e59",
            "5d8f73d5-0596-5932-b92e-b80f030a3bf7",
            "d64e8d73-f0e9-5927-bbeb-8d45ab927ca5")

data <- RSmap.data_uuid(oat, start, end)

str(data)
# In this case it's a list of 4 items, each of which is a list of three items, time & value are lists, uuid is chr.
data[[1]]$value[22]
data[[1]]$time[22]
data[[2]]$uuid[1]

# returns a vector containing the min and max of the data
getExtents <- function(d){
  ex <- lapply(d, function(el){
    c(min(el$value), max(el$value))
  })
  ex <- unlist(ex)
  c(min(ex), max(ex))
}

ylim <- getExtents(data)

# convert to UTC seconds for R plot
time_UTC_sec <- data[[1]]$time/1000


# choose some pretty colors
col <- topo.colors(10)

# set up the plot and draw the first series
plot(time_UTC_sec
     , data[[1]]$value
     , xaxt="n"
     , type="l"
     , col=col[1]
     , ylim=ylim
     , xlab="Datetime"
     , ylab="Outside air temperature [°F]")

# format the x-axis to be the local time
axis.POSIXct(side=1, as.POSIXct(time_UTC_sec, origin="1970-01-01"),  format="%m-%d-%y")

# plot the rest of the series
for (i in 2:length(data)){
  lines(data[[i]]$time/1000, data[[i]]$value, col=col[i])
}



tags <- RSmap.tags("Metadata/Extra/Type = 'oat'")

str(tags)

tags_all <- RSmap.tags("Metadata/Extra = *")
