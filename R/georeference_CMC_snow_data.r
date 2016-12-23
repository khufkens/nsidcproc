# cmc conversion function
georeference_CMC_snow_data <- function(filename="",geotiff=F){
  
  # load required packaages
  require(raster)     # GIS functionality
  require(lubridate)  # to detect leap years
  
  # the projection as used (polar stereographic (north))
  # latitude at natural origin is 60 degrees
  # I use the same spherical projection as the IMS product
  proj = CRS("+proj=stere +lat_0=90 +lat_ts=60 +lon_0=10 +k=1 +x_0=0 +y_0=0 +a=6371200.0 +b=6371200.0 +units=m +no_defs")
  
  # with a x / y resolution of 23815.5 and the pole at 353,353
  e = c(-8405812,8405812,-8405812,8405812)
  
  # some feedback
  cat("Converting file:\n")
  cat(paste(filename,"\n"))
  
  # grab year from filename
  no_path = basename(filename)
  no_extension = sub("^([^.]*).*", "\\1", no_path) 
  year = as.numeric(unlist(strsplit(no_extension,split="_"))[3])
  
  # read the data using scan and force it to use a double format
  # this command returns a vector
  # adjust the length according to leap years
  if ( year == 1998){
    nr_layers=153
  }else{
    if (leap_year(year) == TRUE){
      nr_layers=366
    }else{
      nr_layers=365
    }
  }

  # read in raw text CMC data
  data_vector = scan(filename,skip=0,nlines=(706*nr_layers)+nr_layers,what=character())
  
  # remove the part that messes with stuff (yearly delineators)
  data_vector <- data_vector[-grep(toString(year),data_vector)]
  
  # convert to numeric
  data_vector = as.numeric(data_vector)
  
  # convert the vector into a 3D array, using aperm to sort byrow
  # this is similar to read.table(...,byrow=T) for tables
  data_array = aperm(array(data_vector,c(706,706,nr_layers)),c(2,1,3))
  
  # remove first data vector and free up some memory
  rm(data_vector);gc()
  
  # convert the 3D array to a rasterBrick
  rb = brick(data_array)
  
  # remove data array and free up some memory
  rm(data_array);gc()
  
  # assign the above projection and extent to the raster
  projection(rb) = proj
  extent(rb) = extent(e)
  
  if (year == 1998){
    names(rb) = c(paste("DOY_",213:365,sep=""))
  }else{
    # set layer names by day of year (DOY)
    if (leap_year(year) == TRUE){
      names(rb) = c(paste("DOY_",1:366,sep=""))
    }else{
      names(rb) = c(paste("DOY_",1:365,sep=""))
    }
  }
  
  # return data as geotiff or raster brick
  # keep in mind that these are rather large files
  # when returning data to the workspace
  if (geotiff==F){
    return(rb)
  }else{
    # write data to file
    filename = paste("cmc_analysis_",year,".tif",sep="")
    writeRaster(rb,filename,overwrite=TRUE,options=c("COMPRESS=DEFLATE"))
  }
  
  # free up some more memory / don't leave temporary raster files behind
  removeTmpFiles()
}
