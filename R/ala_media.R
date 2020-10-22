#' Download images and sounds from the ALA.
#' 
#' @param identifier string: a single or vector of identifiers, of type
#' specified by `identifier_type`
#' @param download_dir string: path to directory for downloading media
#' @param identifier_type string: one of `c("occurrence", "media")`
#' @param media_type string: type of media to download, one or both of 
#' `c("image", "sound")`

# should sounds be downloaded by default?
# which fields should be kept?
ala_media <- function(identifier, download_dir, identifier_type = "media",
                      media_type = c("image", "sound")) {
  assert_that(!missing(identifier),
              msg = "Please provide at least one identifier")
  assert_that(is.character(identifier))
  
  valid_media_type <- str_detect(media_type, c("image", "sound"))
  if (!all(valid_media_type)) {
    stop("Valid media types are `c('image', 'sound')`")
  }
  assert_that(identifier_type %in% c("occurrence", "media"),
              msg = "`identifier_type` must be one of `c('occurrence', 'media')`")

  
  assert_that(!missing(download_dir), msg = "Directory to download media to is
              required")
  assert_that(file.exists(download_dir))
  
  media_data <- data.table::rbindlist(lapply(identifier, function(id) {
    if (identifier_type == 'media') {
      # get the media specified
      data <- cbind(media_id = id, as.data.frame(media(id),
                                                 stringsAsFactors = FALSE))
    } else {
      # get media for an occurrence id
      data <- occurrence_media(id)
    }
    data
  }), fill = TRUE)
  
  # download media
  # should add output path to out data?
  d <- mapply(download_media, media_data$media_id, media_data$format,
              download_dir)
  media_data
}

# should also allow filters? 
# handle the case when an occurrence record has more images than the limit?
# is there a limit?
occurrence_media <- function(occurrence_id) {
  url <- getOption("ALA4R_server_config")$base_url_images
  resp <- ala_GET(url, "ws/search",
                  list(q = paste0("occurrenceID:", "\"", occurrence_id, "\"")))

  if(resp$totalImageCount == 0) {
    warning("No media was found for id ", "\"", occurrence_id, "\"")
    return(NULL)
  }
  resp <- resp$images
  names(resp) <- rename_columns(names(resp), type = "media")
  resp[names(resp) %in% wanted_columns("media")]
}

# what to do if no media found? create error for now
media <- function(media_id) {
  url <- getOption("ALA4R_server_config")$base_url_images
  tryCatch(
    resp <- ala_GET(url, paste0("ws/image/", media_id)),
    error = function(e) {
      e$message <- paste0("No media found for id ", "\"", media_id, "\"")
      stop(e)
    }
  )
  # workaround for recognised licence returning null
  if (is.null(resp$recognisedLicence)) {
    resp$recognisedLicence <- NA
  }
  names(resp) <- rename_columns(names(resp), type = "media")
  resp[names(resp) %in% wanted_columns("media")]
}

download_media <- function(id, type, download_dir) {
  url <- parse_url(getOption("ALA4R_server_config")$base_url_images)
  url$path <- c("image", as.character(id), "original")
  ext <- switch (type,
    'image/jpeg' = '.jpg'
  )
  out_path <- file.path(download_dir, paste0(id, ext))
  download.file(build_url(url), destfile = out_path, quiet = TRUE)
  # throttle download requests
  Sys.sleep(1)
}