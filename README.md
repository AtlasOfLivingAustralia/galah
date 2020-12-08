
<!-- README.md is generated from README.Rmd. Please edit that file -->

# koala

[![Travis-CI Build
Status](https://travis-ci.com/AtlasOfLivingAustralia/koala.svg?branch=master)](https://travis-ci.com/AtlasOfLivingAustralia/koala)
[![AppVeyor Build
status](https://ci.appveyor.com/api/projects/status/g9pudc4l7053w4vn/branch/master?svg=true)](https://ci.appveyor.com/project/PeggyNewman/ala4r/branch/master)
[![codecov](https://codecov.io/gh/AtlasOfLivingAustralia/koala/branch/master/graph/badge.svg)](https://codecov.io/gh/AtlasOfLivingAustralia/koala)

<code>koala</code> enables the R community to directly access data hosted by the
Atlas of Living Australia (ALA).

The ALA aggregates Australian biodiversity data from a range of sources,
and makes the data freely available for scientists, policy makers,
industry and the general public.

If you have any questions or suggestions, please [contact
us](mailto:support@ala.org.au).

## Citing koala

To generate a citation for koala run:

``` r
citation(package = "koala")
```

## Installing

To install the development version from GitHub:

``` r
install.packages("remotes")
remotes::install_github("AtlasOfLivingAustralia/koala")
```

On Linux you will first need to ensure that `libcurl` and `v8` (version
\<= 3.15) are installed on your system — e.g. on Ubuntu/Debian, open a
terminal and do:

``` sh
sudo apt-get install libcurl4-openssl-dev libv8-3.14-dev
```

## Usage

See the online documentation at
<https://atlasoflivingaustralia.github.io/koala/> including the [package
vignette](https://atlasoflivingaustralia.github.io/koala/articles/koala.html).
