# code-as-data

## Environment

This project uses
- `conda` to manage the python-based and command-line tools and to install the
base R release
- and `renv` to manage the installation of any R packages

To set up the project, first install the `conda` environment, activate it, then
install the `renv` environment

Once you've got `conda` installed:

```
# To create an identical environment (req Ubuntu)
conda create --name code-as-data --file conda/requirements.txt
```

```
# To create a similar environment
conda env create --file conda/environment.yml --name code-as-data
```

Activate the conda environment

```
conda activate code-as-data
```

To install the R environment (and also make any non-version-controlled
directories: data, results etc):

```
./setup
```

----

To run the analysis:

Once the environment is setup and activated use the bash script to run the
workflow

```
./run
```

If you want the data or results to be stored to a specific location, set up
links to these positions before running `./run`.
