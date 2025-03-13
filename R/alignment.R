# Alignment

align = function(
    soundset_file1 = file.path("output", "soundset_parse1.tsv"),
    soundset_file2 = file.path("output", "soundset_parse2.tsv"),
    save_result = TRUE
) {

  sp1 <- read_tsv(soundset_file1, show_col_types = FALSE) %>%
    select(ID, transcription1 = transcription, graphemic1 = graphemic,
           soundset1 = soundset)
  sp2 <- read_tsv(soundset_file2, show_col_types = FALSE) %>%
    select(ID, transcription2 = transcription, graphemic2 = graphemic,
           soundset2 = soundset)

  df <-
    # Put the two soundset files together, keeping only IDs for which both
    # files have a transcription
    sp1 %>%
    left_join(sp2, by = "ID") %>%
    filter(!is.na(transcription2)) %>%
    # If the transcriptions are identical, only use identical graphemicizations
    filter(transcription1 != transcription2 | graphemic1 == graphemic2) %>%
    mutate(aligned1 = "", aligned2 = "", score = 0) %>%
    # Encode the soundsets
    mutate(
      encoded1 = encode_soundsets(soundset1),
      encoded2 = encode_soundsets(soundset2),
      )

  similarity_matrix = get_align_matrix()
  encoded_rcnames = encode_soundsets(rownames(similarity_matrix))
  colnames(similarity_matrix) <- rownames(similarity_matrix) <- encoded_rcnames
  delim_regex = str_c("[", encode_soundsets(".#"), "]")

  # Add the alignments
  for (i in 1:nrow(df)) {
    enc1 <- df$encoded1[i]
    enc2 <- df$encoded2[i]
    n_delim_1 <- str_count(enc1, delim_regex)
    n_delim_2 <- str_count(enc2, delim_regex)
    score_adjust_dots <- max(n_delim_1, n_delim_2)
    score_adjust_other <- max(str_length(enc1), str_length(enc2))
    al <- pairwiseAlignment(enc1, enc2,
                            substitutionMatrix = similarity_matrix,
                            gapOpening = 0, gapExtension = 10, type = "global")
    df$aligned1[i] <- as.character(al@pattern)
    df$aligned2[i] <- as.character(al@subject)
    df$score[i] <-
      round((al@score - score_adjust_dots * 10) / score_adjust_other, 1)
  }

  # For each ID, sort by score, high to low
  df <- df %>%
    mutate(
      aligned1 = decode_soundsets(aligned1) %>% str_remove_all("#"),
      aligned2 = decode_soundsets(aligned2) %>% str_remove_all("#")
      ) %>%
    arrange(ID, -score) %>%
    select(ID, starts_with("tr"), starts_with("gr"), starts_with("so"),
           starts_with("al"), score)

  if (save_result) { write_tsv(df, file.path("output", "aligned_parse.tsv")) }
  invisible(df)
}


reconcile = function(
    aligned_parse = load_aligned_parse(),
    save_result = TRUE
) {

  df <-
    aligned_parse %>%
    mutate(
      reconciliation = reconcile_soundsets(aligned1, aligned2),
      is_fully_reconciled = !str_detect(reconciliation, "\\?")
    ) %>%
    arrange(ID, -is_fully_reconciled, -score)

  if (save_result) { write_tsv(df, file.path("output", "reconciled_parse.tsv")) }
  invisible(df)
}


get_align_matrix = function() {

  ssets <-
    load_soundsets()$soundset %>%
    str_split("") %>% unlist() %>% unique() %>% c(".")
  nsets <- length(ssets)
  smat <- matrix(-12, nsets, nsets, dimnames = list(ssets,ssets))

  classes <-
    read_tsv(file.path("input", "soundset_alignment_classes.tsv"),
             col_types = "ccn") %>%
    arrange(align_score)

  for (i in 1:nrow(classes)) {
    members <- classes$members[i] %>% str_split("") %>% unlist() %>% unique()
    smat[members, members] <- classes$align_score[i]
  }
  diag(smat) <- 10
  smat

}


encode_soundsets = function(unencoded) {

  decode <- c(load_soundsets()$soundset, ".", "⋅")
  encode <- c(letters, LETTERS)[1:(length(decode) -1)] %>% c("-")
  names(encode) <- decode
  names(decode) <- encode

  sapply(unencoded,
         function(s) {
           to_encode <- unlist(str_split(s, ""))
           str_flatten(encode[to_encode])
         },
         USE.NAMES = FALSE)
}


decode_soundsets = function(encoded) {

  decode <- c(load_soundsets()$soundset, ".", "⋅")
  encode <- c(letters, LETTERS)[1:(length(decode) -1)] %>% c("-")
  names(encode) <- decode
  names(decode) <- encode

  sapply(encoded,
         function(s) {
           to_decode <- unlist(str_split(s, ""))
           str_flatten(decode[to_decode])
         },
         USE.NAMES = FALSE)
}
