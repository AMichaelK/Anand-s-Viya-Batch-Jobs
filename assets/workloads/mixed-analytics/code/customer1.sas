/******************************************************************************
 * Copyright (c) 2013 by SAS Institute Inc, Cary NC 27511  USA
 * This program is part of the Mixed Analytic Workload repository of
 *   test programs used to evaluate SAS concurrent workload.   
 *
 * PASS NAME:  Customer1.sas
 * DESCRIPTION: Customer Provided Benchmark Program - Data Step manipulation with REG and MEANS
 *    
 *    
 * SETUP INSTRUCTIONS: None
 * OUTPUT:  none
 *
 * SYSTEM REQUIREMENTS:  This test works with default settings.
 *
 * ANTICIPATED RUNTIME:  3:00 minutes    
 * TEST CHARACTERIZATION:  I/O, Memory Intensive  
 *
 * SAS PRODUCTS INVOLVED:   BASE, STAT
 * SAS PROCEDURES INVOLVED:  DATA, REG, MEANS 
 *
 * DATA SOURCE: SELF Generated
 * DATA CHARACTERIZATION:   na
 *
 * COMMENTS:
 * DISTRIBUTION STATUS:  External
 * CONTRIBUTED BY: Tom Keefer
 *
 * HISTORY:
 *   Date       Description                       Who
 *   19Jul13    Add to Mixed Analytic Workload    Tony Brown
 ******************************************************************************/
 

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

/* Set program parameters */

%let numobs=30000000;
%let numvars=120;

/*******************************************************************************
 *                       END OF PROGRAM SETUP
 *******************************************************************************/

/* Do NOT edit below this line! */
;

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

* create a dataset;
data sim;
  array xvec{*} x1-x&numvars;
  do i = 1 to &numobs;
    do j = 1 to dim(xvec);
  /*tnk     xvec{j}= rannor(0); */
       xvec{j}= .5;
	end;
	intx1 = int(x1*10);
    output;
  end;
run;

* sorting and regressions;
proc sort data=sim;
  by x1;
run;

proc reg data=sim;
  model x1 = x2-x&numvars;
run;

proc reg data=sim;
  model x1 = x2-x&numvars / selection = adjrsq;
run;

proc sort data=sim;
  by intx1;
run;

proc means data=sim noprint;
  var intx1;
  by intx1;
  output out=n n=n;
run;

data sim;
  merge sim n(keep=intx1 n);
  by intx1;
run;

proc reg data=sim(where=(n gt 5));
  model x1 = x2-x4;
  by intx1;
run;

/***************************************************************************
 *                      END OF PROGRAM CODE SECTION
 ***************************************************************************/

/***************************************************************************
 *                       END OF TEST
 ****************************************************************************/


