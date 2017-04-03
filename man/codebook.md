---
title: "Getting and cleaning data"
output: github_document
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
```

## Introduction 

The objetive of this program is get ad make tidy som information about the accelerometers from the Samsung Galaxy S smartphone.


All info is provided by: 
[UCI - Machine Learning Repository](http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones)

Files can be downloaded in zip format, and all information about the data can be found there.

## Assumptions

### About files

Although data is splitted into several files, I'm focused on:


   - 'features.txt': List of all features.
   - 'activity_labels.txt': Links the class labels with their activity name.
   - 'Directory':
       - 'train/X_train.txt': Training set.
       - 'train/y_train.txt': Training labels.
       - 'train/subject_train.txt': Id of subjects

And inside the data, only get information about medians and standard deviations

I don't assume anything about data but structure of zipped file and naming conventions, that is:


    1.- Activity_labels.txt and features.txt are in root tree
    2.- There are several folders according the requeriments for the machine learning: train, test, val, ...
    3.- Each folder has a name (xxx) and contains three files:
        3.1 subject_xxx.txt Indicating the subject Id
        3.2 y_xxx.txt Indicating the activity of subject
        3.3 x_xxx.txt The observations

### About data

 * Each windowed observation is defined by the three coordinates: X,Y and Z; so, I assume that values are part of one observation.
 * Each windowed observation stores diferents data: min, max, mean and sd. I think that mean and sd values should be always thogether because they are inter-related: first approach is a table with mean(x,y,z) and sd(x,y,z) values, another approach could be two related tables, one for mean values and the other one for sd, but in this capstone I choosed create a row for each data, adding a column measure to indicate the type of data: "mean" or "sd"

## Approach

Main features are:

1.- Make the code as abstract(generic) as possible
2.- Minimize the use of memory
3.- Minimize readings

There are two basic process:

    1.- Load the data into memory
    2.- Make it tidy
    
    
## Load the data

Data is loaded directly from Internet or use a previously downloaded file according the prefix of file name (http or not) and it is readed without decompressing.

Flow is:

    1.- loadFile -> get access to file
    2.- Process features / Select columna names to read in order to avoid read the full data
    3.- For each directory (train, test, etc)
        3.1 .- Load subject file
        3.2 .- Load Y axis
        3.3 .- Load selected columns from X data
    4.- Mark Subject and activities as factor

The relationship between files is:
 
     +--------+  1    1  +---------+  1    1  +---------+
     | X_data | <------> | subject | <------> |    Y    |
     +--------+ By row   +--------+   By row  +---------+

The resulting dataframe is: 
 
    +---------+----------+-----------------------------+
    | subject | activity | vector of selected columns  |
    | subject | activity | vector of selected columns  |
    |  ...    |    ...   |          ....               |
    +---------+----------+-----------------------------+

## Tidying the data

Once data are loaded into memory they are like this:

    +---------+----------+-------------+------------+-------------+---------+---------|----------+-------------------+
    | subject | activity | tbody_mean_x|tbody_mean_y|tbody_mean_z|tbody_sd_x|body_sd_y|tbody_sd_z|tgravity_sd_x .... |
    | subject | activity | tbody_mean_x|tbody_mean_y|tbody_mean_z|tbody_sd_x|body_sd_y|tbody_sd_z|tgravity_sd_x .... |
    |  ...    |    ...   |                                     ....                                                  |
    +---------+----------+-------------------------------------------------------------------------------------------+

Where each row has unfriendly names and diferent info.  
Target is split the data into groups by: 
    * body/gravity/etc
    * mean/sd  

getting a data frame like this:
    1.- Subject: Id of subject
    2.- Activity: Factor of activities
    3.- Object: Measured object: Body, Gravity, ...
    4.- Measure: Type of data: mean or standard deviation
    5.- X: X value
    6.- Y: Y value
    7.- Z: Z value


Flow is:

    1.- for each main pattern (body, gravity, etc.) split the data
        1.1.- Set the column object to pattern
        1.2.- For each measure (mean, sd) split the data
            1.2.1 .- Set the column Measure to its value
            1.2.2 .- Set the names to X,Y,Z
            1.2.2 .-  Combine columns subject/activity with the data frame
        1.3.- Combine rows in a data frame
        
