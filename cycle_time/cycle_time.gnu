set macros
script=ARG0
basename=script[:strstrt(script,'.')]
header=system('head -1 '.basename.'ses')
points=words(header)
datafile="< gsed -E '/^$/Q; s/(^\\s+|\\s+$)//g; s/ +/,/g' ".basename.'ses'
set datafile separator comma

# Cycle time boxplot
set terminal pngcairo font 'arial,10' fontscale 1.5 size 800, 600
outputfile=basename.'png'
set output outputfile

set style data boxplot

set style fill solid 0.5 border -1
set style boxplot outliers pointtype 7
set pointsize 0.5
set errorbars lt black lw 1

set title 'Cycle Time by Points' font 'arial,18'
set ylabel "Hours\n(not incl. Acceptance)"
set key autotitle columnhead
unset key

set border 2
set xtics ('' 0) nomirror scale 0
set ytics nomirror
set logscale y

loop="for [column=1:points]"

do @loop {
    stats datafile using column noout
    set label 1+column sprintf("%i ".(STATS_records == 1 ? "Story" : "Stories"), \
	STATS_records) at column,1 center
    set label 1000+column sprintf("{/:Italic M}=%dhrs.", STATS_median) at column,1000 center

    tablefile='.'.basename.'kfile.'.column.'.tmp'
    # The main datafile is a CSV with headers, so a fake header is
    # necessary because of the autotitle.
    # The separator option doesn't work, which is why a format string
    # below is needed.
    system('echo " x\t y" > '.tablefile)
    set table '.'.basename.'kfile.'.column.'.tmp' append
    plot datafile u column:(1) smooth kdensity bandwidth 10. with filledcurves above y
    unset table
}

set xrange[0:(points+1)]

plot @loop ".".basename."kfile.".column.".tmp" \
     u(column + $2/1.5):1 '%lf %lf' with filledcurve x=column lt column, \
     @loop ".".basename."kfile.".column.".tmp" \
     u(column - $2/1.5):1 '%lf %lf' with filledcurve x=column lt column, \
     @loop datafile \
     u(column):column:(0.075):(columnhead(column)) fc "white" lw 2

do @loop {
    system('rm .'.basename.'kfile.'.column.'.tmp')
}
unset logscale y
reset