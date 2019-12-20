#!/usr/bin/env bash

if [[ $(basename "${CONDA_PREFIX}") != "code_as_data" ]]; then
  echo "Retry with CONDA env 'code_as_data'" >&2
  exit 1
fi

Rscript R/01-get-devtools-cran-table.R

Rscript R/02-github-details.R

Rscript R/03-github-clone.R

Rscript R/04-dupree-analysis.R

Rscript R/05-collapse-benchmarks.R

Rscript R/06-cloc-analysis.R

