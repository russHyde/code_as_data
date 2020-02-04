import pandas as pd
from os.path import join

###############################################################################

configfile: join("conf", "config.yaml")

repositories = pd.read_table(
    join(config["results_dir"], "dev-pkg-repositories.tsv")
).set_index("package", drop=False)

packages=repositories["package"].tolist()

###############################################################################

def get_github_url(wildcards):
    return repositories.loc[wildcards["package"], "remote_repo"]

###############################################################################

# Define the filenames for all package-specific analysis results
# For a given package, these are typically of the form
# `<results_dir>/packages/<current_pkg>/<filename>`
# for filename:
#   gitsum.tsv, cloc_by_file.tsv, dupree_timings.rds, dupree_table.b40.tsv,
#   dupree_table.b100.tsv

package_specific_files = {}

package_specific_suffixes = {
    "gitsum": "gitsum.tsv",
    "cloc": "cloc_by_file.tsv",
    "dupree_timings": "dupree_timings.rds",
    "dupree_results": expand(
        "dupree_table.b{block_size}.tsv",
        block_size = config["min_block_sizes"]
    )
}

for k, v in package_specific_suffixes.items():
    package_specific_files[k] = expand(
        join(config["pkg_results_dir"], "{package}", "{suffix}"),
        package=packages,
        suffix=v
    )

###############################################################################

rule all:
    input:
        config["all_pkg_gitsum_file"],
        config["all_pkg_cloc_file"]

###############################################################################

# ---- REPORT ---- #

###############################################################################

# ---- REDUCE ---- #

rule collapse_gitsum:
    message:
        """
        --- Combine the gitsum results for each repository under study
        """
    input:
        data = package_specific_files["gitsum"],
        script = join("scripts", "rowbind_tsv.R")
    output:
        config["all_pkg_gitsum_file"]
    shell:
        """
        Rscript {input.script} --output {output} {input.data}
        """

rule collapse_cloc:
    message:
        """
        --- Combine the cloc results for each repository under study
        """
    input:
        data = package_specific_files["cloc"],
        script = join("scripts", "rowbind_tsv.R")
    output:
        config["all_pkg_cloc_file"]
    shell:
        """
        Rscript {input.script} --output {output} {input.data}
        """

###############################################################################

# ---- MAP ---- #

rule single_repo_gitsum:
    message:
        """
        --- Analyse the git commits for a single repository
        """
    input:
        repo = join(config["repo_dir"], "{package}"),
        script = join("scripts", "06-gitsum-analysis.R")
    output:
        join(
            config["pkg_results_dir"], "{package}", package_specific_suffixes["gitsum"]
        )
    shell:
        """
        Rscript {input.script} \
            --local_repo {input.repo} \
            --package_name {wildcards.package} \
            --output {output}
        """

rule single_repo_cloc:
    message:
        """
        --- Analyse the lines-of-code for each file in a single repository
        """
    input:
        repo = join(config["repo_dir"], "{package}"),
        script = join("scripts", "05-cloc-analysis.R")
    output:
        join(
            config["pkg_results_dir"], "{package}", package_specific_suffixes["cloc"]
        )
    shell:
        """
        Rscript {input.script} \
            --local_repo {input.repo} \
            --package_name {wildcards.package} \
            --output {output}
        """

###############################################################################

# ---- CLONE ---- #

rule clone_repo:
    message:
        """
        --- Clone the github repo for a single package
        """
    input:
        script = join("scripts", "03-github-clone.R")
    output:
        local_repo = directory(join(config["repo_dir"], "{package}"))
    params:
        remote_repo=lambda wildcards: get_github_url(wildcards)
    shell:
        """
        Rscript {input.script} \
            --remote_repo {params.remote_repo} \
            --local_repo {output.local_repo}
        """

###############################################################################
