# NSIDC IMS / CMC snow cover and depth composites

National Snow and Ice Data Center (NSIDC) processing software. Composites raw NSIDC data files into georeferenced (yearly) stacked geotiffs for easy processing. Additional functions are provided to process this data to extract derived data products such as day of first snow melt and the dates spanning the longest snow free period.

## Installation

Install the package by using the devtools github functionality.

```R
if(!require(devtools)){install.package(devtools)}
devtools::install_github("khufkens/nsidcproc")
```

## Use

Load the library using

```R
library(NSIDCproc)
```


### CMC data

Download all CMC data zipped ascii files from the [NSIDC website](ftp://sidads.colorado.edu/pub/DATASETS/nsidc0447_CMC_snow_depth_v01/). These are the files called ps_cmc_sdepth_analysis_*_ascii.zip.

Unzip the files in your destination folder.

Next load the function into R and call it as such:

	georeference_CMC_snow_data("ps_cmc_sdepth_analysis_ascii_file",geotiff=T)

if geotiff = T then the data will be written to a geotiff, if geotiff=F the data will be returned to your current R workspace. The later option requires a substantial amount of memory so be careful when selecting this option.

### IMS data

The IMS data is provided as daily files which are cumbersome to download separately for all years. Instead I provide a wrapper script which automatically downloads and combines all daily snow cover data in a multi layer geotiff.

Just run the combine_IMS_data function

	combine_IMS_data(resolution=24,output_dir="~")

Where the 'resolution' is the resolution of the IMS data product (24 or 4 km) respectively and 'output_dir' the location where you want to store the processed data.


## Notes

Some of the code is very memory intensive (especially converting the CMC ascii file). I do not recommend running the code on a machine with less than 8GB of RAM. The code is also *nix specific as it requires some command line tools such as gunzip / sed etc.

### Dependencies

The code depends on the following R packages: raster, rgdal, lubridate, RCurl
