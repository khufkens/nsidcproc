georeference_IMS_snow_data <- function(filename="",geotiff=T){
  
  # you need the raster library to georeference
  # the image matrix
  require(raster)
  require(parallel) # to speed up unfolding of the data
                    # especially when dealing with the 4km data
  
  # set the number of cores (max cores - 1)
  cores = parallel:::detectCores() - 1
  
  # Scan for the line on which "Dim Units"
  # occurs for the second time, I'll scan for the
  # first 200 lines if necessary, assuming no 
  # header will be longer than this even given
  # some changes in the header info through time
  # I also assume that the basic naming of the 
  # header info remains the same (file size etc)
  
  # set string occurence and resolution to 0
  str_occurence = 0
  resolution = 0
  
  # attache and open file
  con <- file(filename)
  open(con)
  for(i in 1:200){
    
    # read a line of the ascii file
    l = readLines(con, n=1)
    
    # find the occurence of "Dim Units"
    occurence = grep("Dim Units",l,value=F)
    
    # scan for 
    if (resolution < 4){
      if ( length(grep("6144",l,value=F))!=0 ){
        resolution = 4
      }
    }
    # only process valid results (skip empty strings)
    if(length(occurence)!=0){
      str_occurence = str_occurence + occurence 
    }
    
    # when two occurences are found return the
    # line of the second one
    if (str_occurence == 2){
      skip_lines <<- i # set the global variable skip_lines to i
      break
    }
  }
  # close file
  close(con)
  
  if ( resolution == 24 ){
    # the projection as used (polar stereographic (north))
    proj = CRS("+proj=stere +lat_0=90 +lat_ts=60 +lon_0=10 +k=1 +x_0=0 +y_0=0 +a=6371200 +b=6371200 +units=m +no_defs")
    
    # set extent based upon documentation info x / y resolution top left coordinate
    e = extent(-12126597,12126840,-12126597,12126840)
    
    # set output matirx size
    matrix_size = 1024
    
  } else {
    # the projection as used (polar stereographic (north))
    proj = CRS("+proj=stere +lat_0=90 +lat_ts=60 +lon_0=-80 +k=1 +x_0=0 +y_0=0 +ellps=WGS84 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs")
    
    # set extent based upon documentation info x / y resolution top left coordinate
    e = extent(-12288000,12288000,-12288000,12288000)
    
    # set output matrix size
    matrix_size = 6144
  }
  
  # prescan the first line to figure out if this is the short or long format
  format = scan(filename,skip=skip_lines,nlines=1,what=character()) # read first line
  format = length(format) # count the number of elements in the first line
  
  # read in the data after the header data assumes
  # the reading is not affected by the format but the post processing is
  data_list = scan(filename,skip=skip_lines,nlines=matrix_size,what=character())
  
  # unpack, packed format
  if ( format < 15 ){ 
    # feedback
    cat('-- packed format \n')
    
    # split every element (a long character string) in the list into it's
    # individual characters and return to the original list object
    cat('--- unpacking \n')
    data_list = mclapply(data_list,function(x)substring(x,seq(1,nchar(x),1),seq(1,nchar(x),1)),mc.cores=cores)
    data_list = as.numeric(unlist(data_list))
    
    # only report snow and sea ice values, set land and see values
    # to 0
    cat('--- removing land / water pixels \n')
    data_list[data_list == 1] = 0
    data_list[data_list == 2] = 0
    
  } else {
    
    # make one big vector
    data_list = as.numeric(unlist(data_list))
    
    # substitue long values in the unpacked format
    data_list[data_list == 164] = 3
    data_list[data_list == 165] = 4
  }
  
  # unlist the list and wrap it into a matrix
  data_matrix = matrix(data_list,matrix_size,matrix_size)
  
  # convert to a raster object
  r = raster(data_matrix)
  
  # assign the raster a proper extent and projection
  extent(r) = e
  projection(r) = proj
  
  # return the raster
  if (geotiff == F){
    return(r)
  }else{
    cat('--- writing to file \n')
    no_extension = unlist(strsplit(basename(filename),split='\\.'))[1]
    writeRaster(r,paste(no_extension,".tif",sep=""),overwrite=T,options=c("COMPRESS=DEFLATE"))
  }
}