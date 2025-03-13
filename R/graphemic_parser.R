# Graphemic parser


add_graphemic_parse = function(
    transcription_file = file.path("input", "Blake_transcription1.tsv"),
    graphemes = load_graphemes(),
    exclusions = load_graphotactic_exclusions(),
    save_result = TRUE
) {

  transcription_df <- read_tsv(transcription_file, show_col_types = FALSE)
  cn <- colnames(transcription_df)
  if (!"ID" %in% cn) stop("Column `ID` is missing")
  if (!"transcription" %in% cn) stop("Column `transcription` is missing")

  gr <- unique(graphemes$grapheme)
  ex <- exclusions$exclude
  df <-
    transcription_df %>%
    rowwise() %>%
    mutate(graphemic = list(parse_graphemes(transcription, gr, ex))) %>%
    unnest(graphemic)

  if (save_result) { write_tsv(df, file.path("output", "graphemic_parse.tsv")) }
  invisible(df)
}


parse_graphemes = function(
    word,
    graphemes, # A vector of graphemes
    exclusions # A vector of illegal sequences
) {

  word <- str_c("#", word, "#")
  word_len <- str_length(word)
  max_grapheme_len <- min(max(str_length(graphemes)), str_length(word))

  # Create a set of all conceivable splits of a word of wordlen letters. The
  # split is represented as a string of 1's and 0's. A 1 at string position n
  # indicates that position n is at the start of a new grapheme. Thus, all
  # splits start with 1
  n_splits <- 2 ^ (word_len - 1)
  splits <- str_c("1",
                  intToBin(0:(n_splits -1)) %>%
                    str_pad(width = (word_len - 1), side = "left", pad = "0")
                  )

  # Now remove any sequences of no-split longer than the longest grapheme
  illegal_seq <- str_dup("0", max_grapheme_len)
  is_legal <- !str_detect(splits, illegal_seq)
  splits <- splits[is_legal]

  # Loop through 1-, 2-, 3-, ..., n-letter substrings of word; check if each
  # substring is a grapheme; if not, remove all splits that contain a span
  # corresponding exactly to the position of that substring
  for (span_len in 1:max_grapheme_len) {
    for (span_start in 1:(word_len - span_len + 1)) {
      span_string <- str_sub(word, span_start, span_start + span_len - 1)
      if (!span_string %in% graphemes) {
        # No grapheme matches this span, so remove all splits which contain it
        bad_span_regex <-
          str_c("^", str_dup(".", span_start - 1), "1",
                str_dup("0", span_len - 1), "(1|$)")
        has_bad_span <- str_detect(splits, bad_span_regex)
        splits <- splits[!has_bad_span]
        if(any(is.na(splits))) return("---")
      }
    }
  }

  # Check if any splits are left. If not, return NA
  if (length(splits) == 0) return("---")

  # Generate all parses of word into graphemes by interleaving the letters of
  # the word between the 1's and 0's, then removing the 0's and the initial 1,
  # and then replacing all remaining 1's with a delimiting period.
  parses <-
    str_interleave(splits, word) %>%
    str_remove_all("0") %>%
    str_remove("^1") %>%
    str_replace_all("1", ".")

  # Exclude parses that contain graphotactically illegal substrings
  illegal_regex <-
    exclusions %>% str_replace_all("\\.", "\\\\.") %>% str_flatten("|")
  is_legal <- !str_detect(parses, illegal_regex)
  parses <- parses[is_legal]

  # Return the final result
  if (any(is.na(parses)) | length(parses) == 0) return("---")
  parses
}



str_interleave = function(
    s1, # A vector of strings, all length L
    s2  # A single string of length L
) {

  n1 <- length(s1) # number of strings in s1
  l1 <- str_length(s1) # vector of string lengths
  l2 <- str_length(s2) # a single string length

  if (!all(l1 == l1[1])) stop("Different string lengths in s1.")

  l1 <- l1[1] # a single length now
  if (l1 != l2) stop("s2 has a different string length from s1.")

  vec <- character(l1 + l2)
  vec2 <- str_split(s2, "") %>% unlist()
  vec[(1:l2) * 2] <- vec2

  sapply(s1,
         function(s_i) {
           vec1_i <- str_split(s_i, "") %>% unlist()
           vec[(1:l1) * 2 - 1] <- vec1_i
           str_flatten(vec, "")
         },
         USE.NAMES = FALSE
         )
}
