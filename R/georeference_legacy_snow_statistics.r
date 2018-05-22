#' download and geo-reference legacy (ASCII) NSIDC data
#' 
#' @param output_dir where to store the final dataset (default = tempdir())
#' @keywords snow, ice, temporal data, remote sensing
#' @export
#' @examples
#'
#' \dontrun{
#' # download the data
#' georeference_legacy_snow_statistics()
#' }

georeference_legacy_snow_statistics <- function(output_dir=tempdir()){
  
  # the projection we will use (polar stereographic (north))
  # using the CMC/IMS projection parameters
  # but could be anything for that matter
  proj = CRS("+proj=stere +lat_0=90 +lat_ts=70 +lon_0=10 +k=1 +x_0=0 +y_0=0 +a=6378273 +b=6356889.449 +units=m +no_defs")
  
  #download all data 1972 - 2000
  download.file(url="ftp://sidads.colorado.edu/pub/DATASETS/NOAA/G02168/Data/ASCII/dsf1972_2000.txt",
                 destfile="DSF.txt")
  
  download.file(url="ftp://sidads.colorado.edu/pub/DATASETS/NOAA/G02168/Data/ASCII/wfs1972_2000.txt",
                destfile="WFS.txt")
  
  download.file(url="ftp://sidads.colorado.edu/pub/DATASETS/NOAA/G02168/Data/ASCII/wls1972_2000.txt",
                destfile="WLS.txt")
  
  # read in all data
  DSF = read.table('DSF.txt')
  WFS = read.table('WFS.txt')
  WLS = read.table('WLS.txt')
  
  # make a copy for georeferencing
  ll_m = DSF[,1:4]
  
  # the general way to figure out the georeferencing was to first
  # map all data as spatial point data and figure out the extent
  # with the extent and a projection you can accurately georeference
  # the data in two simple lines of code.
  
  # the third and fourht columns of each of the text files are the lat long
  # coordinates, we will strip one set of these from the first file (DSF)
  
  # convert to SpatialPointsDataFrame
  coordinates(ll_m) = ~V4+V3
   
  # assign the lat lon projection
  proj4string(ll_m)=CRS("+init=epsg:4326") # set it to lat-long
  
  # this is stil a lat lon projection and we don't know the extent of our data
  # in polar stereographic, as such... transform from lat lon to polar stereographic
  stere_px = spTransform(ll_m,proj)
   
  # finally we can get the extent in polar stereographic out of our
  # SpatialPointDataFrame
  e = extent(stere_px)
  
  # create a little function to unwrap and georeference everything
  unwrap_reference <- function(x){
    
    # select and unwrap data
    data_vector = unlist(x[,5:33])
    
    # convert the vector into a 3D array, using aperm to sort byrow
    # this is similar to read.table(...,byrow=T)
    data_array = aperm(array(data_vector,c(89,89,29)),c(2,1,3))
      
    # convert the 3D array to a rasterBrick
    rb = brick(data_array)
      
    # assign the above projection and extent to the raster
    projection(rb) = proj
    extent(rb) = extent(e)
      
    # set layer names by year
    names(rb) = c(paste("year_",1972:2000,sep=""))
    
    # write data to file
    # use deparse(subsitute()) to extract the variable name as a string
    filename = paste(output_dir,"/legacy_snow_statistics_",i,".tif",sep="")
    writeRaster(rb,filename,overwrite=TRUE,options=c("COMPRESS=DEFLATE"))
  }
  
  # process all downloaded files
  for (i in c("DSF","WFS","WLS")){
    unwrap_reference(get(i))
  }
  
  # clean up downloaded files
  system("rm DSF.txt WFS.txt WLS.txt")
}