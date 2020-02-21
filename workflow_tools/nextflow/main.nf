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

/*
  "channels" are how filenames, computed values etc are passed between the
  recipes in nextflow
*/

// There are two main ways to define a channel and associate it with a name:
// Channel.{ ... pipeline ... }.set{ some_name }
// some_name = Channel.{ ... pipeline ... }

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

markdown_ch = Channel.fromPath(params.rmarkdown_file)

/*
  "processes" are similar to "rules" in snakemake
*/

process clone {
    // Directives (process-associated variables) are either defined here
    // using syntax `<directiveName> <someValue>` or in the `process` block of
    // the config file.
    //
    // nextflow has a defined set of directive names ('afterScript',
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
        cloc-analysis.R --package_name "${repository}" \
            --local_repo "${local_repo}" --output "cloc.tsv"
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
        gitsum-analysis.R \
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

    // This process almost identical to the `reduce_cloc` process and I can't
    // work out how (or whether it's worth) deduplicating the two processes
    // could be done

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


process compile_markdown {

    // Please note that the following is a major hack.
    //
    // The way that rmarkdown/knitr and nextflow manage filepaths jars a bit.
    //
    // {rmarkdown} / {knitr} expect filepaths to be specified relative to the
    // position of the .Rmd (and make your life a nightmare otherwise); but I
    // want all notebooks to site in the doc/ subdir of my projects (so
    // rmd-relative paths differ from project-root-relative paths)
    //
    // As such, when I write .Rmd files, i use here::here() to pin filepaths
    // relative to the project-root
    //
    // But, nextflow processes run with a working directory that differs from
    // the project root; and it is difficult to pass in all filepaths that
    // might be required by the rmarkdown rendering step. So ensuring that an
    // .Rmd knows where to get data from is further complicated under nextflow.
    //
    // Workaround:
    // 1) ensure all files that may be required during Rmarkdown rendering are
    // pushed into `publishDir` or `storeDir`;
    // 2) ensure the channels for the corresponding files are 'input's for the
    // markdown rendering step;
    // 3) write the markdown so that it accesses any required data via
    // here()-based project-root relative paths (note this means the channels
    // containing the relevant data won't actually be used); I'd usually pass
    // in the root-relative filepaths from a config;
    // 4) ensure the nextflow working-directory is a subdirectory of the
    // project root (and that a .here or .git or .Rproj file is present in the
    // project root)
    //
    // [BUG ALERT: {rmarkdown}] note that a nextflow process runs inside a
    // working directory that contains symlinks to the inputs for that process
    // but, when a *.Rmd filepath is a symlink to a target location, rmarkdown
    // renders and stores the report in the target directory not the link
    // directory: https://github.com/rstudio/rmarkdown/issues/1508  To
    // circumvent this, we use `output_dir = getwd()` to ensure the report is
    // put into the nextflow working directory for the current process.

    publishDir "doc"

    input:
        file rmd    from markdown_ch
        file gitsum from multi_repo_gitsum_file
        file cloc   from multi_repo_cloc_file

    output:
        file "notebook.html" into markdown_report

    script:
        """
        #!/usr/bin/env Rscript
        rmarkdown::render(
            input = "${rmd}",
            quiet = TRUE,
            output_dir = getwd(),
            params = list(workflow_manager = "nextflow")
        )
        """
}
