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
