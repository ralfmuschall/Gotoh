# Raku implementation of the Gotoh algorithm for string comparison
# Description: https://de.wikipedia.org/wiki/Gotoh-Algorithmus
# Unfortunately no english page is available.

# All parameters are signed, i.e. penalties (gap_start, gap_extend, mismatch)
# should be entered as negative numbers (match_bonus is probably positive or zero).

# DEBUG: Bitmask
#  0: steps in backtrace
#  1: before/after each step in trace matrices
#  2: before/after each step in computematrix
#  3: internals of backtrace_string
#  4: restrict matrix output to the recently changed entry
#  5: suppress output of initial matrices (when bit 1 and/or 2 are set)

# minimalist .Str for a matrix
sub ms($a --> Str) {
    if ($a.^name ne 'Array') { return $a.Str; }
    if ($a[0].^name ne 'Array') { return $a.Str; }
    my $s0='[';
    my $s='';
    for ($a[*]) -> $row {
        $s ~= $s0;
        $s0="\n";
        $s ~= '[';
        for ($row[*]) -> $thing {
            $s ~= ( ($thing == -Inf) ?? '-∞' !! $thing ) ~ ' ';
        }
        $s ~= ']';
    }
    return $s ~ ']';
}

class Gotoh {
    has $!u is required is built; # input strings u,v
    has $!v is required is built;
    has $!m; # length of u
    has @!U; # bytes of u
    has $!n; # length of v
    has @!V; # bytes of v
    has @!A; # substitutions
    has @!B; # deletions (i.e. present in u, missing in v)
    has @!C; # insertions
    has $.DEBUG=0;
    has @!traceA; has @!traceB; has @!traceC;    
    has Real $.gap_start is required;
    has Real $.gap_extend is required;
    has Real $.match_bonus is required;
    has Real $.mismatch is required;
    has Int $!wikipedia is built; # use wikipedia pseudocode instead of original paper
    has Real $.score is rw;
    has @!path; # for backtrace
    method g(Int $l --> Real) { $!gap_start+($l-1)*$!gap_extend; };
    submethod TWEAK() {
        $!m=$!u.chars; $!n=$!v.chars;
        @!U=$!u.ords;  @!V=$!v.ords;
        $!score=-Inf;
        self.preparematrix;
        self.computematrix;
    }
    method preparematrix() {
        @!A=[[0 xx $!n+1] xx $!m+1];
        @!B=[[0 xx $!n+1] xx $!m+1];
        @!C=[[0 xx $!n+1] xx $!m+1];
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
        if (($!DEBUG +& 4) && !($!DEBUG +& 32)) {
            note "init\nA=", ms @!A;
            note 'B=', ms @!B;
            note 'C=', ms @!C;
        }
        @!traceA=[[0 xx $!n+1] xx $!m+1];
        @!traceB=[[0 xx $!n+1] xx $!m+1];
        @!traceC=[[0 xx $!n+1] xx $!m+1];
        if (($!DEBUG +& 2) && !($!DEBUG +& 32)) {
            note "init\ntraceA=", ms @!traceA;
            note 'traceB=', ms @!traceB;
            note 'traceC=', ms @!traceC;
        }
    };
    method computematrix() {
        for 1..$!m -> $i {
            for 1..$!n -> $j {
                my $w=(@!U[$i-1]==@!V[$j-1]) ?? $!match_bonus !! $!mismatch;
                my $a_prevs = ( @!A[$i-1;$j-1], @!B[$i-1;$j-1], @!C[$i-1;$j-1] );
                my $amax = max(|$a_prevs);
                @!A[$i;$j] = $amax + $w;
                @!traceA[$i;$j] = $a_prevs.first(:k, * == $amax);

                my $b_prevs = (
                    @!A[$i-1;$j]+$!gap_start,
                    @!B[$i-1;$j]+$!gap_extend,
                    $!wikipedia ?? (@!C[$i-1;$j]+$!gap_start) !! -Inf
                );
                my $bmax = max(|$b_prevs);
                @!B[$i;$j] = $bmax;
                @!traceB[$i;$j] = $b_prevs.first(:k, * == $bmax);
                
                my $c_prevs = (
                    @!A[$i;$j-1]+$!gap_start,
                    $!wikipedia ?? (@!B[$i;$j-1]+$!gap_start) !! -Inf,
                    @!C[$i;$j-1]+$!gap_extend
                );
                my $cmax = max(|$c_prevs);
                @!C[$i;$j] = $cmax;
                @!traceC[$i;$j] = $c_prevs.first(:k, * == $cmax);
            
                if ($!DEBUG +& 4) {
                    note "after i=$i j=$j a_prevs=($a_prevs) b_prevs=($b_prevs) c_prevs=($c_prevs)";
                    if ($!DEBUG +& 16) {
                        note "A=", @!A[$i;$j], ' B=', @!B[$i;$j], ' C=', @!C[$i;$j];
                    } else {
                        note "A=", (ms @!A), "\nB=", (ms @!B), "\nC=", (ms @!C);
                    }
                }
                if ($!DEBUG +& 2) {
                    note "after i=$i j=$j";
                    if ($!DEBUG +& 16) {
                        note "tA=", @!traceA[$i;$j], ' tB=', @!traceB[$i;$j], ' tC=', @!traceC[$i;$j];
                    } else {
                        note "traceA=", (ms @!traceA), "\ntraceB=", (ms @!traceB), "\ntraceC=", (ms @!traceC);
                    }
                }
            }
        }        
        $!score=max(@!A[$!m;$!n],@!B[$!m;$!n],@!C[$!m;$!n]);
    }
    method backtrace() {
        my $i = $!m;
        my $j = $!n;
        my $mabc=$!score;
        my $mat = $mabc == @!A[$i;$j] ?? 'A' !! $mabc == @!B[$i;$j] ?? 'B' !! 'C';

        if ($!DEBUG +& 2) {
            note "after\ntraceA=", ms @!traceA;
            note 'traceB=', ms @!traceB;
            note 'traceC=', ms @!traceC;
        }
        while $i>=0 && $j>=0 && ($i > 0 || $j > 0) {
            if ($!DEBUG +& 1) { note "i=$i j=$j mat=$mat"; }
            @!path.unshift([$i, $j, $mat]);
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
        return @!path;
    }
    method backtrace_string() {
        # currently broken
        self.backtrace unless defined @!path;
        my Str $res='';
        for (@!path) -> $triple {
            my $i=$triple[0]; my $j=$triple[1]; my $which=$triple[2];
            if ($!DEBUG +& 8) { note "i=$i j=$j which=$which"; }
            if ($which eq 'A') {
                my $ui=@!U[$i-1].chr;
                my $vj=@!V[$j-1].chr;
                if ($ui ne $vj) {
                    $res ~= "($ui -> $vj)";
                } else {
                    $res ~= "(=$ui)";
                }
            } elsif ($which eq 'B') {
                $res ~= '(-' ~ (@!U[$i-1]).chr  ~ ')';
            } else {
                $res ~= '(+' ~ (@!V[$j-1]).chr ~ ')';
            }
        }
        return $res;
    }
}
