version 1.0

task task_variant_interpretation {
  input {
    File vcf
    File bam
    File bai
    File bed
    File json
    String sample_name
    Int minimum_coverage = 0
    Int minimum_total_depth = 0
    Int minimum_variant_depth = 0
    String report
    Boolean all_genes
  }
  
  command {
    variant_interpretation.py \
    --vcf ${vcf} \
    --bam ${bam} \
    --bed ${bed} \
    --json ${json} \
    --sample_name ${sample_name} \
    --minimum_coverage ${minimum_coverage} \
    --minimum_total_depth ${minimum_total_depth} \
    --minimum_variant_depth ${minimum_variant_depth} \
    --report ${report} \
    ${if all_genes then '--all_genes' else ''}
  }
  
  output {
    File interpretation_report = "${report}"
  }
  
  runtime {
    docker: "dbest/variant_interpretation:v1.0.0"
  }
}

workflow wf_variant_interpretation {
  input {
    File vcf
    File bam
    File bai
    File bed
    File json
    String sample_name
    Int minimum_coverage = 0
    Int minimum_total_depth = 0
    Int minimum_variant_depth = 0
    String report
    Boolean all_genes
  }
  
  call task_variant_interpretation {
    input:
    vcf = vcf,
    bam = bam,
    bai = bai,
    bed = bed,
    json = json,
    sample_name = sample_name,
    minimum_coverage = minimum_coverage,
    minimum_total_depth = minimum_total_depth,
    minimum_variant_depth = minimum_variant_depth,
    report = report,
    all_genes = all_genes
  }
  
  output {
    File interpretation_report = task_variant_interpretation.interpretation_report
  }

  parameter_meta {
    vcf: {
      description: "vcf file output from CDC/London TB profiler pipeline.",
      category: "required"
    }
    bam: {
      description: "bam file output from CDC/London TB profiler pipeline.",
      category: "required"
    }
    bai: {
      description: "bam index file output from CDC/London TB profiler pipeline.",
      category: "required"
    }
    bed: {
      description: "bed file with genomic intervals of interest.",
      category: "required"
    }
    json: {
      description: "json file with drug information for variants.",
      category: "required"
    }
    sample_name: {
      description: "sample name.",
      category: "required"
    }
    minimum_coverage: {
      description: "minimum coverage requirement.",
      category: "optional"
    }
    minimum_total_depth: {
      description: "minimum total number of reads that cover a variant requirement.",
      category: "optional"
    }
    minimum_variant_depth: {
      description: "minimum number of reads that support a variant requirement.",
      category: "optional"
    }
    all_genes: {
      description: "flag, if true all genes, not only genes of interest, are written to the output tsv report.",
      category: "optional"
    }
    report: {
      description: "name for output tsv file.",
      category: "required"
    }
    # output
    interpretation_report: {
      description: "output tsv file.",
      category: "required"
    }
  }
  
}
