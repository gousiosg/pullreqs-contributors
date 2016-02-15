# printf for R
printf <- function(...) invisible(print(sprintf(...)))

#
unwrap <- function(str) {
  strwrap(str, width=10000, simplify=TRUE)
}

# Trim whitespace from strings
trim <- function (x) gsub("^\\s+|\\s+$", "", x)

# Get the owner and the repo for a Github-like repo name as a 2 elem. vector
owner.repo <- function(x) {
  strsplit(trim(x), "/")[[1]]
}

# Find the label of a list value and return it as a string
search.list.by.value <- function(l, val) {
  names(l[!is.na(match(l, val))])
}

# Construct a path from the data file location
data.file <- function(x) {
  file.path(data.file.location, x)
}

# Load a data file from the data file location
load.data.file <- function(x) {
  read.csv(data.file(x))
}

load.tagged.file <- function(x, num.tags = 3) {
  data <- load.data.file(x)
  tags <- Map(function(x){sprintf("tag%s", x)}, c(1:num.tags))
  tags <- c('X', tags)
  data[, unlist(tags)]
}

# Search cases where the provided tag appears in any position
tag.existence <- function(data, tag) {
  nrow(subset(data, (tag1 == tag | tag2 == tag | tag3 == tag)))
}

# Search cases where the provided tags co-exist in any tag position
tag.coexistence <- function(data, tag.1, tag.2) {
  nrow(subset(data, (tag1 == tag.1 | tag2 == tag.1 | tag3 == tag.1) & 
           (tag1 == tag.2 | tag2 == tag.2 | tag3 == tag.2)))
}

# Store a plot as PDF. By default, will store to user's home directory
store.pdf <- function(data, name, where = plot.location) {
  tryCatch({
    pdf(file.path(where, name))
    plot(data)
  }, finally = {dev.off()}
  );
}
