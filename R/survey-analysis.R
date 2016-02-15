#
# (c) 2014 Georgios Gousios <gousiosg@gmail.com>
#
# BSD licensed, see LICENSE in top level dir
#

# Process the results of coding open ended questions

source("R/packages.R")
source("R/cmdline.R")
source("R/utils.R")

library(MASS)
library(colorRamps)
library(RColorBrewer)
library(plyr)
library(reshape)
library(ggplot2)
library(likert)

## Analysis of coded open ended questions
# All functions expect a data frame of the following format:
# answer_id, tag1, tag2, tag3,...

# Extract all unique codes from the answer list
tags <- function(data) {
  unique(unlist(data[,-1]))
}

# Plot a code frequency plot
plot.tag.freq <- function(data, num.cols = 3,
                          filter = c("", "no prioritization", "none"),
                          title = "", ranking = T) {

  data <- subset(data, data[,1] != '')

  tag.freq <- Reduce(function(acc, x){
    tag.counts <- Reduce(function(acc, y) {
      # If an error occurs, this means that the processed tag does not exist in
      # the processed column
      count <- tryCatch({nrow(subset(data[,-1], data[,y] == as.character(x)))},
                        error = function(x){0})
      perc <- tryCatch({(count / length(data[,y])) * 100},
                        error = function(x){0})
      rbind(acc, data.frame(tag = as.character(x), rank = y - 1,
                            val = count, perc = perc))
    }, c(1: num.cols + 1), data.frame())

    rbind(acc, tag.counts)
  }, tags(data), data.frame())
  tag.freq$rank <- factor(tag.freq$rank, levels=c("1", "2", "3"))
  levels(tag.freq$rank) <- c("Top", "Second", "Third")

  if (!ranking) {
    tag.freq <- subset(aggregate(val ~ tag, tag.freq, sum), tag != '')
    tag.freq$perc <- tag.freq$val / nrow(data) * 100
  }

  for (f in filter) {
    tag.freq <- subset(tag.freq, tag != f)
  }

  print(tag.freq)

  p <- ggplot(tag.freq)

  if (!ranking) {
    p <- p + aes(x = reorder(tag, perc, order = T), y = perc) +
      geom_bar(stat="identity", position="dodge")
  } else {
    p <- p + aes(x = reorder(tag, perc, function(x){sum(x)}), y = perc, fill = rank) +
      geom_bar(stat="identity", position="stack") +
      theme(legend.position="top")
  }

  p <- p + ylab("Percentage of responses") +
    xlab("") +
    #ggtitle(title) +
    theme_bw(base_family = "Helvetica") +
    theme(panel.grid.major = element_blank()) +
    theme(panel.grid.minor = element_blank()) +
    theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
    coord_flip() +
    scale_fill_grey(start=0.8, end=0)

  p
}

# Plot an alluvial chart for showing the flow of codes in developer's answers
plot.alluvial <- function(data, filter = c()) {
  to.plot <- subset(data, tag1 != "")
  to.plot <- subset(to.plot, tag1 !="no prioritization")

  to.plot <- ddply(to.plot[,-1], .(tag1,tag2,tag3), nrow)
  to.plot <- rename(to.plot, replace=c("V1"="Freq"))

  colour <- function(line) {
    if (line[3] == "") {
      if (line[2] == "") {
        "white"
      } else {
        "red"
      }
    } else {
      "red"
    }
  }

  alluvial(to.plot[, 1:3],
           freq=to.plot$Freq,
           border=NA,
           hide = to.plot$Freq < quantile(to.plot$Freq, .50),
           col= apply(to.plot, 1, colour))
}

## Analysis of multiple choice and likert-like questions
# For here on, all functions expect a data.frame as loaded by reading a
# survey monkey exported CSV

# Given a question number, e.g. Q9, return a vector of all columns that
# represent answers e.g. Q9.A1, Q9.A2 etc
find.answer.cols <- function(data, question, other = TRUE) {
  if (other) {
    grep(sprintf("%s([\\.]|$)", question), colnames(data))
  } else {
    grep(sprintf("%s$", question), colnames(data))
  }
}

# Plot answers to multiple choice questions with one or more potential answers
# per question.
plot.multi.choice <- function(data, question, title) {
  # Restrict dataset to just the answer columns to make filtering easier later
  answers <- data[, find.answer.cols(data, question)]

  to.plot <- Reduce(function(acc, x) {
    # Calculate percentage of answers where answer option 'x' was selected
    percentage = (nrow(data) - nrow(subset(data, data[,x] == ""))) / nrow(data) * 100
    # For questions having the "Other" option, make sure the correct label is
    # displayed
    ans <- if (length(grep("\\.other", x)) > 0) {
      "Other"
    } else {
      as.character(subset(data, data[,x] != "")[1,x])
    }

    # Only return results for choices that at least one answer used
    if (percentage == 100) {
      acc
    } else {
      rbind(acc, data.frame(answer = ans, perc = percentage))
    }
  }, colnames(answers), data.frame())

  # Wrap answer labels to nicely fit to plot
  answers.wrap <- lapply(strwrap(to.plot$answer, 25, simplify=F), paste,
                         collapse="\n")
  print(to.plot)
  ggplot(to.plot) +
    aes(x = answer, y = perc) +
    geom_bar(position = "dodge", stat = "identity", width=.5) +
    scale_x_discrete(labels=answers.wrap) +
    theme_bw() +
    theme(panel.grid.major = element_blank()) +
    theme(panel.grid.minor = element_blank()) +
    ylab("Percentage of answers") +
    xlab("Answer") +
    ggtitle(title) +
    coord_flip()
}

# Plot answers to multiple choice questions with just one potential answer
plot.single.choice <- function(data, question, order = c(), title = "") {

  # Since we only have one column of answers subseting data will give us
  # a factor instead of a dataframe. So make sure we do get a dataframe
  answers <- data.frame(answer = data[, find.answer.cols(data, question, FALSE)])

  if (length(order) != 0) {
    answers$answer <- factor(answers$answer, order)
  }

  answers.wrap <- lapply(strwrap(answers$answer, 25, simplify=F), paste,
                         collapse="\n")
  ggplot(answers) +
    aes(x = answer) +
    geom_bar(position = "dodge", stat = "bin", width = .5) +
    scale_x_discrete(labels = answers.wrap) +
    coord_flip() +
    theme_bw(base_family = "Helvetica") +
    theme(panel.grid.major = element_blank()) +
    theme(panel.grid.minor = element_blank()) +
    theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
    xlab("Answer") +
    ylab("Number of answers") +
    ggtitle(title)
}

# Piecharts for demographic questions
plot.pie <- function(data, question, title = '', levels = c()) {
  answers <- data[, find.answer.cols(data, question)]

  if (class(answers) == class(data.frame())) {
    allowed.cols <- Filter(function(x){length(grep("\\.other", x)) <= 0}, colnames(answers))
    answers <- answers[, allowed.cols]
  }

  # Filter out empty answers
  answers <- Filter(function(x){x != ""}, answers)
  counts <- data.frame(table(answers))

  if (length(levels > 0)) {
    counts$answers <- ordered(counts$answers, levels = levels)
  }

  ggplot(counts) +
    aes(x = "", y = Freq, fill = answers) +
    geom_bar(width = 1, stat = "identity") +
    coord_polar(theta = "y") +
    geom_text(aes(y = Freq/2 + c(0, cumsum(Freq)[-length(Freq)]), label = Freq), size = 7, colour = "white") +
    ylab('') +
    xlab('') +
    scale_fill_discrete(name="") +
    theme_bw() +
    theme(panel.border = element_blank()) +
    theme(panel.grid.major = element_blank()) +
    theme(panel.grid.minor = element_blank()) +
    theme(axis.ticks = element_blank()) +
    theme(axis.text = element_blank()) +
    theme(axis.text = element_blank()) +
    theme(title = element_text(size = 14, face = "bold"))  +
    #scale_fill_grey(name = "", start = 0.2, end = 0.8, na.value = "red") +
    ggtitle(title)
}

# Prepare data for ploting likert scale questions
plot.likert.data <- function(data, question, order = c(),  title = '',
                             group.by = '', mappings = column.mappings) {
  answers <- data[, find.answer.cols(data, question)]

  allowed.cols <<- Filter(function(x){length(grep("\\.other", x)) <= 0}, colnames(answers))
  answers <- answers[, allowed.cols]

  # Re-level factors according to the provided order
  for (col in colnames(answers)) {
    answers[,col] <- factor(answers[,col], order)
  }

  answers <- resolve.question.text(answers)
  if(nchar(group.by) == 0) {
    plot(likert(answers), centered=TRUE, wrap=15, legend.position='top',
         text.size = 2, title = title)
  } else {
    answers$groupping <- data[, group.by]
    plot(likert(subset(answers, select=-c(groupping)),
                grouping=answers$groupping),
         centered=TRUE, wrap=95, legend.position='top',
         title = title, grouping = answers$groupping)
  }
}

resolve.question.text <- function(df, mappings = column.mappings) {
  qs <- Map(function(x){
    # Reverse lookup of the question text in the  mapping table
    q.text <- search.list.by.value(mappings, x)
    # Get a formatted version of the answer text
    parse.sm.question.text(q.text)$answer
  }, colnames(df))

  rename(df, qs)
}

# Parse a SurveyMonkey formatted question header, return a list with 2
# elements, $question and $answer
parse.sm.question.text <- function(x) {

  replace.chars <- function(x) {
    gsub(".", ' ', gsub("..", ", ", x, fixed = T), fixed = T)
  }

  # Get question part, identified by ...+
  q <- replace.chars(strsplit(x, "\\.\\.\\.+", )[[1]][1])

  # If a capital character appears after a comma, this is means 2 sentences in
  # question. Format second sentence starting character.
  q <- gsub(", ([A-Z])", ". \\1", q)

  # Append question mark
  q <- sprintf("%s?", q)

  a <- replace.chars(strsplit(x, "\\.\\.\\.+")[[1]][2])
  list(question = trim(q), answer = trim(a))
}
