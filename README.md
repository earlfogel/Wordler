# Wordler

## Introduction

Wordler is a perl script that uses regular expressions to solve Wordle-like puzzles.

The game comes with two word lists:

* 'words' is a list of common 5 letter words.  Each time you run it, the
  program picks a random word from this list for you to guess.

* 'dict' is a more complete word list, used to make sure that all guesses
  are actual words.

These lists are based on Peter Norvig's work (https://norvig.com/ngrams/)
with some manual editing.


## Game Play

Run 'wordler.pl' from the command line.  E.g.

    $ wordler.pl
    Ok, I've picked a word.  Can you guess what it is?
    If you don't know, press <Enter> and I'll guess for you.

    guess 1: train
	     __A__  263 words left
    guess 2: shape
	     __ApE  4 words left
    guess 3: 
    I guess: peace
	     P_ACE  1 word left
    guess 4: place
	     PLACE
    We did it!

The program replies to each guess with a series of upper and lower-case
letters and underscores.  In the example above, the uppercase 'A' after the
first guess indicates that that letter is correct.  The '\_\_ApE' after the
second guess shows that 'A' and 'E' are in those places in the answer, and
'p' exists somewhere else in the word.

Note that instead of making a third guess, the user pressed 'Enter', so
the program guessed for them.


## The Solver

Wordler uses the clues gleaned from each guess to build a regular
expression, which is then used to filter the word list, leaving only
words that match the pattern.

In the example above, after the second guess we know the third and fifth
letters are 'a' and 'e', we know that 'p' is either the first or second
letter, and we know that the word does not contain 't', 'r', 'i', 'n', 's'
or 'h'.  We encode this information into a regular expression use it to
filter the word list.

So, each guess shrinks the word list, making future guesses more accurate.


## Command Line Options

Each time you run Wordler, it chooses a word at random for you to guess.
You can change this with command-line options, i.e.:

    wordler.pl -today  - choose a new word each day
    wordler.pl -1      - solve yesterday's word (also -2, -3, etc.)
    wordler.pl <abcde> - use the given word
    wordler.pl <12345> - use the Nth word in the word list
    
If you replace the included 'words' file with the actual Wordle wordlist,
then you can run 'wordler.pl -today' to use the same word that Wordle does.

