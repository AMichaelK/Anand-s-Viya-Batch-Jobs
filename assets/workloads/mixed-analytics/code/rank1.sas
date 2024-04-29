/******************************************************************************
 *  Copyright (c) 2013 by SAS Institute Inc, Cary NC 27511  USA
 *
 * This program is part of the Mixed Analytic Workload repository of
 *   test programs used to evaluate SAS concurrent workload.   
 *
 * NAME:  RANK1.sas
 *
 * DESCRIPTION: This test generates a large dataset and uses it as a training
 *              dataset to perform an intensive RANK proceedure.
 *
 * SETUP INSTRUCTIONS:
 *     Data for this test is provided by generated data.
 *
 * OUTPUT:  PROC SUMMARY Output
 *
 * SYSTEM REQUIREMENTS:  2 GB RAM
 *
 * ANTICIPATED RUNTIME:  Approximately 10 hours
 * TEST CHARACTERIZATION:  CPU
 *
 * SAS PRODUCTS INVOLVED:  Base SAS
 * SAS PROCEDURES INVOLVED: Proc Rank, Proc Means
 *
 * DATA SOURCE: Gendata1
 * DATA CHARACTERIZATION:  n/a
 *
 * COMMENTS:
 * DISTRIBUTION STATUS:  Internal
 * CONTRIBUTED BY:        Leigh Ihnen
 *
 * HISTORY:
 *   Date       Description                       Who
 *  19JUL13     Added to Mixed Analytic Workload  Tony Brown
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
/*** Assign Rank_Test 1 data generation quantity to macros                  ***/
%let nvar=200;
%let nobs=1000000;

/*** Assign Rank_Test 1 Libname for data creation, storage, and usage       ***/
*%let data=/SASWORK;
*libname data "&data";

/*** Add Options Not Covered by PASS MACRO CODE                             ***/
options nocenter nodate nonumber ;

/*** Assign Macro Variables Used in Rank_Test Code                          ***/
%let train=work.testdata;
%let target=response ;
%let tobs=max ;
/* Do NOT edit below this line! */

 
/* End of Data Setup Section */

/* Do NOT edit below this line! */

 
/*******************************************************************************
 *                       END OF PROGRAM SETUP
 *******************************************************************************/

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


/*** Generate Data ***/

data work.testdata&nvar;
     keep response x1-x&nvar;
     array x x1-x&nvar;
     array limit limit1-limit&nvar;
     do i=1 to &nvar;
        limit[i]=1+int(10000*ranuni(123456789));
     end;

     do i=1 to &nobs;
        response=ranuni(1235679);
        do j=1 to &nvar;
           x[j]=int(limit[j]*ranuni(123456789));
        end;
        output;
     end;
run;

/***************************************************************************/
/***  META MACRO                                                         ***/
/***                                                                     ***/
/***  Figures out which vars should be interval and                      ***/
/***  which should be class (binary).  Sets macro vars                   ***/
/***  used in running the procedures.                                    ***/
/***                                                                     ***/
/***  Assumes all non-target variables are numeric                       ***/
/***************************************************************************/

%macro meta( inds=inds , obs=10000000 , target=target ) ;   /*** Start Meta Macro ***/

     %GLOBAL CLASS ;
     %GLOBAL BINARY ;
     %GLOBAL INTERVAL ;
     %GLOBAL RINTVAL;

     title 'Means of data set' ;
     proc means data=&inds(obs=&obs) noprint min max mean sum ;
          output out=means(drop=_type_ _freq_ ) ;
     run ;

     *proc print data=means; run ;

     proc sort data=means;
          by _stat_ ;
     run ;

     proc transpose data=means out=tmeans;
          id _stat_ ;
     run ;

     data tmeans ;
          set tmeans ( drop= n where=(lowcase(_name_) ne lowcase("&target") )) ;
          length level $8 ;
          if min eq max then
             level= 'unary'   ;
          else if index(lowcase(_label_),'binary') then
               level= 'binary' ;
          else if index(lowcase(_label_),'bin.') then
               level= 'binary' ;
          else if min eq 0 and max eq 1 then
               level= 'maybe' ;
          else level= 'interval' ;
     run ;

     proc sort data=tmeans ;
          by descending level _name_ ;
     run ;

     *proc print data=tmeans ;
     *title 'Initial levels for variables' ;
     *run ;

     %let MAYBE=;
     %let INTERVAL=;
     %let RINTVAL=;
     %let BINARY=;

     data _null_ ;
          set tmeans ;
          if level eq 'interval' then do;
             call symput('INTERVAL', symget('INTERVAL') !! ' ' !! _NAME_ )  ;
             call symput('RINTVAL', symget('RINTVAL') !! ' R' !! _NAME_ )  ;
          end;
          if level eq 'binary'  then
             call symput('BINARY'  , symget('BINARY') !! ' ' !! _NAME_ )  ;
          if level eq 'maybe' then
             call symput('MAYBE', symget('MAYBE') !! ' ' !! _NAME_ )  ;
     run ;

     %put INITIAL INTERVAL variables: ;
     %put &INTERVAL;
     %put  ;
     %put ININTIAL RINTVAL variables: ;
     %put  &RINTVAL;
     %put ;
     %put INITIAL BINARY variables: ;
     %put &BINARY;
     %put  ;
     %put INITIAL MAYBE variables: ;
     %put &MAYBE ;

     %let dsid= %sysfunc(open(tmeans)) ;
     %let nobs= %sysfunc(attrn(&dsid,nobs)) ;
     %let dsid= %sysfunc(close(&dsid)) ;
     %put Total number of variables= &nobs ;

     data _tmp ;
          set tmeans(where=(level='maybe')) ;
     run ;

     %let dsid= %sysfunc(open(_tmp)) ;
     %let nobs= %sysfunc(attrn(&dsid,nobs)) ;
     %let dsid= %sysfunc(close(&dsid)) ;
     %put Total number of maybe variables= &nobs ;

     %if %eval(&nobs > 0) %then %do ;
         proc freq data=&inds(obs=&nobs) noprint ;
         %do i=1 %to &nobs ;
             %let var= %scan( &MAYBE , &i, ' ' ) ;
             table &var / out= &var ;
         %end ;
         run ;

         %do i=1 %to &nobs ;
             %let var= %scan( &MAYBE , &i, ' ' ) ;
             data &var ;
             set &var ;
             where percent ne . ;
             run ;
         %end ;

         %do i=1 %to &nobs ;
             %let var= %scan( &MAYBE , &i, ' ' ) ;
             %let dsid=%sysfunc(open(&var)) ;
             %let fobs=%sysfunc(attrn(&dsid,nobs)) ;
             %let disd=%sysfunc(close(&dsid)) ;
             %if %eval(&fobs gt 2 ) %then %do;
                 %let INTERVAL = &INTERVAL &VAR ;
                 %let RINTVAL= &RINTVAL R&VAR;
             %end;

             %if %eval(&fobs eq 2 ) %then
                 %let BINARY   = &BINARY &VAR ;
             %if %eval(&fobs eq 1 ) %then
                 %put UNARY VARIABLE DETECTED: &var ;
         %end ;

         proc delete data=
         %do i=1 %to &nobs ;
             %let var= %scan( &MAYBE , &i, ' ' ) ;
             &var
         %end ;
         run ;

         %let MAYBE=;
     %end ;

     %put ; %put ; %put ;
     %put FINAL INTERVAL variables: ;
     %put &INTERVAL;
     %put  ;
     %put FINAL RINTVAL variables: ;
     %put &RINTVAL ;
     %put ;
     %put FINAL BINARY variables: ;
     %put &BINARY;
     %put  ;
     %put FINAL MAYBE variables: ;
     %put &MAYBE ;
     %put ; %put ; %put ;

     proc rank data=&inds(obs=&obs) out=outrank group=100;
          var &interval;
          ranks &rintval;
     run;

     %let i=1;
     %let var= %scan( &interval , &i, ' ' ) ;
     %let rvar= %scan( &Rintval , &i, ' ' ) ;
     %do %while(%length(&var)>0);
         proc summary data=outrank;
              class &rvar;
              var &var;
              output out=&var mean=mean n=n min=min max=max;
         run;
         %let var= %scan( &interval , &i, ' ' ) ;
         %let rvar= %scan( &Rintval , &i, ' ' ) ;
         %let i = %eval(&i+1);
     %end;
%mend meta;                                             /*** End Meta Macro***/

/***************************************************************************/
/***                   END OF MACRO CREATION                             ***/
/***************************************************************************/
/***                                                                     ***/
/***                   START MACRO PROGRAM                               ***/
/***                                                                     ***/
/***************************************************************************/

option nomprint;   /*** Turn off the mprint to save log space ***/

%meta( inds=&train.&nvar ,obs=100000000 , target=&target ) ;
/***************************************************************************
 *                        END OF PROGRAM CODE SECTION
 ***************************************************************************/
/***************************************************************************
 *                                END OF TEST
 ****************************************************************************/
