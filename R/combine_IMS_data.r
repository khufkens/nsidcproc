# convert and combine all IMS snow cover data
# in yearly stacks
combine_IMS_data <- function(resolution=24,output_dir="~"){
  
  # library requirements
  require(raster)
  require(RCurl)
  require(lubridate)  # to detect leap years
  
  # set location of your data
  setwd(output_dir) # path to the location where you want to save the data
  
  if (resolution == 24){
    
    # the projection as used (polar stereographic (north))
    proj = CRS("+proj=stere +lat_0=90 +lat_ts=60 +lon_0=10 +k=1 +x_0=0 +y_0=0 +a=6371200 +b=6371200 +units=m +no_defs")
    
    # set extent based upon documentation info x / y resolution top left coordinate
    e = extent(-12126597,12126840,-12126597,12126840)
    
    # create empty raster brick layer
    r = raster(ncols=1024,nrows=1024)
    
    # set projection and extent
    projection(r) = proj
    extent(r) = e
    r[] = NA # fill with NA values
    
    start_year = 1997
  
  } else{
    
    # the projection as used (polar stereographic (north))
    proj = CRS("+proj=stere +lat_0=90 +lat_ts=60 +lon_0=-80 +k=1 +x_0=0 +y_0=0 +ellps=WGS84 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs")
    
    # set extent based upon documentation info x / y resolution top left coordinate
    e = extent(-12288000,12288000,-12288000,12288000)
    
    # create empty raster brick layer
    r = raster(ncols=6144,nrows=6144)
    
    # set projection and extent
    projection(r) = proj
    extent(r) = e
    r[] = NA # fill with NA values
    
    start_year = 2004
  }
  
  # process all years up until today
  for (i in start_year:2013){
    
    # check if it is a leap year, set number of layers accordingly
    if (leap_year(i) == TRUE){
      nr_layers=366
    }else{
      nr_layers=365
    }
  
    if (resolution == 24 ){
      files = getURL(paste("ftp://sidads.colorado.edu/pub/DATASETS/NOAA/G02156/24km/",i,"/",sep=""),ftp.use.epsv=TRUE,dirlistonly = TRUE)
      files = unlist(strsplit(files,split="\n"))
    } else {
      files = getURL(paste("ftp://sidads.colorado.edu/pub/DATASETS/NOAA/G02156/4km/",i,"/",sep=""),ftp.use.epsv=TRUE,dirlistonly = TRUE)
      files = unlist(strsplit(files,split="\n"))
    }
    
    # search for faulty classified images! cut the crap out of the file listing
    loc = grep(pattern=paste("ims",i,sep=""),files)
    files = files[loc]
    
    # get the filename withouth an extension
    no_extension = unlist(lapply(strsplit(files,split='\\.'),"[[",1))
    
    # extract the doy value form the filename
    doy = as.numeric(substr(no_extension,8,10))
    
    # loop over all layers, and write (empty) geotiffs if necessary
    for (j in 1:nr_layers){
  
      # file location
      file_loc = which(doy == j)
      
      # if there is nothing add NA
      # layer and skip to next
      if (length(file_loc)==0){
        
        # print feedback
        cat(paste("No file for doy ",j, " of year ", i,"\n"))
        
        if (resolution == 24){
          # write empty file
          writeRaster(r,paste("ims",i,sprintf("%03d", j),"_24km.tif",sep=""),overwrite=T,options=("COMPRESS=DEFLATE"))
        } else {
          # write empty file
          writeRaster(r,paste("ims",i,sprintf("%03d", j),"_4km.tif",sep=""),overwrite=T,options=("COMPRESS=DEFLATE"))
        }
        
        
      } else {
        
        # print feedback
        cat(paste("Adding data for doy ",j, " of year ", i,"\n"))
        
        if ( !file.exists(paste(no_extension[file_loc],".asc",sep="")) ){
          if (resolution == 24){
            #download the file
            download.file(url=paste("ftp://sidads.colorado.edu/pub/DATASETS/NOAA/G02156/24km/",i,"/",files[file_loc],sep=""),
                          destfile=files[file_loc],
                          method="curl",
                          cacheOK=TRUE,
                          quiet=TRUE)
          } else {
            #download the file
            download.file(url=paste("ftp://sidads.colorado.edu/pub/DATASETS/NOAA/G02156/4km/",i,"/",files[file_loc],sep=""),
                          destfile=files[file_loc],
                          method="curl",
                          cacheOK=TRUE,
                          quiet=TRUE)
          }
          
          #unzip the file
          system(paste("gunzip -f ", files[file_loc],sep=""))
        }
        
        #convert to a raster file
        georeference_IMS_snow_data(paste(no_extension[file_loc],".asc",sep=""),geotiff=T)
        
      }
    }
    
    # list all converted geotiffs
    geotiffs = list.files(".",pattern=paste("^ims",i,".*\\.tif$",sep=""))
    
    # add all files to a stack
    rb = stack(geotiffs)
    
    # set layer names by day of year (DOY)
    names(rb) = c(paste("DOY_",1:nr_layers,sep=""))
    
    # write everything to file after compositing all the layers
    if (resolution == 24 ){
      filename = paste("IMS_24k_daily_snow_cover_",i,".tif",sep="")
    } else {
      filename = paste("IMS_4k_daily_snow_cover_",i,".tif",sep="")
    }
    writeRaster(rb,filename,overwrite=TRUE,options=c("COMPRESS=DEFLATE"))
    
    # clean system dir
    system("rm *.asc")
    system("rm *4km.tif")
  }
}
