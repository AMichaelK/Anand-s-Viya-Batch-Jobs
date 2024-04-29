 /******************************************************************************
 * Copyright (c) 2013 by SAS Institute Inc, Cary NC 27511  USA
 * This program is part of the Mixed Analytic Workload repository of
 *   test programs used to evaluate SAS concurrent workload.   
 *
 * PASS NAME:  HPMIXED.sas

 * DESCRIPTION:  STAT Performance test for PROC HPMIXED  
 *    
 *    
 * SETUP INSTRUCTIONS:None.
 * OUTPUT:  none
 *
 * SYSTEM REQUIREMENTS:  This test works with default settings.
 *
 * ANTICIPATED RUNTIME:   00:14:00.00 
 * TEST CHARACTERIZATION:  CPU  Intensive  
 *
 * SAS PRODUCTS INVOLVED: BASE			  
 * SAS PROCEDURES INVOLVED: DATA, HPMIXED   
 *
 * DATA SOURCE: focus.dat flat file
 * DATA CHARACTERIZATION: Large Flat Files 
 *
 * COMMENTS:
 * DISTRIBUTION STATUS:  External
 * CONTRIBUTED BY: Leigh Ihnen   
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
%let txt_loc = &suiteloc/input;
%let out_loc = &suiteloc/output;

%put &out_loc;
%put &out_loc;

filename in ("&suiteloc/input/pumsaxca_&sysparm..txt");
libname o BASE "&out_loc";
%LET HSET=o.HRECS_ca_&sysparm.;
%LET PSET=o.PRECS_ca_&sysparm.;


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
 *                        PROGRAM CODE SECTION
 ***************************************************************************/

  /*** proc hpmixed ***/;
%let nobs=5e6;
%let nclass=20;
%let ncov=20;
%let nlev=50;

data hpm159;
drop i;
array c c1-c&nclass;
array x x1-x&ncov;
kte=7;
do i=1 to &nobs;
  do over c;
    c=ranbin(1,&nlev,.5);
    x=ranuni(5);
    end;
  y=ranuni(3);
  output;
  end;
run;

proc hpmixed data=hpm159;
class c1-c&nclass;
effect cx=collection(c1-c&nclass x1-x&ncov/details);
model y=x1 cx;
random x2;
run;

proc delete data=work.hpm159;
quit;


/***************************************************************************
 *                         PROGRAM CODE SECTION
 ***************************************************************************/

  /***************************************************************************
 *                      END OF PROGRAM CODE SECTION
 ***************************************************************************/

/***************************************************************************
 *                       END OF TEST
 ****************************************************************************/
