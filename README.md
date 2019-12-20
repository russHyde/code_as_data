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

Some of the packages used in this project are not on anaconda, CRAN or
Bioconductor

```
# In R:
library(devtools)
devtools::install_github("hrbmstr/cloc", dependencies = FALSE)
```

----

To run the analysis:

First activate the conda environment (if you haven't already)

```
conda activate code_as_data
```

Then use the bash script to run the workflow (this will make any results
directories that are missing)

```
./run_me.sh
```
