# Gotoh algorithm in raku

* Compute the alignment of two strings using affine gap penalties, i.e. `g(l):=gap_start+(l-1)*gap_extend`
* Description: https://de.wikipedia.org/wiki/Gotoh-Algorithmus
  * unfortunately there is no Wikipedia page in other languages than german

## Explanation of the algorithm

### General remark

All parameters are signed. If something has to be a penalty
(i.e. $gapextend$), a negative value has to be given.  Ususally only
$matchbonus$ will be non-negative.

### Initialization

We compare Strings $u$ (length $m$) and $v$ (length $n$).

At initialization three matrices $A, B, C$ of height $m+1$ and width $n+1$ are
created. Each element of these matrices contains at the place $(i,j)$
the best achievable score for the pair $(u[i-1],v[j-1])$.

Matrix $A$ traces matches and mismatches, $B$ traces deletions, $C$
traces insertions.

Initially, $A_{00}$ is set to 0 and the remaining cells of the top row
and left column to $-\infty$ (this denotes that we cannot have a
(mis)match with characters that came before the start of the strings).

$B_{00}$ is also set to zero, the rest of the top row is $-\infty$ (we
cannot have deleted elements before the start of the string). The left
column is set to $gapstart$, $gapstart+gapextend$,
$gapstart+2*gapextend$ etc. denoting the score for having deleted the initial character(s).

$C_{00}$ is zero, the rest of the left column is $-\infty$ (we cannot
have insertion before start) and the top row is set to $gapstart$,
$gapstart+gapextend$, $gapstart+2*gapextend$ etc. denoting the score
for having gained the initial character(s) by insertion.

### Double loop

We loop over $i: 1...m$ and $j: 1...n$.

At each step, we fill $A_{ij}$ with the best score achievable by
(mis)match (i.e. we look one column left and one row up, take the best
element of $A$, $B$ or $C$ and add the score fpr (mis)matching our
character pair).

We get $B_{ij}$ by looking to the row above our position in all three
matrices and select the best possibility. This is either something
from $A$ or $C$ and we start a fresh deletion, or something from $B$
and we extend a pre-existing deletion.

We get $C_{ij}$ by looking to the column left to our position in all
three matrices and select the best possibility. This is either
something from $A$ or $B$ and we start a fresh insertion, or something
from $C$ and we extend a pre-existing insertion.

## Backtracking

### Bug (unsolved)

```bash
raku g.raku -s -u=a -v=bbb --sp=-1 --ep=-0.01 --match_bonus=0 --mismatch=-3 
```

gives the correct score of -2.01 (one deletion of length 1 costing
1.0, one insertion of length 3 costing 1.02) but the wrong trace `[[0
2 A] [0 3 C] [1 3 B]]` (i.e. one (mis)match, one insertion, one
deletion). The input data intentionally contains a prohibitively
string mismatch penalty to enforce the use of only deletions and
insertions.

### Description of the backtrace algorithm

Three more matrices $traceA$, $traceB$ and $traceC$ of the same size
as that of $A$ are created and initialized to zero.

At each step in the double loop, the following happens:

We look {\it how} we achieved the element $A_{ij}$. It must be a
(mis)match, but we want to know if the parent was another (mis)match,
a deletion or an insertion. Depending on that, $traceA_{ij}$ is set to
0, 1, or 2. We do the same for $traceB_{ij}$ and $traceC_{ij}$, the
element of the trace matrix describes wether the parent element of out
main matrix element came from $A$, $B$ or $C$.

After the end of the main loop, we look which of $A$, $B$ or $C$ gave
the best score (this also gives the final element of the backtrace)
and walk backwards through the trace matrices. At each step we
consider the trace matrices in order to see where we came from and
prepend the triple $(i,j,matrixletter)$ to the trace.

## Practical example

We compare the strings $u={\rm "xa"}$ and $v={\rm "yxb"}$ with the
weights $gapstart=-1$, $gapextend=-0.1$, $matchbonus=0.01$ and
$mismatch=0.75$.

After initialization we have

$$A=\begin{bmatrix} 0 & -\infty & -\infty & -\infty\\
-\infty & 0 & 0 & 0\\
-\infty & 0 & 0 & 0\end{bmatrix}$$

$$B=\begin{bmatrix}0 & -\infty & -\infty & -\infty\\
-1 & 0 & 0 & 0\\
-1.1 & 0 & 0 & 0\end{bmatrix}$$

$$C=\begin{bmatrix}0 & -1 & -1.1 & -1.2\\
-\infty & 0 & 0 & 0\\
-\infty & 0 & 0 & 0\end{bmatrix}$$

$$traceA=traceB=traceC=\begin{bmatrix}0 & 0 & 0 & 0\\
0 & 0 & 0 & 0\\
0 & 0 & 0 & 0\end{bmatrix}$$

Step $i=j=1$ sets $A_{11}$ to -0.75 (mismatch added on top of the 0 in $A_{00}$), $B_{11}=-2$ ($gapstart$ added to the -1 above in $C$), $C_{11}=-2$ ($gapstart$ added to the -1 on the left in $B$).

$traceA$ remains unchanged, $traceB_{11}=2$ (i.e. we came from $C$), $traceC_{11}=1$ (we came from $B$).

Step $(i=1, j=2)$ makes $A_{12}=-0.99$ ($matchbonus$ added to the -1
from $C_{01}$), $B_{12}=-2.1$ by adding $gapstart$ to $C_{02}$ (all
alternatives would be $-\infty$), $C_{12}=-1.75$ by adding $mismatch$
to $A_{11}.  Accordingly $traceA_{12}=2$, $traceB_{12}=2$, $traceC_{12}=0$.

The following steps are summarized in this table (where only the
changed matrix elements are mentioned), it should be clear by now how
each matrix entry was generated.

$$\begin{array}{cccccccc}
 i & j & A_{ij} & B_{ij} & C_{ij} & traceA_{ij} & traceB_{ij} & traceC_{ij} \\
 \hline
 1 & 3 & -1.85 & -2.2 & -1.85 & 2 & 2 & 2 \\
 2 & 1 & -1.75 & -1.75 & -2.1 & 1 & 0 & 1 \\
 2 & 2 & -1.5 & -1.99 & -2.2 & 0 & 0 & 2 \\
 2 & 3 & -1.74 & -2.3 & -2.3 & 0 & 1 & 2
\end{array}$$

Now we see that the highest bottom-right element of $A$, $B$, $C$ is
-1.74 in $A$, so our score is -1.74. Therefore the last action in the
backtrace was a (mis)match. For the second-last backtrace entry we
therefore look into $traceA_{23}=0$, the value 0 says that this step
was also a (mis)match. Now we look at $traceA_{12}=2$ so the step
before that was an insertion. Now $i=0$ and $j=1$, so we are at the
start (the stop condition for the backtrace is that neither $i$ nor
$j$ are negative and at least one is positive).


### Step-by-step analysis of the buggy result

$$\begin{array}{cccccccc}
 i & j & A_{ij} & B_{ij} & C_{ij} & traceA_{ij} & traceB_{ij} & traceC_{ij} \\
 \hline
 1 & 1 & -10 & -2 & -2 & 0 & 2 & 1\\
 1 & 2 & -11 & -2.01 & -2.01 & 2 & 2 & 2\\
 1 & 3 & -111 & -2.02 & -2.02 & 2 & 2 & 2
\end{array}$$

At $i=j=1$ $A_{11}$ is $-10$ as expected, $B_{11}=-2 (from $C_{01}=-1$
and $gapstart$), $C_{11}=-2$ (from $B_{01}=-1$ and $gapstart$).

$traceA_{11}=0$ because the variable `$a_prev` 

TO BE CONTINUED
