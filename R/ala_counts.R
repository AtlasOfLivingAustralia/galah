#' Count of ALA records
#'
#' Prior to downloading data it is often valuable to have some estimate of how
#' many records are available, both for deciding if the query is feasible,
#' and for estimating how long it will take to download. Alternatively, for some kinds
#' of reporting, the count of observations may be all that is required, for example
#' for understanding how observations are growing or shrinking in particular
#' locations of for particular taxa. To this end, \code{ala_counts()} takes
#' arguments in the same format as \code{\link{ala_occurrences}()}, and
#' provides either a total count of records matching the criteria, or a
#' \code{data.frame} of counts matching the criteria supplied to the \code{group_by}
#' argument.
#'
#' @param taxa \code{data.frame}: generated by a call to \code{\link{select_taxa}()}. This
#' argument also accepts a vector of unique species identifiers.
#' @param filters \code{data.frame}: generated by a call to \code{\link{select_filters}()}
#' @param locations \code{string}: generated by a call to \code{\link{select_locations}()}
#' @param group_by \code{string}: field to count by
#' @param limit \code{numeric}: maximum number of categories to return, defaulting to 100.
#' If limit is NULL, all results are returned. For some categories this will
#' take a while.
#' @param type \code{string}: one of \code{c("record", "species")}. Defaults to
#' "record". If "species", the number of species matching the criteria will be
#' returned, if "record", the number of records matching the criteria will be
#' returned.
#' @return
#' \itemize{
#'  \item{A single count, if \code{group_by} is not specified or,}
#'  \item{A \code{data.frame} of counts by \code{group_by} field, if it is specified}
#'}
#' @examples \dontrun{
#' # With no arguments, return the total number of records in the ALA
#' ala_counts()
#'
#' # Group counts by state and territory
#' ala_counts(group_by = "stateProvince")
#'
#' # Count records matching a filter
#' ala_counts(filters = select_filters(basisOfRecord = "FossilSpecimen"))
#' 
#' # Count the number of species recorded for each kingdom
#' ala_counts(group_by = "kingdom", type = "species")
#' }
#' @export ala_counts

ala_counts <- function(taxa = NULL, filters = NULL, locations = NULL, group_by,
                       limit = 100, type = "record") {
  query <- list()
  page_size <- 100
  verbose <- ala_config()$verbose
  
  profile <- extract_profile(filters)
  query <- build_query(taxa, filters, locations, profile = profile)

  if (missing(group_by)) {
    if (type == "species") {
      return(species_count(query))
    }
    return(record_count(query))
  }

  # check facet is valid
  validate_facet(group_by)
  query$facets <- group_by

  url <- server_config("records_base_url")
  path <- "occurrence/facets"
  cache_file <- cache_filename(args = c(url, path, unlist(query), limit,
                                        group_by, type),
                               ext = ".csv")

  caching <- getOption("galah_config")$caching
  if (caching && file.exists(cache_file)) {
    if (verbose) {message("Using cached file")}
    return(read.csv(cache_file, as.is = TRUE))
  }

  total_cats <- total_categories(url, path, query)
  if (total_cats == 0) {
    return(data.frame(name = as.character(), count = as.numeric()))
  }

  if (is.null(limit)) {
    limit <- total_cats
  }

  if (total_cats > limit && total_cats > page_size) {
    resp <- ala_GET(url, path, params = query, paginate = TRUE, limit = limit,
                    page_size = page_size, offset_param = "foffset")
    counts <- data.table::rbindlist(lapply(resp, function(x) {
      fromJSON(x)$fieldResult[[1]]
      }))
    } else {
      query$flimit <- limit
      resp <- ala_GET(url, path, params = query)
      counts <- resp$fieldResult[[1]]
  }

  if (total_cats > limit) {
    warning("This field has ", total_cats, " values. ", limit,
            " will be returned. Change `limit` to return more values.")
  }
  # parse out field value
  value <- parse_fq(counts$fq)
  
  if (type == "species") {
    # this can take a while so add progress bar
    if (verbose) { pb <- txtProgressBar(max = 1, style = 3) }
    counts <- data.table::rbindlist(lapply(seq_along(value), function(x) {
      if (verbose) {
        val <- (x / length(value))
        setTxtProgressBar(pb, val)
      }
      species_query <- list()
      species_query$fq <- c(query$fq,
                            query_term(name = group_by, value = value[[x]],
                            include = TRUE))
      count <- species_count(species_query)
      data.frame(name = value[[x]], count = count)
    }))
  } else {
    counts <- data.frame(
      name = value,
      count = counts$count
    )
  }
  names(counts) <- c(group_by, "count")
  
  if (caching) {
    write.csv(counts, cache_file, row.names = FALSE)
  }
  
  return(counts)
}

# get just the record count for a query
# handle too long queries in here?
record_count <- function(query) {
  query$pageSize <- 0
  url <- server_config("records_base_url")
  resp <- ala_GET(url, "occurrences/search", query)
  resp$totalRecords
}

species_count <- function(query) {
  query$flimit <- 1
  query$facets <- "speciesID"
  url <- server_config("records_base_url")
  total_categories(url, "occurrence/facets", query)
}

validate_facet <- function(facet) {
  if (!facet %in% c(search_fields()$id, all_fields()$name)) {
    stop("\"", facet, "\" is not a valid group_by field. ",
         "Use `search_fields()` to get a list of valid options")
  }
}

total_categories <- function(url, path, query) {
  query$flimit <- 1
  resp <- ala_GET(url, path, params = query)
  if (is.null(resp$count)) {
    return(0)
  }
  resp$count
}

parse_fq <- function(fq) {
  vapply(fq, function(z) {
    sub('.*?"([^"]+)"', "\\1", z)
  }, USE.NAMES = FALSE, FUN.VALUE = character(1))
}

