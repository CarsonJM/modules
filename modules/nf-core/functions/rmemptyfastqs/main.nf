// create a function that filters channels to remove empty fastq files
def rmEmptyFastQs(ch_fastqs, print_output) {
    def ch_nonempty_fastqs = ch_fastqs
        .filter { meta, fastq ->
                if ( meta.single_end ) {
                    try {
                        fastq.countFastq(limit: 10) > 1
                    } catch (java.util.zip.ZipException e) {
                        log.warn "[HoffLab/phageannotator]: ${fastq} is not in GZIP format, this is likely because it was cleaned with --remove_intermediate_files"
                        true
                    } catch (EOFException) {
                        log.warn "[HoffLab/phageannotator]: ${fastq} has an EOFException, this is likely an empty gzipped file."
                    }
                } else {
                    try {
                        fastq[0].countLines( limit: 10 ) > 1
                    } catch (java.util.zip.ZipException e) {
                        log.warn "[HoffLab/phageannotator]: ${fastq} is not in GZIP format, this is likely because it was cleaned with --remove_intermediate_files"
                        true
                    } catch (EOFException) {
                        log.warn "[HoffLab/phageannotator]: ${fastq[0]} has an EOFException, this is likely an empty gzipped file."
                    }
                }
            }

    if (print_output) {
        ch_nonempty_fastqs.view()
    }
    return ch_nonempty_fastqs
}
