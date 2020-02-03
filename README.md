If you've got `conda` installed and want to reproduce the results:

```
# To create an identical environment (req Ubuntu)
conda create --name code_as_data --file envs/requirements.txt
```

```
# To create a similar environment
conda env create --file envs/environment.yml
```

Activate the environment

```
conda activate code_as_data
```

Some of the R packages used in this project are not on anaconda, CRAN or
Bioconductor. These are installed by the script `scripts/00-setup-env.R`.
See the 'remotes' entry in the config for details of the packages that are
installed in this way.

Install any remaining dependencies, and make any non-version-controlled
directories (data, results etc)

```
./setup
```

----

To run the analysis:

First activate the conda environment (if you haven't already)

```
conda activate code_as_data
```

Then use the bash script to run the workflow

```
./run
```

If you want the data or results to be stored to a specific location, set up
links to these positions before running `./run`.
