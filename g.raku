#!/usr/bin/raku

use lib '.';
use Gotoh;

sub MAIN(Str:D :u($u), Str:D :v($v), Real:D :sp($gap_start),
         Real:D :ep($gap_extend), Real:D :match_bonus($match_bonus)=0,
         Real:D :mismatch($mismatch), Int:D :debug($DEBUG)=0,
         Bool:D :s($stringify)=False, Bool:D :w($use_wikipedia)=True
        ) {
    my $g=Gotoh.new(u=>$u, v=>$v,
                    gap_start => $gap_start,
                    gap_extend => $gap_extend,
                    match_bonus => $match_bonus,
                    mismatch => $mismatch,
                    wikipedia => $use_wikipedia ?? 1 !! 0,
                    DEBUG => $DEBUG);
    say 'score: ',$g.score;
    say 'backtrace: ',$g.backtrace;
    if ($stringify) {
        say $g.backtrace_string;
    }
}
