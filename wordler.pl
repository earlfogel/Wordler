#!/usr/bin/perl
#
# wordler - a program that plays and solves Wordles
#
# Usage:
#
#     wordler.pl        - choose a random word
#     wordler.pl -today - use today's word
#     wordler.pl -1     - use yesterday's word (also -2, -3, etc.)
#     wordler.pl [word] - use the given word
#     wordler.pl [123]  - use the Nth word in the word list
#     wordler.pl -auto  - I solve the puzzle on my own
#     wordler.pl -debug - show debugging info
#
# The word list is based on Peter Norvig's work (https://norvig.com/ngrams/)
# with proper names, jargon and swear words removed.
#
# Earl Fogel, February 2022
use strict;
use warnings;

my $words = "./words";  # common words, used when we pick a word
my $dict = "./dict";  # more words, used to validate guesses
my $letters = "abcdefghijklmnopqrstuvwxyz";
my $maxguess = 6;
my $nguess = 0;
my $wordlen = 5;
my %all_words;
my @common_words;
my %possible_words;
my @correct;
my $answer;
my $day;
my $pattern = "";
my $me = 0;
my $you = 0;
my $auto = 0;
my $debug = 0;

# check for command-line options
while ($_ = $ARGV[0] and /^-/) {
    shift;
    /^-(\d+)$/ && ($day=$1);
    /^--?today$/ && ($day=0);
    /^--?auto/ && ($auto++);
    /^--?debug/ && ($debug++);
    #die "Invalid option $_";
}

setup();

print << "EOF" unless $auto;
Ok, I've picked a word.  Can you guess what it is?
If you don't know, press <Enter> and I'll guess for you.

EOF

while ($nguess < $maxguess) {
    $nguess++;
    my $guess = guess();
    my $result = check($guess);
    if ($result =~ /^[A-Z]+$/) {		# got it!
	if ($me and !$you) {
	    print "I did it!\n";
	} elsif ($you and $me) {
	    print "We did it!\n";
	} else {
	    print "Congratulations!\n";
	}
	exit;
    }
}
print "Sorry, the word was: $answer\n";

#
# on your mark, ...
#
sub setup {
    #
    # read the word lists
    #
    my $text = read_file($words);
    while ($text =~ /\b([a-z]{$wordlen})\b/g) {
	my $word = $1;
	push(@common_words,$word);
	$all_words{$word} = 2;  # prefer common words when we guess
    }
    $text = read_file($dict);
    while ($text =~ /\b([a-z]{$wordlen})\b/g) {
	my $word = $1;
	$all_words{$word}++;
    }
    %possible_words = %all_words;

    if (defined $day && -x "wordle.pl") {
	my $start = 18797;			# days since the epoch
	my $today = time - 60*60*6;		# time zone adjustment
	$today = int $today / (60*60*24);	# convert from seconds to days
	my $n = $today - $start - $day + 1;
	while ($n < 1) {			# wrap if too small
	    $n += scalar @common_words;
	}
	while ($n > scalar @common_words) {	# wrap if too large
	    $n -= scalar @common_words;
	}
	$answer = $common_words[$n-1];
    } elsif (exists $ARGV[0]) {
	if ($ARGV[0] =~ /^[a-z]{$wordlen}$/) {  # use the given word
	    $answer = $ARGV[0];
	    $possible_words{$answer} = 1;
	    $all_words{$answer} = 1;
	    #srand 1;
	} elsif ($ARGV[0] =~ /^(\d+)$/) {  # use the Nth word in the list
	    my $n = $1;
	    while ($n > scalar @common_words) {	# wrap if too large
		$n -= scalar @common_words;
	    }
	    $answer = $common_words[$n-1];
	} else {
	    print "Invalid word $ARGV[0]\n";
	    exit;
	}
	shift @ARGV;
    } else {  # we pick a word
	$answer = $common_words[int rand @common_words];
    }

    @correct = split //, $answer;
}


#
# next guess
#
sub guess {
    my $guess;
    my $try = "";

    while (!defined $guess) {
	print "guess $nguess: ";
	if (!$auto) {
	    $try = lc <>;
	}
	chomp $try;
	if (exists $all_words{$try}) {
	    $guess = $try;
	    $you++;
	} elsif ($try eq "") {     # ok, I'll pick
	    if (keys %possible_words < 1) {
		print "I give up\n";
		exit;
	    }
	    for (my $i=1; $i < 5; $i++) {
		$guess = (keys %possible_words)[int rand keys %possible_words];
		last if $possible_words{$guess} > 1;  # prefer common words
	    }
	    if ($auto) {
		print "$guess\n";
	    } else {
		print "I guess: $guess\n";
	    }
	    $me++;
	} else {  # invalid input, try again
	    print "remaining: $letters\n" if lc $try eq "abcde";
	    print "regex: $pattern\n" if lc $try eq "regex";
	}
    }
    return $guess;
}


{
my @p;	# an array of regular expressions, one for each letter in the word

#
# check a word
#
sub check {
    my ($guess) = @_;
    my $response;
    my $n = 0;

    if (!@p) {
	for (my $i=0; $i < $wordlen; $i++) {
	    $p[$i] = "[$letters]";
	}
    }

    foreach my $letter (split //, $guess) {
	if ($letter eq $correct[$n]) {	  # letter is in the right place
	    $response .= uc($letter);
	    $p[$n] = $letter;
	} elsif ($answer =~ /$letter/) {  # letter is in the word, but elsewhere
	    $response .= $letter;
	    $p[$n] =~ s/$letter//;
	    delete %possible_words{grep(!/$letter/, keys %possible_words)};
	} else {			  # letter is not in the word
	    $response .= '_';
	    map s/$letter//, @p;
	}
	$letters =~ s/$letter//;
	$n++;
    }
    #
    # remove any extra letters from response
    # (when a letter appears more times in a guess than in the solution)
    #
    for (my $i=$wordlen-1; $i >= 0; $i--) {
	my $char = substr($response,$i,1);
	if ($char =~ /[a-z]/) {  # lower-case letter
	    my $a_count = () = ($answer =~ /$char/g);    # count in answer
	    my $r_count = () = ($response =~ /$char/gi); # count in response
	    if ($r_count > $a_count) {
		substr($response,$i,1) = "_";
	    }
	}
    }
    print "         $response";
    $pattern = join('', '^', @p);
    delete %possible_words{grep(!/$pattern/, keys %possible_words)}; # remove impossibles
    if ($guess ne $answer) {
	delete $possible_words{$guess};	# remove this guess
	my $n = keys %possible_words;
	if ($n == 1) {
	    print "  " . $n . " word left";
	} elsif ($n <= 5 and $debug) {
	    print "  " . $n . " words left: ", join(' ', keys %possible_words);
	} elsif ($n > 0) {
	    print "  " . $n . " words left";
	}
    }
    print "\n";
    return $response;
}

}


#
# read a file into a string
#
sub read_file {
    my($fname) = @_;
    my($contents);
    local($/);  # read the entire file at one go
    local(*IN);

    die("Can't find file '$fname'")
        if ! -f $fname;
    open (IN,"$fname")
        or die("Can't read $fname: $!\n");
    $contents = <IN>;
    close(IN);
    return $contents;
}

