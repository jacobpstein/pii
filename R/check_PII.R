#' Search Data Frames for Personally Identifiable Information
#'
#' @param df a data frame object
#'
#' @return Returns a data frame of columns that potentially contain PII
#' @import dplyr
#' @import stringr
#' @importFrom stats median
#' @importFrom stats na.omit
#' @export
#'
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
#' check_PII(pii_df)

check_PII <- function(df) {
  # Helper function to detect email addresses
  detect_email <- function(x) {
    x <- na.omit(x)  # Remove NA values for pattern matching
    any(str_detect(x, "\\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}\\b"))
  }

  # Helper function to detect phone numbers
  detect_phone <- function(x) {
    x <- na.omit(x)
    any(str_detect(x, "\\b\\+?[0-9\\s-]{7,15}\\b"))
  }

  # Helper function to detect geographic coordinates
  detect_geo <- function(x) {
    x <- na.omit(x)
    all(str_detect(x, "^[-+]?\\d{1,3}\\.\\d+$")) && length(unique(x)) > 5
  }

  # Helper function to detect name-like patterns
  detect_names <- function(x) {
    x <- na.omit(x)
    any(str_detect(x, "\\b[A-Z][a-z]+\\b"))
  }

  # Helper function to detect high uniqueness
  detect_unique <- function(x) {
    non_na_x <- x[!is.na(x)]
    length(unique(non_na_x)) / length(non_na_x) > 0.9
  }

  # Iterate through each column to detect PII
  pii_results <- lapply(names(df), function(col_name) {
    col <- df[[col_name]]

    # Check for specific patterns
    email_flag <- detect_email(col)
    phone_flag <- detect_phone(col)
    geo_flag <- detect_geo(col)
    name_flag <- detect_names(col)

    # Heuristic for high uniqueness
    unique_flag <- detect_unique(col)

    # Flag columns with suspicious names
    suspicious_name_flag <- any(str_detect(tolower(col_name),
                                           "\\b(name|phone|email|lat|long|id|identification|address|disability)\\b"))

    # Combine flags and return results
    any_flag <- email_flag || phone_flag || geo_flag || name_flag || unique_flag || suspicious_name_flag
    if (any_flag) {
      type <- paste(
        c(
          if (email_flag) "Email",
          if (phone_flag) "Phone",
          if (geo_flag) "Geo",
          if (name_flag) "Name",
          if (unique_flag) "High Uniqueness",
          if (suspicious_name_flag) "Suspicious Column Name"
        ),
        collapse = ", "
      )
      return(data.frame(Column = col_name, Issue = type, stringsAsFactors = FALSE))
    } else {
      return(NULL)
    }
  })

  # Combine results into a single data frame
  pii_results <- do.call(rbind, pii_results)
  if (is.null(pii_results)) {
    pii_results <- data.frame(Column = character(), Issue = character(), stringsAsFactors = FALSE)
  }

  return(pii_results)
}

