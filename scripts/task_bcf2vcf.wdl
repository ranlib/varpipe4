version 1.0

task task_bcf2vcf {
  input {
    File bcf_file
  }

  String vcf = "${basename(bcf_file)}.vcf.gz"

  command {
    bcftools view ${bcf_file} | gzip > ${vcf}
  }

  output {
    File vcf_file = vcf
  }

  runtime {
    docker: "staphb/bcftools:1.17"
  }
}

