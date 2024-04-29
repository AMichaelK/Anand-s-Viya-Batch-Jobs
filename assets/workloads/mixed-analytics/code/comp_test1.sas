/******************************************************************************
 * Copyright (c) 2013 by SAS Institute Inc, Cary NC 27511  USA
 * This program is part of the Mixed Analytic Workload repository of
 *   test programs used to evaluate SAS concurrent workload.   
 *
 * PASS NAME:  comp_test1a.sas
 * DESCRIPTION:
 *   This computational test is a numercially intensive test 
 *
 *   We are doing stepwise linear regression and a stepwise logistic
 *   regression.  Performance can be increased if you can set the
 *   the MEMSIZE parameter high enough to cache the data for the
 *   the logistic regression.
 *
 *   This test is the same code as COMP_TEST2 and COMP_TEST3, but
 *   it only uses 25% of the total data.
 *
 * SETUP INSTRUCTIONS:
 *   This test requires you to import data stored in the transport file 
 *   boardrm.tra into a SAS data set using the CIMPORT procedure.
 *
 *   Modify the Data Setup Section below to specify the path containing the
 *   boardrm data set.
 *
 *   OUTPUT:  none
 *
 * SYSTEM REQUIREMENTS:  This test works with default settings.
 *
 * ANTICIPATED RUNTIME:   5-15 minutes
 * TEST CHARACTERIZATION:  CPU Intensive  
 *
 * SAS PRODUCTS INVOLVED:  base SAs, SAS/STAT
 * SAS PROCEDURES INVOLVED:  LOGISTIC, REG 
 *
 * DATA SOURCE:  boardrm.tra SAS transport file
 * DATA CHARACTERIZATION:  297 Variables
 *
 * COMMENTS:
 * DISTRIBUTION STATUS:  External
 * CONTRIBUTED BY:  Margaret Crevar
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

*libname neo "&data";


/*  Import in the transported SAS data file.                        */
proc cimport lib=work  infile="&data/boardrm.tra";
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



/*  Creates the list of independent variables for model selection.  */
%let indepent =
 BLXPTIMN BL_LPDM BL_LPFRE BL_LPREN BL_LTDNN BL_ND24N BL_ND25N BL_NDPRN
 BL_NO25N BL_NPDM BL_OEXP BL_OFREE BL_OGOOD BL_ONEWB BL_OPDM BL_OPFRE
 BL_OPGIF BL_OPNEW BL_ORENW BL_PFREE BL_POPAY BL_POPEN BL_PRECN BL_RENN
 BOOKIND  BP_NDOLN BR_DNRNO BR_LPNEW BR_LPREN BR_ND25N BR_NO25N BR_ORENW
 BR_PDNRC BR_RENN  BUS_FLAG CC_NDOLN CC_NPRON CONT_RNT CO_NDOLN CO_NPRON
 CP_NDOLN C_LPDM   C_ND24N  C_NDPRON C_NIPRON C_NO24N  C_NPDM   C_ODM
 C_OGOOD  C_OINST  C_OPDGD  C_OPDM   C_PCCAN  C_PFPAY  C_PHPAY  C_PHRSP
 C_POPEN  DELIVER  ENCENTRL FO_NDOLN FO_NPRON HC_LTDNN HC_ND25N HC_NDPRN
 HC_NO25N HC_ONEWB HC_PRECN HC_RENN  HO_NDOLN HO_NPRON HP_NDOLN IHOHIT
 LCUST_BL LTDPROMN MAILTYP2 MAILTYP4 NCUST_BL NCUST_TH NDLHIT   NDOMTRV
 NEWENGL  NFORDDUN OCUST_BL ONSHTRNT OORDDURN O_LPDM   O_LPNEW  O_LTDNPN
 O_ND24N  O_ND25N  O_NDPRON O_NIPRON O_NO24N  O_NO25N  O_NONGF  O_NPDM
 O_NPNEW  O_ODM    O_OGOOD  O_OINST  O_ONEWB  O_OPDGD  O_OPDM   O_OPNEW
 O_PFPAY  O_PFREE  O_PHPAY  O_PHRSP  O_POPAY  O_POPEN  PB_BLRNT PB_HCRNT
 PB_THRNT PB_TMRNT PHPAY    PHRSP    PRDCT_BL PRDCT_HC PREV_LCS PROLORDN
 PUBIND   P_LPDM   P_LPFRE  P_LPREN  P_LTDNPN P_ND25N  P_NDPRON P_NIPRON
 P_NO25N  P_NPDM   P_ODM    P_OEXP   P_OFREE  P_OGOOD  P_ONEWB  P_OPDM
 P_OPFRE  P_OPGIF  P_OPNEW  P_ORENW  P_PFREE  P_PHRSP  P_POPAY  P_POPEN
 RE_BLDEF RLPH01N  RLPH02N  RLPH03N  RLPH04N  RLPH05N  RLPH06N  RLPH07N
 RLPH08N  RLPH10N  RLPH11N  RLPH16N  RLPH18N  RLPH19N  RLPH21N  RLPH23N
 RLPH24N  RLPH28N  RLPH29N  RLPH30N  RP_NDOLN S2L1NDBN S2L1NDCN S2L1NDPN
 S2L1NDTN S2L1NIBN S2L1NICN S2L1NITN S2L1RDBN S2L1RDCN S2L1RDPN S2L1RDTN
 S2L1RIBN S2L1RICN S2L1RIPN S2L1RITN S2LTNDBN S2LTNDCN S2LTNDPN S2LTNDTN
 S2LTNIBN S2LTNICN S2LTNIPN S2LTNITN S2LTRDBN S2LTRDCN S2LTRDPN S2LTRDTN
 S2LTRIBN S2LTRICN S2LTRIPN S2LTRITN S2ORECN  S2PRECN  SEXF     THXPTIMN
 TH_LPDM  TH_LPNEW TH_LTDNN TH_ND24N TH_ND25N TH_NDPRN TH_NO25N TH_NONGF
 TH_NPDM  TH_NPNEW TH_OBPAY TH_ODM   TH_OGOOD TH_OPDGD TH_OPDM  TH_OPNEW
 TH_ORECN TH_PCCAN TH_PFPAY TH_POPEN TH_PRECN TMXPTIMN TM_LPDM  TM_LPFRE
 TM_LPNEW TM_LPREN TM_LTDNN TM_ND24N TM_NO24N TM_NONGF TM_NPDM  TM_NPNEW
 TM_ODM   TM_OGOOD TM_OPDGD TM_OPDM  TM_OPNEW TM_ORECN TM_PBPAY TM_PCCAN
 TM_PDNRC TM_PDNRP TM_PFPAY TM_PFREE TM_PHPAY TM_PHRSP TM_POPEN TM_PRECN
 TO_NDOLN TO_NPRON TP_NDOLN TP_NPRON TX_NDOLN TX_NPRON XAD75    XAD3544
 XAD4554  XAD5564  XAD6574  XAGE10YN XAGE4YN  XBIBLE   XCARVALN XCRAFTS
 XCRDBO   XCRDBR   XCRDRO   XDMBR3   XDMBR4   XDMBR8   XGARDN   XGRANCH
 XHEALTH  XHIGHSCH XHMOWNC  XHMRNTC  XHOMEPC  XHPLANT  XINCOMCN XKNIT
 XLENRESN XMARRC   XNARINCN XNRADLTN XNRPERSN XNUMKIDN XOCCNWF  XOCCSBC
 XPOLIT   XREALES  XSTOCK   XVETERN  XVIDGAM  XWALK    XWKSHOP ;


/*  Create a SAS data set with a Full random sample.                       */
data sample;
  set work.boardrm;
  z=ranuni(578587);
  *if z<.25 then output;
run;

/*  Fit a stepwise linear regression.                                    */
proc reg data=sample;
  model netresp= &indepent /selection=STEPWISE sle=.15 sls=.05 vif collin stb;
run;

/*  Fit a stepwise logistic regression.                                  */
proc logistic data=sample;
  model netresp= &indepent / maxiter=200 risklimits selection=S
  lackfit;
run;
/***************************************************************************
 *                      END OF PROGRAM CODE SECTION
 ***************************************************************************/

/***************************************************************************
 *                       END OF TEST
 ****************************************************************************/

