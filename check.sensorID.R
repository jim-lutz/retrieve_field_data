# check.sensorID.R
# script to check on records with and without sensorIDs
# Jim Lutz "Thu Sep 14 14:57:09 2017"

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
sort(unique(UUIDs))
# there's 2947 both ways, so they're all unique

# get a list of sensorIDs
sensorIDs <- DT_tags$sensorID
length(sensorIDs)
# 2947, every UUID has a sensorID?
# that's not true
length(unique(sensorIDs))
# only 254, 253 if not count NAs

DT_tags[is.na(sensorID),]
nrow(DT_tags[is.na(sensorID),])
# 436 without sensorIDs

# check if those are all pingtest
DT_tags[is.na(sensorID) & path %like% "/pingtest",]
nrow(DT_tags[is.na(sensorID) & path %like% "/pingtest",])
# 335

sort(unique(DT_tags[is.na(sensorID) & path %like% "/pingtest",path]))
  # [1] "/pingtest/128.3.28.51/max"        "/pingtest/128.3.28.51/median"     "/pingtest/128.3.28.51/min"       
  # [4] "/pingtest/128.3.28.51/success"    "/pingtest/128.8.237.77/max"       "/pingtest/128.8.237.77/median"   
  # [7] "/pingtest/128.8.237.77/min"       "/pingtest/128.8.237.77/success"   "/pingtest/www.google.com/max"    
  # [10] "/pingtest/www.google.com/median"  "/pingtest/www.google.com/min"     "/pingtest/www.google.com/success"

# what are the other 100 records?
DT_tags[is.na(sensorID) & !(path %like% "/pingtest"),]
# net_reliability?

unique(DT_tags[is.na(sensorID) & !(path %like% "pingtest"), list(path)])
  #                                      path
  # 1:   /hwds_test/net_reliabilty/packets_rx
  # 2: /hwds_test/net_reliabilty/packets_lost
  # 3:   /hwds_test/net_reliability/num_motes
  # 4:  /hwds_test/net_reliabilty/reliability

unique(DT_tags[ path %like% "net_reliability" , path])

nrow(DT_tags[is.na(sensorID),])
# 436

nrow(DT_tags[path %like% "net_reliability" | path %like% "/pingtest"])
# 359
nrow(DT_tags[path %like% "net_reliability"])
#  24
nrow(DT_tags[path %like% "/pingtest"])
# 335

# so what are the remaining ones?
DT_tags[is.na(sensorID)][(path %like% "pingtest"),][,path] # 335
DT_tags[is.na(sensorID)][(path %like% "net_reliability"),][,path] # 24
DT_tags[is.na(sensorID)][(path %like% "net_reliabilty"),][,path] # 77  notice the typo in reliability!

335 + 24 + 77 #436 OK they're all there
nrow(DT_tags[path %like% "net_reliability" | path %like% "net_reliabilty" | path %like% "pingtest"])
# 436

