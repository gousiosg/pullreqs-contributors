#
# (c) 2014 Georgios Gousios <gousiosg@gmail.com>
#
# BSD licensed, see LICENSE in top level dir
#

source(file = "R/packages.R")
library(optparse)

# The following variables are exported to all scripts including this file
mysql.user =  "ghtorrent"
mysql.passwd = "ghtorrent"
mysql.db = "ghtorrent"
mysql.host = "127.0.0.1"

#analyzed.set <- "integrators"
analyzed.set <- "contributors"

# Paths
base.dir        = file.path(".")

plot.location   = file.path(base.dir, "figs")
latex.location  = file.path(base.dir, "latex")

data.file.location    = "data"

dir.create(plot.location, showWarnings = FALSE)

debug = T
num.processes = 2

# Cmd-line parser
option_list <- list(
  make_option(c("-b", "--base-dir"), default=base.dir, dest = 'base.dir',
              help = "Base directory [\"%default\"]"),

  make_option(c("-s", "--mysql-host"), default=mysql.host, dest = 'mysql.host',
              help = "MySQL host [\"%default\"]"),
  make_option(c("-d", "--mysql-db"), default=mysql.db, dest = 'mysql.db',
              help = "MySQL database [\"%default\"]"),
  make_option(c("-u", "--mysql-user"), default=mysql.user, dest = 'mysql.user',
              help = "MySQL user [\"%default\"]"),
  make_option(c("-p", "--mysql-passwd"), default=mysql.passwd, dest = 'mysql.passwd',
              help = "MySQL password [\"%default\"]"),

  make_option(c("-n", "--num-processes"), default = num.processes,
              dest = 'num.processes', type = "integer",
              help = "Number of processes to use when running in parallel [\"%default\"]"),

  make_option(c("-x", "--debug"), default=debug, dest = 'debug',
              help = "More verbose output [\"%default\"]")
)

args <- parse_args(OptionParser(option_list = option_list),
                   print_help_and_exit = FALSE)

if (args$help) {
  parse_args(OptionParser(option_list = option_list))
}

project.list  = args$project.list
base.dir      = args$base.dir
mysql.user    = args$mysql.user
mysql.passwd  = args$mysql.passwd
mysql.db      = args$mysql.db
mysql.host    = args$mysql.host
num.processes = args$num.processses

plot.location   = file.path(base.dir, "figs")
latex.location  = file.path(base.dir, "latex")
project.list    = file.path(base.dir, "projects.txt")

data.file.location    = "data"
overall.dataset.stats = file.path(data.file.location, "project-statistics.txt")
