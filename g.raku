#!/usr/bin/raku

use lib '.';
use Gotoh;

sub MAIN(Str:D :u($u), Str:D :v($v), Real:D :sp($gap_start),
         Real:D :ep($gap_extend), Real:D :match_bonus($match_bonus),
         Real:D :mismatch($mismatch),
         Int:D :debug($DEBUG)=0
        ) {
    my $g=Gotoh.new(u=>$u, v=>$v,
                    gap_start => $gap_start,
                    gap_extend => $gap_extend,
                    match_bonus => $match_bonus,
                    mismatch => $mismatch,
                    DEBUG => $DEBUG);
    say 'score: ',$g.score;
    say 'backtrace: ',$g.backtrace, $g.backtrace_string;
}
