#!/usr/bin/raku

use lib '.';
use Gotoh-simple;
use Test;

sub gotoh_score(Str:D :u($u), Str:D :v($v), Real:D :sp($gap_start),
                Real:D :ep($gap_extend), Real:D :match($match_bonus),
                Real:D :mismatch($mismatch),
                Int:D :debug($DEBUG) =0
               ) {
    my $g=Gotoh-simple.new(u=>$u, v=>$v,
                    gap_start => $gap_start,
                    gap_extend => $gap_extend,
                    match_bonus => $match_bonus,
                    mismatch => $mismatch,
                    DEBUG => $DEBUG);
    return $g.score;
}

plan 8;

#is l('foo','foo'),0,'foo-foo=0';
is gotoh_score(u=>'foo',v=>'foo', sp=>-3, ep=>-1, match=>0, mismatch=>0),0,
'foo==foo, sp=>-3, ep=>-1, match=>0, mismatch=>0';

is gotoh_score(u=>'foo',v=>'fox', sp=>-3, ep=>-1, match=>0, mismatch=>-1),-1,
'foo/fox sp=>-3, ep=>-1, match=>0, mismatch=>-1';

is gotoh_score(u=>'foaaaao',v=>'foo', sp=>-3, ep=>-1, match=>0, mismatch=>-1),-6,
'foaaaao/foo sp=>-3, ep=>-1, match=>0, mismatch=>-1';

is gotoh_score(u=>'foaaaao',v=>'foxxxxo', sp=>-3, ep=>-1, match=>0, mismatch=>-1),-4,
'foaaaao/foxxxxo sp=>-3, ep=>-1, match=>0, mismatch=>-1, uses 4*mm : -4';

is gotoh_score(u=>'foaaaao',v=>'foxxxxo', sp=>-1, ep=>-1, match=>0, mismatch=>-2),-8,
'foaaaao/foxxxxo sp=>-1, ep=>-1, match=>0, mismatch=>-2, uses 4*mm: -8';

is gotoh_score(u=>'foaaaao',v=>'foxxaao', sp=>-1, ep=>-1, match=>0, mismatch=>-2),-4,
'foaaaao/foxxaao sp=>-1, ep=>-1, match=>0, mismatch=>-2, uses 2*mm: -4';

is gotoh_score(u=>'foaaaao',v=>'foxxaao', sp=>-1, ep=>-1, match=>0, mismatch=>-5),-4,
'foaaaao/foxxaao sp=>-1, ep=>-1, match=>0, mismatch=>-5, uses 2*(sp+ep): -4';

is gotoh_score(u=>'foaaaao',v=>'foxxaao', sp=>-1, ep=>-0.1, match=>0, mismatch=>-5),-2.2,
'foaaaao/foxxaao sp=>-1, ep=>-0.1, match=>0, mismatch=>-5, uses 2*(sp+ep): -2.2';
