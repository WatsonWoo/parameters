# summary -----------------------------------------------------------------




#' @export
summary.parameters_efa <- function(object, ...) {
  x <- attributes(object)$summary

  cols <- intersect(
    c("Std_Dev", "Eigenvalues", "Variance", "Variance_Cumulative", "Variance_Proportion"),
    colnames(x)
  )


  x <- as.data.frame(t(x[, cols]))
  x <- cbind(data.frame("Parameter" = row.names(x), stringsAsFactors = FALSE), x)
  names(x) <- c("Parameter", attributes(object)$summary$Component)
  row.names(x) <- NULL

  if ("parameters_efa" %in% class(object)) {
    class(x) <- c("parameters_efa_summary", class(object))
  } else {
    class(x) <- c("parameters_pca_summary", class(object))
  }
  x
}

#' @export
summary.parameters_pca <- summary.parameters_efa



#' @export
model_parameters.parameters_efa <- function(model, ...) {
  x <- attributes(model)$summary

  if ("parameters_efa" %in% class(model)) {
    class(x) <- c("parameters_efa_summary", class(model))
  } else {
    class(x) <- c("parameters_pca_summary", class(model))
  }
  x
}

#' @export
model_parameters.parameters_pca <- model_parameters.parameters_efa






#' @export
summary.parameters_omega <- function(object, ...) {
  table_var <- attributes(object)$summary
  class(table_var) <- c("parameters_omega_summary", class(table_var))
  table_var
}

# predict -----------------------------------------------------------------



#' @export
predict.parameters_efa <- function(object, newdata = NULL, names = NULL, ...) {
  if (is.null(newdata)) {
    out <- as.data.frame(attributes(object)$scores)
  } else {
    out <- as.data.frame(predict(attributes(object)$model, newdata = newdata, ...))
  }
  if (!is.null(names)) {
    names(out)[1:length(c(names))] <- names
  }
  row.names(out) <- NULL
  out
}

#' @export
predict.parameters_pca <- predict.parameters_efa







# print -------------------------------------------------------------------


#' @importFrom insight format_table
#' @export
print.parameters_efa_summary <- function(x, digits = 3, ...) {
  insight::print_color("# (Explained) Variance of Components\n\n", "blue")

  if ("Parameter" %in% names(x)) {
    x$Parameter <- c("Eigenvalues", "Variance Explained", "Variance Explained (Cumulative)", "Variance Explained (Proportion)")
  } else if ("Component" %in% names(x)) {
    names(x) <- c("Copmponent", "Eigenvalues", "Variance Explained", "Variance Explained (Cumulative)", "Variance Explained (Proportion)")
  }

  cat(insight::format_table(x, digits = digits, ...))

  invisible(x)
}

#' @export
print.parameters_pca_summary <- print.parameters_efa_summary





#' @importFrom insight print_color print_colour
#' @export
print.parameters_efa <- function(x, digits = 2, sort = FALSE, threshold = NULL, labels = NULL, ...) {
  if (inherits(x, "parameters_pca")) {
    method <- "Principal Component Analysis"
  } else {
    method <- "Factor Analysis"
  }

  # Labels
  if (!is.null(labels)) {
    x$Label <- labels
    x <- x[c("Variable", "Label", names(x)[!names(x) %in% c("Variable", "Label")])]
  }

  # Sorting
  if (isTRUE(sort)) {
    x <- .sort_loadings(x)
  }

  # Replace by NA all cells below threshold
  if (!is.null(threshold)) {
    x <- .filter_loadings(x, threshold = threshold)
  }


  rotation_name <- attr(x, "rotation", exact = TRUE)

  if (is.null(rotation_name) || rotation_name == "none") {
    insight::print_color(sprintf("# Loadings from %s (no rotation)\n\n", method), "blue")
  } else {
    insight::print_color(sprintf("# Rotated loadings from %s (%s-rotation)\n\n", method, rotation_name), "blue")
  }

  cat(insight::format_table(x, digits = digits, ...))

  if (!is.null(attributes(x)$type)) {
    cat("\n")
    insight::print_colour(.text_components_variance(x), "yellow")
    cat("\n")
  }
}

#' @export
print.parameters_pca <- print.parameters_efa



#' @export
print.parameters_omega <- function(x, ...) {
  names(x) <- c("Composite", "Omega (total)", "Omega (hierarchical)", "Omega (group)")
  cat(insight::format_table(x))
}


#' @export
print.parameters_omega_summary <- function(x, ...) {
  names(x) <- c("Composite", "Total Variance (%)", "Variance due to General Factor (%)", "Variance due to Group Factor (%)")
  cat(insight::format_table(x))
}



#' @keywords internal
.text_components_variance <- function(x) {
  type <- attributes(x)$type
  if (type %in% c("prcomp", "principal", "pca")) {
    type <- "principal component"
  } else if (type %in% c("fa")) {
    type <- "latent factor"
  } else if (type %in% c("kmeans")) {
    type <- "cluster"
  } else {
    type <- paste0(type, " component")
  }

  if (type == "cluster") {
    summary <- as.data.frame(x)
    variance <- attributes(x)$variance * 100
  } else {
    summary <- attributes(x)$summary
    variance <- max(summary$Variance_Cumulative) * 100
  }

  if (nrow(summary) == 1) {
    text <- paste0("The unique ", type)
  } else {
    text <- paste0("The ", nrow(summary), " ", type, "s")
  }

  # rotation
  if (!is.null(attributes(x)$rotation) && attributes(x)$rotation != "none") {
    text <- paste0(text, " (", attributes(x)$rotation, " rotation)")
  }


  text <- paste0(
    text,
    " accounted for ",
    sprintf("%.2f", variance),
    "% of the total variance of the original data"
  )

  if (type == "cluster" || nrow(summary) == 1) {
    text <- paste0(text, ".")
  } else {
    text <- paste0(
      text,
      " (",
      paste0(summary$Component,
        " = ",
        sprintf("%.2f", summary$Variance * 100),
        "%",
        collapse = ", "
      ),
      ")."
    )
  }
  text
}





# sort --------------------------------------------------------------------


#' @export
sort.parameters_efa <- function(x, ...) {
  .sort_loadings(x)
}

#' @export
sort.parameters_pca <- sort.parameters_efa




#' @keywords internal
.sort_loadings <- function(loadings, cols = NULL) {
  if (is.null(cols)) {
    cols <- attributes(loadings)$loadings_columns
  }

  # Remove variable name column
  x <- loadings[, cols, drop = FALSE]
  row.names(x) <- NULL

  # Initialize clusters
  nitems <- nrow(x)
  loads <- data.frame(item = seq(1:nitems), cluster = rep(0, nitems))

  # first sort them into clusters: Find the maximum for each row and assign it to that cluster
  loads$cluster <- apply(abs(x), 1, which.max)
  ord <- sort(loads$cluster, index.return = TRUE)
  x[1:nitems, ] <- x[ord$ix, ]

  rownames(x)[1:nitems] <- rownames(x)[ord$ix]
  total.ord <- ord$ix

  # now sort column wise so that the loadings that have their highest loading on each cluster
  items <- table(loads$cluster) # how many items are in each cluster?
  first <- 1
  item <- loads$item
  for (i in 1:length(items)) {
    if (items[i] > 0) {
      last <- first + items[i] - 1
      ord <- sort(abs(x[first:last, i]), decreasing = TRUE, index.return = TRUE)
      x[first:last, ] <- x[item[ord$ix + first - 1], ]
      loads[first:last, 1] <- item[ord$ix + first - 1]
      rownames(x)[first:last] <- rownames(x)[ord$ix + first - 1]

      total.ord[first:last] <- total.ord[ord$ix + first - 1]
      first <- first + items[i]
    }
  }

  order <- row.names(x)
  loadings <- loadings[as.numeric(as.character(order)), ] # Arrange by max
  row.names(loadings) <- NULL

  loadings
}

# Filter --------------------------------------------------------------------


#' @keywords internal
.filter_loadings <- function(loadings, threshold = 0.2, loadings_columns = NULL) {
  if (is.null(loadings_columns)) {
    loadings_columns <- attributes(loadings)$loadings_columns
  }


  if (threshold == "max" | threshold >= 1) {
    if (threshold == "max") {
      for (row in 1:nrow(loadings)) {
        maxi <- max(abs(loadings[row, loadings_columns, drop = FALSE]))
        loadings[row, loadings_columns][abs(loadings[row, loadings_columns]) < maxi] <- NA
      }
    } else {
      for (col in loadings_columns) {
        loadings[tail(order(abs(loadings[, col]), decreasing = TRUE), -round(threshold)), col] <- NA
      }
    }
  } else {
    loadings[, loadings_columns][abs(loadings[, loadings_columns]) < threshold] <- NA
  }

  loadings
}
