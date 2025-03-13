# Data processing

process_transcription = function(
    transcription_file = file.path("input", "transcription.tsv")
) {

  cat("Running preliminary checks.\n")
  check_inputs(transcription_file)

  cat("Parsing graphemes.\n")
  p <- add_graphemic_parse(transcription_file, save = FALSE)

  cat("Parsing soundsets.\n")
  p <- p %>% add_soundsets(save_result = TRUE)

  cat("Result saved as 'soundset_parse.tsv' in folder 'output'.\n")
}


align_and_report = function(
    soundset_file1 = file.path("output", "soundset_parse1.tsv"),
    soundset_file2 = file.path("output", "soundset_parse2.tsv")
) {

  cat("Running preliminary checks.\n")
  check_inputs(transcription_file = NULL)

  cat("Aligning the two soundset parses.")
  p <- align(soundset_file1, soundset_file2, save_result = FALSE)

  cat("Reconciling aligned soundsets.\n")
  p <- p %>% reconcile(save_result = FALSE)

  cat("Producng reports.\n")
  prepare_report(p, save_result = TRUE)

  cat("Outputs saved as 'reconstitution_report.txt' and 'report_data.tsv'",
      "in folder 'output'.\n")
}








