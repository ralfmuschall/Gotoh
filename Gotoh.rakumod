# Raku implementation of the Gotoh algorithm for string comparison
# Description: https://de.wikipedia.org/wiki/Gotoh-Algorithmus
# Unfortunately no english page is available.

# All parameters are signed, i.e. penalties (gap_start, gap_extend, mismatch)
# should be entered as negative numbers (match_bonus is probably positive or zero).

# DEBUG: Bitmask
#  0: steps in backtrace
#  1: before/after each step in trace matrices
#  2: before/after each step in computematrix

class Gotoh {
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
    has @!traceA; has @!traceB; has @!traceC;    
    has Real $.gap_start is required;
    has Real $.gap_extend is required;
    has Real $.match_bonus is required;
    has Real $.mismatch is required;
    has Real $.score is rw;
    has Real $!minusinf=-Inf;
    method g(Int $l --> Real) { $!gap_start+($l-1)*$!gap_extend; };
    submethod TWEAK() {
        $!m=$!u.chars; $!n=$!v.chars;
        @!U=$!u.ords;  @!V=$!v.ords;
        $!score=$!minusinf;
        self.preparematrix;
        self.computematrix;
    }
    method preparematrix() {
        @!A=[0 xx $!n+1] xx $!m+1;
        @!B=[0 xx $!n+1] xx $!m+1;
        @!C=[0 xx $!n+1] xx $!m+1;
        @!traceA=[0 xx $!n+1] xx $!m+1;
        @!traceB=[0 xx $!n+1] xx $!m+1;
        @!traceC=[0 xx $!n+1] xx $!m+1;
        @!A[0;0]=0; @!B[0;0]=0; @!C[0;0]=0;
        for 1..$!m {
            @!A[$_;0]=$!minusinf;
            @!B[$_;0]=self.g($_);
            @!C[$_;0]=$!minusinf;
        }
        for 1..$!n {
            @!A[0;$_]=$!minusinf;
            @!B[0;$_]=$!minusinf;
            @!C[0;$_]=self.g($_);
        }
    };
    method computematrix() {
        for 1..$!m -> $i {
            for 1..$!n -> $j {
                if ($!DEBUG +& 4) { note 'before A=', @!A; say 'B=', @!B; say 'C=', @!C; }
                if ($!DEBUG +& 2) {
                    note 'before traceA=', @!traceA, "\ntraceB=", @!traceB, "\ntraceC=", @!traceC;
                }
                my $w=(@!U[$i-1]==@!V[$j-1]) ?? $!match_bonus !! $!mismatch;

                my $a_prevs = ( @!A[$i-1;$j-1], @!B[$i-1;$j-1], @!C[$i-1;$j-1] );

                my $amax = max(|$a_prevs);
                @!A[$i;$j] = $amax + $w;
                @!traceA[$i;$j] = $a_prevs.first(:k, * == $amax);

                my $b_prevs = (
                    @!A[$i-1;$j]+$!gap_start,
                    @!B[$i-1;$j]+$!gap_extend,
                    @!C[$i-1;$j]+$!gap_start
                );
                my $bmax = max(|$b_prevs);
                @!B[$i;$j] = $bmax;
                @!traceB[$i;$j] = $b_prevs.first(:k, * == $bmax);
                
                my $c_prevs = (
                    @!A[$i;$j-1]+$!gap_start,
                    @!B[$i;$j-1]+$!gap_start,
                    @!C[$i;$j-1]+$!gap_extend
                );
                my $cmax = max(|$c_prevs);
                @!C[$i;$j] = $cmax;
                @!traceC[$i;$j] = $c_prevs.first(:k, * == $cmax);
            
                if ($!DEBUG +& 4) { note 'after A=', @!A, "\nB=", @!B, "\nC=", @!C; }
                if ($!DEBUG +& 2) {
                    note 'after traceA=', @!traceA, "\ntraceB=", @!traceB, "\ntraceC=", @!traceC;
                }
            }
        }
        $!score=max(@!A[$!m;$!n],@!B[$!m;$!n],@!C[$!m;$!n]);
    }
    method backtrace() {
        my $i = $!m;
        my $j = $!n;
        my $mabc=max(@!A[$i;$j], @!B[$i;$j], @!C[$i;$j]);
        my $mat = $mabc == @!A[$i;$j] ?? 'A' !! $mabc == @!B[$i;$j] ?? 'B' !! 'C';
        my @path;

        while $i>=0 && $j>=0 && ($i > 0 || $j > 0) {
            if ($!DEBUG +& 1) { note "i=$i j=$j"; }
            @path.unshift([$i, $j, $mat]);
            if $mat eq 'A' {
                my $prev = @!traceA[$i;$j];
                $mat = <A B C>[$prev];
                $i--; $j--;
            }
            elsif $mat eq 'B' {
                my $prev = @!traceB[$i;$j];
                $mat = <A B C>[$prev];
                $i--;
            }
            else {
                my $prev = @!traceC[$i;$j];
                $mat = <A B C>[$prev];
                $j--;
            }
        }
        return @path;
    }
}
