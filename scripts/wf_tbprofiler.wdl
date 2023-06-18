version 1.0

import "./task_tbprofiler.wdl" as tbprofiler
import "./task_bcf2vcf.wdl" as bcf2vcf
import "./task_fastqc.wdl" as fastqc
import "./task_bbduk.wdl" as bbduk
import "./task_trimmomatic.wdl" as trimmomatic
import "./task_RunCollectMultipleMetrics.wdl" as bamQC

workflow wf_tbprofiler {
  input {
    File read1
    File read2
    String samplename
    String tbprofiler_docker_image
    String mapper
    String caller
    Float min_af
    Float min_af_pred
    Int threads
    Int min_depth
    Int cov_frac_threshold
    Int minNumberReads
    Int trimmomatic_minlen
    Int trimmomatic_window_size
    Int trimmomatic_quality_trim_score
    Boolean no_trim
    Boolean run_decontamination
    Boolean run_bamQC
    File reference
    String outputBasename
  }

  call fastqc.task_fastqc {
    input:
    forwardReads = read1,
    reverseReads = read2,
    threads = threads
  }

  Boolean filter1 = task_fastqc.numberForwardReads == task_fastqc.numberReverseReads
  Boolean filter2 = task_fastqc.numberForwardReads > minNumberReads
  Boolean filter = filter1 && filter2
  if ( filter ) {
    call trimmomatic.task_trimmomatic {
      input:
      read1 = read1,
      read2 = read2,
      samplename = samplename,
      cpu = threads,
      trimmomatic_minlen = trimmomatic_minlen,
      trimmomatic_window_size = trimmomatic_window_size,
      trimmomatic_quality_trim_score = trimmomatic_quality_trim_score
    }

    if ( run_decontamination ) {
      call bbduk.task_bbduk {
	input:
	read1_trimmed = task_trimmomatic.read1_trimmed,
	read2_trimmed = task_trimmomatic.read2_trimmed,
	samplename = samplename,
	cpu = threads
      }
    }

    call tbprofiler.task_tbprofiler {
      input:
      read1 = select_first([task_bbduk.read1_clean, task_trimmomatic.read1_trimmed]),
      read2 = select_first([task_bbduk.read2_clean, task_trimmomatic.read1_trimmed]),
      samplename = samplename,
      cpu = threads,
      tbprofiler_docker_image =  tbprofiler_docker_image,
      mapper = mapper,
      caller = caller,
      min_depth = min_depth,
      min_af = min_af,
      min_af_pred = min_af_pred,
      cov_frac_threshold = cov_frac_threshold,
      no_trim = no_trim
    }
    
    call bcf2vcf.task_bcf2vcf {
      input:
      bcf_file = task_tbprofiler.bcf
    }

    if ( run_bamQC ) {
      call bamQC.RunCollectMultipleMetrics {
	input:
	inputBam = task_tbprofiler.bam,
	reference = reference,
	outputBasename = outputBasename
      }
    }
  }
  # end filter
  
  output {
    File? csv = task_tbprofiler.csv
    File? bam = task_tbprofiler.bam
    File? bai = task_tbprofiler.bai
    File? vcf = task_tbprofiler.vcf
    File? svs = task_bcf2vcf.vcf_file
    # output from trimmer
    File? trim_stats = task_trimmomatic.trim_stats
    # output from decontamination
    File? phiX_stats = task_bbduk.phiX_stats
    File? adapter_stats = task_bbduk.adapter_stats
    # output from fastqc
    File? forwardHtml = task_fastqc.forwardHtml
    File? reverseHtml = task_fastqc.reverseHtml
    File? forwardZip = task_fastqc.forwardZip
    File? reverseZip = task_fastqc.reverseZip
    File? forwardSummary = task_fastqc.forwardSummary
    File? reverseSummary = task_fastqc.reverseSummary
    File? forwardData = task_fastqc.forwardData
    File? reverseData = task_fastqc.reverseData
    # output from bam QC
    Array[File]? collectMetricsOutput = RunCollectMultipleMetrics.collectMetricsOutput

  }
}