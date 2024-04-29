/******************************************************************************
 * Copyright (c) 2013 by SAS Institute Inc, Cary NC 27511  USA
 * This program is part of the Mixed Analytic Workload repository of
 *   test programs used to evaluate SAS concurrent workload.   
 *
 * PASS NAME:  CENSUS.sas
 * DESCRIPTION: Census File Read & Global Parms Maniuplation
 *    
 *    
 * SETUP INSTRUCTIONS: Uses PUMS files    
 *
 * OUTPUT:  none
 *
 * SYSTEM REQUIREMENTS:  This test works with default settings.
 *
 * ANTICIPATED RUNTIME:   10 minutes 
 * TEST CHARACTERIZATION:  I/O Intensive  
 *
 * SAS PRODUCTS INVOLVED:  BASE 
 * SAS PROCEDURES INVOLVED:   DATA
 *
 * DATA SOURCE: PUMS Files in /$asuite/input  
 * DATA CHARACTERIZATION:   Flat Files
 *
 * COMMENTS:
 * DISTRIBUTION STATUS:  External
 * CONTRIBUTED BY: Magaret Crevar  
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

/********************************************************************/
/*                                                                  */
/*  This test reads raw PUMS file from from "in" and writes 2 SAS   */
/*  data sets as specified by user-defined global parms HRECS and   */
/*  PRECS (for HOUSEHOLD and PERSON data, respectively).  This      */
/*  test is very I/O intenstive.                                    */
/*                                                                  */
/*  If you run the test as is, it will create the HRECS data set    */
/*  which is ~1.1 gigabytes in size (5,527,046 records and 115      */
/*  columns) and it will create the PRECS data set which is ~2.8    */
/*  gigabytes in size (12,501,406 records and 128 columns).         */
/*                                                                  */
/*  If you would like to create larger or smaller files, please     */
/*  contact Margaret Crevar at 919/677-8000 ext 7095 for            */
/*  instructions on how to modify this program.                     */
/*                                                                  */
/********************************************************************/


/*  If your data will be in different location, simply change the   */
/*  path names in the next two statements.                          */


/*  You should not need to modify any statements below this point.  */
filename in ("&suiteloc/cdata/pumsaxak.txt"
"&suiteloc/cdata/pumsaxal.txt" "&suiteloc/cdata/pumsaxar.txt" "&suiteloc/cdata/pumsaxaz.txt"
"&suiteloc/cdata/pumsaxca.txt" "&suiteloc/cdata/pumsaxco.txt" "&suiteloc/cdata/pumsaxct.txt"
"&suiteloc/cdata/pumsaxdc.txt" "&suiteloc/cdata/pumsaxde.txt" "&suiteloc/cdata/pumsaxfl.txt"
"&suiteloc/cdata/pumsaxga.txt" "&suiteloc/cdata/pumsaxhi.txt" "&suiteloc/cdata/pumsaxia.txt"
"&suiteloc/cdata/pumsaxid.txt" "&suiteloc/cdata/pumsaxil.txt" "&suiteloc/cdata/pumsaxin.txt"
"&suiteloc/cdata/pumsaxks.txt" "&suiteloc/cdata/pumsaxky.txt" "&suiteloc/cdata/pumsaxla.txt"
"&suiteloc/cdata/pumsaxma.txt" "&suiteloc/cdata/pumsaxmd.txt" "&suiteloc/cdata/pumsaxme.txt" 
"&suiteloc/cdata/pumsaxmi.txt" "&suiteloc/cdata/pumsaxmn.txt" "&suiteloc/cdata/pumsaxmo.txt"
"&suiteloc/cdata/pumsaxms.txt" "&suiteloc/cdata/pumsaxmt.txt" "&suiteloc/cdata/pumsaxnc.txt"
"&suiteloc/cdata/pumsaxnd.txt" "&suiteloc/cdata/pumsaxne.txt" "&suiteloc/cdata/pumsaxnh.txt"
"&suiteloc/cdata/pumsaxnj.txt" "&suiteloc/cdata/pumsaxnm.txt" "&suiteloc/cdata/pumsaxnv.txt" 
"&suiteloc/cdata/pumsaxny.txt" "&suiteloc/cdata/pumsaxoh.txt" "&suiteloc/cdata/pumsaxok.txt"
"&suiteloc/cdata/pumsaxor.txt" "&suiteloc/cdata/pumsaxpa.txt" "&suiteloc/cdata/pumsaxri.txt" 
"&suiteloc/cdata/pumsaxsc.txt" "&suiteloc/cdata/pumsaxsd.txt" "&suiteloc/cdata/pumsaxtn.txt"
"&suiteloc/cdata/pumsaxtx.txt" "&suiteloc/cdata/pumsaxut.txt" "&suiteloc/cdata/pumsaxva.txt"
"&suiteloc/cdata/pumsaxvt.txt" "&suiteloc/cdata/pumsaxwa.txt" "&suiteloc/cdata/pumsaxwi.txt"
"&suiteloc/cdata/pumsaxwv.txt" "&suiteloc/cdata/pumsaxwy.txt"); 

libname census BASE "&suiteloc/input";

%LET HSET=census.hrecs_&sysparm.;
%LET PSET=census.precs_&sysparm.;


/********************************************************************/
 %GLOBAL REVDATE;  %LET REVDATE=19JAN94; *<----DATE OF LAST REVISION;

/* UPDATE HISTORY:
   1-19-94: IF PROBLEM ENCOUNTERED ON INPUT FILE (EXPECTED H RECORD
          NOT FOUND) WE CHANGED THE 'STOP' STMT TO AN 'ABORT RETURN
          911' STATEMENT.                                           */

  %PUT %STR( );
  %PUT ***************************************************************;
  %PUT *       PUMS90C CODE REV. &REVDATE BEGIN EXECUTION             *;
  %PUT *           MISSOURI STATE CENSUS DATA CENTER                 *;
  %PUT ***************************************************************;
  %PUT %STR( );

*---THE INVOKING PROGRAM ***MUST*** SPECIFY THE FOLLOWING TWO GLOBAL
    PARMS PRIOR TO INVOKING THE CODE.  the values are the names of
    the h and p data sets created by the generated data step---;

*--THE FOLLOWING GLOBAL PARMS ARE A CODING CONVENIENCE AND SHOULD
   NOT BE CHANGED--;
%let idvars= SAMPLE DIVISION STATE PUMA AREATYPE MSAPMSA PSA SUBSAMPL ;
%let hvars= HOUSWGT PERSONS GQINST  UNITS1 HUSFLAG PDSFLAG ROOMS
 TENURE ACRE10 COMMUSE VALUE RENT1 MEALS VACANCY1 VACANCY2 VACANCY3
 VACANCY4 YRMOVED BEDROOMS PLUMBING KITCHEN TELEPHON AUTOS FUELHEAT
 WATER SEWAGE YRBUILT CONDO ONEACRE AGSALES ELECCOST GASCOST WATRCOST
 FUELCOST RTAXAMT INSAMT MORTGAG MORTGAG3 TAXINCL INSINCL
 MORTGAG2 MORTAMT2 CONDOFEE MOBLHOME RFARM RGRENT RGRAPI
 ROWNRCST RNSMOCPI RRENTUNT RVALUNT RFAMINC RHHINC RWRKR89 RHHLANG
 RLINGISO RHHFAMTP RNATADPT RSTPCHLD RFAMPERS NRELCHLD RNONREL R18UNDR
 R60OVER R65OVER RSUBFAM;
%let havars= AUNITS1 AROOMS ATENURE AACRES1 ACOMMUSE AVALUE ARENT1
 AMEALS AVACNCY2 AVACNCY3 AVACNCY4 AYRMOVED ABEDROOM APLUMBNG AKITCHEN
 APHONE AVEHICLE AFUEL AWATER ASEWER AYRBUILT ACONDO AONEACRE AAGSALES
 AELECCST AGASCST AWATRCST FUELCST ATAXAMT AINSAMT AMORTG AMORTG3
 ATAXINCL AINSINCL AMORTG2 AMRTAMT2 ACNDOFEE AMOBLHME ;
%let havars2= AUNITS1 AROOMS ATENURE AACRES1 ACOMMUSE AVALUE ARENT1
 AMEALS AVACNCY2 AVACNCY3 AVACNCY4 AYRMOVED ABEDROOM APLUMBNG AKITCHEN
 APHONE AVEHICLE AFUEL AWATER ASEWER ACONDO AONEACRE AAGSALES
 AELECCST AGASCST AWATRCST FUELCST ATAXAMT AINSAMT AMORTG3
 ATAXINCL AINSINCL AMORTG2 AMRTAMT2 ACNDOFEE AMOBLHME ;
%let PVARS= RELAT1 SEX RACE AGE MARITAL PWGT1 REMPLPAR
 RPOB RSPOUSE ROWNCHLD RAGECHLD RRELCHLD RELAT2 SUBFAM2 SUBFAM1 HISPANIC
 POVERTY POB CITIZEN IMMIGR SCHOOL YEARSCH ANCSTRY1 ANCSTRY2 MOBILITY
 MIGSTATE MIGPUMA LANG1 LANG2 ENGLISH MILITARY RVETSERV SEPT80 MAY75880
 VIETNAM FEB55 KOREAN WWII OTHRSERV YRSSERV DISABL1 DISABL2 MOBILLIM
 PERSCARE FERTIL RLABOR WORKLWK HOURS POWSTATE POWPUMA MEANS RIDERS
 DEPART TRAVTIME TMPABSNT LOOKING AVAIL YEARWRK INDUSTRY OCCUP CLASS
 WORK89 WEEK89 HOUR89 REARNING RPINCOME INCOME1 INCOME2 INCOME3 INCOME4
 INCOME5 INCOME6 INCOME7 INCOME8 AAUGMENT;
%let pavars= ARELAT1 ASEX ARACE AAGE AMARITAL AHISPAN ABIRTHPL ACITIZEN
 AIMMIGR ASCHOOL AYEARSCH AANCSTR1 AANCSTR2 AMOBLTY AMIGSTAT ALANG1
 ALANG2 AENGLISH AVETS1 ASERVPER AYRSSERV ADISABL1 ADISABL2 AMOBLLIM
 APERCARE AFERTIL ALABOR AHOURS APOWST AMEANS ARIDERS ADEPART ATRANTME
 ALSTWRK AINDUSTR AOCCUP ACLASS AWORK89 AWKS89 AHOUR89 AINCOME1 AINCOME2
 AINCOME3 AINCOME4 AINCOME5 AINCOME6 AINCOME7 AINCOME8;
%let pavars1= ARELAT1 ASEX ARACE AAGE AMARITAL AHISPAN ABIRTHPL ACITIZEN
 AIMMIGR ASCHOOL AYEARSCH AANCSTR1 AANCSTR2 AMOBLTY AMIGSTAT ALANG1
 ALANG2 AENGLISH AVETS1 ASERVPER AYRSSERV ADISABL1 ADISABL2 AMOBLLIM
 APERCARE AFERTIL ALABOR AHOURS APOWST AMEANS ARIDERS ADEPART ATRANTME
 ALSTWRK AINDUSTR AOCCUP ACLASS AWORK89 AWKS89 AHOUR89;
%let pavars2=AINCOME1 AINCOME2
 AINCOME3 AINCOME4 AINCOME5 AINCOME6 AINCOME7 AINCOME8;


DATA &HSET(LABEL='PUMS HOUSEHOLD DATA SET'
  KEEP=year RECTYPE SERIALNO &IDVARS &HVARS &HAVARS)
     &PSET(LABEL='PUMS PERSON DATA SET'
 KEEP=year RECTYPE SERIALNO STATE PUMA &PVARS &PAVARS);
 /************************************************/
 /* Added year variable for future replication   */
 /************************************************/

 retain year 1990;

 INFILE IN lrecl=231;
   LENGTH DEFAULT=4;
   INPUT
   RECTYPE $1. @;
 IF RECTYPE NE 'H' THEN DO;
 * FILE LOG;* PUT '****EROR READING PUMS IN FILE: EXPECTED H RECORD '
    'NOT FOUND.  CHECK FILE AND/OR PROGRAM****' / _ALL_;
     return ;   *<====replaces stop stmt, 1-94====;
    END;
 *---READ THE H RECORD WHICH WILL TELL US HOW MANY P RECORDS WILL
     FOLLOW.  WE WILL THEN READ THE P RECORDS IN A LOOP--*;
  INPUT
   SERIALNO $7.
   SAMPLE $1.  DIVISION $1.  STATE $2.  PUMA $5.  AREATYPE $2.  MSAPMSA
   $4.  PSA $3.  SUBSAMPL $2.  HOUSWGT 4.  PERSONS 2.  GQINST $1.
   +3  UNITS1 $2.  HUSFLAG $1.  PDSFLAG $1.  ROOMS 1.  TENURE  $1.
   ACRE10 $1.  COMMUSE $1.  VALUE $2.  RENT1 $2.  MEALS $1.
   VACANCY1 $1.  VACANCY2 $1.  VACANCY3 $1.  VACANCY4 $1.  YRMOVED $1.
   BEDROOMS $1.  PLUMBING $1.  KITCHEN $1.  TELEPHON $1.  AUTOS $1.
   FUELHEAT $1.  WATER $1.  SEWAGE $1.  YRBUILT $1.  CONDO $1.  ONEACRE
   $1.  AGSALES $1.  ELECCOST 4.  GASCOST 4.  WATRCOST 4.  FUELCOST 4.
   RTAXAMT $2.  +3 INSAMT 4.  MORTGAG $1.  MORTGAG3 5.  TAXINCL $1.
   INSINCL $1.  MORTGAG2 $1.  MORTAMT2 5.  CONDOFEE 4.  MOBLHOME 4.
   RFARM $1.  RGRENT 4.  RGRAPI $2.  +1 ROWNRCST 5.  RNSMOCPI 3.
   RRENTUNT $1.  RVALUNT $1.  RFAMINC 7.  RHHINC 7.  RWRKR89 $1.
   RHHLANG $1.  RLINGISO $1.  RHHFAMTP $2.  RNATADPT 2.  RSTPCHLD 2.
   RFAMPERS 2.  NRELCHLD 2.  RNONREL $1.  R18UNDR $1.  R60OVER $1.
   R65OVER $1.  RSUBFAM $1.  AUNITS1 $1.  AROOMS $1.  ATENURE $1.
   AACRES1 $1.  ACOMMUSE $1.  AVALUE $1.  ARENT1 $1.  AMEALS $1.
   AVACNCY2 $1.  AVACNCY3 $1.  AVACNCY4 $1.  AYRMOVED $1.  ABEDROOM $1.
   APLUMBNG $1.  AKITCHEN $1.  APHONE $1.  AVEHICLE $1.  AFUEL $1.
   AWATER $1.  ASEWER $1.  AYRBUILT $1.  ACONDO $1.  AONEACRE $1.
   AAGSALES $1.  AELECCST $1.  AGASCST $1.  AWATRCST $1.  FUELCST $1.
   ATAXAMT $1.  AINSAMT $1.  AMORTG $1.  AMORTG3 $1.  ATAXINCL $1.
   AINSINCL $1.  AMORTG2 $1.  AMRTAMT2 $1.  ACNDOFEE $1.  AMOBLHME $1. ;

link hholdchk;
   OUTPUT &HSET;
   IF PERSONS GT 0 THEN DO _NP_=1 TO PERSONS;
     INPUT
     RECTYPE $1.  SERIALNO $7.  RELAT1 $2.  SEX $1.  RACE $3.  AGE 2.
     MARITAL $1.  PWGT1 4.  +4 REMPLPAR $3.  RPOB $2.  RSPOUSE $1.
     ROWNCHLD $1.  RAGECHLD $1.  RRELCHLD $1.  RELAT2 $1.  SUBFAM2 $1.
     SUBFAM1 $1.  HISPANIC $3.  POVERTY 3.  POB $3.  CITIZEN $1.  IMMIGR
     $2.  SCHOOL $1.  YEARSCH $2.  ANCSTRY1 $3.  ANCSTRY2 $3.  MOBILITY
     $1.  MIGSTATE $2.  MIGPUMA $5.  LANG1 $1.  LANG2 $3.  ENGLISH $1.
     MILITARY $1.  RVETSERV $2.  SEPT80 $1.  MAY75880 $1.  VIETNAM $1.
     FEB55 $1.  KOREAN $1.  WWII $1.  +1 OTHRSERV $1.  YRSSERV 2.
     DISABL1 $1.  DISABL2 $1.  MOBILLIM $1.  PERSCARE $1.  FERTIL $2.
     RLABOR $1.  WORKLWK $1.  HOURS 2.  POWSTATE $2.  POWPUMA $5.  MEANS
     $2.  RIDERS 1.  DEPART $4.  TRAVTIME 2.  TMPABSNT $1.  LOOKING $1.
     AVAIL $1.  YEARWRK $1.  INDUSTRY $3.  OCCUP $3.  CLASS $1.  WORK89
     $1.  WEEK89  2.  HOUR89 2.  REARNING 6.  RPINCOME 6.  INCOME1 6.
     INCOME2 6.  INCOME3 6.  INCOME4 6.  INCOME5 5.  INCOME6 5.  INCOME7
     5.  INCOME8 5.  AAUGMENT $1.  ARELAT1 $1.  ASEX $1.  ARACE $1.
     AAGE $1.  AMARITAL $1.  AHISPAN $1.  ABIRTHPL $1.  ACITIZEN $1.
     AIMMIGR $1.  ASCHOOL $1.  AYEARSCH $1.  AANCSTR1 $1.  AANCSTR2 $1.
     AMOBLTY $1.  AMIGSTAT $1.  ALANG1 $1.  ALANG2 $1.  AENGLISH $1.
     AVETS1 $1.  ASERVPER $1.  AYRSSERV $1.  ADISABL1 $1.  ADISABL2 $1.
     AMOBLLIM $1.  APERCARE $1.  AFERTIL $1.  ALABOR $1.  AHOURS $1.
     APOWST $1.  AMEANS $1.  ARIDERS $1.  ADEPART $1.  ATRANTME $1.
     ALSTWRK $1.  AINDUSTR $1.  AOCCUP $1.  ACLASS $1.  AWORK89 $1.
     AWKS89 $1.  AHOUR89 $1.  AINCOME1 $1.  AINCOME2 $1.  AINCOME3 $1.
     AINCOME4 $1.  AINCOME5 $1.  AINCOME6 $1.  AINCOME7 $1.  AINCOME8
     $1. ;
     link perschk;
     OUTPUT &PSET;
     length rfaminc rhhinc 5; *<---the only 7-digit numerics--;
     length rooms week89 hour89 rnatadpt rstpchld rfampers Nrelchld
           riders travtime
           yrsserv 3; *<===edit "00002" for non-MVS platforms-;
     END;
RETURN;

 LABEL
   RECTYPE='Record Type'
   SERIALNO='Serial #: Housing Unit ID'
   SAMPLE='Sample Identifier'
   DIVISION='Division code'
   STATE='State Code'
   PUMA='Public Use Microdata Area (State Dpndnt)'
   AREATYPE='Area Type Rev. for PUMS Equivalency fl'
   MSAPMSA='MSA/PMSA'
   PSA='PLANNING SRVC AREA (ELDERLY SAMPLE ONLY)'
   SUBSAMPL='SUBSAMPLE NUMBER (USE TO PULL EXTRACTS)'
   HOUSWGT='Housing Weight'
   PERSONS='Number of person records this house'
   GQINST='Group quarters institution'
   UNITS1='Units in structure'
   HUSFLAG='All 100% housing unit data substituted'
   PDSFLAG='All 100% person data substituted'
   ROOMS='Rooms'
   TENURE='Tenure'
   ACRE10='On ten acres or more'
   COMMUSE='Business or medical office on property'
   VALUE='Property value'
   RENT1='Monthly rent'
   MEALS='Meals included in rent'
   VACANCY1='Vacant usual home elsewhere (UHE)'
   VACANCY2='Vacancy status'
   VACANCY3='Boarded up status'
   VACANCY4='Months vacant'
   YRMOVED='When moved into this house or apartment'
   BEDROOMS='Bedrooms'
   PLUMBING='Complete plumbing facilities'
   KITCHEN='Complete kitchen facilities'
   TELEPHON='Telephone in Unit'
   AUTOS='Vehicles (1 ton or less) available'
   FUELHEAT='House heating fuel'
   WATER='Source of water'
   SEWAGE='Sewage disposal'
   YRBUILT='When structure first built'
   CONDO='House or apartment part of condominium'
   ONEACRE='House on less than 1 acre'
   AGSALES='1989 Sales of Agriculture Products'
   ELECCOST='Electricity (yearly cost)'
   GASCOST='Gas (yearly cost)'
   WATRCOST='Water (yearly cost)'
   FUELCOST='House heating fuel (yearly cost)'
   RTAXAMT='Property taxes (yearly amount)'
   INSAMT='Fire/hazard/flood insurance (yearly amt)'
   MORTGAG='Mortgage status'
   MORTGAG3='Mortgage payment (monthly amount)'
   TAXINCL='Payment include real estate taxes'
   INSINCL='Payment include fire/hazard/flood insura'
   MORTGAG2='Second mortgage or home equity loan stat'
   MORTAMT2='Second mortgage payment (monthly amount)'
   CONDOFEE='Condo fee (monthly amount)'
   MOBLHOME='Mobile home costs (yearly amount)'
   RFARM='Farm/nonfarm status'
   RGRENT='Gross rent'
   RGRAPI='Gross rent as a percentage of household'
   ROWNRCST='Selected monthly owner costs'
   RNSMOCPI='Selected mnthly ownr costs as % hh inc'
   RRENTUNT='Specified rent unit'
   RVALUNT='Specified value unit'
   RFAMINC='Family income'
   RHHINC='Household income'
   RWRKR89='Workers in family in 1989'
   RHHLANG='Household language'
   RLINGISO='Linguistic isolation'
   RHHFAMTP='Household/family type'
   RNATADPT='Number of own natural born/adopted child'
   RSTPCHLD='Number of own stepchildren in household'
   RFAMPERS='Number of persons in family (unweighted)'
   nRELCHLD='Number of related children in household'
   RNONREL='Presence of nonrelatives in household'
   R18UNDR='Presence of person < 18 yrs in househld'
   R60OVER='Presence of persons 60 yrs+ in househld'
   R65OVER='Presence of person 65 years+ in househld'
   RSUBFAM='Presence of subfamilies in Household';
 LABEL
   AUNITS1='Units in structure allocation'
   AROOMS='Rooms allocation'
   ATENURE='Tenure allocation'
   AACRES1='On ten acres or more allocation'
   ACOMMUSE='Business or medical office on prop alloc'
   AVALUE='Value allocation'
   ARENT1='Monthly rent allocation'
   AMEALS='Meals included in rent allocation'
   AVACNCY2='Vacancy status allocation'
   AVACNCY3='Boarded up status allocation'
   AVACNCY4='Months vacant allocation'
   AYRMOVED='When moved into this house or apartment'
   ABEDROOM='Number of bedrooms allocation'
   APLUMBNG='Complete plumbing facilities allocation'
   AKITCHEN='Complete kitchen facilities allocation'
   APHONE='Telephones in house allocation'
   AVEHICLE='Vehicles available by household allocati'
   AFUEL='House heating fuel allocation'
   AWATER='Source of water allocation'
   ASEWER='Sewage disposal allocation'
   AYRBUILT='When structure first built allocation'
   ACONDO='House or apartment pt of condo allocat'
   AONEACRE='House on less than 1 acre allocation'
   AAGSALES='1989 Sales of Agricultural Products allo'
   AELECCST='Electricity (yearly cost) allocation'
   AGASCST='Gas (yearly cost) allocation'
   AWATRCST='Water (yearly cost) allocation'
   FUELCST='House heating fuel (yearly cost) allocat'
   ATAXAMT='Taxes on property allocation'
   AINSAMT='Fire, hazard, flood insurance allocation'
   AMORTG='Mortgage status allocation'
   AMORTG3='Regular mortgage payment allocation'
   ATAXINCL='Payment include real estate taxes alloca'
   AINSINCL='Payment include fire, hazard, flood insu'
   AMORTG2='Second mortgage status allocation'
   AMRTAMT2='Second mortgage payment allocation'
   ACNDOFEE='Condominium fee allocation'
   AMOBLHME='Mobile home costs allocation';
 *---LABEL STATMENT FOR PERSON RECORD VARIABLES---*;
 LABEL
   RELAT1='Relationship'
   SEX='Sex'
   RACE='Recoded detailed race code (Appendix C)'
   AGE='Age'
   MARITAL='Marital status'
   PWGT1='Person weight'
   REMPLPAR='Employment status of parents'
   RPOB='Place of birth (Recode)'
   RSPOUSE='Married, spouse present/spouse absent'
   ROWNCHLD='Own child'
   RAGECHLD='Presence and age of own children'
   RRELCHLD='Related child'
   RELAT2='Detailed relationship (other relative)'
   SUBFAM2='Subfamily number'
   SUBFAM1='Subfamily relationship'
   HISPANIC='Detailed Hispanic origin cd (See App I)'
   POVERTY='Person poverty status recode (See App B)'
   POB='Place of birth (Appendix I)'
   CITIZEN='Citizenship'
   IMMIGR='Year of entry'
   SCHOOL='School enrollment'
   YEARSCH='Educational attainment'
   ANCSTRY1='Ancestry - first entry (See appendix I)'
   ANCSTRY2='Ancestry - second entry (See appendix I)'
   MOBILITY='Mobility status (lived here on 4/1/85) '
   MIGSTATE='Migration - State or foreign country cod'
   MIGPUMA='Migration PUMA (state dependent)'
   LANG1='Language other than English at home'
   LANG2='Language spoken at home (See appendix I)'
   ENGLISH='Ability to speak English'
   MILITARY='Military service'
   RVETSERV='Veteran period of service'
   SEPT80='Served September 1980 or later'
   MAY75880='Served May 1975 to August 1980'
   VIETNAM='Served Vietnam era (August 1964 - 4/75)'
   FEB55='Served February 1955 - July 1964'
   KOREAN='Served Korean conflict (6/50 - 1/55)'
   WWII='Served WW II (Sept 1940 - July 1947)'
   OTHRSERV='Served any other time'
   YRSSERV='Years of active duty military service'
   DISABL1='Work limitation status'
   DISABL2='Work prevented status'
   MOBILLIM='Mobility limitation'
   PERSCARE='Personal care limitation'
   FERTIL='Number of children ever born'
   RLABOR='Employment status recode'
   WORKLWK='Worked last week'
   HOURS='Hours worked last week'
   POWSTATE='Place of work - state - (Appendix I)'
   POWPUMA='Place of work PUMA (State dependent)'
   MEANS='Means of transportation to work'
   RIDERS='Vehicle occupancy'
   DEPART='Time of departure for work - hour and mi'
   TRAVTIME='Travel time to work'
   TMPABSNT='Temporary absence from work'
   LOOKING='Looking for work'
   AVAIL='Available for work'
   YEARWRK='Year last worked'
   INDUSTRY='Industry'
   OCCUP='Occupation'
   CLASS='Class of worker'
   WORK89='Worked last year (1989)'
   WEEK89='Weeks worked last year (1989)'
   HOUR89='USUAL HOURS WORKED PER WK LAST YR (1989)'
   REARNING="Total person's earnings"
   RPINCOME="Total person's income (signed)"
   INCOME1='Wages or salary income in 1989'
   INCOME2='Nonfarm self-emplymnt incm in 1989 (sgn)'
   INCOME3='Farm self-employment income, 1989 (sgn)'
   INCOME4='Interest, dividends,&net rental incm 89'
   INCOME5='Social security income in 1989'
   INCOME6='Public assistance income in 1989'
   INCOME7='Retirement income in 1989'
   INCOME8='All other income in 1989'
   AAUGMENT='Augmented person (see text pp. C-5)';
 LABEL
   ARELAT1='Relationship allocation flag'
   ASEX='Sex allocation flag'
   ARACE='Detailed race allocation flag'
   AAGE='Age allocation flag'
   AMARITAL='Marital status allocation flag'
   AHISPAN='Detailed Hispanic origin allocation flag'
   ABIRTHPL='Place of birth'
   ACITIZEN='Citizenship allocation flag'
   AIMMIGR='Year of entry allocation flag'
   ASCHOOL='School enrollment allocation flag'
   AYEARSCH='Highest education allocation flag'
   AANCSTR1='First ancestry allocation flag'
   AANCSTR2='Second ancestry allocation flag'
   AMOBLTY='Mobility status allocation flag'
   AMIGSTAT='Migration state allocation flag'
   ALANG1='LANGUAGE OTHER THAN ENGLISH ALLOCATN FLG'
   ALANG2='Language spoken at home allocation flag'
   AENGLISH='Ability to speak English allocation flag'
   AVETS1='Military service allocation flag'
   ASERVPER='MILITARY PERIODS OF SERVICE ALLOCATN FLG'
   AYRSSERV='YEARS OF MILITARY SERVICE ALLOCATION FLG'
   ADISABL1='Work limitation status allocation flag'
   ADISABL2='Work prevention status allocation flag'
   AMOBLLIM='Mobility limitation status allocation fl'
   APERCARE='PERSONAL CARE LIMITATION STATUS ALLOC FL'
   AFERTIL='Children ever born allocation flag'
   ALABOR='Employment status recode allocation flag'
   AHOURS='Hours worked last week allocation flag'
   APOWST='Place of work state allocation flag'
   AMEANS='MEANS OF TRANSPORTATION TO WORK ALLOC FL'
   ARIDERS='Vehicle occupancy allocation flag'
   ADEPART='TIME OF DEPARTURE TO WORK ALLOCATION FLG'
   ATRANTME='Travel time to work allocation flag'
   ALSTWRK='Year last worked allocation flag'
   AINDUSTR='Industry allocation flag'
   AOCCUP='Occupation allocation flag'
   ACLASS='Class of worker allocation flag'
   AWORK89='Worked last year allocation flag'
   AWKS89='Weeks worked in 1989 allocation flag'
   AHOUR89='Usual hours worked per week in 1989 allo'
   AINCOME1='Wages and salary income allocation flag'
   AINCOME2='NONFARM SELF-EMPLOYMENT INCOME ALLOC FLG'
   AINCOME3='FARM SELF-EMPLOYMENT INCM ALLOCATION FLG'
   AINCOME4='INTEREST, DVDND,& NET RNTAL INCM ALLOC F'
   AINCOME5='Social security income allocation flag'
   AINCOME6='Public assistance allocation flag'
   AINCOME7='Retirement income allocation flag'
   AINCOME8='ALL OTHER INCOME ALLOCATION FLAG';

hholdchk:
error = 0;
length char $1 tempnum 8;
/* scan serialno for values '0000000' to '9999999' */
do i=1 to 7;
   char=substr(serialno,i,1);
   if char<'0' or char> '9' then error+1;
end;

/* Sample can only be 1 - 5% sample */
if sample ^= '1' then error+1;

/* Division is between '0' and '9' */
if division<'0' or division>'9' then error+1;

/* state is FIPS code use fipstate function check for '--' */
if fipstate(state)='--' then error+1;

* put 'error=' error;

/* scan PUMA for values '00000' to '99999' */
do i=1 to 5;
   char=substr(puma,i,1);
   if char<'0' or char> '9' then error+1;
end;

/* area type check see pums90.dict */
if areatype not in('10','11','20','21','22','30','31','40','50',
               '60','61','70','80','81','82') then error+1;

/* MSAPMSA is in 40-9340, 9997,9998,9999 range */
/* MSAPMSA in AZ has value 9360 change valid range */
tempnum=msapmsa;
if _error_ then do; error+1; _error_=0; end;
else do;
 if tempnum<40 then error+1;
 else if tempnum>9360 and  tempnum not in(9997,9998,9999) then
                              error+1;
 end;

/* Skip PSA as values not clear */
/* subsample   value '00'-'99'      */
do i=1 to 2;
   char=substr(subsampl,i,1);
   if char<'0' or char> '9' then error+1;
end;

/* houswgt  integer value between 0 and 1152  */
if houswgt<0 or houswgt>1152 then error+1;

/* persons 0-29   */
if persons<0 or persons>29 then error+1;

/* Gqinst  in '0','1','2' */
if gqinst not in('0','1','2') then error+1;

*  put 'error=' error;

/* Units1 in '00'-'10' */
if units1 not in('00','01','02','03',
                 '04','05','06','07','08','09','10') then error+1;

/* husflag '0','1' */
if husflag not in('0','1') then error+1;

/* pdsflag '0','1' */
if pdsflag not in('0','1') then error+1;

*  put 'error=' error;
/* ROOMS 0-9 */
if rooms<0 or rooms>9 then error+1;

/* Tenure '0'-'4' */
if tenure not in('0','1','2','3','4') then error+1;
/* acre10 '0'-'2' */
if acre10 not in('0','1','2') then error+1;

/* commuse '0'-'2' */
if commuse not in('0','1','2') then error+1;

*  put 'error=' error;
/* create formats to check value,rent  */

/* check rent1 using v_rent format  */
* if put(rent1,$v_rent.)='0' then error+1;

/* check value using v_value format  */
* if put(value,$v_value.)='0' then error+1;

/* meals '0'-'2' */
if meals not in('0','1','2') then error+1;

/* vacancy1 '0'-'3' */
if vacancy1 not in('0','1','2','3') then error+1;

* put 'error=' error;
/* vacancy2 '0'-'6' */
if vacancy2 not in('0','1','2','3','4','5','6') then error+1;

/* vacancy3 '0'-'2' */
if vacancy3 not in('0','1','2') then error+1;

/* vacancy4 '0'-'6' */
if vacancy4 not in('0','1','2','3','4','5','6') then error+1;

/* yrmoved  '0'-'6' */
if yrmoved  not in('0','1','2','3','4','5','6') then error+1;

/* bedrooms '0'-'6' */
if bedrooms not in('0','1','2','3','4','5','6') then error+1;

/* plumbing '0'-'2' */
if plumbing not in('0','1','2') then error+1;

/* kitchen  '0'-'2' */
if kitchen  not in('0','1','2') then error+1;

/* telephon '0'-'2' */
if telephon not in('0','1','2') then error+1;

/* autos    '0'-'8' */
if autos    not in('0','1','2','3','4','5','6','7','8') then error+1;

/* fuelheat    '0'-'9' */
if fuelheat not in('0','1','2','3','4','5','6','7','8','9') then error+1;

/* water    '0'-'4' */
if water    not in('0','1','2','3','4') then error+1;

/* sewage   '0'-'3' */
if sewage   not in('0','1','2','3') then error+1;

/* yrbuilt  '0'-'8' */
if yrbuilt  not in('0','1','2','3','4','5','6','7','8') then error+1;

/* condo    '0'-'2' */
if condo    not in('0','1','2') then error+1;

/* oneacre  '0'-'2' */
if oneacre  not in('0','1','2') then error+1;

/* cross validate oneacre and acre10  */
if acre10='1' and oneacre ^= '2' then error+1;

/*agsales  '0'-'6' */
if agsales  not in('0','1','2','3','4','5','6') then error+1;

/* eleccost 0-N/A,1-N/A(in rent),2-0, othervalues valid */
if eleccost<0 or eleccost>9999 then error+1;
else do;
 if eleccost<3 then do;
  if eleccost=0 then eleccost=.;
  else if eleccost=1 then eleccost=.a;
  else eleccost=0;
end;
end;

/* gascost 0-N/A,1-N/A(in rent),2-0, othervalues valid */
if gascost<0 or gascost>9999 then error+1;
else do;
 if gascost<3 then do;
  if gascost=0 then gascost=.;
  else if gascost=1 then gascost=.a;
  else gascost=0;
end;
end;

/* watrcost 0-N/A,1-N/A(in rent),2-0, othervalues valid */
if watrcost<0 or watrcost>9999 then error+1;
else do;
 if watrcost<3 then do;
  if watrcost=0 then watrcost=.;
  else if watrcost=1 then watrcost=.a;
  else watrcost=0;
end;
end;

/* fuelcost 0-N/A,1-N/A(in rent),2-0, othervalues valid */
if fuelcost<0 or fuelcost>9999 then error+1;
else do;
 if fuelcost<3 then do;
  if fuelcost=0 then fuelcost=.;
  else if fuelcost=1 then fuelcost=.a;
  else fuelcost=0;
end;
end;

/* create format for rtaxamt called v_rtax */
 * if put(rtaxamt,$v_rtax.)='0' then error+1;

/* insamt 0-N/A,1-N/A(in rent),2-0, othervalues valid */
if insamt<0 or insamt>9999 then error+1;
else do;
 if insamt<2 then do;
  if insamt=0 then insamt=.;
  else if insamt=1 then insamt=0;
end;
end;

/* MOrtgag  '0'-'4' */
if mortgag not in('0','1','2','3') then error+1;

/* mortgag3 0-n/a,1-n/a(not regular) */
if mortgag3<2 then do;
  if mortgag3<0 then error+1;
  else if mortgag3=0 then mortgag3=.;
  else mortgag3=.a;
end;

/* taxincl  '0'-'2' */
if taxincl not in('0','1','2') then error+1;

/* insincl  '0'-'2' */
if insincl not in('0','1','2') then error+1;

/* mortgag2 0-n/a,1-n/a(not regular) */
if mortgag2 not in('0','1','2') then error+1;
if mortamt2<2 then do;
  if mortamt2<0 then error+1;
  else if mortamt2=0 then mortamt2=.;
  else mortamt2=.a;
end;

/* condofee 0-n/a */
if condofee<1 then do;
  if condofee<0 then error+1;
  else if condofee=0 then condofee=.;
end;

/* moblhome 0-n/a */
if moblhome<1 then do;
  if moblhome<0 then error+1;
  else if moblhome=0 then moblhome=.;
end;

/* rfarm    '0'-'2' */
if rfarm   not in('0','1','2') then error+1;

/* rgrent   0-n/a */
if rgrent<1 then do;
  if rgrent<0 then error+1;
  else if rgrent=0 then rgrent=.;
end;

/* create format $V_RGRAPI for rgrapi */
 * if put(rgrapi,$v_rgrapi.)='0' then error+1;

/* rgrent   0-n/a */
if rownrcst<1 then do;
  if rownrcst<0 then error+1;
  else if rownrcst=0 then rownrcst=.;
end;

if rnsmocpi<1 then do;
  if rnsmocpi<0 then error+1;
  else if rnsmocpi=0 then rnsmocpi=.;
end;

*  put 'error=' error;
if rrentunt not in('1','0') then error+1;

if rvalunt not in('1','0') then error+1;

if rwrkr89 not in('0','1','2','3','4') then error+1;

if rhhlang not in('0','1','2','3','4','5') then error+1;

if rlingiso not in('0','1','2') then error+1;

if rhhfamtp not in('00','01','02','03','11','12','21','22') then error+1;

if rnatadpt<0 or rnatadpt>28 then error+1;

if rstpchld<0 or rstpchld>28 then error+1;

*  put 'error=' error;
if rfampers<0 or rfampers>29 then error+1;

if nrelchld<0 or nrelchld>28 then error+1;

if rnonrel not in('1','0') then error+1;

if r18undr  not in('1','0') then error+1;

if r60over not in('1','0','2') then error+1;
*  put 'error=' error;

if r65over not in('1','0','2') then error+1;

if rsubfam not in('1','0') then error+1;

/* check allocation flags  */
 array h_array &havars2;
 do over h_array;
   if h_array not in('0','1') then error+1;
 end;

if ayrbuilt not in('1','0','2') then error+1;
if amortg   not in('1','0','2') then error+1;

if error>0 then do;  put error=;* put _all_; stop; end;
return;
perschk:
perror = 0;
length char $1 tempnum 8;

/* relat1  '00' - '14' */
if relat1 not in('00','01','02','03','04','05','06','07',
                 '08','09','10','11','12','13') then
          perror=1;

/* sex '0','1' transform to 'M','F' */
if sex not in('0','1') then perror=1;
 else if sex='0' then sex='M';
 else sex='F';

/* race is '001'-'037', '301'-'327' */
tempnum=race;
if _error_ then do; perror+1; _error_=0; end;
else do;
 if tempnum<1 then perror+1;
  else if tempnum>37 and tempnum<301 then perror+1;
  else if tempnum>327 then perror+1;
 end;

 /* age in range 0 to 90 */
if age<0 or age>90 then perror+1;

*if perror then  put 'point1 perror=' perror;

/* Marital in '0'-'4' */
if marital not in('0','1','2','3','4') then perror+1;

/* pwgt1 in 1-1152 */
if pwgt1<0 or pwgt1>1152 then perror+1;
if perror then do;  put 'point1 perror=' perror; put 'pwgt1=' pwgt1;end;

/* Remplpar '000' '111' '112' '...' */
if remplpar not in('000','111','112','113','114','121','122','133',
                   '134','141','211','212','213','221','222','223')
            then perror+1;

/* RPOB  '10','21',...'52'  */
if rpob  not in('10','21','22','23','24','31','32','33','34','35',
                '36','40','51','52') then perror+1;

/* Rspouse  '0'-'6'  */
if rspouse not in('0','1','2','3','4','5','6') then perror+1;

/* Ragechld '0'-'4'  */
if ragechld not in('0','1','2','3','4') then perror+1;

/* Rrelchld '1'-'0'  */
if rrelchld not in('1','0') then perror+1;

if perror then  put 'point2 perror=' perror;

/* relat2  '0' - '9' */
if relat2 not in('0','1','2','3','4','5','6','7',
                 '8','9') then
          perror+1;

/* subfam2  '0'-'3'  */
if subfam2 not in('0','1','2','3') then perror+1;

/* subfam1  '0'-'3'  */
if subfam1 not in('0','1','2','3') then perror+1;

/* hispanic is '001'-'004', etc */
tempnum=hispanic;
if _error_ then do; perror+1; _error_=0; end;
else do;
 if tempnum<0 or tempnum>401 then perror+1;
 end;

/*poverty  '000'-'501'  */
tempnum=poverty;
if _error_ then do; perror+1; _error_=0; end;
else do;
 if tempnum<0 or tempnum>501 then perror+1;
 end;

*if perror then  put 'point2 perror=' perror;

/*pob fipstate or   '060'-'555'  */
tempnum=pob;
if _error_ then do; perror+1; _error_=0; end;
else do;
 if tempnum<57 then do;
  if fipstate(tempnum)='--' then
  perror+1;
  end;
 else if tempnum<60 or tempnum>555 then perror+1;
 end;

/* citizen '0'-'4'  */
if citizen not in('0','1','2','3','4') then perror+1;

/* immigr  '00' - '10' */
if immigr not in('00','01','02','03','04','05','06','07',
                 '08','09','10') then
          perror+1;

/* school  '0'-'3'  */
if school  not in('0','1','2','3') then perror+1;

/* yearsch '00' - '17' */
if yearsch not in('00','01','02','03','04','05','06','07',
                 '08','09','10','11','12','13','14','15',
                 '16','17') then
          perror+1;

/* ancstry1    value '001'-'999'      */
if ancstry1='000' then perror+1;
else
do i=1 to 3;
   char=substr(ancstry1,i,1);
   if char<'0' or char> '9' then perror+1;
end;

/* ancstry2    value '001'-'999'      */
if ancstry2='000' then perror+1;
else
do i=1 to 3;
   char=substr(ancstry2,i,1);
   if char<'0' or char> '9' then perror+1;
end;

/* mobility   '0'-'2'  */
if mobility not in('0','1','2') then perror+1;

/*migstate  '00' ,fipstate or  '72','98','99'  */
tempnum=migstate;
if _error_ then do; perror+1; _error_=0; end;

else do;
if tempnum=0 then;
else if tempnum<57 then do;
  if fipstate(tempnum)='--' then
  perror+1;
  end;
 else if tempnum=72 or tempnum=98 or tempnum=99  then;
 else perror+1;
 end;

if perror then  put 'point3 perror=' perror;

/*migpuma  '00000' '00100'-'99800','99900'  */
tempnum=migpuma;
if _error_ then do; perror+1; _error_=0; end;
else do;
if tempnum=0 then;
 else if tempnum<100 then perror+1;
  else if tempnum>99800 and tempnum^=99900  then perror+1;
 end;

/* lang1   '0'-'2'  */
if lang1 not in('0','1','2') then perror+1;

/* lang2    value '001'-'999'      */
if ancstry1='000' then perror+1;
else
do i=1 to 3;
   char=substr(lang2,i,1);
   if char<'0' or char> '9' then perror+1;
end;

/* english '0'-'4'  */
if english not in('0','1','2','3','4') then perror+1;

/* military '0'-'4'  */
if military not in('0','1','2','3','4') then perror+1;

/* rvetserv '00' - '10' */
if rvetserv not in('00','01','02','03','04','05','06','07',
                 '08','09','10','11') then
          perror+1;

/* sept80 '0','1' */
if sept80^=0 and sept80 ^='1' then perror+1;


if perror then  put 'point4 perror=' perror;

/* may75880 '0','1' */
if may75880^=0 and may75880 ^='1' then perror+1;

/* vietnam  '0','1' */
if vietnam^=0 and vietnam ^='1' then perror+1;

/* feb55    '0','1' */
if feb55^=0 and feb55 ^='1' then perror+1;

/* korean   '0','1' */
if korean^=0 and korean ^='1' then perror+1;

/* wwii     '0','1' */
if wwii^=0 and wwii ^='1' then perror+1;

/* othrserv '0','1' */
if othrserv^=0 and othrserv ^='1' then perror+1;

/*yrssrev  '00'-'50'  */
tempnum=yrsserv;
if _error_ then do; perror+1; _error_=0; end;

else do;
if tempnum<0 or tempnum>50  then perror+1;
end;

/* disabl1  '0'-'2'  */
if disabl1  not in('0','1','2') then perror+1;

/* disabl2  '0'-'2'  */
if disabl2  not in('0','1','2') then perror+1;

/* mobillim '0'-'2'  */
if mobillim not in('0','1','2') then perror+1;

if perror then  put 'point5 perror=' perror;

/* perscare '0'-'2'  */
if perscare not in('0','1','2') then perror+1;

/* fertil  '00' - '14' */
if fertil not in('00','01','02','03','04','05','06','07',
                 '08','09','10','11','12','13') then
          perror=1;

/* rlabor   '0'-'6'  */
if rlabor  not in('0','1','2','3','4','5','6') then perror+1;

/* worklwk  '0'-'2'  */
if worklwk  not in('0','1','2') then perror+1;

/*hours    '00'-'50'  */
tempnum=hours;
if _error_ then do; perror+1; _error_=0; end;

else do;
if tempnum<0 or tempnum>99  then perror+1;
end;

/*powstate  '00' ,fipstate or  '72','98','99'  */
tempnum=powstate;
if _error_ then do; perror+1; _error_=0; end;

else do;
if tempnum=0 then;
else if tempnum<57 then do;
  if fipstate(tempnum)='--' then
  perror+1;
  end;
 else if tempnum=72 or tempnum=98 or tempnum=99  then;
 else perror+1;
 end;

/*powpuma  '00000' '00100'-'99800','99900''  */
tempnum=powpuma;
if _error_ then do; perror+1; _error_=0; end;

else do;
if tempnum=0 then;
 else if tempnum<100 then perror+1;
  else if tempnum>99800 and tempnum^=99900  then perror+1;
 end;

if perror then  put 'point6 perror=' perror;

/* means   '00' - '14' */
if means  not in('00','01','02','03','04','05','06','07',
                 '08','09','10','11','12') then
          perror=1;

/* riders   '0'-'6'  */
if riders  not in('0','1','2','3','4','5','6','7','8') then perror+1;

/*travtime  '00'-'99'  */
tempnum=travtime;
if _error_ then do; perror+1; _error_=0; end;

else do;
if tempnum<0 or tempnum>99  then perror+1;
end;

/* tmpabsnt    '0'-'3'  */
if tmpabsnt not in('0','1','2','3') then perror+1;

/* looking  '0'-'2'  */
if looking not in('0','1','2') then perror+1;

/* avail    '0'-'4'  */
if avail not in('0','1','2','3','4') then perror+1;

/* yearwrk   '0'-'7'  */
if yearwrk not in('0','1','2','3','4','5','6','7') then perror+1;

if perror then  put 'point7 perror=' perror;


/*industry    '000','010'-'992'  */
tempnum=industry;
if _error_ then do; perror+1; _error_=0; end;

else do;
if tempnum=0 then;
 else if tempnum<10  then perror+1;
 else if tempnum>992 then perror+1;
end;

/*occup    '000','003'-'909'  */
tempnum=occup;
if _error_ then do; perror+1; _error_=0; end;

else do;
if tempnum=0 then;
 else if tempnum<3   then perror+1;
 else if tempnum>909 then perror+1;
end;

/* class     '0'-'9'  */
if class   not in('0','1','2','3','4','5','6','7','8','9') then perror+1;

/* work89    '0'-'2'  */
if work89  not in('0','1','2') then perror+1;

/*week89   '00'-'52'  */
tempnum=week89;
if _error_ then do; perror+1; _error_=0; end;

else do;
if tempnum<0 or tempnum>52 then perror+1;
end;

/*hour89   '00'-'99'  */
tempnum=hour89;
if _error_ then do; perror+1; _error_=0; end;

else do;
if tempnum<0 or tempnum>99 then perror+1;
end;

if perror then  put 'point8 perror=' perror;
  array p_array1 &pavars1;
 do over p_array1;
   if p_array1 not in('0','1') then perror+1;
 end;

if perror then  put 'point9 perror=' perror;
  array p_array2 &pavars2;
 do over p_array2;
   if p_array2 not in('0','1','2') then perror+1;
 end;
if perror>0 then do;  put perror=;* put _all_;  end;
return;
run;
/***************************************************************************
 *                      END OF PROGRAM CODE SECTION
 ***************************************************************************/

/***************************************************************************
 *                       END OF TEST
 ****************************************************************************/


