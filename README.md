If you've got `conda` installed and want to reproduce the results:

```
# To create an identical environment (req Ubuntu)
conda create --name code_as_data --file envs/requirements.txt
```

```
# To create a similar environment
conda env create --file envs/environment.yml
```

Some of the packages used in this project are not on anaconda, CRAN or
Bioconductor

```
# In R:
library(devtools)
devtools::install_github("hrbmstr/cloc", dependencies = FALSE)
```


----

Then make the results folders:

```
mkdir results results/packages
```

----

Then run the scripts in turn:

```
Rscript R/01-*.R
Rscript R/02-*.R
...
```

