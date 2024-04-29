# MA Workload Jobs

Hopefully this makes it easier to understand what each of the individual jobs does in the mixed analytics workload. Let me know if you have any questions.

In the current mixed analytics 20 (MA20) workload, these jobs are run in batch via a shell script and are passed a handful of options at runtime. Most jobs are executed multiple times throughout the run and are balanced to maintain an average of ~20 jobs (20 users) running at a given time.

Each of the jobs has a header that provides a description, test characterization, products & proceedures involved, data source & characterization, etc.

The workload is ~1.2 TB in total, primarily due to the large input data sizes. The input data used for each job ranges from a couple KB to 146 GB+ and is a mix of sas7bdat, tra, txt, dat, binary and self-generated files.

I went through and tried to pull out some info about the input data and primary focus areas of each test. Note this was done fairly quickly so there's likely some info missing and what's listed below may not be 100% accurate.

| Name | Primary Type | Input Data | Input Data Size |
| ------ | ------ | ------ | ------ |
| census1 | IO | 51 pumsax*.txt files | 37.5 GB |
| codegen_issue | MEM | in.sas7bdat | 1.3 GB |
| comp_test1 | COMP | boardrm.tra | 95 MB |
| comp_test2 | COMP | boardrm.tra |  |
| comp_test5 | COMP | self-generated |  |
| customer1 | IO | self-generated |  |
| dim_50mil | IO | customer_(50mil,type)_(1-4).dat | 76.7 GB |
| focus2 | IO | focus.dat | 3 MB |
| genmod | COMP | genmod1.tra | 61 MB |
| glimmix | COMP | self-generated |  |
| gsort | IO | messy_1.sas7bdat | 145.3 GB |
| hist_clm | COMP/IO | hxx[(1-7)pjbc,dp(eac,h1c,jcc)],rtmscnts | 1.6 GB |
| hpmixed | COMP/MEM | self-generated |  |
| io1_ca | IO | pumsaxca_ca1.txt | 44.9 GB |
| io2 | IO | (hrecs,precs)_large(1-3).sas7bdat | 107.2 GB |
| nlmixed | COMP/MEM | smptest.tra | 51 MB |
| pension2 | COMP/IO/MEM | self-generated |  |
| rank1 | COMP/IO | self-generated |  |
| ranrw | IO - RANDOM | self-generated |  |
| surveylogistic | COMP/MEM | self-generated |  |
