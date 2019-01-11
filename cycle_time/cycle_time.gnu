script=ARG0
basename=script[:strstrt(script,'.')]
header=system('head -1 '.basename.'ses')
points=words(header)
datafile="< gsed -nE '{:loop; /^(\\f|$)/q; s/(^\\s+|\\s+$)//g; s/ +/,/g; p; n; b loop}' ".basename.'ses'
set datafile separator comma

# Cycle time boxplot
set terminal pngcairo font 'arial,10' fontscale 1.5 size 800, 600
outputfile=basename.'png'
set output outputfile

set style data boxplot

set style fill solid 0.5 border -1
set style boxplot outliers pointtype 7
set pointsize 0.5

set title 'Cycle Time by Points'
set ylabel "Hours\n(not incl. Acceptance)"
set key autotitle columnhead
unset key

set border 2
set xtics ('' 0) nomirror scale 0
set ytics nomirror
set logscale y

do for [column=1:points] {
    stats datafile using column noout
    set label column sprintf("{/:Italic M}=%dhrs.", STATS_median) at column,1 center
}

plot for [column=1:*] datafile u(column):column:(0.5):(columnhead(column))

unset for [column=1:points] label column
unset logscale y


# Cycle time histogram
set terminal pngcairo font 'arial,10' fontscale 1.5 size 1600, 1200
outputfile=basename.'hist.png'
set output outputfile
array Dim[2]=[0.0,0.0]
Dim[1]=int(ceil(sqrt(points)))
Dim[2]=int(ceil(points/real(Dim[1])))
set multiplot layout Dim[1],Dim[2] title 'Frequency of Cycle Time'

do for [column=1:points] {

    stats datafile using column noout

    binwidth=24 # hours
    tics_freq=binwidth*(((ceil(STATS_max / binwidth))/10)+1)
    
    set title sprintf("%s\n%i ".(STATS_records == 1 ? "Story" : "Stories"), \
	word(header,column), STATS_records)

    set xrange [0:]
    set xlabel 'Hours'
    set xtics tics_freq font 'arial,8' 
    
    set format y '%0.f'
    set ylabel 'Frequency'
    
    bin(x)=binwidth*floor(x/binwidth)+binwidth/2.0
    set boxwidth binwidth*0.9
    
    plot datafile u(bin(stringcolumn(column))):(1.0) smooth freq with boxes lc column
}

unset multiplot
