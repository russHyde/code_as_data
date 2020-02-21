letters = Channel.from('a', 'b', 'c')

process map_to_file {

    input:
        val letter from letters

    output:
        file("out.txt") into letter_files

    script:
        """
        echo ${letter} > out.txt
        """
}

process reduce_files {

    publishDir "mr"

    input:
        // convert the multiple-emmission `letter_files` channel into a
        // single-emmission channel by 'collect'ing its values
        val L from letter_files.collect()

    output:
        file("results.txt") into final_out

    script:
        """
        cat ${L.join(" ")} > results.txt
        """
}
