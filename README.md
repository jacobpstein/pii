
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

Let’s say you’re working with the `mtcars` data set. But this isn’t just
any version of `mtcars`, this is more like a data about characters from
the hit feature film [*Cars*](https://cars.disney.com)! You happen to
have phone numbers and the location of each car’s house. A colleague at
a partner org asks for the data, but you aren’t sure if it has PII, so
you run the `check_PII` function.

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
library(tibble)
library(pii)
#> Loading required package: stringr

# Set a seed for reproducibility
set.seed(101624)

# Number of rows in the cars dataset
n <- nrow(mtcars)

# Generate car phone numbers as strings
phone_numbers <- sprintf("555-%03d-%04d", sample(100:999, n, replace = TRUE), sample(1000:9999, n, replace = TRUE))

# Generate latitudes for where the cars live (range roughly between -90 and 90)
latitudes <- runif(n, min = -90, max = 90)

# Generate longitudes for where the cars live (range roughly between -180 and 180)
longitudes <- runif(n, min = -180, max = 180)

# Merge new columns into the mtcars dataset using mutate
mtcars_with_pii <- mtcars %>%
  mutate(phone_number = phone_numbers,
         latitude = latitudes,
         longitude = longitudes) |> 
  # we also have row names with actual car names!
  rownames_to_column(var = "car_name")

# run our function over the data
mtcars_pii <- check_PII(mtcars_with_pii)

# take a look at the output
print(mtcars_pii)
#>                  Column                                                Reason
#> 1              car_name                              Column name suggests PII
#> 2          phone_number                              Column name suggests PII
#> 3       mpg & longitude Potential latitude/longitude or similar pair detected
#> 4       cyl & longitude Potential latitude/longitude or similar pair detected
#> 5      drat & longitude Potential latitude/longitude or similar pair detected
#> 6        wt & longitude Potential latitude/longitude or similar pair detected
#> 7      qsec & longitude Potential latitude/longitude or similar pair detected
#> 8        vs & longitude Potential latitude/longitude or similar pair detected
#> 9        am & longitude Potential latitude/longitude or similar pair detected
#> 10     gear & longitude Potential latitude/longitude or similar pair detected
#> 11     carb & longitude Potential latitude/longitude or similar pair detected
#> 12 latitude & longitude Potential latitude/longitude or similar pair detected
```

The `check_PII` function flags combinations of columns that together
could identify individuals. It also flags columns that contain names
that suggest a column contains PII, like, `phone_number.`
