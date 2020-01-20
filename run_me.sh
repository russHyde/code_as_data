#!/usr/bin/env bash
set -euo pipefail

# Config file

config_file="conf/config.yaml"

# Ensure the environment is activated

if [[ $(basename "${CONDA_PREFIX}") != "code_as_data" ]]; then
  echo "Retry with CONDA env 'code_as_data'" >&2
  exit 1
fi

# Ensure the results directories are set up

for key in "results_dir" "pkg_results_dir" "repo_dir"; do
  dir="$(cat "${config_file}" | shyaml get-value "${key}")"
  if [[ ! -d ${dir} ]]; then mkdir -p ${dir}; fi
done

# Install any non-conda R-dependencies

Rscript "scripts/00-setup-r-env.R" --config "${config_file}"

# Run each step of the analysis:

Rscript "scripts/01-get-devtools-cran-table.R" --config "${config_file}"

Rscript "scripts/02-github-details.R" --config "${config_file}"

Rscript "scripts/03-github-clone.R" --config "${config_file}"

Rscript "scripts/04-dupree-analysis.R" --config "${config_file}"

Rscript "scripts/05-collapse-benchmarks.R" --config "${config_file}"

Rscript "scripts/06-cloc-analysis.R" --config "${config_file}"

Rscript "scripts/07-gitsum-analysis.R" --config "${config_file}"

# Make the report

echo "TODO: compile an Rmarkdown report of the results" >&2
