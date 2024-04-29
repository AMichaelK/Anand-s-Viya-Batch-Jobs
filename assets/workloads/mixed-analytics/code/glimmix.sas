/******************************************************************************
 * Copyright (c) 2013 by SAS Institute Inc, Cary NC 27511  USA
 *
 * This program is part of the Mixed Analytic Workload repository of
 *   test programs used to evaluate SAS concurrent workload.   
 * NAME:    GLIMMIX.sas
 * DESCRIPTION:  STAT Performance Litmus Test for PROC GLIMMIX  
 *
 * SETUP INSTRUCTIONS: None.
 *
 *
 *   OUTPUT: None.
 *
 * SYSTEM REQUIREMENTS: None.
 *
 * ANTICIPATED RUNTIME:  minutes on Linux R64 (SPL Benchmark Standard).
 * TEST CHARACTERIZATION:  CPU Intensive
 *
 * SAS PRODUCTS INVOLVED:  STAT
 * SAS PROCEDURES INVOLVED: GLIMMIX  
 *
 * DATA SOURCE: SELF GENERATED
 * DATA CHARACTERIZATION: N/A 
 *
 * COMMENTS:
 * DISTRIBUTION STATUS:  Public
 * CONTRIBUTED BY: Cheryl LeSaint
 *
 * HISTORY:
 *   Date       Description                         Who
 *  19JUL13    Added to Mixed Analytic Workload     Tony
 *   
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

/* End of Data Setup Section */

/* Do NOT edit below this line! */


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


   /*** PROC GLIMMIX ***/;
data RawData;
  seed=232323;
  drop n;
  do n=1 to 3e7;
   call rantbl(seed,0.3,0.7,y);  y=y-1;
    flag=1; if ranuni(232323) < .4 then flag=-1;
    x1=ranuni(12345) + flag*y;
   output;
  end;
run;

proc glimmix data=RawData;
  model y=x1 / dist=binomial s;
run;	

proc delete data=work.rawdata;
quit;






  /***************************************************************************
 *                      END OF PROGRAM CODE SECTION
 ***************************************************************************/

/***************************************************************************
 *                       END OF TEST
 ****************************************************************************/
