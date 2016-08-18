## Pull Request Contributors survey data

[![DOI](https://zenodo.org/badge/doi/10.5281/zenodo.46063.svg)](http://dx.doi.org/10.5281/zenodo.46063)

A repository with survey data for how project owners (integrators) use pull
requests on Github. The repository corresponds to data and code used for the
following publication:

G. Gousios, M.-A. Storey, and A. Bacchelli, “[Work Practices and Challenges in Pull-Based Development: The Contributor’s Perspective](http://www.gousios.gr/bibliography/GSB16.html),” in *Proceedings of the 38th International Conference on Software Engineering*, 2016.

### Contents

The contents in this repository are organized as follows:

* `data`: Contains the CSV files with the raw answer set (`contributors.csv`),
the same answer set enriched with data from the [GHTorrent](http://ghtorrent.org)
dataset (`contributors-enriched.csv`) and coded answers for 5 open ended
questions.
* `doc`: Contains the sources to the camera ready version of our ICSE paper
* `R`: Contains R scripts to load, analyze and plot the answer data. The file
you are mainly interested in is `contributors-analysis.R`.

### Potential Uses

You are welcome to use the data as you please. Further uses not explored in our
ICSE paper are the following:

* Slice the dataset and explore answer sets per repository size, project team
size, activity and so on.
* Inform the design of tools for handling pull requests
* Ideas for further research

You can use [GHTorrent](http://ghtorrent.org) to enrich the dataset by
linking the repository names to actual code and metadata.

### Citation information

If you find this data useful for your research, please consider citing
the work behind this dataset as follows:

```
@inproceedings{GSB16,
  author = {Gousios, Georgios and Storey, Margaret-Anne and Bacchelli, Alberto},
  title = {Work Practices and Challenges in Pull-Based Development: The Contributor's Perspective},
  booktitle = {Proceedings of the 38th International Conference on Software Engineering},
  year = {2016},
  month = may,
  location = {Austin, Texas},
  series = {ICSE '16},
  isbn = {978-1-4503-3900-1},
  publisher = {ACM},
  pages = {285--296},
  doi = {10.1145/2884781.2884826},
  note = {ACM SIGSOFT Distinguished paper},
  url = {http://gousios.gr/bibliography/GSB16.html}
}
```
