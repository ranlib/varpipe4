version 1.0

task task_trimmomatic {
  input {
    File read1
    File read2
    String samplename
    String docker="staphb/trimmomatic:0.39"
    Int trimmomatic_minlen = 40
    Int trimmomatic_window_size = 4
    Int trimmomatic_quality_trim_score = 15
    Int cpu = 4
    String memory = "8 GB"
  }

  command <<<
    date | tee DATE

    trimmomatic -version > VERSION

    trimmomatic PE \
    -threads ~{cpu} \
    ~{read1} ~{read2} \
    -baseout ~{samplename}.fastq.gz \
    -trimlog ~{samplename}.trim.log \
    -summary ~{samplename}.trim.stats.txt \
    LEADING:3 TRAILING:3 \
    SLIDINGWINDOW:~{trimmomatic_window_size}:~{trimmomatic_quality_trim_score} \
    MINLEN:~{trimmomatic_minlen} 2> ~{samplename}.trim.err

    gzip ~{samplename}.trim.log
  >>>

  output {
    File read1_trimmed = "${samplename}_1P.fastq.gz"
    File read2_trimmed = "${samplename}_2P.fastq.gz"
    File trim_stats = "${samplename}.trim.stats.txt"
    File trim_log = "${samplename}.trim.log.gz"
    File trim_err = "${samplename}.trim.err"
    String version = read_string("VERSION")
    String pipeline_date = read_string("DATE")
  }

  runtime {
    docker: "~{docker}"
    memory: "~{memory}"
    cpu: cpu
    disks: "local-disk 100 SSD"
    preemptible: 0
  }
}
