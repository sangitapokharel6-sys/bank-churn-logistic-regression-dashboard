# Install the R packages used by this project.
# Run this once before running src/ChurnLogRegression.R

packages <- c(
  "ggplot2",
  "pROC",
  "writexl"
)

installed <- rownames(installed.packages())
for (pkg in packages) {
  if (!pkg %in% installed) {
    install.packages(pkg)
  }
}
