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

package_specific_gitsum_files = expand(
    join(config["pkg_results_dir"], "{package}", "gitsum.tsv"),
    package=packages
)

###############################################################################

rule all:
    input:
        config["all_pkg_gitsum_file"]

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
        data = package_specific_gitsum_files,
        script = join("scripts", "rowbind_tsv.R")
    output:
        config["all_pkg_gitsum_file"]
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
        join(config["pkg_results_dir"], "{package}", "gitsum.tsv")
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
