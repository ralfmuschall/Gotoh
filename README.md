# Gotoh algorithm in raku

* Compute the alignment of two strings using affine gap penalties, i.e. `g(l):=gap_start+(l-1)*gap_extend`
* Description: https://de.wikipedia.org/wiki/Gotoh-Algorithmus
  * unfortunately there is no Wikipedia page in other languages than german

## Rough explanation of the code in Gotoh-simple

* all penalties etc. are signed
  * i.e. you will probably use negative `mismatch`, `gap_start` and `gap_extend` but positive `match_bonus`
* we need three matrices of size `O(#u * #v)` each
  * expect huge memoy consumption unless the data strings `u` and `v` are short

The method `preparematrix` sets up the matrices as described in
https://de.wikipedia.org/wiki/Gotoh-Algorithmus#Matrix-Rekurrenzen 

Then we walk across both strings and put the score for
identities/substitutions into matrix `A`, deletions into matrix `B`
and insertions into matrix `C`. The final score is the largest of the
three bottom right corner values of the three matrices.

## Additions for finding the backtrace

The class `Gotoh` is an extension of the code created using Perplexity
(which gave no explanation about what happens there) and is
essentially untested (i.e. don't use it unless you want to take the
risk of getting bad results). It allocates three more matrices of the
same size and the method `backtrace` computes the backtrace from them.

## Command-line toy tool g.raku

This runs the code and gives the score and the backtrace.

Options:

* `-u`, `-v`: strings to be compared
* `--sp`: gap\_start (is a penalty, so one should give a negative value)
* `--ep`: gap\_extend (penalty)
* `--match\_bonus`: score gain for matching characters (default: 0)
* `--mismatch`: penalty for substitutions
* `-w`: use the algorithm as in Wikipedia (default=True, use
  `-w=False` for Gotoh's original version instead of this one)
* `-s`: try to generate a string describing the backtrace

Trivial example:

```bash
raku g.raku -u=foobar -v=foxbar --sp=-1 --ep=-0.1 --match_bonus=0.01 --mismatch=-0.7 
```

Result:

```
score: -0.65
backtrace: [[1 1 A] [2 2 A] [3 3 A] [4 4 A] [5 5 A] [6 6 A]]
```
