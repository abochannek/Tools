cycle_time
==========

`cycle_time` is gnuplot script that takes an Emacs SES spreadsheet as its input and creates one box-and-whisker plot for all columns and a multiplot with a histogram for each column.

It was written to track software development story cycle time relative to their point estimate with the goal of assisting the developers in improving their estimations. While some issue trackers have cycle time graphs, the per-estimate variability is often difficult to identify.

The input to the script is an SES spreadsheet, which is converted to a CSV file on read. Other formats should be easy to support.

Notes
-----

- The CSV conversion is done by using `sed` (specifically GNU `sed`) whenever `stats` or `plot` are called, which is inefficient
- The canvas dimensions are hard-coded and the layout for the multiplot is calculated based on how many columns are to be plotted
- Each empty cell to the left of a fill cell needs to be invalid (e.g., with a `NaN` content) or the filled cell will be attributed to the wrong column; there should be an easier way to do this
- The multiple histograms might be easier to compare if they used similar axis ranges

![Cycle Time boxplot][cycle_time.png ?raw=true "Cycle Time boxplot"]
![Cycle Time histogram][cycle_time.hist.png ?raw=true "Cycle Time histogram"]
