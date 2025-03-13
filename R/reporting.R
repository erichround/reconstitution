# Report writing

prepare_report = function(
    reconciled_parse = load_reconciled_parse(),
    report_file = file.path("output", "reconstitution_report.txt"),
    save_result = TRUE
) {

  # The task here is to align the two transcriptions (in their graphemic
  # delimitation) and the two soundset representations. The unit of alignment is
  # essentially the grapheme. Graphemes are delimited in all the representations
  # by a period. However, graphemes aren't always in 1:1 correspondence across
  # the two words, so the unit of alignment isn't exactly the grapheme but
  # rather what I'll call the "piece". For a given word, sometimes a graphemes
  # will correspond to multiple pieces. And sometimes, a piece will correspond
  # to no grapheme at all, but just to an alignment gap "⋅".

  df <-
    reconciled_parse %>%
    mutate(report_line1 = "", report_line2 = "", report_line3 = "",
           report_line4 = "", report_line5 = "") %>%
    group_by(ID) %>%
    mutate(n = n(), this_row = row_number(), rows_left = n - this_row)

  for (i in 1:nrow(df)) {

    # Places where one word has a grapheme break "." while the other doesn't
    # will show up in the aligned forms: one will have "." where the other has
    # "⋅". In the reconciliation, this is marked as an ellipsis "…". Here, we
    # first need to work out, for each ellipsis, which of the two forms has "."
    # and which has "-".

    # Find the positions of all boundaries between pieces, whether they're also
    # grapheme boundaries or not. These positions are shared across the
    # reconciliation (where they're already directly observable as "…") and the
    # two alignments
    rec <- df$reconciliation[i]
    rec_chars <- rec %>% str_split("") %>% unlist()
    all_split_pos <- which(rec_chars %in% c(".", "…"))

    # Find positions in alignment1 which are semi-splits, i.e., a piece boundary
    # but not a grapheme boundary. Mark them as "…" in place of the current "⋅"
    al1 <- df$aligned1[i]
    al1_chars <- al1 %>% str_split("") %>% unlist()
    al1_semi_split_pos <- all_split_pos[which(al1_chars[all_split_pos] == "⋅")]
    if (length(al1_semi_split_pos) > 0) {
      for (j in al1_semi_split_pos) {
        al1 <- str_c(str_sub(al1, 1, j-1), "…", str_sub(al1, j+1, -1))
      }
    }

    # Same for alignment2
    al2 <- df$aligned2[i]
    al2_chars <- al2 %>% str_split("") %>% unlist()
    al2_semi_split_pos <- all_split_pos[which(al2_chars[all_split_pos] == "⋅")]
    if (length(al2_semi_split_pos) > 0) {
      for (j in al2_semi_split_pos) {
        al2 <- str_c(str_sub(al2, 1, j-1), "…", str_sub(al2, j+1, -1))
      }
    }

    # Split the alignments into pieces by breaking them immediately before a
    # piece delimiter (i.e., "." or "…"). This means that a piece will appear in
    # its own string, together with the piece-delimiter on its left.
    #
    # However, before doing that, ensure we can distinguish between different
    # cases of semi-splits: (1) gap-split-grapheme; (2) grapheme-split-gap; (3)
    # grapheme-across-a-split. In case (1) we'll want the eventual display to
    # show a grapheme-sized gap then a split then a grapheme. In case (2) we'll
    # want the eventual display to show a grapheme then a split then a
    # grapheme-sized gap In case (3) we'll want to place a bracket around the
    # split-up parts of the grapheme. Note that grapheme-sized gaps are
    # different to the usual alignment gap, which is a gap at the level of
    # soundsets.

    # Place a special grapheme-gap sign "⨀" in positions where it belongs, and
    # remove the "…" next to it. This mean that the only semi-splits "…" that
    # remain are those which are straddled by parts of a single grapheme. Then
    # split alignment1 and alignment1 into pieces, keeping the piece together
    # with its left-side boundary.
    al1_pce <-
      al1 %>%
      # change gap to grapheme-gap if bordered on either side by semi-split
      str_replace_all("(?<=\\.|…)⋅+(?=…)", "⨀") %>%
      str_replace_all("(?<=…)⋅+(?=\\.|…)", "⨀") %>%
      # change semi-split to grapheme split if separated from another grapheme
      # split only by ⨀ or ⨀…⨀…⨀...
      str_replace_all("(?<=\\.(⨀…){0,9}⨀)…", ".") %>%
      str_replace_all("…(?=⨀(…⨀){0,9}\\.)", ".") %>%
      # split
      str_split("(?=(\\.|…))") %>% unlist()
    al2_pce <-
      al2 %>%
      str_replace_all("(?<=\\.|…)⋅+(?=…)", "⨀") %>%
      str_replace_all("(?<=…)⋅+(?=\\.|…)", "⨀") %>%
      str_replace_all("(?<=\\.(⨀…){0,9}⨀)…", ".") %>%
      str_replace_all("…(?=⨀(…⨀){0,9}\\.)", ".") %>%
      str_split("(?=(\\.|…))") %>% unlist()

    # Split graphemic1 in graphemes. Then slot them into a template based on
    # alignment1, such that the graphemes can go in slots not occupied by a
    # grapheme gap, nor into a slot whose left-hand boundary is "…" -- which is
    # to say, graphemes that straddle a semi-split will get placed in placed in
    # the leftmost piece that they straddle.
    g1 <- df$graphemic1[i]
    g1_graphemes <- g1 %>% str_split("\\.") %>% unlist()
    # Create the template: a vector with all elements empty except those which
    # block the placement of a grapheme in them
    g1_pce <- al1_pce %>% str_remove_all("[^…⨀]") %>% str_replace("…⨀", "…")
    is_blocked <- str_length(g1_pce) > 0
    # Place the graphemes is non-blocked slots
    g1_pce[!is_blocked] <- g1_graphemes
    # Do bracketing of straddling graphemes
    is_continuation <- g1_pce == "…"
    is_span_start <- !is_continuation & lead(is_continuation, default = F)
    is_span_end <- is_continuation & lead(!is_continuation, default = F)
    g1_pce[is_span_start] <- str_c("(", g1_pce[is_span_start])
    g1_pce[is_span_end] <- "…)"
    # Remove special symbols
    g1_pce <-
      g1_pce %>% str_replace("⨀", "⋅") %>%
      str_c(" ", .) %>% str_replace("^ \\(", "(")
    al1_pce <-
      al1_pce %>% str_remove("\\.|…") %>% str_replace("⨀", "⋅") %>%
      str_c(" ", .)

    # Same for graphemic2
    g2 <- df$graphemic2[i]
    g2_graphemes <- g2 %>% str_split("\\.") %>% unlist()
    g2_pce <- al2_pce %>% str_remove_all("[^…⨀]") %>% str_replace("…⨀", "…")
    is_blocked <- str_length(g2_pce) > 0
    g2_pce[!is_blocked] <- g2_graphemes
    # Do bracketing of straddling graphemes
    is_continuation <- g2_pce == "…"
    is_span_start <- !is_continuation & lead(is_continuation, default = F)
    is_span_end <- is_continuation & lead(!is_continuation, default = F)
    g2_pce[is_span_start] <- str_c("(", g2_pce[is_span_start])
    g2_pce[is_span_end] <- "…)"
    # Remove special symbols
    g2_pce <-
      g2_pce %>% str_replace("⨀", "⋅") %>%
      str_c(" ", .) %>% str_replace("^ \\(", "(")
    al2_pce <-
      al2_pce %>% str_remove("\\.|…") %>% str_replace("⨀", "⋅") %>%
      str_c(" ", .)

    rec_pce <- rec %>% str_split("\\.|…") %>% unlist() %>% str_c(" ", .)
    df$report_line1[i] <-
      str_c("Transcript as graphemes 1: ",
            str_flatten(str_pad(g1_pce, width = 7, side = "right")))
    df$report_line2[i] <-
      str_c("                        2: ",
            str_flatten(str_pad(g2_pce, width = 7, side = "right")))
    df$report_line3[i] <-
      str_c("Soundsets in shorthand  1: ",
            str_flatten(str_pad(al1_pce, width = 7, side = "right")))
    df$report_line4[i] <-
      str_c("                        2: ",
            str_flatten(str_pad(al2_pce, width = 7, side = "right")))
    df$report_line5[i] <-
      str_c("Reconciliation:            ",
            str_flatten(str_pad(rec_pce, width = 7, side = "right")))

  }

  # Start writing the report file, beginning with its header
  write_initial_header(report_file, "Reconstitution automated alignments")

  # Now we'll work through row-by-row of the original data. Recall, each of these
  # rows corresponds to one pair of orthographic forms.
  skip_ID <- NA
  prev_ID <- NA
  for(i in 1:nrow(df)) {

    if (!is.na(skip_ID)) if (df$ID[i] == skip_ID) next

    if (is.na(prev_ID) | prev_ID != df$ID[i]) {
      # Write a sub-header to the report file
      write_line(report_file, text = "\n")
      write_line(report_file)
      write_line(report_file, str_c("ID: ", df$ID[i]))
      write_line(report_file)
    }

    write_line(report_file, str_c("Fully reconciled: ", df$is_fully_reconciled[i]))
    write_line(report_file, str_c("Score: ", df$score[i]))
    write_line(report_file, text = " ")
    write_line(report_file, df$report_line1[i])
    write_line(report_file, df$report_line2[i])
    write_line(report_file, text = " ")
    write_line(report_file, df$report_line3[i])
    write_line(report_file, df$report_line4[i])
    write_line(report_file, text = " ")
    write_line(report_file, df$report_line5[i])
    write_line(report_file, text = " ")
    write_line(report_file)
    if (!df$is_fully_reconciled[i] & df$this_row[i] > 4 & df$rows_left[i] > 0) {
      write_line(report_file,
                 str_c("Skipping ", df$rows_left[i], " more unreconciled ",
                       "parses with lower scores..."))
      skip_ID <- df$ID[i]
    }
    prev_ID <- df$ID[i]
  }

  df <- df %>% select(-n, -this_row, -rows_left)

  if (save_result) { write_tsv(df, file.path("output", "report_data.tsv")) }
  invisible(df)
}


write_initial_header = function(outfile, text = "Report") {
  write_line(outfile, append = FALSE)
  write_line(outfile, text = text)
  write_line(outfile)
}


write_line = function(outfile, text = str_dup("=", 80), append = TRUE) {
  write.table(text, file = outfile, row.names = FALSE,
              col.names = FALSE, append = append, quote = FALSE)
}


