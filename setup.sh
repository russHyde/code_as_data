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
