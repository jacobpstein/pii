
<!-- README.md is generated from README.Rmd. Please edit that file -->

# pii

<!-- badges: start -->
<!-- badges: end -->

The goal of pii is to flag columns that potentially contain personally
identifiable information. This package was inspired by concerns that
survey data might be shared without users realizing the files contain
PII. It is based on a set of [standard
guidlines](https://www.usaid.gov/sites/default/files/2022-05/508saa.pdf)
from the United States Agency for International Development, though
people can debate what is and isn’t PII.

## Installation

You can install the development version of pii from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("jacobpstein/pii")
```

## Example

Let’s say you’re working with the `cars` data set. But this isn’t just
any version of `cars`, this is more like a data about characters from
the hit feature film [*Cars*](https://cars.disney.com)! You happen to
have phone numbers and the location of each cars house. A colleague at a
partner org asks for the data, but you aren’t sure if it has PII, so you
run the `check_PII` function.

``` r

library(dplyr)
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union
library(pii)
#> Loading required package: stringr

# Set a seed for reproducibility
set.seed(101624)

# Number of rows in the cars dataset
n <- nrow(cars)

# Generate car phone numbers as strings
phone_numbers <- sprintf("555-%03d-%04d", sample(100:999, n, replace = TRUE), sample(1000:9999, n, replace = TRUE))

# Generate latitudes for where the cars live (range roughly between -90 and 90)
latitudes <- runif(n, min = -90, max = 90)

# Generate longitudes for where the cars live (range roughly between -180 and 180)
longitudes <- runif(n, min = -180, max = 180)

# Merge new columns into the cars dataset using mutate
cars_with_pii <- cars %>%
  mutate(PhoneNumber = phone_numbers,
         Latitude = latitudes,
         Longitude = longitudes)

# run our function over the data
cars_pii <- check_PII(cars_with_pii)

# take a look at the list
print(cars_pii)
#> $PhoneNumber
#> [1] "Column name suggests PII"
#> 
#> $`speed & dist`
#> [1] "Potential latitude/longitude pair detected"
#> 
#> $`Latitude & dist`
#> [1] "Potential latitude/longitude pair detected"
#> 
#> $`speed & Longitude`
#> [1] "Potential latitude/longitude pair detected"
#> 
#> $`Latitude & Longitude`
#> [1] "Potential latitude/longitude pair detected"
```

The `check_PII` function flags combinations of columns that together
could identify individuals. It also flags columns that contain names
that suggest a column contains PII, like, `PhoneNumber.`
