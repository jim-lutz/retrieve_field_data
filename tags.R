# tags.R

# get all the tags from http://ec2-54-184-120-83.us-west-2.compute.amazonaws.com/
# Jim Lutz "Wed Sep 13 08:34:52 2017"

# set packages & etc
source("setup.R")


install.packages("/home/jiml/Downloads/RSmap_1.0.tar.gz", repos=NULL)
library(RSmap)

# set up paths to working directories
source("setup_wd.R")

# RSmap functions
# source("functions.R")
# not sure if any of these are useful

# following these instructions
# https://pythonhosted.org/Smap/en/2.0/R_access.html
RSmap("http://ec2-54-184-120-83.us-west-2.compute.amazonaws.com/backend")

# get the tags for one Sourcename
Sourcename.tags <- RSmap.tags("Metadata/SourceName ~ 'HWDS'")

str(Sourcename.tags)

length(Sourcename.tags)
# [1]  2947
# got something

# save the raw RSmap object
save(Sourcename.tags, file = paste0(wd_data,"RSmap.tags.raw.RData"))

# this is the number of UUIDs for this Sourcename
n.UUID <- length(Sourcename.tags)
#  2947

# make an empty data.table to hold all the tags
DT_tags <- data.table(NULL)

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

# looks like it worked
# save the raw data
save(DT_tags, file = paste0(wd_data,"DT_tags_raw.RData"))

# clean up the DT_tags data.table

# drop Metadata.uuid
DT_tags[,Metadata.uuid:=NULL]

# better names
setnames(DT_tags,
         c('Properties.Timezone',
           'Properties.UnitofMeasure', 
           'Properties.ReadingType', 
           'Path', 
           'uuid', 
           'Metadata.SourceName', 
           'Metadata.Metadata.Instrument.Model', 
           'Metadata.Metadata.Instrument.Manufacturer', 
           'Metadata.Metadata.Extra.Driver', 
           'Metadata.Description'),
         c('timezone',
           'units', 
           'type', 
           'path', 
           'uuid', 
           'source', 
           'model', 
           'study', 
           'driver', 
           'other')
         )

# get house number
DT_tags[source %like% "HWDS_h", house:= str_sub(source,7,8)]
sort(unique(DT_tags$house)) # looks like if worked, but house 35?

# get sensorID and sensortype
DT_tags[path %like% "/hwds_test/0x", ':=' (sensorID = str_sub(path,13,17),
                                          sensortype = str_sub(path,19,-1)
                                          )
        ]
sort(unique(DT_tags$sensorID)) # OK?
sort(unique(DT_tags$sensortype)) # OK, except when sensorID =="x5c2/"

DT_tags[sensorID =="x5c2/", ':=' (sensorID = str_sub(path,13,16),
                                  sensortype = str_sub(path,18,-1)
                                  )]

sort(unique(DT_tags$sensortype)) # OK, that's better

# better order
names(DT_tags)
setcolorder(DT_tags, c('source', 'path', 'house', 'sensorID', 'sensortype', 'units', 'uuid', 
                       'type', 'study', 'model', 'timezone', 'driver', 'other'))

save(DT_tags, file = paste0(wd_data,"DT_tags.RData"))
write.csv(DT_tags, file = paste0(wd_data,"DT_tags.csv"), row.names = FALSE, na="" )

