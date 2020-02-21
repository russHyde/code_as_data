#!/usr/bin/env nextflow

/*
  The workflow analyses a bunch of github repositories.

  Each repo defines an R package and it's details (the package name, the github
  URL and where we want to store it) are stored in the file
  `params.repo_details_file` (see the config).

  We convert that tab-separated file into a nextflow channel that can iterate
  over the different repositories

  Code is based on https://groups.google.com/forum/#!topic/nextflow/T7zDmtLAzSQ
*/

Channel
    .fromPath(params.repo_details_file)
    // split as if a tab-separated file, note that first line is the header
    .splitCsv(header:true, sep:"\t")
    // keep the package, remote_repo and local_repo columns for each row
    .map{ row -> tuple(row.package, row.remote_repo, row.local_repo) }
    // remove comment lines
    .filter{ row -> row[0] =~ /^[^#].*/ }
    // then give the channel a name
    .set{ repository_details_ch }

process clone {

    // Directives (process-associated variables) are either defined here
    // using syntax `<directiveName> <someValue>` or in the `process` block of
    // the config file.
    //
    // nextflow has a defined set of directive names ('afterScruot',
    // 'beforeScript', 'cache', 'conda', ...) and complains if you use an
    // unexpected directive name (but doesn't prevent you from doing this).
    //
    // You can access directive values using "${task.directiveName}" in the
    // 'script' section.

    // long-term cache: don't download the repo if a local copy already exists
    storeDir "."

    input:
        tuple repository, remote_repo, local_repo from repository_details_ch

    output:
        tuple repository, file(local_repo) into repository_dirs_ch

    script:
        """
        ${task.script} --remote_repo ${remote_repo} --local_repo ${local_repo}
        """
}

process cloc {

    publishDir "results/packages/${repository}"

    // treat the repository directory as a file
    input:
        tuple repository, file(local_repo) from repository_dirs_ch

    // note that you don't need to construct a package-specific path //
    output:
        file "cloc.tsv" into single_repo_cloc_files

    script:
        """
        ${task.script} \
            --package_name "${repository}" \
            --local_repo "${local_repo}" \
            --output "cloc.tsv"
        """
}
