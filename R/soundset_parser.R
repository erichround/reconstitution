# Soundset parser

add_soundsets = function(
    graphemic_parse = load_graphemic_parse(),
    save_result = TRUE
) {

  df <-
    graphemic_parse %>%
    select(ID, graphemic) %>%
    mutate(soundset = graphemes_to_soundsets(graphemic) %>% str_split("/")) %>%
    unnest(soundset) %>%
    left_join(graphemic_parse, ., by = c("ID", "graphemic"))

  if (save_result) { write_tsv(df, file.path("output", "soundset_parse.tsv")) }
  invisible(df)
}


graphemes_to_soundsets = function(
    gparses # A vector of period-delimited strings containing graphemic parses
) {

  graphemes = load_graphemes()
  legal_g <- unique(graphemes$grapheme)

  sapply(
    gparses, # Go through each string, g_i, in gparses
    function(g_i) {
      if (g_i == "---") return("---")
      # For each grapheme in g_i, get the set of possible parses
      graphemes_i <- str_split(g_i, "\\.") %>% unlist()
      parses_list <-
        lapply(
          graphemes_i,
          function(g_j) {
            if (!g_j %in% legal_g) {
              stop(str_c("Grapheme ", g_j, " is not recognised."))
            }
            filter(graphemes, grapheme == g_j)$soundsets
          })
      # Create a vector of all possible passes which this entails
      parses_i <-
        expand.grid(parses_list, stringsAsFactors = FALSE) %>%
        apply(MARGIN = 1, function(s) str_flatten(s, "."))
      # Convert the vector to comma delimited list
      str_flatten(parses_i, "/")
    },
    USE.NAMES = FALSE
  )

}


reconcile_soundsets = function(s1, s2) {

  soundsets <- load_soundsets()
  sets <- c(soundsets$members, "⋅", ".")
  names(sets) <- c(soundsets$soundset, "⋅", ".")

  delim_indel <- c("z", "x", "⋅")
  delim <- c("z", "x")
  dot_indel <- c(".", "⋅")

  sapply(
    1:length(s1),
    function(i) {
      sh1 <- s1[i] %>% str_remove_all("^Z|Z$") %>% str_split("") %>% unlist()
      sh2 <- s2[i] %>% str_remove_all("^Z|Z$") %>% str_split("") %>% unlist()
      ss1 <- sets[sh1]
      ss2 <- sets[sh2]
      if (any(is.na(ss1))) {
        stop(str_c("Unrecognised shorthand: ",
                   str_flatten(unique(sh1[is.na(ss1)]))))
      }
      if (any(is.na(ss2))) {
        stop(str_c("Unrecognised shorthand: ",
                   str_flatten(unique(sh2[is.na(ss2)]))))
      }
      l1 <- str_length(ss1)
      l2 <- str_length(ss2)

      sapply(1:length(ss1),
             function(j) {
               set1 <- ss1[j]
               set2 <- ss2[j]
               if (sh1[j] %in% delim_indel & sh2[j] %in% delim_indel) return("⋅")
               if (set1 == "." & set2 == ".") return(".")
               if (set1 %in% dot_indel & set2 %in% dot_indel) return("…")
               if (set1 == set2 & l1[j] == 1) return(set1)
               if (l1[j] == 1 & l2[j] == 1) return("?")
               recon <- intersect(str_split(set1, ",") %>% unlist(),
                                  str_split(set2, ",") %>% unlist())
               if (length(recon) == 0) return("?")
               if (length(recon) == 1) return(recon)
               recon <- str_flatten(sort(recon), ",")
               if (recon %in% sets) recon <- names(sets)[sets == recon][1]
             },
             USE.NAMES = FALSE
      ) %>% str_flatten()
    },
    USE.NAMES = FALSE
  )
}
