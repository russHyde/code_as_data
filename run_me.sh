#!/usr/bin/env bash

# Ensure the environment is activated

if [[ $(basename "${CONDA_PREFIX}") != "code_as_data" ]]; then
  echo "Retry with CONDA env 'code_as_data'" >&2
  exit 1
fi

# Ensure the results directories are set up

for dir in results results/packages; do
  if [[ ! -d "${dir}" ]]; then mkdir "${dir}"; fi
done

# Run each step of the analysis:

Rscript R/01-get-devtools-cran-table.R

Rscript R/02-github-details.R

Rscript R/03-github-clone.R

Rscript R/04-dupree-analysis.R

Rscript R/05-collapse-benchmarks.R

Rscript R/06-cloc-analysis.R

