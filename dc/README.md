# dc
Miscellaneous dc scripts

The dc desk calculator is one of the oldest Unix programs still included in every Unix and Unix-like operating system. It has been part of Unix since before 1st Edition, in fact a version written in B was compiled on the PDP-7 at Bell Labs to run on the PDP-11 before even an assembler worked on the PDP-11. This was in 1970.

Robert Morris and Lorinda Cherry owned the dc program at Bell Labs. In 1975 they constructed the more user-friendly front-end bc, which was included in 6th Edition. bc was originally a Yacc grammar for an infix arithmetic calculator with C-like programming constructs that used dc as its backend.

## l.dc

Robert Morris included a [math library](https://www.tuhs.org/cgi-bin/utree.pl?file=V6/usr/lib/lib.b) to provide scientific functions for bc in 6th Edition Unix (1975.) Each library function uses an iterative approximation approach. This code is a line-by-line translation of the bc math library to dc. No effort has been made to preserve register content nor is this particularly idiomatic dc code.

## Example Usage

```
$ dc -f l.dc  -
1 lE x
2.71828182845904523536
3.14159265358979323846 lS x
0
3.14159265358979323846 lC x
-1.00000000000000000000
q
$
```
