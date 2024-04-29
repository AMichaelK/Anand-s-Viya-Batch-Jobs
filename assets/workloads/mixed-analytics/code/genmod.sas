/******************************************************************************
 * Copyright (c) 2013 by SAS Institute Inc, Cary NC 27511  USA
 *
 * This program is part of the Mixed Analytic Workload repository of
 *   test programs used to evaluate SAS concurrent workload.   
 *
 * NAME:  GENMOD.sas
 * DESCRIPTION: New GENMOD test from Leigh Ihnen.  PROC GENMOD.
 *
 * SETUP INSTRUCTIONS:
 *   Data for this test is static adn imported from a transport file.
 *
 *   OUTPUT:  none
 *
 * SYSTEM REQUIREMENTS:  NA
 *
 * ANTICIPATED RUNTIME:  34 minutes on LAX
 * TEST CHARACTERIZATION:  CPU Intensive
 *
 * SAS PRODUCTS INVOLVED:  Base SAS
 * SAS PROCEDURES INVOLVED: Data Step, GENMOD
 *
 * DATA SOURCE:  static -  genmod.tra
 * DATA CHARACTERIZATION:  n/a
 *
 * COMMENTS:
 * DISTRIBUTION STATUS:  Internal
 * CONTRIBUTED BY:  Leigh Ihnen
 *
 * HISTORY:
 *   Date       Description                       Who
 *  19Jul13   Converted to Std. Header for      
 *            Mixed Analytic Workload             Tony Brown
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

*libname neo "&data";


/*  Import in the transported SAS data file.                        */

/*******************************************************************************
 *                       END OF PROGRAM SETUP
 *******************************************************************************/
libname in  "&suiteloc/input/";
libname out "&suiteloc/output/";
proc cimport lib=work infile="&suiteloc/input/genmod&sysparm..tra";

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




data genmod;
set work.genmoddata;
run;

PROC GENMOD DATA=GENMOD ; 

class id2 sex program_year; 

model a1cb4 = PROGRAM_YEAR age rub sex MM 

                   PROGRAM_YEAR*age PROGRAM_YEAR*RUB PROGRAM_YEAR*SEX PROGRAM_YEAR*MM rub*rub 

                   PROGRAM_YEAR*age*RUB PROGRAM_YEAR*age*SEX PROGRAM_YEAR*age*MM AGE*RUB*SEX AGE*RUB*MM  RUB*SEX*MM

                  PROGRAM_YEAR*age*RUB*sex PROGRAM_YEAR*age*rub*MM age*rub*sex*MM PROGRAM_YEAR*age*rub*sex*MM 

                  / dist=BINOMIAL link=LOGIT type3 ;

repeated subject = id2 / type=ind;

contrast 'Comparing the Effect Program Year on A1c Tests' PROGRAM_Year 1 -1 ;

title1 'Test for LOGIT Model_1 - SATURATED';

title2 'Comparing the Effect Program Year on A1c Tests';

title3 'Controlling for AGE, MM, RUB and SEX WITH HIGHER-ORDER INTERACTIONS - STRUC=IND';

run;

 

PROC GENMOD DATA=GENMOD ; 

class id2 sex program_year; 

model a1cb4 = PROGRAM_YEAR age rub sex MM 

                   PROGRAM_YEAR*age PROGRAM_YEAR*RUB PROGRAM_YEAR*SEX PROGRAM_YEAR*MM rub*rub 

                   PROGRAM_YEAR*age*RUB PROGRAM_YEAR*age*SEX PROGRAM_YEAR*age*MM AGE*RUB*SEX AGE*RUB*MM  RUB*SEX*MM

                  PROGRAM_YEAR*age*RUB*sex PROGRAM_YEAR*age*rub*MM age*rub*sex*MM PROGRAM_YEAR*age*rub*sex*MM 

                  / dist=BINOMIAL link=LOGIT type3 ;

repeated subject = id2 / type=EXCH;

contrast 'Comparing the Effect Program Year on A1c Tests' PROGRAM_Year 1 -1 ;

title1 'Test for LOGIT Model_2 - SATURATED';

title2 'Comparing the Effect Program Year on A1c Tests';

title3 'Controlling for AGE, MM, RUB and SEX WITH HIGHER-ORDER INTERACTIONS - STRUC=EXCH';

run;

 

PROC GENMOD DATA=GENMOD ; 

class id2 sex program_year; 

model a1cb4 = PROGRAM_YEAR age rub sex MM 

                   PROGRAM_YEAR*age PROGRAM_YEAR*RUB PROGRAM_YEAR*SEX PROGRAM_YEAR*MM rub*rub 

                   PROGRAM_YEAR*age*RUB PROGRAM_YEAR*age*SEX PROGRAM_YEAR*age*MM AGE*RUB*SEX AGE*RUB*MM  RUB*SEX*MM

                  PROGRAM_YEAR*age*RUB*sex PROGRAM_YEAR*age*rub*MM age*rub*sex*MM PROGRAM_YEAR*age*rub*sex*MM 

                  / dist=BINOMIAL link=LOGIT type3 ;

repeated subject = id2 / type=UNSTR;

contrast 'Comparing the Effect Program Year on A1c Tests' PROGRAM_Year 1 -1 ;

title1 'Test for LOGIT Model_3 - SATURATED';

title2 'Comparing the Effect Program Year on A1c Tests';

title3 'Controlling for AGE, MM, RUB and SEX WITH HIGHER-ORDER INTERACTIONS - STRUC=UNSTR';

run;

 

 

PROC GENMOD DATA=GENMOD ; 

class id2 sex program_year; 

model a1cb4 = PROGRAM_YEAR age rub sex MM 

                   PROGRAM_YEAR*age PROGRAM_YEAR*MM PROGRAM_YEAR*RUB PROGRAM_YEAR*sex rub*rub 

                  / dist=BINOMIAL link=LOGIT type3 ;

repeated subject = id2 / type=ind;

contrast 'Comparing the Effect Program Year on A1c Tests' PROGRAM_Year 1 -1 ;

title1 'Test for LOGIT Model_1 ';

title2 'Comparing the Effect Program Year on A1c Tests';

title3 'Controlling for AGE, MM, RUB and SEX WITH FIRST ORDER INTERACTIONS - STRUC=IND';

run;

 
/****** This step errors on means limits
PROC GENMOD DATA=GENMOD ; 

class id2 sex program_year; 

model a1cb4 = PROGRAM_YEAR age rub sex MM 

                   PROGRAM_YEAR*age PROGRAM_YEAR*MM PROGRAM_YEAR*RUB PROGRAM_YEAR*sex rub*rub 

                  / dist=POISSON link=LOGIT type3 ;

repeated subject = id2 / type=ind;

contrast 'Comparing the Effect Program Year on A1c Tests' PROGRAM_Year 1 -1 ;

title1 'Test for LOGIT Model_2 ';

title2 'Comparing the Effect Program Year on A1c Tests';

title3 'Controlling for AGE, MM, RUB and SEX WITH FIRST ORDER INTERACTIONS - DIST=POI';

run;
********/
 

PROC GENMOD DATA=GENMOD ; 

class id2 sex program_year; 

model a1cb4 = PROGRAM_YEAR age rub sex MM 

                   PROGRAM_YEAR*age PROGRAM_YEAR*MM PROGRAM_YEAR*RUB PROGRAM_YEAR*sex rub*rub 

                  / dist=BINOMIAL link=LOGIT type3 ;

repeated subject = id2 / type=EXCH;

contrast 'Comparing the Effect Program Year on A1c Tests' PROGRAM_Year 1 -1 ;

title1 'Test for LOGIT Model_3 ';

title2 'Comparing the Effect Program Year on A1c Tests';

title3 'Controlling for AGE, MM, RUB and SEX WITH FIRST ORDER INTERACTIONS - STRUC=EXCH';

run;

/***************************************************************************
 *                      END OF PROGRAM CODE SECTION
 ***************************************************************************/

/***************************************************************************
 *                       END OF TEST
 ****************************************************************************/

