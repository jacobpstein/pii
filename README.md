
<!-- README.md is generated from README.Rmd. Please edit that file -->

# pii: A package for dealing with personally identifiable information

<!-- badges: start -->
<!-- badges: end -->

The goal of pii is to flag columns that potentially contain personally
identifiable information. This package was inspired by concerns that
survey data might be shared without users realizing the files contain
PII. It is based on a set of [standard
guidlines](https://www.usaid.gov/sites/default/files/2022-05/508saa.pdf)
from the United States Agency for International Development, though
people can debate what is and isn’t PII.

The main function of the `pii` package, `check_PII` looks for the
following:

- Names
- Email addresses
- Phone numbers
- Locations (e.g., city or village name)
- Geo-coordinates
- Disability status
- Combinations of the above that might identify someone

The function dynamically determines potential PII issues across by
comparing a column’s uniqueness to the median uniqueness of the dataset,
adjusting it accordingly (e.g., by 20%). Numeric and date columns are
skipped. Mixed classes within a column (e.g., text and numbers) are
flagged as this type of information is more likely to contain PII.

This function provides a first step in flagging *potential* PII within
your data. Nothing beats gaining familiarity with the data, strong
documentation, and careful data management.

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
#> Loading required package: uuid

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

## Seperate your PII

Once you have run the `check_PII` function, you might want to remove
those columns from your data frame so that the data can easily be
shared. The `split_PII_data` function removes the columns flagged by
`check_PII,` puts them into a separate data frame, and creates a unique
join key should you need to merge them back in at some point.

``` r

# use our data from earlier
car_df_split <- split_PII_data(mtcars_with_pii, exclude = "car_name")

# this creates a list containing two data frames: one with PII, one without

car_df_to_share <- car_df_split$non_pii_data

car_PII <- car_df_split$pii_data
```

Note that the `exclude =` argument allows the user to keep certain
columns that were flagged as PII in the data.

``` r

# take a look at our non-PII data
head(car_df_to_share)
#>            car_name disp  hp                             join_key
#> 1         Mazda RX4  160 110 a9420f45-12d0-4bc4-bb7b-4eacbba26fc2
#> 2     Mazda RX4 Wag  160 110 317cbb8f-58bb-4b19-9583-56b00b90990c
#> 3        Datsun 710  108  93 b3379990-9280-40df-b70b-8e06f6eab635
#> 4    Hornet 4 Drive  258 110 d7f7daa2-fd6c-48db-9df7-17b83cf8126c
#> 5 Hornet Sportabout  360 175 3cf2f525-b962-44a4-9642-4fa54186a385
#> 6           Valiant  225 105 0676124d-dbd0-4d95-b084-f2944884cb84
```

Seems ok. Meanwhile, you can put the PII in a secure, encrypted
location. But let’s take a peak…

``` r

# take a look at our PII data
head(car_PII)
#>   phone_number  mpg  longitude cyl drat    wt  qsec vs am gear carb  latitude
#> 1 555-292-5528 21.0 -165.64468   6 3.90 2.620 16.46  0  1    4    4 -71.17268
#> 2 555-699-1808 21.0  -63.92327   6 3.90 2.875 17.02  0  1    4    4  23.78131
#> 3 555-732-3162 22.8 -103.97027   4 3.85 2.320 18.61  1  1    4    1  35.18776
#> 4 555-513-8575 21.4 -119.58928   6 3.08 3.215 19.44  1  0    3    1 -77.85741
#> 5 555-597-6296 18.7  177.27554   8 3.15 3.440 17.02  0  0    3    2 -75.31981
#> 6 555-973-6320 18.1 -178.92443   6 2.76 3.460 20.22  1  0    3    1  36.31883
#>                               join_key
#> 1 a9420f45-12d0-4bc4-bb7b-4eacbba26fc2
#> 2 317cbb8f-58bb-4b19-9583-56b00b90990c
#> 3 b3379990-9280-40df-b70b-8e06f6eab635
#> 4 d7f7daa2-fd6c-48db-9df7-17b83cf8126c
#> 5 3cf2f525-b962-44a4-9642-4fa54186a385
#> 6 0676124d-dbd0-4d95-b084-f2944884cb84
```
