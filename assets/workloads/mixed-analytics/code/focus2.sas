 /******************************************************************************
 * Copyright (c) 2013 by SAS Institute Inc, Cary NC 27511  USA
 * This program is part of the Mixed Analytic Workload repository of
 *   test programs used to evaluate SAS concurrent workload.   
 *
 * PASS NAME:  focus2.sas
 * DESCRIPTION:  The test does a random effects mixed model with repeated 
 *   measures.  This is customer example.
 *    
 *    
 * SETUP INSTRUCTIONS:None.
 * OUTPUT:  none
 *
 * SYSTEM REQUIREMENTS:  This test works with default settings.
 *
 * ANTICIPATED RUNTIME:   00:19:30.00 
 * TEST CHARACTERIZATION:  Memory Intensive, CPU Intensive  
 *
 * SAS PRODUCTS INVOLVED: BASE			  
 * SAS PROCEDURES INVOLVED: DATA   
 *
 * DATA SOURCE: /$asuite/focus.dat  
 * DATA CHARACTERIZATION: Large Flat File 
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
%put &suiteloc;

*%let suiteloc=%sysget(ASUITE);

%let data= &suiteloc/input;   

filename in "&suiteloc/input/focus.dat"; */ /* location of source focus.dat  

/*
filename in "!BATCHJOBDIR/focus.dat";
*/
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


DATA one; INFILE in;
   INPUT ANIMAL $ MONTH $ SEASON $ PERIOD $ SEX $ POP $ AGE $ LENGTH MASS BINTOTAL FOCUS MMPT TIMESER;
   ONES=1;
RUN;
    
proc sort data=one; 
  by animal timeser;
run;

data f; 
   set one; 
   by animal timeser;
   if first.animal;
   keep animal ft;
   ft=floor(timeser);
run;

data one; 
   merge one f;
   by animal;
   time2=timeser-ft;
run;
		
PROC MIXED UPDATE ITDETAILS scoring=7 covtest;
   CLASS AGE SEX SEASON PERIOD POP ANIMAL;
   MODEL FOCUS=AGE SEX pop period season AGE*SEX AGE*POP 
         AGE*PERIOD AGE*SEASON SEX*POP SEX*PERIOD SEX*SEASON 
         POP*PERIOD POP*SEASON PERIOD*SEASON AGE*SEX*POP AGE*SEX*PERIOD
         AGE*SEX*SEASON AGE*POP*PERIOD AGE*POP*SEASON AGE*PERIOD*SEASON 
         SEX*POP*PERIOD SEX*POP*SEASON SEX*PERIOD*SEASON 
         POP*PERIOD*SEASON /ddfm=satterth;
   RANDOM intercept /subject=ANIMAL(POP AGE SEX);
   random season(pop sex age) period(pop sex age) season*period(pop sex age);
   REPEATED/TYPE=sp(sph)(time2) local SUBJECT=Animal(pop);
   PARMS (.006)(.004)(.002)(.002)(.005) (5) (.04);
   LSMEANS age sex pop period season age*sex age*pop age*period age*season
           sex*pop sex*period sex*season pop*period pop*season period*season
           AGE*SEX*PERIOD AGE*SEX*SEASON AGE*POP*PERIOD AGE*POP*SEASON AGE*PERIOD*SEASON 
           SEX*POP*PERIOD SEX*POP*SEASON SEX*PERIOD*SEASON POP*PERIOD*SEASON;
   
 
RUN;

/***************************************************************************
 *                      END OF PROGRAM CODE SECTION
 ***************************************************************************/

/***************************************************************************
 *                       END OF TEST
 ****************************************************************************/
