# Raku implementation of the Gotoh algorithm for string comparison
# Description: https://de.wikipedia.org/wiki/Gotoh-Algorithmus
# Unfortunately no english page is available.

# All parameters are signed, i.e. penalties (gap_start, gap_extend, mismatch)
# should be entered as negative numbers (match_bonus is probably positive or zero).

class Gotoh-simple {
    has $!u is required is built; # input strings u,v
    has $!v is required is built;
    has $!m; # length of u
    has @!U; # bytes of u
    has $!n; # length of v
    has @!V; # bytes of v
    has $.distance is rw;
    has @!A; # substitutions
    has @!B; # deletions (i.e. present in u, missing in v)
    has @!C; # insertions
    has $.DEBUG=0;
    has Real $.gap_start is required;
    has Real $.gap_extend is required;
    has Real $.match_bonus is required;
    has Real $.mismatch is required;
    has Real $.score is rw;
    method g(Int $l --> Real) { $!gap_start+($l-1)*$!gap_extend; };
    submethod TWEAK() {
        $!m=$!u.chars; $!n=$!v.chars;
        @!U=$!u.ords;  @!V=$!v.ords;
        $!score=-Inf;
        self.preparematrix;
        self.computematrix;
    }
    method preparematrix() {
        @!A=[0 xx $!n+1] xx $!m+1;
        @!B=[0 xx $!n+1] xx $!m+1;
        @!C=[0 xx $!n+1] xx $!m+1;
        @!A[0;0]=0; @!B[0;0]=0; @!C[0;0]=0;
        for 1..$!m {
            @!A[$_;0]=-Inf;
            @!B[$_;0]=self.g($_);
            @!C[$_;0]=-Inf;
        }
        for 1..$!n {
            @!A[0;$_]=-Inf;
            @!B[0;$_]=-Inf;
            @!C[0;$_]=self.g($_);
        }
    };
    method computematrix() {
        for 1..$!m -> $i {
            for 1..$!n -> $j {
                if ($!DEBUG) { note 'before A=', @!A; say 'B=', @!B; say 'C=', @!C; }
                my $w=(@!U[$i-1]==@!V[$j-1]) ?? $!match_bonus !! $!mismatch;
                my $a_prevs = ( @!A[$i-1;$j-1], @!B[$i-1;$j-1], @!C[$i-1;$j-1] );
                my $amax = max(|$a_prevs);
                @!A[$i;$j] = $amax + $w;
                my $b_prevs = (
                    @!A[$i-1;$j]+$!gap_start,
                    @!B[$i-1;$j]+$!gap_extend,
                    @!C[$i-1;$j]+$!gap_start
                );
                my $bmax = max(|$b_prevs);
                @!B[$i;$j] = $bmax;
                my $c_prevs = (
                    @!A[$i;$j-1]+$!gap_start,
                    @!B[$i;$j-1]+$!gap_start,
                    @!C[$i;$j-1]+$!gap_extend
                );
                my $cmax = max(|$c_prevs);
                @!C[$i;$j] = $cmax;             
               if ($!DEBUG) { note 'after A=', @!A, "\nB=", @!B, "\nC=", @!C; }
            }
        }
        $!score=max(@!A[$!m;$!n],@!B[$!m;$!n],@!C[$!m;$!n]);
    }
}
