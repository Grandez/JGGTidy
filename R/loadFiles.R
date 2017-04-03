require(stringr, quietly=T)
require(dplyr, quietly=T)
require(data.table, quietly=T)

#' @title  Getting and Cleaning Data
#' @description
#'    Load data from a file downloaded from UCI machine Learning
#'    Does make tidy
#'    The file generated has this layout:
#'    1.- Subject
#'    2.- Activity
#'    3.- Object: Body, Gravity,...
#'    4.- Measure: mean or sd
#'    5.- X,Y,Z
#'
#'
#'

DEFAULT_FILE = "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"


tidyFile <- function(fileName = NULL) {
  df <- loadRawData(fileName)
  df <- makeTidyData(df)
  return (as.data.table(df))
}

loadRawData <- function(fileName = NULL) {
  nDirs = 0

#  browser()

    wrk = loadFile(fileName)

  #################################################
  # Process columns to select
  #################################################

  # Load file with all column names
  tmp <- getDataframe(wrk, "features.txt")

  # Select the second column (names)
  allCols <- as.vector(tmp[,2])
  colClasses = rep("NULL", nrow(tmp))

  # Select all columns related to means and std
  colClasses[grep("(t)(Body|Gravity)Acc-(mean|std)\\(\\)-[XYZ]$",allCols)] <- "numeric"

  # Select columns with type not equal NULL
  colNames <- allCols[!(colClasses == "NULL")]

  # Process directories into zip file: train, test, val, ...
  for (dir in getDirectories(wrk, 1)) {
    dirDf <- processDirectory(wrk, dir, colClasses, colNames)
    df = if (nDirs > 0) rbind(df, dirDf) else dirDf
    nDirs = nDirs + 1
  }

  # Translate activity into a factor
  fact = getDataframe(wrk,"activity_labels.txt")
  df$Activity = fact[df$Activity,2]
  df$Activity <- as.factor(df$Activity)
  df$Subject  <- as.factor(df$Subject)
  unlink(wrk)

  return (df)
}

#
#' @title  processDirectory
#' @description
#'    Zip file has several folders. Basically: train and test
#'    but is possible file change including new sets, by example, validators sets
#'    Each folder has:
#'       A) The code of subjects
#'       B) The code of activity
#'       C) The observations
#'
#'   Their relationship is:
#'
#'   +--------+  1    1  +---------+  1    1  +---------+
#'   | X_data | <------> | subject | <------> |    Y    |
#'   +--------+ By row   +--------+   By row  +---------+
#'
#' @param zipFile the zipped file
#' @param the name of folder (is used to discover their files)
#' @param classes Vector with the columns to retrieve
#' @param Vector with the names of columns selected
#'
#' @return A data frame like
#'
#'   +---------+----------+-----------------------------+
#'   | subject | activity | vector of selected columns  |
#'   | subject | activity | vector of selected columns  |
#'   |  ...    |    ...   |          ....               |
#'   +---------+----------+-----------------------------+
#'
#
processDirectory <- function (zipFile, directory, classes, colNames) {
  df.obs <- getDataframe(zipFile, sprintf("%s/X_%s.txt", directory, directory), colNames, classes)
  df.id  <- getDataframe(zipFile, sprintf("%s/subject_%s.txt", directory, directory), "Subject")
  df.act <- getDataframe(zipFile, sprintf("%s/y_%s.txt", directory, directory), "Activity")
  return (cbind(df.id, df.act, df.obs))
}

#
#' @title  loadFile
#' @description
#'    load in memory the file selected.
#'    By default use the file set in DEFAULT_FILE
#'
#'    If file starts with "http" unload the file from Internet
#'    else assumes file is in local server
#'
#'    @param fileName String with the file name
#'
#'    @return An object file pointing to zipped file
#
loadFile <- function (fileName) {

  if (is.null(fileName)) {
    tmp = tempfile()
    download.file(DEFAULT_FILE, tmp)
    return (tmp)
  }

  if (length(grep("^http", fileName, ignore.case=T)) > 0) {
    tmp = tempfile()
    download.file(fileName, tmp)
    return (tmp)
  }

  if (!file.exists(fileName)) {
    stop("File " + fileName + " does not exist")
  }

  return (fileName)
}

#
#' @title  getDataFrame
#' @description
#'    Load a file from zipped file into a data frame
#'
#'    @param zipFile the zipped file object
#'    @param fileName Fullname of file to read
#'    @param colNames Vector of names for the columns. By default none
#'    @param colClasses Vector of columns to retrieve. By default ALL
#'
#'    @return The data frame
#

getDataframe <- function(zipFile, fileName, colNames=NULL, colClasses=NA) {
  tmp <- unzip(zipFile, exdir=tempdir(), paste("UCI HAR Dataset", fileName, sep="/"))
  df <- read.table(tmp, header=F, colClasses = colClasses)
  if (!is.null(colNames)) colnames(df) = colNames
  unlink(tmp)
  return (df)
}

#
#' @title  getDirectories
#' @description
#'    Get the folders inside a zip file
#'
#'    @param zipFile the zipped file object
#'    @param level Depth of zipped tree starting by 1 (Inside root)
#'
#'    @return Vector of directories
#

getDirectories <- function (zipFile, level = 1) {
   n = level + 1
   lst = unzip(zipFile, list=T)

   lstFiles = str_split(lst[,1], "/")
   dirs = c()
   for (t in lstFiles) {
     if (length(t) > n) {
        dirs <- c(dirs, t[n])
     }
   }

   return (unique(dirs))
}

#
#' @title  makeTidyData
#' @description
#'    Make data tidy
#'    Split data into:
#'    Subject
#'    Activity
#'    Object   : The subject (Body) or the artifact (Gravity)
#'    Measure  : Median or Standard deviation
#'    X,Y,Z    : each coordinate
#'
#'    @param df messy data frame
#'
#'    @return tidy data
#

makeTidyData <- function(df) {

  left <- df[,1:2]
  left$Object <- "Body"

  dt <- as.data.table(df)
  aux1 <- subset(dt, select = grep("tBodyAcc", names(dt)))
  names(aux1) <- gsub(".+(mean|std).+([XYZ]$)", "\\1_\\2",names(aux1))

  aux11 <- subset(aux1, select = grep("mean", names(aux1)))
  names(aux11) <- c("X","Y","Z")
  left$Measure<-"mean"
  aux11 <- cbind(left, aux11)

  aux12 <- subset(aux1, select = grep("std", names(aux1)))
  names(aux12) <- c("X","Y","Z")
  left$Measure<-"sd"
  aux12 <- cbind(left, aux12)


  left$Object <- "Gravity"
  aux2 <- subset(dt, select = grep("tGravityAcc", names(dt)))
  names(aux2) <- gsub(".+(mean|std).+([XYZ]$)", "\\1_\\2",names(aux2))

  aux21 <- subset(aux2, select = grep("mean", names(aux2)))
  names(aux21) <- c("X","Y","Z")
  left$Measure<-"mean"
  aux21 <- cbind(left, aux21)

  aux22 <- subset(aux2, select = grep("std", names(aux2)))
  names(aux22) <- c("X","Y","Z")
  left$Measure<-"sd"
  aux22 <- cbind(left, aux22)

  df <- rbind(aux11,aux12, aux21, aux22)
  df$Object <- as.factor(df$Object)
  df$Measure <- as.factor(df$Measure)

  return (df)

}
