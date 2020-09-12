### Load libraries ###
library(DBI)
library(RSQLite)
library(lubridate)
library(data.table)
library(parallel)
library(scales)
library(RColorBrewer)
library(ggplot2)
library(cowplot)
library(leaflet)
library(highcharter)
library(glmnet)
library(e1071)
library(rpart)
library(randomForest)
library(xgboost)
library(shiny)
library(shinythemes)


### Set variables ###
sqlite_db_location <- "/Volumes/AN/Data/SQLite/"
r_func_location <- "/Users/minathaniel/Documents/R/R Scripts/Functions/"
no_cores <- detectCores()


### Set functions ###
## Pre-defined functios.
source(file=paste0(r_func_location, "coordinate_distance.R"))
source(file=paste0(r_func_location, "roc.R"))
source(file=paste0(r_func_location, "model_performance.R"))
source(file=paste0(r_func_location, "permutation_importance.R"))


### Import data ###
## GNAF.
conn <- dbConnect(drv=SQLite(), dbname=paste0(sqlite_db_location, "PSMA.db"))
gnaf_state <- c("act","nsw","nt","ot","qld","sa","vic","wa")
gnaf <- lapply(1:length(gnaf_state),
               function(x1) {
                 print(paste0("importing data from ", gnaf_state[x1]))
                 start_time <- proc.time()
                 print(Sys.time())
                 dt_query <- "
                 select         x1.ADDRESS_DETAIL_PID AS GNAF_ID,
                                x1.DATE_CREATED,
                                x1.BUILDING_NAME,
                                x1.LOT_NUMBER,
                                x1.LEVEL_NUMBER,
                                x1.FLAT_NUMBER,
                                x1.NUMBER_FIRST,
                                x1.NUMBER_LAST,
                                x2.STREET_NAME,
                                x2.STREET_TYPE_CODE,
                                x3.LOCALITY_NAME,
                                x1.POSTCODE,
                                x4.STATE_NAME,
                                x4.STATE_ABBREVIATION,
                                x1.CONFIDENCE,
                                x5.LONGITUDE,
                                x5.LATITUDE,
                                x6.MB_2016_PID
                 
                 from           '____'_address_detail x1
                 left join      '____'_street_locality x2
                 on             x1.STREET_LOCALITY_PID=x2.STREET_LOCALITY_PID
                 left join      '____'_locality x3
                 on             x1.LOCALITY_PID=x3.LOCALITY_PID
                 left join      '____'_state x4
                 on             x3.STATE_PID=x4.STATE_PID
                 left join      '____'_address_default_geocode x5
                 on             x1.ADDRESS_DETAIL_PID=x5.ADDRESS_DETAIL_PID
                 left join      '____'_address_mesh_block_2016 x6
                 on             x1.ADDRESS_DETAIL_PID=x6.ADDRESS_DETAIL_PID
                 "
                 dt <- dbGetQuery(conn=conn, statement=gsub("'____'", gnaf_state[x1], dt_query))
                 setDT(dt)
                 dt[, DATE_CREATED:=as.Date(DATE_CREATED, "%Y-%m-%d")]
                 end_time <- proc.time()
                 print(Sys.time())
                 print(paste0(round((end_time-start_time)[3], 2), " seconds"))
                 return(dt)
               })
gnaf <- rbindlist(l=gnaf, use.names=TRUE, fill=TRUE)
rm(conn, gnaf_state)

## ABS MB 2016.


## ABS MB 2016.
mb16 <- mclapply(list.files(path=abs_location, pattern="*.mb_2016_.*._csv\\.zip$"),
                 function(x1) {
                   dt_name <- paste0("MB_2016_", unlist(lapply(strsplit(x=unlist(lapply(strsplit(x=x1, split="\\."), function(x) x[1])), split="_"), function(y) toupper(y[4]))), ".csv")
                   print(paste0("downloading region: ", dt_name))
                   dt <- read.delim(file=unzip(zipfile=paste0(abs_location, x1), files=dt_name), sep=",", fill=TRUE, header=TRUE, check.names=FALSE, stringsAsFactors=FALSE)
                   setDT(dt)
                   return(dt)
                 },
                 mc.cores=no_cores)
mb16 <- rbindlist(l=mb16, use.names=TRUE, fill=TRUE)