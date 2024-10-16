

check_PII <- function(df) {

  # Keywords to check for column names that might contain PII
  pii_keywords <- c("name", "id", "identification", "phone", "email", "geo", "address", "city", "town", "village", "disability", "ssn", "social security", "zip")

  # Regular expressions for phone numbers, email, and geo coordinates
  phone_regex <- "\\(?\\d{3}\\)?[ -]?\\d{3}[ -]?\\d{4}"
  email_regex <- "\\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}\\b"

  # Initialize a list to store flagged columns
  flagged_columns <- list()

  # Get dataset-specific heuristics
  n_rows <- nrow(df)

  # Get median string length for text columns and overall uniqueness proportion
  string_lengths <- sapply(df, function(col) if (is.character(col)) nchar(as.character(col)) else NA)
  median_string_length <- median(unlist(string_lengths), na.rm = TRUE)

  # Calculate the uniqueness proportion across all columns
  uniqueness_proportions <- sapply(df, function(col) length(unique(col)) / length(col))
  median_uniqueness <- median(uniqueness_proportions)

  # Define ranges for latitudes and longitudes
  lat_range <- c(-90, 90)
  long_range <- c(-180, 180)

  # Track potential latitude and longitude columns
  lat_cols <- c()
  long_cols <- c()

  # Iterate over each column
  for (colname in names(df)) {

    # Convert column to character to simplify checks
    column_data <- as.character(df[[colname]])

    # 1. Skip numeric or purely date columns unless they're potentially lat/long
    if (is.numeric(df[[colname]]) || inherits(df[[colname]], "Date")) {
      # Check if numeric column could be latitude or longitude
      if (all(df[[colname]] >= lat_range[1] & df[[colname]] <= lat_range[2])) {
        lat_cols <- c(lat_cols, colname)
      } else if (all(df[[colname]] >= long_range[1] & df[[colname]] <= long_range[2])) {
        long_cols <- c(long_cols, colname)
      }
      next
    }

    # 2. Check if the column name contains any PII-related keywords
    if (any(str_detect(tolower(colname), pii_keywords))) {
      flagged_columns[[colname]] <- "Column name suggests PII"
      next
    }

    # 3. Check for phone numbers using regex
    if (any(str_detect(column_data, phone_regex))) {
      flagged_columns[[colname]] <- "Phone number detected"
      next
    }

    # 4. Check for email addresses using regex
    if (any(str_detect(column_data, email_regex))) {
      flagged_columns[[colname]] <- "Email address detected"
      next
    }

    # 5. Adjust string length thresholds dynamically
    string_length_min <- max(2, median_string_length * 0.5)  # Minimum name length: dynamic
    string_length_max <- median_string_length * 1.5  # Maximum name length: dynamic
    length_check <- all(nchar(column_data) >= string_length_min & nchar(column_data) <= string_length_max)

    # 6. Adjust uniqueness proportion dynamically
    col_uniqueness <- length(unique(column_data)) / length(column_data)
    uniqueness_threshold <- median_uniqueness * 1.2  # Increase median threshold by 20%

    if (col_uniqueness > uniqueness_threshold && length_check) {
      flagged_columns[[colname]] <- paste("Potential name or unique identifier detected (string length", string_length_min, "-", string_length_max, "and uniqueness >", uniqueness_threshold, ")")
      next
    }

    # 7. Mixed data types check (potential identifier)
    if (any(is.numeric(df[[colname]]) & !all(is.na(column_data)))) {
      flagged_columns[[colname]] <- "Mixed data types detected (potential identifier)"
      next
    }

    # 8. Check for city, town, or village names with high uniqueness
    if (col_uniqueness > 0.5 && any(str_detect(tolower(colname), c("city", "town", "village", "region", "district")))) {
      flagged_columns[[colname]] <- "Potential city/town/village name detected"
      next
    }

    # 9. Check for disability status by looking for relevant keywords in the data
    if (any(str_detect(tolower(column_data), "disability|disabled|handicap"))) {
      flagged_columns[[colname]] <- "Disability status detected"
      next
    }
  }

  # 10. Flagging paired latitude and longitude columns
  if (length(lat_cols) > 0 && length(long_cols) > 0) {
    lat_long_combinations <- expand.grid(lat_cols, long_cols)
    for (i in 1:nrow(lat_long_combinations)) {
      flagged_columns[[paste(lat_long_combinations[i, 1], lat_long_combinations[i, 2], sep = " & ")]] <- "Potential latitude/longitude pair detected"
    }
  }

  # Return the list of flagged columns
  return(flagged_columns)
}

