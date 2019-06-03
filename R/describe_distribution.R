#' Describe a Distribution
#'
#'
#' This function describes a distribution.
#'
#' @param x A numeric vector.
#' @param range Return the range (min and max).
#' @inheritParams bayestestR::point_estimate
#'
#' @examples
#' describe_distribution(rnorm(100))
#' describe_distribution(rpois(100, lambda = 4))
#' describe_distribution(runif(100))
#' @export
describe_distribution <- function(x, centrality = "mean", dispersion = TRUE, range = TRUE, ...) {
  UseMethod("describe_distribution")

}


#' @importFrom stats na.omit
#' @export
describe_distribution.numeric <- function(x, centrality = "mean", dispersion = TRUE, range = TRUE, ...) {

  # Missing
  n_missing <- sum(is.na(x))
  x <- stats::na.omit(x)

  # Distribution
  type <- as.data.frame(t(find_distribution(x, probabilities = TRUE)))
  type$Type <- row.names(type)

  out <- data.frame(Type = type[which.max(type[, 1]), "Type"],
                     Type_Confidence = type[which.max(type[, 1]), 1] * 100)

  # Point estimates
  out <- cbind(out,
               bayestestR::point_estimate(x, centrality = centrality, dispersion = dispersion, ...))

  # Range
  if (range) {
    out <- cbind(out,
                 data.frame(Min = min(x, na.rm = TRUE),
                            Max = max(x, na.rm = TRUE)))
  }

  # Skewness
  out <- cbind(out,
               data.frame(Skewness = skewness(x),
                          Kurtosis = kurtosis(x)))

  out$n_Obs <- length(x)
  out$n_Missing <- n_missing

  out
}