#' @export
sort.parameters_efa <- function(x, ...) {
  .sort_loadings(x)
}

#' @export
sort.parameters_pca <- sort.parameters_efa

#' @export
summary.parameters_efa <- function(object, ...) {
  insight::print_color("# (Explained) Variance of Principal Components\n\n", "blue")

  x <- attributes(object)$summary
  x$Variance_Explained <- x$Variance / sum(x$Variance)
  x$Std_Dev <- attributes(object)$model$sdev

  col_names <- x$Component

  cols <- intersect(
    c("Std_Dev", "Eigenvalues", "Variance", "Variance_Cumulative", "Variance_Explained"),
    colnames(x)
  )

  rows <- c("Eigenvalues", "Variance", "Cumulative Variance", "Explained Variance")
  if ("Std_Dev" %in% cols) rows <- c("Standard Deviation", rows)

  x <- as.data.frame(t(x[, cols]))
  x <- cbind(data.frame("Values" = rows, stringsAsFactors = FALSE), x)

  colnames(x) <- c("", col_names)
  class(x) <- c("parameters_efa_summary", class(x))
  x
}

#' @export
print.parameters_efa_summary <- function(x, digits = 3, ...) {
  cat(format_table(x, digits = digits, ...))

  invisible(x)
}

#' @export
summary.parameters_pca <- summary.parameters_efa




#' @export
model_parameters.parameters_efa <- function(model, ...) {
  attributes(model)$summary
}
#' @export
model_parameters.parameters_pca <- model_parameters.parameters_efa




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




#' @importFrom insight print_color print_colour
#' @export
print.parameters_efa <- function(x, digits = 2, sort = FALSE, threshold = NULL, labels = NULL, ...) {

  # Labels
  if(!is.null(labels)){
    x$Label <- labels
    x <- x[c("Variable", "Label", names(x)[!names(x) %in% c("Variable", "Label")])]
  }

  # Sorting
  if (sort) {
    x <- .sort_loadings(x)
  }

  # Replace by NA all cells below threshold
  if (!is.null(threshold)) {
    x <- .filer_loadings(x, threshold = threshold)
  }



  .rotation <- attr(x, "rotation", exact = TRUE)

  if (.rotation == "none") {
    insight::print_color("# Loadings from Principal Component Analysis (no rotation)\n\n", "blue")
  } else {
    insight::print_color(sprintf("# Rotated loadings from Principal Component Analysis (%s-rotation)\n\n", .rotation), "blue")
  }

  cat(format_table(x, digits = digits, ...))

  if (!is.null(attributes(x)$type)) {
    cat("\n")
    insight::print_colour(.text_components_variance(x), "yellow")
  }
}
#' @export
print.parameters_pca <- print.parameters_efa





#' @export
principal_components.lm <- function(x, ...) {
  principal_components(insight::get_predictors(x, ...), ...)
}

#' @export
principal_components.merMod <- principal_components.lm






#' @keywords internal
.text_components_variance <- function(x) {
  type <- attributes(x)$type
  if (type %in% c("prcomp", "principal")) {
    type <- "principal component"
  } else if (type %in% c("fa")) {
    type <- "latent factor"
  } else {
    type <- paste0(type, " component")
  }


  summary <- attributes(x)$summary

  if (nrow(summary) == 1) {
    text <- paste0("The unique ", type)
  } else {
    text <- paste0("The ", nrow(summary), " ", type, "s")
  }

  # rotation
  if (attributes(x)$rotation != "none") {
    text <- paste0(text, " (", attributes(x)$rotation, " rotation)")
  }

  text <- paste0(
    text,
    " accounted for ",
    sprintf("%.2f", max(summary$Variance_Cumulative) * 100),
    "% of the total variance of the original data"
  )

  if (nrow(summary) == 1) {
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

      total.ord[first:last] <- total.ord[ord$ix + first - 1 ]
      first <- first + items[i]
    }
  }

  order <- row.names(x)
  loadings <- loadings[as.numeric(as.character(order)), ] # Arrange by max
  row.names(loadings) <- NULL

  loadings
}