# README

These scripts can be used to generate and stage input data used by the workloads.

- [data.tar.bz2](https://abisenblobfs.blob.core.windows.net/data/datasets/mixed-analytics-dataset/data.tar.bz2?sp=r&st=2023-06-10T01:18:25Z&se=2024-12-31T10:18:25Z&spr=https&sv=2022-11-02&sr=b&sig=Q8d7xvcy4MEvv2YACSeSI%2FAnXshUzxLSxK1rIFiy7lg%3D)
- [census1_pums.tar.bz2](https://abisenblobfs.blob.core.windows.net/data/datasets/mixed-analytics-dataset/census1_pums.tar.bz2?sp=r&st=2023-06-10T01:20:40Z&se=2024-12-31T10:20:40Z&spr=https&sv=2022-11-02&sr=b&sig=59RRuOsZfWzqMj4oDEfx3Aoo9KQteebCX2E4ctlz%2BX0%3D)

## `census1.sas`

IO intensive test which uses an elaborate DATA Step whichcreads ~38GB of input text files and generates ~8GB of output across 2 sas7bdat files (precsX and hrecsX).

To generate the input data use `./generate_census1.sh` bash script which generates ~38GB worth of text files that are used by `census1.sas` 

This test reads raw PUMS file from from "in" and writes 2 SAS data sets as specified by user-defined global parms HRECS and PRECS (for HOUSEHOLD and PERSON data, respectively).  This test is very I/O intenstive.

If you run the test as is, it will create the HRECS data set which is ~1.1 gigabytes in size (5,527,046 records and 115 columns) and it will create the PRECS data set which is ~2.8 gigabytes in size (12,501,406 records and 128 columns).

## `comp_test_[1,2].sas`

This computational test is a numercially intensive test performed against a 182,973 row table with 297 variables. We are performing stepwise linear regression and a stepwise logistic regression. Performance can be increased if you can set the the `MEMSIZE` parameter high enough to cache the data for the logistic regression. This test requires you to import data stored in the transport file boardrm.tra (96MB) into a SAS data set using the CIMPORT procedure.

| Key                     | Val                            |
|-------------------------|--------------------------------|
| SAS PRODUCTS INVOLVED   | Base SAS, SAS/STAT             |
| SAS PROCEDURES INVOLVED | LOGISTIC, REG                  |
| DATA SOURCE             | boardrm.tra SAS transport file |
| ANTICIPATED RUNTIME     | 5-15 minutes                   |
| TEST CHARACTERIZATION   | CPU Intensive                  |
| DATA CHARACTERIZATION   | 297 Variables                  |

- `comp_test_2`: This test is the same code as `comp_test1.sas`, but it only uses 50% of the total data.

## `comp_test_5.sas`

This computational test is a numercially intensive test using GLM (Generalized Linear Model).  This code artificially generates the data it needs for the GLM procedure within the code.
