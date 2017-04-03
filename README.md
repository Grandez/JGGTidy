# JGGTidy
## Data Science Getting and cleaning data

The objetive of this program is get ad make tidy som information about the accelerometers from the Samsung Galaxy S smartphone.
All functions are enclosed into run_analyisis.R

Use: run_analysis([fileName])

* if fileName is mising the program try to dowload the file: https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip
* if fileName starts with http the program try to downloaded from that url
* Otherwise assume it is a local zipped file

Return a Data frame/Data table with this layout:

1.- Subject: Id of sibject
2.- Activity: A factor according the activities name
3.- Object:A factor indicating what Object was measured: Currently Gravity and Body
4.- Measure: A factor indicating what values are showed: Mean or Sd
5.- X,Y,Z values

