#' help-functions
#' @keywords internal
.data_frame <- function(...) {
  x <- data.frame(..., stringsAsFactors = FALSE)
  rownames(x) <- NULL
  x
}








#' Flatten a list
#'
#' @param object A list.
#' @param name Name of column of keys in the case the output is a dataframe.
#' @keywords internal
.flatten_list <- function(object, name = "name") {
  if (length(object) == 1) {
    object[[1]]
  } else if (all(sapply(object, is.data.frame))) {
    if (is.null(names(object))) {
      as.data.frame(t(sapply(object, rbind)))
    } else {
      tryCatch(
        {
          rn <- names(object)
          object <- do.call(rbind, object)
          object[name] <- rn
          object[c(name, setdiff(names(object), name))]
        },
        warning = function(w) {
          object
        },
        error = function(e) {
          object
        }
      )
    }
  } else {
    object
  }
}



#' Recode a variable so its lowest value is beginning with zero
#'
#' @keywords internal
.recode_to_zero <- function(x) {
  # check if factor
  if (is.factor(x) || is.character(x)) {
    # try to convert to numeric
    x <- .factor_to_numeric(x)
  }

  # retrieve lowest category
  minval <- min(x, na.rm = TRUE)
  sapply(x, function(y) y - minval)
}



#' Safe transformation from factor/character to numeric
#'
#' @importFrom stats na.omit
#' @keywords internal
.factor_to_numeric <- function(x) {
  if (is.numeric(x)) {
    return(x)
  }

  if (anyNA(suppressWarnings(as.numeric(as.character(stats::na.omit(x)))))) {
    if (is.character(x)) {
      x <- as.factor(x)
    }
    levels(x) <- 1:nlevels(x)
  }

  as.numeric(as.character(x))
}



#' Safe transformation from factor/character to numeric
#'
#' @importFrom stats na.omit
#' @keywords internal
.factor_to_dummy <- function(x) {
  if (is.numeric(x)) {
    return(x)
  }

  # get unique levels / values
  values <- if (is.factor(x)) {
    levels(x)
  } else {
    stats::na.omit(unique(x))
  }

  dummy <- as.data.frame(do.call(cbind, lapply(values, function(i) {
    out <- rep(0, length(x))
    out[is.na(x)] <- NA
    out[x == i] <- 1
    out
  })))

  colnames(dummy) <- values
  dummy
}


#' Find most common occurence
#'
#' @keywords internal
.find_most_common <- function(x) {
  out <- names(sort(table(x), decreasing = TRUE))[1]

  if (is.numeric(x)) out <- as.numeric(out)

  out
}



#' remove NULL elements from lists
#' @keywords internal
.compact_list <- function(x) x[!sapply(x, function(i) length(i) == 0 || is.null(i) || any(i == "NULL"))]



#' remove empty string from character
#' @keywords internal
.compact_character <- function(x) x[!sapply(x, function(i) nchar(i) == 0 || is.null(i) || any(i == "NULL"))]



#' @keywords internal
.rename_values <- function(x, old, new) {
  x[x %in% old] <- new
  x
}


#' for models with zero-inflation component, return required component of model-summary
#' @keywords internal
.filter_component <- function(dat, component) {
  switch(
    component,
    "conditional" = dat[dat$Component == "conditional", ],
    "zi" = ,
    "zero_inflated" = dat[dat$Component == "zero_inflated", ],
    dat
  )
}



# Find log-terms inside model formula, and return "clean" term names
#' @importFrom insight find_terms
.log_terms <- function(model) {
  x <- insight::find_terms(model, flatten = TRUE)
  gsub("^log\\((.*)\\)", "\\1", x[grepl("^log\\((.*)\\)", x)])
}


# capitalize first character in string
#' @keywords internal
.capitalize <- function(x) {
  capped <- grep("^[A-Z]", x, invert = TRUE)
  substr(x[capped], 1, 1) <- toupper(substr(x[capped], 1, 1))
  x
}


#' @keywords internal
.safe_deparse <- function(string) {
  paste0(sapply(deparse(string, width.cutoff = 500), trimws, simplify = TRUE), collapse = " ")
}



#' @keywords internal
.remove_columns <- function(data, variables) {
  to_remove <- which(colnames(data) %in% variables)
  if (length(to_remove)) {
    data[, -to_remove, drop = FALSE]
  } else {
    data
  }
}




#' @keywords internal
.is_empty_object <- function(x) {
  if (is.list(x)) {
    x <- tryCatch(
      {
        .compact_list(x)
      },
      error = function(x) {
        x
      }
    )
  }
  # this is an ugly fix because of ugly tibbles
  if (inherits(x, c("tbl_df", "tbl"))) x <- as.data.frame(x)
  x <- suppressWarnings(x[!is.na(x)])
  length(x) == 0 || is.null(x)
}
