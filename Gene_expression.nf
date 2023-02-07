params.results_dir = "results/"
params.transcriptome = "transcriptome/GRCh38_latest_rna.fna"
params.name          = "RNA-Seq Analysis"
params.reads         = "results/{SRA_list}/*.fastq"
params.fragment_len  = '180'
params.fragment_sd   = '20'
params.bootstrap     = '100'

params.output        = "results/"
SRA_list = params.SRA.split(",")

transcriptome_file     = file(params.transcriptome)


log.info ""
log.info "  Q U A L I T Y   C O N T R O L  "
log.info "================================="
log.info "SRA number         : ${SRA_list}"
log.info "Results location   : ${params.results_dir}"
log.info "Ref seq location   : ${params.transcriptome}"

process DownloadFastQ {
  publishDir "${params.results_dir}"

  input:
    val sra

  output:
    path "${sra}/*"

  script:
    """
    /content/sratoolkit.3.0.0-ubuntu64/bin/fasterq-dump ${sra} -O ${sra}/
    """
}

process QC {
  input:
    path x

  output:
    path "qc/*"

  script:
    """
    mkdir qc
    /content/FastQC/fastqc -o qc $x
    """
}

process MultiQC {
  publishDir "${params.results_dir}"

  input:
    path x

  output:
    path "multiqc_report.html"

  script:
    """
    multiqc $x
    """
}

process index {
    input:
    file transcriptome_file

    output:
    file "transcriptome.index" into transcriptome_index

    script:
    //
    // Kallisto tools mapper index
    //
    """
    kallisto index -i transcriptome.index ${transcriptome_file}
    """
}

workflow {
  data = Channel.of( SRA_list )
  DownloadFastQ(data)
  QC( DownloadFastQ.out )
  MultiQC( QC.out.collect() )
  Kaliso indexing(data)
}