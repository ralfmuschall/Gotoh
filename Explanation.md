# Gotoh algorithm in raku

* Compute the alignment of two strings using affine gap penalties, i.e. `g(l):=gap_start+(l-1)*gap_extend`
* Description: https://de.wikipedia.org/wiki/Gotoh-Algorithmus
  * unfortunately there is no Wikipedia page in other languages than german

## Explanation of the algorithm

### General remark

All parameters are signed. If something has to be a penalty
(i.e. $gap\_extend$), a negative value has to be given.  Ususally only
$matchbonus$ will be non-negative.

### Initialization

We compare strings $u$ (length $m$) and $v$ (length $n$).

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
column is set to $gap\_start$, $gap\_start+gap\_extend$,
$gap\_start+2*gap\_extend$ etc. denoting the score for having deleted the initial character(s).

$C_{00}$ is zero, the rest of the left column is $-\infty$ (we cannot
have insertion before start) and the top row is set to $gap\_start$,
$gap\_start+gap\_extend$, $gap\_start+2*gap\_extend$ etc. denoting the score
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

At each step, the matrix elements of $traceA/B/C$ are filled with one
of the numbers $9$, $1$ or $2$ (denoting $A$, $B$ or $C$, respectively)
describing how we arrived at the current state.

## Backtracking

### Step-by-step analysis of the backtracking algorithm

```bash
raku g.raku -s -u=a -v=bbb --sp=-1 --ep=-0.01 --match_bonus=0 --mismatch=-10 
```

The mismatch penalty is intentionally chosen to be prohibitive, so we
expect all actions to be deletions or insertions. The returned score
is $-2.02$ which matches the expectation (one deletion of the $"a"$
(cost: $-1$) and one long insertion of $"bbb"$ (cose $-1.02$).

The trace matrices have the following values at the end of the loop:

$$traceA=\begin{bmatrix}0 & 0 & 0 & 0\\ 0 & 0 & 2 & 2\end{bmatrix}$$

$$traceB=\begin{bmatrix}0 & 0 & 0 & 0\\ 0 & 2 & 2 & 2\end{bmatrix}$$

$$traceC=\begin{bmatrix}0 & 0 & 0 & 0\\ 0 & 1 & 2 & 2\end{bmatrix}$$

The elements at the top and left margin of the trace matrices are
always $0$ from the initialization, they are never changed or used.

For the backtracking we start at the lower right corner of the
matrices and we need to know what the last operation was (i.e. $"A"$,
$"B"$ or $"C"$), these facts are known from the score computation.

We cannot simply follow the trace matrices, because then we might hit
their margins and misinterpret the $0$ there as indicating that a
substitution had been performed. Therefore we handle the border cases
first and eliminate the situations where deletion or insertion is the
only possible step.

In our example we know that the matrix to look at is $B$, so we use
$traceB_{13}=2$, telling us that the next matrix to look into is
$traceC$. Therefore in the next step we got up to $i=0, j=3$ and find
$traceC_{0,3}=0$ which is to be ignored (we have reached the
margin). No matter what the matrix elements are, we can only do
insertions (i.e. $C$) until we reach the top left corner.
