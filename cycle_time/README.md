cycle_time
==========

`cycle_time` is gnuplot script that takes an Emacs SES spreadsheet as its input and creates a combined box-and-whisker and violin plot for all columns.

It was written to track software development story cycle time relative to their point estimate with the goal of assisting the developers in improving their estimations. While some issue trackers have cycle time graphs, the per-estimate variability is often difficult to identify.

The input to the script is an SES spreadsheet, which is converted to a CSV file on read. Other formats should be easy to support.

Notes
-----

- The CSV conversion is done by using `sed` (specifically GNU `sed`) whenever `stats` or `plot` are called, which is inefficient
- Each empty cell to the left of a filled cell needs to be invalid (e.g., with a `NaN` content) or the filled cell will be attributed to the wrong column; there should be an easier way to do this
- The kernel density tables are written into temporary files, which are cleaned up

![Cycle Time boxplot](cycle_time.png?raw=true "Cycle Time boxplot")
