/******************************************************************************
 * Copyright (c) 2013 by SAS Institute Inc, Cary NC 27511  USA
 *
 * This program is part of the Mixed Analytic Workload repository of
 *   test programs used to evaluate SAS concurrent workload.   
 *
 * NAME:  comp_test5a.sas
 * DESCRIPTION:
 *   This computational test is a numercially intensive test using
 *   GLM (General Linear Model).  It is an artifical example.
 *
 * SETUP INSTRUCTIONS:  This test artifically generates the data it needs 
 *   for the GLM procedure within the code.
 *
 *   OUTPUT:  none
 *
 * SYSTEM REQUIREMENTS:  This test runs with the default settings.
 *
 * ANTICIPATED RUNTIME:  less than a minute
 * TEST CHARACTERIZATION:  CPU Intensive  
 *
 * SAS PRODUCTS INVOLVED:  Base SAS, SAS/STAT
 * SAS PROCEDURES INVOLVED:  GLM
 *
 * DATA SOURCE:  Created within the SAS job.
 * DATA CHARACTERIZATION:  SELF GENERATED
 *
 * COMMENTS:
 * DISTRIBUTION STATUS:  External
 * CONTRIBUTED BY:  Margaret Crevar
 *
 * HISTORY:
 *   Date       Description                       Who
 *    
 *   19Jul13   Added to Mixed Analytic Workload   Tony Brown
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

TITLE 'GLM24: COMPARE TIME REQUIREMENTS FOR LARGE MODEL';
/* We are creating a temporary data set... */
DATA work.TEST1;
  DO A=0,1,2,3,4;
    DO B=0,1,2,3,4;
      DO C=0,1,2,3;
        DO D=0,1;
          DO E=1 TO 20;
            DO F=1 TO 10;
              DO I=1 TO 2;
                Y1=2*A+B-C+D-2*F+RANNOR(11111);
                Y2=Y1+F+RANNOR(33333);
                Y3=Y1-Y2+RANNOR(54321);
                Y4=2*Y3+Y1+RANNOR(12345);
                Y5=Y4-Y2+RANNOR(32135);
                OUTPUT;
              END;
            END;
          END;
        END;
      END;
    END;
  END;
  DROP I;
DATA work.TEST1;
  SET work.TEST1;
  IF MOD(_N_,4)=0 THEN Y1=.;
  IF MOD(_N_,6)^=0 THEN Y2=.;
  IF MOD(_N_,3)^=0 THEN Y3=.;
  IF MOD(_N_,3)^=2 THEN Y4=.;
run;

PROC GLM DATA=WORK.TEST1;
  TITLE2 'REQUESTING SS1 AND SS4';
  CLASS A B C D E F;
  MODEL Y1-Y5=A B C D A*B A*C A*D B*C C*D A*B*C*D F A*F B*F C*F D*F
              A*B*F A*C*F A*D*F B*C*F C*D*F E(A*B*C*D)/SS1 SS4;
  MEANS A B C D A*B A*C A*D B*C C*D A*B*C*D/DUNCAN;
  TEST H=A B C D A*B A*C A*D B*C C*D A*B*C*D
       E=E(A*B*C*D);
RUN;
QUIT;

PROC GLM DATA=work.TEST1;
  TITLE2 'DEFAULTING TO SS1 AND SS3';
  CLASS A B C D E F;
  MODEL Y1-Y5=A B C D A*B A*C A*D B*C C*D A*B*C*D F A*F B*F C*F D*F
                  A*B*F A*C*F A*D*F B*C*F C*D*F E(A*B*C*D);
  MEANS A B C D A*B A*C A*D B*C C*D A*B*C*D/DUNCAN;
  TEST H=A B C D A*B A*C A*D B*C C*D A*B*C*D
       E=E(A*B*C*D);
RUN;
QUIT;


/***************************************************************************
 *                      END OF PROGRAM CODE SECTION
 ***************************************************************************/

/***************************************************************************
 *                       END OF TEST
 ****************************************************************************/
