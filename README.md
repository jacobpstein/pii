
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
car_df_split <- split_PII_data(mtcars_with_pii, exclude_columns = c("car_name", "mpg", "cyl", "drat", "wt", "qsec", "vs", "am", "gear", "carb"))

# this creates a list containing two data frames: one with PII, one without

car_df_to_share <- car_df_split$non_pii_data

car_PII <- car_df_split$pii_data
```

Note that the `exclude_columns =` argument allows the user to keep
certain columns that were flagged as PII in the data.

``` r

# take a look at our non-PII data
head(car_df_to_share)
#>            car_name  mpg cyl disp  hp drat    wt  qsec vs am gear carb
#> 1         Mazda RX4 21.0   6  160 110 3.90 2.620 16.46  0  1    4    4
#> 2     Mazda RX4 Wag 21.0   6  160 110 3.90 2.875 17.02  0  1    4    4
#> 3        Datsun 710 22.8   4  108  93 3.85 2.320 18.61  1  1    4    1
#> 4    Hornet 4 Drive 21.4   6  258 110 3.08 3.215 19.44  1  0    3    1
#> 5 Hornet Sportabout 18.7   8  360 175 3.15 3.440 17.02  0  0    3    2
#> 6           Valiant 18.1   6  225 105 2.76 3.460 20.22  1  0    3    1
#>                               join_key
#> 1 9cae626f-54b9-4c10-a7db-74a974381e61
#> 2 6b6897d3-5c37-4996-9e6d-32d099bf8437
#> 3 f953236b-ca69-41fb-b27c-37609f01183b
#> 4 17a32c55-ecc8-4c20-acd4-ef2cc143328f
#> 5 f87060c0-4f59-49df-a48d-3c55a694d88b
#> 6 8eda4b67-6d43-462a-88b6-b0185c144cfa
```

Seems ok. Meanwhile, you can put the PII in a secure, encrypted
location. But let’s take a peak…

``` r

# take a look at our PII data
head(car_PII)
#>   phone_number  longitude  latitude                             join_key
#> 1 555-292-5528 -165.64468 -71.17268 9cae626f-54b9-4c10-a7db-74a974381e61
#> 2 555-699-1808  -63.92327  23.78131 6b6897d3-5c37-4996-9e6d-32d099bf8437
#> 3 555-732-3162 -103.97027  35.18776 f953236b-ca69-41fb-b27c-37609f01183b
#> 4 555-513-8575 -119.58928 -77.85741 17a32c55-ecc8-4c20-acd4-ef2cc143328f
#> 5 555-597-6296  177.27554 -75.31981 f87060c0-4f59-49df-a48d-3c55a694d88b
#> 6 555-973-6320 -178.92443  36.31883 8eda4b67-6d43-462a-88b6-b0185c144cfa
```
