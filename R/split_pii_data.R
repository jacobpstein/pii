#' Split Data Into PII and Non-PII Columns
#'
#' @param df a data frame object
#' @param exclude_columns columns to exclude from the data frame splitdescription
#'
#' @return Returns two data frames into the global environment: one containing the PII columns and one without the PII columns.
#'     A unique merge key is created to join them. The function then prints the columns that were flagged and split to the console.
#' @import dplyr
#' @import stringr
#' @import uuid
#' @import utils

#' @examples
#' # create a data frame containing various personally identifiable information
#' pii_df <- data.frame(
#'  lat = c(40.7128, 34.0522, 41.8781),
#'  long = c(-74.0060, -118.2437, -87.6298),
#'  first_name = c("John", "Michael", "Linda"),
#'  phone = c("123-456-7890", "234-567-8901", "345-678-9012"),
#'  age = sample(30:60, 3, replace = TRUE),
#'  email = c("test@example.com", "contact@domain.com", "user@website.org"),
#'  disabled = c("No", "Yes", "No"),
#'  stringsAsFactors = FALSE
#' )
#'
#' split_PII_data(pii_df, exclude_columns = c("phone"))
#'

#' @export
split_PII_data <- function(df, exclude_columns = NULL) {

  # create join key object
  join_key <- NULL

  # create a function within our function to split paired PII columns, like lat & long
  extract_unique_columns <- function(flagged_columns) {
    # Split on "&" to get individual column names, then flatten and trim whitespace
    unique_columns <- unlist(str_split(flagged_columns, " & "))
    unique_columns <- unique(str_trim(unique_columns))
    return(unique_columns)
  }

  # Run the PII check quietly
  flagged <- check_PII(df)

  # Extract all unique PII column names (handle pairs like "name & phone")
  pii_columns <- extract_unique_columns(flagged$Column)

  # If exclude_columns is provided, remove those columns from the flagged list
  if (!is.null(exclude_columns)) {
    exclude_columns <- unlist(exclude_columns)  # Ensure it's treated as a vector
    # Remove any columns from the PII list that are in exclude_columns
    pii_columns <- setdiff(pii_columns, exclude_columns)
  }


  # Create a unique join key for each row in the original data frame
  df$join_key <- UUIDgenerate(n = nrow(df))

  # Split the data into PII and non-PII data frames
  pii_data <- df %>% select(all_of(pii_columns), join_key)
  non_pii_data <- df %>% select(-all_of(pii_columns))


  # return data frames
  return(list(pii_data = pii_data, non_pii_data = non_pii_data))
}
