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

/*
  The cloned repositories (which have been pushed into channel
  'repository_dirs_ch') are to be analysed by both cloc and by gitsum.

  It isn't possible to use the same channel as input to two different processes
  (unless that channel only contains a single entry).

  But, you can replicate a channel into multiple channels, and use one of the
  resulting channels as input.
*/

repository_dirs_ch.into { datasets_cloc; datasets_gitsum }

process cloc {

    publishDir "${params.pkg_results_dir}/${repository}"

    // treat the repository directory as a file
    input:
        tuple repository, file(local_repo) from datasets_cloc

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

process gitsum {

    // Save a link to the gitsum results in this directory
    //
    // Note, since the `repository` will be different for each run of this
    // process, we can't define `publishDir` in the config [if "blah/${xyz}"
    // is in the config, the field 'xyz' must be defined in the config
    // somewhere]
    publishDir "${params.pkg_results_dir}/${repository}"

    input:
        tuple repository, file(local_repo) from datasets_gitsum

    output:
        file "gitsum.tsv" into single_repo_gitsum_files

    script:
        """
        ${task.script} \
            --package_name "${repository}" \
            --local_repo "${local_repo}" \
            --output "gitsum.tsv"
        """
}

process reduce_cloc {

    // Because we've set the label to "pooled_results", this process will take
    // some directives defined in the "withLabel: pooled_results {}" section of
    // the process block in the config file
    //
    // Presently, that just means that the publishDir is set by the config for
    // any process with label `pooled_results`
    //
    // Note that there is a precedence for defining directives:
    // withName (in the config) > withLabel > process-specific vals (in the
    // script) > generic values
    label "pooled_results"

    // this is a `reduce` step, so all the files that are emitted by the
    // cloc-analysis channel are collected into a single object
    input:
        val fs from single_repo_cloc_files.collect()

    output:
        file "cloc.tsv" into multi_repo_cloc_file

    // `fs` is a collection of filenames for those files that are to be
    // combined together.
    // This script will combine together any number of files and uses syntax
    // `my_script.R --output some_file input1 input2 input3 ...`
    script:
        """
        ${params.rowbind_script} --output "cloc.tsv" ${fs.join(" ")}
        """
}

process reduce_gitsum {

    // This is almost identical to the `reduce_cloc` process and I can't work
    // out how (or whether it's worth) deduplicating the two processes could be
    // done

    label "pooled_results"

    input:
        val fs from single_repo_gitsum_files.collect()

    output:
        file "gitsum.tsv" into multi_repo_gitsum_file

    script:
        """
        ${params.rowbind_script} --output "gitsum.tsv" ${fs.join(" ")}
        """
}
