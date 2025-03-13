# Checks of inputs

load_graphemes = function() {
  read_tsv(file.path("input", "graphemes.tsv"),
           col_types = "cc")
}

load_soundsets = function() {
  read_tsv(file.path("input", "soundsets.tsv"),
           col_types = "cc")
}

load_graphotactic_exclusions = function() {
  read_tsv(file.path("input", "graphotactic_exclusions.tsv"),
           col_types = "c")
}

load_graphemic_parse = function() {
  read_tsv(file.path("output", "graphemic_parse.tsv"),
           col_types = "ccccc")
}

load_soundset_parse = function() {
  read_tsv(file.path("output", "soundset_parse.tsv"),
           col_types = "ccccccc")
}

load_aligned_parse = function() {
  read_tsv(file.path("output", "aligned_parse.tsv"),
           col_types = "cccccccccn")
}

load_reconciled_parse = function() {
  read_tsv(file.path("output", "reconciled_parse.tsv"),
           col_types = "cccccccccncl")
}


check_inputs = function(
    transcription_file = file.path("input", "transcriptions.tsv")
) {
  okay <-
    (if (is.null(transcription_file)) {
      TRUE
    } else {
      check_transcription_file(transcription_file)
    }) &
    check_graphemes() &
    check_graphotactics() &
    check_soundsets()
  if (!okay) stop(str_c("One or more checks of the input files failed. See ",
                        "the warning messages for details."))
  TRUE
}


check_transcription_file = function(
    transcription_file = file.path("input", "transcriptions.tsv"),
    graphemes_file = file.path("input", "graphemes.tsv")
) {

  tr <- read_tsv(transcription_file, show_col_types = FALSE)
  gr <- read_tsv(graphemes_file, show_col_types = FALSE)

  # Check for non-unique IDs
  bad_IDs <-
    tr %>% count(ID) %>%
    filter(n > 1) %>% .$ID %>% str_flatten(", ")
  if (str_length(bad_IDs) > 0) {
    msg <- str_c("The ID of each transciption pair should be unique. ",
                 "This isn't true for: ", bad_IDs, ".")
    warning(msg)
  }

  # Check for characters not found in any grapheme
  good_chars <- gr$grapheme %>% str_split("") %>% unlist() %>% unique()
  tr_chars <- tr$transcription %>% str_split("") %>% unlist() %>% unique()
  bad_chars <- setdiff(tr_chars, good_chars) %>% str_flatten(", ")
  if (str_length(bad_chars) > 0) {
    msg <- str_c("The transcription column of the transcription file ",
                 "contains one or more characters that are not found in ",
                 "any grapheme:", bad_chars, ".")
    warning(msg)
    return(FALSE)
  }
  TRUE
}


check_graphemes = function(
    graphemes_file = file.path("input", "graphemes.tsv"),
    soundsets_file = file.path("input", "soundsets.tsv")
) {

  gr <- read_tsv(graphemes_file, show_col_types = FALSE)
  ss <- read_tsv(soundsets_file, show_col_types = FALSE)
  ssets_g <- gr$soundsets %>% str_split("") %>% unlist() %>% unique()
  ssets_s <- ss$soundset %>% str_split("") %>% unlist() %>% unique()

  bad_sets <- setdiff(ssets_g, ssets_s) %>% str_flatten(", ")
  if (str_length(bad_sets) > 0) {
    msg <- str_c("The soundsets column of the graphemes file contains ",
                 "one or more sets that are not defined in the ",
                 "soundsets file: ", bad_sets, ".")
    warning(msg)
    return(FALSE)
  }
  TRUE
}


check_graphotactics = function(
    graphemes_file = file.path("input", "graphemes.tsv"),
    tactics_file = file.path("input", "graphotactic_exclusions.tsv")
) {

  gr <- read_tsv(graphemes_file, show_col_types = FALSE)
  ta <- read_tsv(tactics_file, show_col_types = FALSE)

  graphemes_gr <- gr$grapheme %>% unique()
  graphemes_ta <- ta$exclude %>% str_split(".") %>% unlist() %>% unique()

  odd_graphemes <- setdiff(graphemes_ta, graphemes_gr) %>% str_flatten(", ")
  if (str_length(odd_graphemes) > 0) {
    msg <- str_c("The file of graphotactic exclusions refers to one or more ",
                 "graphemes that aren't defined in the graphemes file: ",
                 odd_graphemes, ". Did you mean to refer to something else?")
    warning(msg)
    # Note: this oddity doesn't cause any actual problems, so the check always
    # passes as TRUE.
  }
  TRUE
}


check_soundsets = function(
    soundsets_file = file.path("input", "soundsets.tsv"),
    classes_file = file.path("input", "soundset_alignment_classes.tsv")
) {

  ss <- read_tsv(soundsets_file, show_col_types = FALSE)
  cl <- read_tsv(classes_file, show_col_types = FALSE)

  # Check for duplicate definitions of a set
  sets <- ss$soundset
  bad_sets <- sets[duplicated(sets)] %>% str_flatten(", ")
  if (str_length(bad_sets) > 0) {
    msg <- str_c("The soundsets file defines one or more sets more ",
                 "than once: ", bad_sets, ".")
    warning(msg)
    return(FALSE)
  }

  # Check for duplicate memberships
  ss_dups <-
    ss %>%
    rowwise() %>%
    mutate(members_sorted =
             unlist(str_split(members, ",")) %>%
             sort() %>% str_flatten(",")) %>%
    group_by(members_sorted) %>%
    mutate(n = n()) %>%
    filter(n > 1)

  if (nrow(ss_dups) > 0) {
    bad_sets = ss$soundset %>% str_flatten(", ")
    msg <- str_c("The soundsets file assigns the same membership to ",
                 "multiple soundsets. Each soundset should have a ",
                 "distinct membership. Check these: ", bad_sets, ".")
    warning(msg)
    return(FALSE)
  }

  # Check for classes with undefined soundsets
  sets_cl <- cl$members %>% str_split("") %>% unlist() %>% unique()
  bad_sets <- setdiff(sets_cl, sets) %>% str_flatten(", ")
  if (str_length(bad_sets) > 0) {
    msg <- str_c("The members columns of the soundset_alignment_classes file ",
                 "refers to one or more soundsets that aren't defined in the ",
                 "soundsets files: ", bad_sets, ".")
    warning(msg)
    return(FALSE)
  }
  TRUE
}
