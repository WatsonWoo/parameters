% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/model_parameters.aov.R
\name{model_parameters.aov}
\alias{model_parameters.aov}
\title{Parameters from ANOVAs}
\usage{
\method{model_parameters}{aov}(
  model,
  omega_squared = NULL,
  eta_squared = NULL,
  epsilon_squared = NULL,
  ...
)
}
\arguments{
\item{model}{Object of class \link{aov}, \link{anova} or \code{aovlist}.}

\item{omega_squared}{Compute omega squared as index of effect size. Can be \code{"partial"} (adjusted for effect size) or \code{"raw"}.}

\item{eta_squared}{Compute eta squared as index of effect size. Can be \code{"partial"} (adjusted for effect size) or \code{"raw"}.}

\item{epsilon_squared}{Compute epsilon squared as index of effect size.}

\item{...}{Arguments passed to or from other methods.}
}
\value{
A data frame of indices related to the model's parameters.
}
\description{
Parameters from ANOVAs.
}
\examples{
df <- iris
df$Sepal.Big <- ifelse(df$Sepal.Width >= 3, "Yes", "No")

model <- aov(Sepal.Length ~ Sepal.Big, data = df)
model_parameters(model, omega_squared = "partial", eta_squared = "partial", epsilon_squared = TRUE)

model <- anova(lm(Sepal.Length ~ Sepal.Big, data = df))
model_parameters(model)
model_parameters(model, omega_squared = "partial", eta_squared = "partial", epsilon_squared = TRUE)

model <- aov(Sepal.Length ~ Sepal.Big + Error(Species), data = df)
model_parameters(model)

if (require("lme4")) {
  model <- anova(lmer(Sepal.Length ~ Sepal.Big + (1 | Species), data = df))
  model_parameters(model)
}
}
