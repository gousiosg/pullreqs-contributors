#
# (c) 2014 -- onwards Georgios Gousios <gousiosg@gmail.com>
#
# BSD licensed, see LICENSE in top level dir
#

if (!"plyr" %in% installed.packages()) install.packages('plyr')
if (!"MASS" %in% installed.packages()) install.packages("MASS")
if (!"colorRamps" %in% installed.packages()) install.packages("colorRamps")
if (!"optparse" %in% installed.packages()) install.packages("optparse")
if (!"reshape" %in% installed.packages()) install.packages("reshape")
if (!"klaR" %in% installed.packages()) install.packages("klaR")
if (!"RColorBrewer" %in% installed.packages()) install.packages("RColorBrewer")
if (!"RMySQL" %in% installed.packages()) install.packages("RMySQL",
                                                          type="source")
if (!"ggplot2" %in% installed.packages()) install.packages("ggplot2")
if (!"combinat" %in% installed.packages()) install.packages("combinat")

# Install from github
if (!"devtools" %in% installed.packages()) install.packages("devtools")
require(devtools)

if (!"likert" %in% installed.packages()) install_github("likert","gousiosg")
#
load_all('/Users/gousiosg/Developer/likert')

