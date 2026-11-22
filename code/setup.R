# Install the locked analysis environment into an ignored, project-local library.
options(repos = c(CRAN = "https://cloud.r-project.org"))
dir.create(".R-library", showWarnings = FALSE)
.libPaths(c(normalizePath(".R-library"), .libPaths()))
if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv", lib = ".R-library")
renv::restore(project = getwd(), lockfile = "renv.lock", library = ".R-library", prompt = FALSE)
