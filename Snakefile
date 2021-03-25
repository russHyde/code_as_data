import pandas as pd
from os.path import join

###############################################################################

my_config = join("conf", "config.yaml")

configfile: my_config

repositories = pd.read_table(
    config["repo_details_file"]
).set_index("package", drop=False)

packages=repositories["package"].tolist()

reports=config["reports"]

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

package_specific_suffixes["dupree"] = [
    package_specific_suffixes["dupree_timings"]
] + package_specific_suffixes["dupree_results"]

for k, v in package_specific_suffixes.items():
    package_specific_files[k] = expand(
        join(config["pkg_results_dir"], "{package}", "{suffix}"),
        package=packages,
        suffix=v
    )

pooled_results = [
    config["pooled_results"][analysis]
    for analysis in ["gitsum", "cloc", "dupree_benchmarks"]
]

###############################################################################

rule all:
    input:
        pooled_results,
        reports

###############################################################################

# ---- REPORT ---- #

rule render_markdown:
    message:
        """
        --- Render each .Rmd into a .html report
        """

    input:
        rmd = join("doc", "{report_name}.Rmd"),
        results = pooled_results

    output:
        html = join("doc", "{report_name}.html")

    shell:
        """
        Rscript -e "rmarkdown::render(input='{input.rmd}', output='{output.html}', output_format='html_document')"
        """

###############################################################################

# ---- REDUCE ---- #

rule collapse_gitsum:
    message:
        """
        --- Combine the gitsum results for each repository under study
        """
    input:
        data = package_specific_files["gitsum"],
        script = join("scripts", "rowbind-tsv.R")
    output:
        config["pooled_results"]["gitsum"]
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
        script = join("scripts", "rowbind-tsv.R")
    output:
        config["pooled_results"]["cloc"]
    shell:
        """
        Rscript {input.script} --output {output} {input.data}
        """

rule collapse_dupree_timings:
    message:
        """
        --- Combine the dupree timings for each repository under study
        """
    input:
        data = package_specific_files["dupree_timings"],
        script = join("scripts", "04b-collapse-dupree-benchmarks.R")
    output:
        config["pooled_results"]["dupree_benchmarks"]
    shell:
        """
        Rscript {input.script} --output {output} {input.data}
        """

###############################################################################

# ---- MAP ---- #

# Note: in all rules where a repository is taken as input, that repository is
# set to `ancient`. This was done to prevent recomputation of results. On
# running `gitsum` for a repo, a subdirectory is modified that makes the repo
# dir look like it's been updated (although none of the code-for-analysis has
# been modified by gitsum).

rule single_repo_gitsum:
    message:
        """
        --- Analyse the git commits for a single repository
        """
    input:
        repo = ancient(
            join(config["repo_dir"], "{package}"),
        ),
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
        repo = ancient(
            join(config["repo_dir"], "{package}"),
        ),
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

rule single_repo_dupree:
    message:
        """
        --- Analyse the duplication in the R/ directory of a repository
        """
    input:
        repo = ancient(
            join(config["repo_dir"], "{package}"),
        ),
        script = join("scripts", "04a-dupree-analysis.R")
    output:
        expand(
            join(config["pkg_results_dir"], "{{package}}", "{suffix}"),
            suffix=package_specific_suffixes["dupree"]
        )
    params:
        config_file=my_config,
        output_dir=lambda wildcards: join(config["pkg_results_dir"], wildcards["package"])
    shell:
        """
        Rscript {input.script} \
            --config {params.config_file} \
            --package_name {wildcards.package} \
            --local_repo {input.repo} \
            --output_dir {params.output_dir}
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
