#!/usr/bin/env bash
set -euo pipefail

# Config file

config_file="conf/config.yaml"

# Ensure the environment is activated

if [[ $(basename "${CONDA_PREFIX}") != "code_as_data" ]]; then
  echo "Retry with CONDA env 'code_as_data'" >&2
  exit 1
fi

###############################################################################

# Helper functions

yaml_value() {
  # args: yaml-file, fieldname
  # extracts the field from the yaml file
  cat "${1}" | shyaml get-value "${2}"
}

add_prefix_and_suffix() {
  # args: file, prefix, suffix
  # return prefix/<line>/suffix for each line in file
  awk '{print prefix "/" $0 "/" suffix}' prefix="$2" suffix="$3" "$1"
}

###############################################################################

# Input data for the project
task_view_url="$(yaml_value "${config_file}" "task_view_url")"

# Files constructed by the called scripts
cran_table="$(yaml_value "${config_file}" "cran_details_file")"
repo_details="$(yaml_value "${config_file}" "repo_details_file")"
dupree_benchmarks="$(yaml_value "${config_file}" "all_pkg_benchmarks_file")"
cloc_table="$(yaml_value "${config_file}" "all_pkg_cloc_file")"
gitsum_table="$(yaml_value "${config_file}" "all_pkg_gitsum_file")"

# Parent directories for package-specific:
# - local-storage of the github repos
repo_dir="$(yaml_value "${config_file}" "repo_dir")"
# - results
pkg_results_dir="$(yaml_value "${config_file}" "pkg_results_dir")"

# Temporary files that are used to specify inputs to some jobs
pkg_names="temp/packages"
dupree_paths="temp/package_specific_dupree_files"
cloc_paths="temp/package_specific_cloc_files"
gitsum_paths="temp/package_specific_gitsum_files"

###############################################################################

# Run each step of the analysis:

Rscript "scripts/01-get-devtools-cran-table.R" \
  --config "${config_file}" \
  --url "${task_view_url}" \
  --output "${cran_table}"

Rscript "scripts/02-github-details.R" \
  --input "${cran_table}" \
  --repo_dir "${repo_dir}" \
  --output "${repo_details}"

# The collection of packages under study is saved temporarily
cat "${repo_details}" | tail -n+2 | cut -f1 > "${pkg_names}"

# Read each line from a header-stripped 3-column .tsv
# For each row, store the entries in 'package', 'remote_repo' and 'local_repo'

while IFS=$'\t' read package remote_repo local_repo
do
  if [[ ! -d "${pkg_results_dir}/${package}" ]]; then
    mkdir "${pkg_results_dir}/${package}"
  fi

  Rscript "scripts/03-github-clone.R" \
    --remote_repo "${remote_repo}" \
    --local_repo "${local_repo}"

  Rscript "scripts/04a-dupree-analysis.R" \
    --config "${config_file}" \
    --package_name "${package}" \
    --local_repo "${local_repo}" \
    --output_dir "${pkg_results_dir}/${package}"

  Rscript "scripts/05-cloc-analysis.R" \
    --local_repo "${local_repo}" \
    --package_name "${package}" \
    --output "${pkg_results_dir}/${package}/cloc_by_file.tsv"

  Rscript "scripts/06-gitsum-analysis.R" \
    --local_repo "${local_repo}" \
    --package_name "${package}" \
    --output "${pkg_results_dir}/${package}/gitsum.tsv"

done < <(tail -n+2 "${repo_details}")

###############################################################################

# Combine the package-specific results into all-package combined datasets

# `dupree`

add_prefix_and_suffix \
  "${pkg_names}" "${pkg_results_dir}" "dupree_timings.rds" \
  > "${dupree_paths}"

Rscript "scripts/04b-collapse-dupree-benchmarks.R" \
  --input_files "${dupree_paths}" \
  --output "${dupree_benchmarks}"

# `cloc`
# -- define the input files
add_prefix_and_suffix \
  "${pkg_names}" "${pkg_results_dir}" "cloc_by_file.tsv" \
  > "${cloc_paths}"

# -- collapse
Rscript "scripts/rowbind_tsv.R" \
  --input_files "${cloc_paths}" \
  --output "${cloc_table}"

# `gitsum`
# -- define the input files

add_prefix_and_suffix \
  "${pkg_names}" "${pkg_results_dir}" "gitsum.tsv" \
  > "${gitsum_paths}"

# -- collapse
Rscript "scripts/rowbind_tsv.R" \
  --input_files "${gitsum_paths}" \
  --output "${gitsum_table}"

# Make the report

echo "TODO: compile an Rmarkdown report of the results" >&2
