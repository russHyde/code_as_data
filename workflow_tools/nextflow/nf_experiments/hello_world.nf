#!/usr/bin/env nextflow

process helloWorld {
    output:
        stdout result

    """
    echo "${params.str}"
    """
}

result.view { it.trim() }
