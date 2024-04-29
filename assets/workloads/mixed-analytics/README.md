# MA Workloads

| Name           | Primary Type | Input Data                              | Input Data Size |
|----------------|--------------|-----------------------------------------|-----------------|
| census1        | IO           | 51 pumsax*.txt files                    | 37.5 GB         |
| codegen_issue  | MEM          | in.sas7bdat                             | 1.3 GB          |
| comp_test1     | COMP         | boardrm.tra                             | 95 MB           |
| comp_test2     | COMP         | boardrm.tra                             |                 |
| comp_test5     | COMP         | self-generated                          |                 |
| customer1      | IO           | self-generated                          |                 |
| dim_50mil      | IO           | customer_(50mil,type)_(1-4).dat         | 76.7 GB         |
| focus2         | IO           | focus.dat                               | 3 MB            |
| genmod         | COMP         | genmod1.tra                             | 61 MB           |
| glimmix        | COMP         | self-generated                          |                 |
| gsort          | IO           | messy_1.sas7bdat                        | 145.3 GB        |
| hist_clm       | COMP/IO      | hxx[(1-7)pjbc,dp(eac,h1c,jcc)],rtmscnts | 1.6 GB          |
| hpmixed        | COMP/MEM     | self-generated                          |                 |
| io1_ca         | IO           | pumsaxca_ca1.txt                        | 44.9 GB         |
| io2            | IO           | (hrecs,precs)_large(1-3).sas7bdat       | 107.2 GB        |
| nlmixed        | COMP/MEM     | smptest.tra                             | 51 MB           |
| pension2       | COMP/IO/MEM  | self-generated                          |                 |
| rank1          | COMP/IO      | self-generated                          |                 |
| ranrw          | IO - RANDOM  | self-generated                          |                 |
| surveylogistic | COMP/MEM     | self-generated                          |                 |

## Workloads

### census1

This test reads raw PUMS file from from "in" and writes 2 SAS data sets as specified by user-defined global parms HRECS and PRECS (for HOUSEHOLD and PERSON data, respectively). This test is very I/O intenstive.

If you run the test as is, it will create the HRECS data set which is ~1.1 gigabytes in size (5,527,046 records and 115 columns) and it will create the PRECS data set which is ~2.8 gigabytes in size (12,501,406 records and 128 columns).

### codegen_issue

### comp_test1

This computational test is a numercially intensive test performed against a 182,973 row table with 297 variables. We are performing stepwise linear regression and a stepwise logistic regression. Performance can be increased if you can set the the `MEMSIZE` parameter high enough to cache the data for the logistic regression. This test requires you to import data stored in the transport file boardrm.tra into a SAS data set using the CIMPORT procedure.

| Key                     | Val                            |
|-------------------------|--------------------------------|
| SAS PRODUCTS INVOLVED   | Base SAS, SAS/STAT             |
| SAS PROCEDURES INVOLVED | LOGISTIC, REG                  |
| DATA SOURCE             | boardrm.tra SAS transport file |
| ANTICIPATED RUNTIME     | 5-15 minutes                   |
| TEST CHARACTERIZATION   | CPU Intensive                  |
| DATA CHARACTERIZATION   | 297 Variables                  |

### comp_test2

This test is the same code as COMP_TEST1, but it only uses 50% of the total data.

### comp_test5

This computational test is a numercially intensive test using GLM (General Linear Model).  This code artificially generates the data it needs for the GLM procedure within the code.

| Key                     | Val                                       |
|-------------------------|-------------------------------------------|
| SAS PRODUCTS INVOLVED   | Base SAS, SAS/STAT                        |
| OUTPUT                  | none                                      |
| SYSTEM REQUIREMENTS     | This test runs with the default settings. |
| ANTICIPATED RUNTIME     | less than a minute                        |
| TEST CHARACTERIZATION   | CPU Intensive                             |
| SAS PRODUCTS INVOLVED   | Base SAS, SAS/STAT                        |
| SAS PROCEDURES INVOLVED | GLM                                       |
| DATA SOURCE             | Created within the SAS job.               |
| DATA CHARACTERIZATION   | SELF GENERATED                            |

### customer1

Customer Provided Benchmark Program - Data Step manipulation with REG and MEANS

| Key                     | Val                                    |
|-------------------------|----------------------------------------|
| SETUP INSTRUCTIONS      | None                                   |
| OUTPUT                  | None                                   |
| SYSTEM REQUIREMENTS     | This test works with default settings. |
| TEST CHARACTERIZATION   | I/O, Memory Intensive                  |
| SAS PRODUCTS INVOLVED   | BASE, STAT                             |
| SAS PROCEDURES INVOLVED | DATA, REG, MEANS                       |
| DATA SOURCE             | SELF Generated                         |
| DATA CHARACTERIZATION   | na                                     |
  
### dim_50mil

### focus2

### genmod

### glimmix

### gsort

### hist_clm

### hpmixed

### io1_ca

### io2

### nlmixed

### pension2

### rank1

### ranrw

### surveylogistic


## Input Data

The input data that many of the jobs in this workload needs to be first
staged in a location which is accessible from the Viya environment. There
are scripts in `assets/workloads/mixed-analytics/data` that should be
used to generate the dataset. Please note the amount of data is a few
hundred GB and can take a few hours (depending upon the performance of
storage). 

Before executing the scripts first download the following two files and
uncompress inside `assets/workloads/mixed-analytics/data` directory. 

- [data.tar.bz2](https://abisenblobfs.blob.core.windows.net/data/datasets/mixed-analytics-dataset/data.tar.bz2?sp=r&st=2023-06-10T01:18:25Z&se=2024-12-31T10:18:25Z&spr=https&sv=2022-11-02&sr=b&sig=Q8d7xvcy4MEvv2YACSeSI%2FAnXshUzxLSxK1rIFiy7lg%3D)
- [census1_pums.tar.bz2](https://abisenblobfs.blob.core.windows.net/data/datasets/mixed-analytics-dataset/census1_pums.tar.bz2?sp=r&st=2023-06-10T01:20:40Z&se=2024-12-31T10:20:40Z&spr=https&sv=2022-11-02&sr=b&sig=59RRuOsZfWzqMj4oDEfx3Aoo9KQteebCX2E4ctlz%2BX0%3D)