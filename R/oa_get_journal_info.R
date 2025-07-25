#' Get journal metadata
#'
#' @description
#' This function requests the OpenAlex database by using the package
#' `openalexR` and the function `oa_fetch()`. From a single source (journal
#' name), it retrieves metadata (ISSN, source name in OA, source identifier).
#'
#' @param journal a `character` of length 1. The journal name for which metadata
#'   must be retrieved.
#'
#' @return A `data.frame` with the following columns:
#'   - `journal`: the journal name (input)
#'   - `oa_source_name`: the journal name that best matches in OA
#'   - `oa_source_id`: the journal identifier in OA
#'   - `oa_works_count`: the total number of works in OA (for this journal)
#'   - `oa_source_issn_l`: the ISSN of the journal
#'   - `oa_source_issn`: all ISSN of the journal
#'
#' @note
#' Before using this function, ensure that you ran:
#' `options(openalexR.mailto = 'your_email')`.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' ## Be polite ----
#' options(openalexR.mailto = 'user.email@mail.com')
#'
#' ## Get journal metadata ----
#' oa_get_journal_info(journal = "Applied Vegetation Science")
#' }

oa_get_journal_info <- function(journal) {
  ## Check argument ----

  if (missing(journal)) {
    stop("Argument 'journal' is required")
  }

  if (!is.character(journal)) {
    stop("Argument 'journal' must be character")
  }

  if (length(journal) != 1) {
    stop("Argument 'journal' must be character of length 1")
  }

  ## Check if user is polite ----

  if (is.null(options()$"openalexR.mailto")) {
    stop(
      "Be polite with OpenAlex API and run: ",
      "`options(openalexR.mailto = 'your_email')`"
    )
  }

  ## Prepare output ----

  oa_data <- data.frame(
    "journal" = journal,
    "match" = NA,
    "oa_source_name" = NA,
    "oa_source_id" = NA,
    "oa_works_count" = NA,
    "oa_source_issn_l" = NA,
    "oa_source_issn" = NA,
    "oa_publisher_name" = NA,
    "oa_country" = NA,
    "oa_topic" = NA,
    "oa_subfield" = NA,
    "oa_field" = NA
  )

  ## Retrieve source metadata from name ----

  response <- openalexR::oa_fetch(entity = "source", search = journal) |>
    as.data.frame()

  if (nrow(response) > 0) {
    display_names <- response$"display_name"
    display_names <- tolower(display_names)
    display_names <- gsub("[[:punct:]]", " ", display_names)
    display_names <- gsub("\\s+", " ", display_names)
    display_names <- trimws(display_names)

    journal_name <- journal
    journal_name <- tolower(journal_name)
    journal_name <- gsub("[[:punct:]]", " ", journal_name)
    journal_name <- gsub("\\s+", " ", journal_name)
    journal_name <- trimws(journal_name)

    ## Search for exact match ----

    pos <- which(display_names == journal_name)

    if (length(pos) == 1) {
      result <- pos
      method <- "exact"
    } else {
      dists <- stringdist::stringdist(journal_name, display_names)
      result <- which.min(dists)
      method <- "distance"
    }

    # response <- response[which.max(response$"relevance_score"), ]

    oa_data[1, "match"] <- method

    oa_data[1, "oa_source_name"] <-
      response[result, "display_name", drop = TRUE]

    oa_data[1, "oa_source_id"] <-
      response[result, "id", drop = TRUE]

    oa_data[1, "oa_works_count"] <-
      response[result, "works_count", drop = TRUE]

    oa_data[1, "oa_source_issn"] <-
      paste0(unlist(response[result, "issn", drop = TRUE]), collapse = " | ")

    oa_data[1, "oa_source_issn_l"] <-
      response[result, "issn_l", drop = TRUE]

    oa_data[1, "oa_publisher_name"] <-
      response[result, "host_organization_name", drop = TRUE]

    oa_data[1, "oa_country"] <-
      response[result, "country_code", drop = TRUE]

    topics <- response[result, "topics"][[1]] |>
      as.data.frame()

    topic <- topics[topics$type == "topic", ]

    if (nrow(topic) > 0) {
      oa_data[1, "oa_topic"] <-
        topic[which.max(topic$"count"), "display_name"]

      subfield <- topics[topics$type == "subfield", ]

      oa_data[1, "oa_subfield"] <-
        subfield[which.max(subfield$"count"), "display_name"]

      field <- topics[topics$type == "field", ]

      oa_data[1, "oa_field"] <-
        field[which.max(subfield$"count"), "display_name"]
    }
  }

  oa_data
}
