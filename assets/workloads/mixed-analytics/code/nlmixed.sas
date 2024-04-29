/******************************************************************************
 *  * Copyright (c) 2013 by SAS Institute Inc, Cary NC 27511  USA
 *
 * This program is part of the Mixed Analytic Workload repository of
 *   test programs used to evaluate SAS concurrent workload.  
 * NAME:  NLMIXED.sas
 * DESCRIPTION: Threaded NLMIXED
 *
 * SETUP INSTRUCTIONS: This test can run threaded or non-threaded.  Default is non-threaded.
 *
 *
 *   OUTPUT: None.
 *
 * SYSTEM REQUIREMENTS: None.
 *
 * ANTICIPATED RUNTIME:  22 minutes on Windows 32bit.
 * TEST CHARACTERIZATION: STAT Procedure NLMIXED tested on small dataset for single threaded
 *                        performance on an SMP Server.
 *
 * SAS PRODUCTS INVOLVED:  BASE, STAT
 * SAS PROCEDURES INVOLVED: NLMIXED
 *
 * DATA SOURCE: smptest.sas7bdat
 * DATA CHARACTERIZATION: Very Small (4000 obs) numeric data dataset for NLMIXED test.
 *
 * COMMENTS:
 * DISTRIBUTION STATUS:  Public
 * CONTRIBUTED BY: Randy Tobias
 *
 * HISTORY:
 *   Date       Description                         Who
 *  19JUL13     Added to Mixed Analytic Workload    Tony Brown
 *******************************************************************************/

 /**********************************************************************
 *Starting code for log review information                             
 **********************************************************************/

%macro stdout (command, debug=no);

  %local fileref fid rc;

  %let rc = %sysfunc (filename (fileref, &command, PIPE));

%if &debug=yes %then %put fileref=&fileref;

  %if &rc = 0 %then %do;

    %let fid = %sysfunc (fopen (&fileref, S));
    %if &fid ne 0 %then %do;

      %do %while(%sysfunc(fread(&fid)) = 0);

        %local line;
        %let rc = %qsysfunc(fget(&fid,line,200));

%if &debug=yes %then %put line=&line;

        &line

      %end;

      %let fid = %sysfunc (fclose (&fid));
    %end;
    %else %do;

      %put ERRROR: PIPE OPEN FAILED, %sysfunc(sysmsg());
      PIPE OPEN FAILED

    %end;

    %let rc = %sysfunc (filename (fileref));
  %end;
  %else %do;
    %put ERRROR: COMMAND PIPE SETUP FAILED, rc=&rc..;
    COMMAND PIPE SETUP FAILED
  %end;

%mend;

/**********************************************************************
 *Ending - code for log review information                            
 **********************************************************************/



/*******************************************************************************
 *                        PROGRAM SETUP
 * Use this section to alter macro variables, options, or other aspects of the
 * test.  No Edits to this Program are allowed past the Program Setup section!!
 *******************************************************************************/
%let mysysparm=%sysfunc(getoption(SYSPARM));
*%let suiteloc=%sysget(ASUITE);
%put &suiteloc;

%let data= &suiteloc/input;   /*  location of source data  */

/* End of Data Setup Section */

/* Do NOT edit below this line! */

libname in  "&suiteloc/input/";
libname out "&suiteloc/output/";

 
/*** Import Data From Transport Format ***/

proc cimport lib=work infile="&suiteloc/input/smptest.tra" isfileutf8=true;
run; 


 

/*******************************************************************************
 *                       END OF PROGRAM SETUP
 *******************************************************************************/

/* Do NOT edit below this line! */

options fmterr fullstimer source source2 mprint notes;

/*******************************************************************************
 *                        PASS MACRO CODE - DO NOT EDIT
 *  This section controls information printed to the log for performance analysis
 ********************************************************************************/
/* PASS: Print information to the log for performance analysis. */ 
%macro passinfo;
  data _null_;
   temp=datetime();
   temp2=lowcase(trim(left(put(temp,datetime16.))));
   call symput('datetime', trim(temp2));
 
   %if ( &SYSSCP = WIN )
   %then call symput('host', "%sysget(computername)");
   %else call symput('host', "%sysget(HOST)");
   ;
  run;

  %put PASS HEADER BEGIN;
  %put PASS HEADER os=&sysscp;
  %put PASS HEADER os2=&sysscpl;
  %put PASS HEADER host=&host;
  %put PASS HEADER ver=&sysvlong;
  %put PASS HEADER date=&datetime;
  %put PASS HEADER parm=&sysparm;

  proc options group=memory; run;
  proc options group=performance; run;
  options SASTRACE=',,,d' SASTRACELOC=saslog NOSTSUFFIX;

  libname _all_ list; run; 

  %put PASS HEADER END;
%mend passinfo;
%passinfo;
run;
 
DATA _NULL_; 
 %PUT This job started on &sysdate at &systime; 
RUN;
 
/***************************************************************************
 *                        END OF PASS MACRO CODE
 ***************************************************************************/

 

/***************************************************************************
 *                         PROGRAM CODE SECTION
 ***************************************************************************/

/****************  Double the size of the Data going to the NLMIXED Test ***********************/


Data work.smptestdbl;
        Set work.smptest work.smptest;
      Run;

Proc sort data=work.smptestdbl;
       By v20;
Run;


proc nlmixed data=work.smptestdbl GCONV=0 df=417  ;
  parms alpha=-1 betaV1=0 betaV2=0 beta2=0 mu=0;
  eta = alpha + betaV1*V1 + betaV2*V2
        + gV3*V3
        + gV4*V4
        + gV5*V5
        + beta2*V6
        + gV7*V7
        + gV8*V8  + gV9*V9 + gV10*V10
        + gV11*V11 + gV12*V12 + gV13*V13
        + gV14*V14 + gV15*V15
        + gV16*V16 + gV17*V17
        + gV18*V18 + gV19*V19 + u;
  expeta = exp(eta);
  p = expeta/(1+expeta);
  model outcome ~ binary(p);
  random u ~ normal(mu,s2u) subject=V20;
run;


/***************************************************************************
 *                      END OF PROGRAM CODE SECTION
 ***************************************************************************/

/***************************************************************************
 *                       END OF TEST
 ****************************************************************************/
