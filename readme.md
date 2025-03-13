# R package 'reconstitution'

Please cite as:

Round, Erich R. (2025), reconsitution: Computer assisted reconstitution, R package version 0.1, https://github.com/erichround/reconstitution

If you use this package, I would welcome feedback to help improve it further.


## Conceptual overview

### Aims

Many early transcriptions of Australian Indigenous languages were made by amateurs, who attempted to render the words they heard using English spelling conventions. The fidelity of these transcriptions, as attempted records of the true words of the vernacular langauge, were impaired by two main factors. Firstly, the transcribers had little familiarity with the languages, meaning that they would not faithfully perceive the linguistic subtleties of the words they heard. This meant that what the transcribers were attempting to write down was already an unfaithful percept of the true words. Secondly, English spelling is notoriously inconsistent as a tool for turning speech sounds into letters, even for English itself, let alone for languages whose sets of speech sounds differ from those of English. Thus, transcribers were attempting transpose their unfaithful percepts of sounds into letters using a poor tool. 

The upshot of this two-layered distortion of speech sounds is that early transcriptions of Australian Indigenous languages are ambiguous. However, they can still be valuable and many linguists have worked on inferring what the orginal Indigenous language words might have been, which correspond to early transcriptions. Usually, this work is done manually, rather than with computational tools. And usually it is done expertly but informally, which is to say, it doesn't follow a strict process, and may not be reproducible. Finally, the aim of the work is usually to produced just one inferred form for a given word, even though it is very commonly the case that a transcript is compatible (to various degrees of probability) with multiple possible inferred forms. 

The aim of this software package is twofold. Firstly, it aims to help anyone who is interpretting early transcriptions to speed up their workflow. Secondly, it aims to make the workflow more explicit, reproducible, and documented. In doing so, it is inspired by previous scholarship on "reconsistitution" (Broadbent 1957, Dench 1999, Browne 2016, Anderson 2018, Bott 2018, Round 2018, Browne et al 2019).

The software implements a process of inferrence, and provides the output of the process. The details of the process can be controlled by the user. Essentially, the process runs two two-step process of the early transcribers in reverse. In step 1, we take a string of letters and divide it into its functional parts, called 'graphemes'. Often there are multiple, valid ways this can be carried out for a single string. In step 2, we take those functional parts and consider their possible sound values, called 'soundsets'. Likewise, there are often multiple valid ways to do this. By chaining the two steps together, we move from letters to graphemes to soundsets. As an additional step, we can also compare two transcriptions of the same word. Since any one transcription is usually consistent with many possible sound values, it can be helpful to compare multiple transcriptions and ask: which possible interpretations are shared by both transcriptions? This is a process we term 'reconciling'.

### Step 1 - from letters to graphemes

For each word, we start with a sequence of letters. The first step is to group that sequences into shorter substrings, called graphemes, which function as units. For instance, the substring of n followed by g, written \<ng\>, often functions as a unit in English spelling. So do \<ea\>, and \<ch\>. The substring \<ge\> can also be considered a grapheme since the letter g takes on a different likely sound value when followed by e. There is a text file called "graphemes.tsv" in the folder "input" which contains an inventory of all graphemes. The user can apply their expertise and experience to curate this list. The software will examine a data file containing transcriptions of words, and for each transcription, it will discover all possible subdivisions of that word into a string of the graphemes listed in "graphemes.tsv".

### Step 2 - from graphemes to soundsets

The file "graphemes.tsv" also records all of the soundsets that are associated with each grapheme. In the "graphemes.tsv" file, each soundset is represented by a single-character label, such as "V" for the set of vowels, or "p" for the labial stop. The notion of a soundset is a set of similar sounds, all of which could be what the grapheme was intended to represent. These individual sounds, which make up a soundset are stated in the file "soundsets.tsv". To take an example of how we can relate graphemes to soundsets to individual sounds: the grapheme \<i\>, might correspond to vowel sound i (IPA i) or the consonant sound y (IPA j). Since these are similar sounds, we group them in a soundset and give it a single-character label, in this case "Y". In "graphemes.tsv", one of the rows states that grapheme \<i\> corresponds to soundset "Y". In "soundsets.tsv" it states that soundset "Y" corresponds to the individual IPA sounds i,j. Soundsets are intended to be an informal, practical device. The user is free to define them in whatever way works best. The files "graphemes.tsv" and "soundsets.tsv" which are provided with the software package provide a starting point, and are intended to be edited as the user sees fit. The versions of these files provided with the software package reflect a relativesly miminal approach: they uses only three vowel qualities (i,a,u), and make no distinctions for vowel length or stop voicing. They proceeds from the idea that the sounds in a soundset are, roughly, percepts in the minds of early transcribers, not the actual sounds of the Indigenous languages. Correspondingly, we've kept the total inventory rather small. For instance, though many Indigenous languages of Australia distingish a dental nasal (IPA n̪) from the alveolar nasal (IPA n), we expect that early transcribers would not have noticed the difference, as so we only use n, not n̪. However, the user is free to apply whatever principles are found to work.

Some other points are:
- Many graphemes correspond not to just one soundset, but to a sequence of soundsets. For instance, \<gi\> can correspond to a palatal stop followed by a high vowel. Thus, in the soundset column of "graphemes.tsv", we often want to specify that a grapheme corresponds to a sequence of soundsets. This is done by writing a sequence single-character soundset labels, e.g. in this case, "ci".
- Graphemes might also be associated with multiple, alternative sound values. For instance \<ng\> could correspond to the velar nasal soundset "ŋ", or the palatal nasal soundset "ɲ", or the sequence of velar soundsets "ŋk". To handle cases like this, each alternative is written on a separate line of "graphemes.tsv".
- We use the hash symbol # to indicate the edge of a word. For instance, the grapheme \<le#\> refers the letter l then e at the end of the word. In transciptions, we find that it can corresponds to any vowel followed by a l sound, and we would write this sequence of soundsets as "Vl#".

The software, after having found all ways to divide a word into graphemes, will then find all ways to convert those strings of graphemes into sequences of soundsets. This results will be saved as a file "soundset_parse.tsv" in the folder "output". Typically, each word will have been associated with multiple possible parses.

### Step 3 - reconciling two transcibers

As a final step, we can take the analysis of two sets of transcriptions, and try to reconcile them. The software attempts to line up the graphemes and soundsets in the two transcribers' versions of a word (a process called "alignment"), and then it looks at the aligned soundsets and attempts to reconcile them. For instance, suppose that it aligns soundset "V" in transcription #1 with soundset "a" in transcription #2. The only sound value which is supported by both transcriptions in this case is "a", and so the reconciliation is "a". For a given word, the software repeats this process by aligning every possible parse of transcription #1 with every possible parse of transcription #2. For many of these alignments, it is not actually possible to arrive at a full reconciliation. For instance, if a soundset "a" is aligned with "i", then there is no sound value in common. This is useful. Since a single word may have many dozens of alignments, the process of reconciling them helps us to find the relatively few interpretations of the transciptions which are mutually consistent. The software also takes note of how similar or dissimilar the aligned sounds are, and produces a score for each alignment. The results are recorded in two ways. First, a user-friendly file "reconstitution_report.txt" is saved in the folder "output". This is meant to be easily readable, and for each word it reports the five best alignments (or, if more than five are fully reconciled, then it reports all of the fully reconciled alignments). Another file, "report_data.tsv" in folder "output" provides a full report table, but is less easy to read.

## How to use the software

We assume a basic ability to use R, to install the software package and edit text files. Here we just describe the key work processes.

### Input files

Input files are text files in "tab separated values" (tsv) format.

In the "input" folder you will find the files "graphemes.tsv" and "soundssets.tsv" described above. Edit these in order to change how the software groups letters into graphemes, or how it converts graphemes into soundsets. The "input" folder also includes the files:
- graphotactic_exclusions.tsv
- soundset_alignment_classes.tsv
- Blake_transcription1.tsv
- Blake_transcription2.tsv

The file "graphotactic_exclusions.tsv" is a list of sequences of graphemes that stated to be implausible. Thus, even if a word could notionally be divided up in such a way that it includes these sequences of graphemes, it will not be. Adding to this list is a handy way of cutting down on the production of nuisance graphemic analyses, which are implausible.

When two words are aligned, in preparation for reconciliation, the alignment process pays attention to how similar two soundsets are, in order to determine how to plausibly align them. The file "soundset_alignment_classes.tsv" contains a short list of broad classes of soundsets. These classes are used during alignment. If you define a new soundset and add it to "graphemes.tsv" and "soundssets.tsv", then consider adding also in "soundset_alignment_classes.tsv", so the alignment process knows what it is broadly similar to.

The files "Blake_transcription1.tsv" and "Blake_transcription2.tsv" provide a list of transcribed words from Blake's 2003 study of Bunganditj, each by a different transcriber. They can be useful raw materials for testing out any changes that you make to "graphemes.tsv" and "soundssets.tsv". They also illustrate the required form for input data: two columns called "ID" and "transcription". On each row, the ID column must contain a unique identifier. This will be essential whenever you want to align the same word for two transcribers. This is done by taking one file for each transcriber, and across those files, any pair of words to be aligned will share their identifier.

### Running analyses

The code to run an analysis has been kept maximally simple. To analyse transcriptions by a single transcriber, place them in a file in the "input" folder, following the format like "Blake_transcription1.tsv" and "Blake_transcription2.tsv". For instance, suppose this transcription file is called "my_transcriptions.tsv". The code to analyse it is:

```
process_transcription(file.path("input", "my_transcriptions.tsv"))
```

This will initiate two steps. The first is a checking step. The software will examine the files in your input folder: "graphemes.tsv", "soundssets.tsv", "graphotactic_exclusions.tsv", "soundset_alignment_classes.tsv" as well as the file you nominated, "my_transcriptions.tsv". If it finds any problems, it will report them to you and halt. If no problems are found, it will process the transcriptions and save the result in the file "soundset_parse.tsv" in the "output" folder.

To align and reconcile two transcribers, you will first need to process the two individual transcription files. For instance, here we process "Blake_transcription1.tsv" and "Blake_transcription2.tsv", renaming the resulting file in each case:

```
process_transcription(file.path("input", "Blake_transcription1.tsv"))
file.rename(file.path("output", "soundset_parse.tsv"), file.path("output", "soundset_parse1.tsv"))
process_transcription(file.path("input", "Blake_transcription2.tsv"))
file.rename(file.path("output", "soundset_parse.tsv"), file.path("output", "soundset_parse2.tsv"))
```

Now we have two individual results files "soundset_parse1.tsv" and "soundset_parse2.tsv" in the "output" folder. The code to align and reconcile them is:

```
align_and_report(oundset_file1 = file.path("output", "soundset_parse1.tsv"), soundset_file2 = file.path("output", "soundset_parse2.tsv"))
```

Again, this will first run checks and then will produce the analysis. A user-friendly version appears with the name "reconstitution_report.txt", and a full versions with the name "report_data.tsv", both in the "output" folder.

## References

Anderson, Rachael (2018). Computationally Assisted Interlanguage Reconstitution. Unpublished ms.

Blake, Barry (2003). The Bunganditj (Buwandik) language of the Mount Gambier Region. Canberra: Pacific Linguistics

Bott, Thomas (2018). Towards Automation in Reconstitution. Unpublished ms.

Broadbent, Sylvia (1957). Rumsen I: Methods of Reconstitution. International Journal of American Linguistics, 23(4), 275-280.

Browne, Mitchell (2016). When Only Words Remain: Testing a Method of ‘Comparative Reconstitution’ in Ngarluma. Honours thesis, University of Western Australia.

Browne, Mitchell, Rachael Anderson, Edith Kirlew, Thomas Bott, and Erich R. Round. (2019). 'Comparative Reconstitution: Using and Automating the Historical-Comparative Method to Interpret Historical Language Sources'. Presented at the Historical-Comparative Linguistics for Language Revitalization, University of California, Davis, July 1.

Dench, Alan (1999). Comparative Reconstitution. In J. C. Smith, & D. Bentley, Selected papers from the 12th International Conference of Historical Linguistics (pp. 57-72). Manchester: John Benjamins.

Round, Erich R. (2018). Computationally assisted vocabulary reconstitution from amateur wordlists. Unpublished ms.






