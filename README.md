# Wordler

## Introduction

Wordler is a perl script that uses regular expressions to solve Wordle-like puzzles.

The game comes with two word lists:

* 'words' is a list of common 5 letter words.  Each time you run it, the
  program picks a random word from this list for you to guess.

* 'dict' is a more complete word list, used to make sure that all guesses
  are actual words.

## Game Play

Run 'wordler.pl' from the command line.  E.g.

    $ wordler.pl
    Ok, I've picked a word.  Can you guess what it is?
    If you don't know, press <Enter> and I'll guess for you.

    guess 1: train
	     __A__  263 words left
    guess 2: shape
	     __ApE  4 words left
    guess 3: aware
	     __A_E  3 words left
    guess 4:
    I guess: place
	     PLACE
    We did it!

## Behind the Scenes

Wordler
