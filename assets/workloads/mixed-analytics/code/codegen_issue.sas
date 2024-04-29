/******************************************************************************
 * Copyright (c) 2013 by SAS Institute Inc, Cary NC 27511  USA
 * This program is part of the Mixed Analytic Workload repository of
 *   test programs used to evaluate SAS concurrent workload.   
 *
 * PASS NAME:  CODEGEN.sas
 * DESCRIPTION:  Nested DATA Step Variable Generation
 *    
 *    
 * SETUP INSTRUCTIONS:None
 *   
 * OUTPUT:  none
 *
 * SYSTEM REQUIREMENTS:  This test works with default settings.
 *
 * ANTICIPATED RUNTIME:    2:00 minutes
 * TEST CHARACTERIZATION:  I/O Intensive  
 *
 * SAS PRODUCTS INVOLVED:  BASE 
 * SAS PROCEDURES INVOLVED:   DATA
 *
 * DATA SOURCE:   In.sas7bdat /$asuite/input
 * DATA CHARACTERIZATION: SAS Dataset
 *
 * COMMENTS:
 * DISTRIBUTION STATUS:  External
 * CONTRIBUTED BY:  Leigh Ihnen 
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

%let data= &suiteloc/asuite/input;   /*  location of source data  */


%let sp500=1242.31;
 
%let stkwt  =0.75;
%let bdwt   =0.125;
%let fixedwt=0.125;

%let rateshock=0.0000;
%let volshock=0.0000;
%let ptmove=0; 
 
 
%let durperyr=4; 
 
%let years=60;
%let durs=%eval((&durperyr)*(&years)); 
libname perm "&suiteloc/input/";

 

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

data work.results; 
	set perm.in;  
	array disc{&durs};
	array acc{&durs};
	array femaleDeathRate{120};
	array maleDeathRate{120};
	array lapses_AvUnder70Pct{&years};
	array lapses_Av70To90Pct{&years};
	array lapses_AvOver90Pct{&years};

	do shockindex = 1 to 21;
		avshock = (shockindex * 0.05) + 0.45;
		gwbfactor=0.01*gwbgrp;
		electionAge=agegrp;
		gawapct=gawagrp;
		if agegrp < 60 then electionAge = 60;
		if agegrp > 75 then electionAge = 75;

		fpvliab=0;
		mpvliab=0;
		mpvdef=0;
		fpvdef=0;
		mpvsurp=0;
		fpvsurp=0;

		if electionAge ge 60 and electionAge le 64 then chgs = 0.90;
		if electionAge ge 65 and electionAge le 69 then chgs = 0.60;
		if electionAge ge 70 and electionAge le 74 then chgs = 0.50;
		if electionAge ge 75 then chgs = 0.40;

		fper=1;
		mper=1;
		
		accountValue = ((&sp500 * avshock + &ptmove) * (&stkwt)) + (&sp500 * &bdwt) + (&sp500 * &fixedwt);
		gawaUtilization = 5.0/5.0;
	
		gawa=0.01 * gawapct * (&sp500);
		gwb=gwbfactor*(&sp500);

		timeStep = 1.0 / (&durperyr);
		lastStepUpDur = 0;

		do dur=1 to &durs;
	  		if fper > 0 and mper > 0 then do;
				benefitYear = int((dur-1) * timeStep) + 1;
				completedYears = 0;  
				policyYear = completedYears + int((dur - 1) * timeStep) + 1;
				attainedAge = electionAge + benefitYear - 1;

				desiredWithdrawal = gawa * gawaUtilization * timeStep;
				actualWithdrawal = desiredWithdrawal;	 
				accountValue = accountValue * (1+acc{dur});
				def = max(actualWithdrawal - accountValue,0);

				if def=0 then do;
					 

					if accountValue < 0.70 * gwb then do;
						fper = fper * (1-femaleDeathRate{attainedAge}) ** timeStep *
							  (1-lapses_AvUnder70Pct{policyYear}) ** timeStep;
						mper = mper * (1-maleDeathRate{attainedAge}) ** timeStep *
							  (1-lapses_AvUnder70Pct{policyYear}) ** timeStep;
					end;
					else if 0.70 * gwb le accountValue and accountValue < 0.90 * gwb then do;
						fper = fper * (1-femaleDeathRate{attainedAge}) ** timeStep *
							  (1-lapses_Av70To90Pct{policyYear}) ** timeStep;
						mper = mper * (1-maleDeathRate{attainedAge}) ** timeStep *
							  (1-lapses_Av70To90Pct{policyYear}) ** timeStep;
					end;
					else if 0.90 * gwb le accountValue then do;
						fper = fper * (1-femaleDeathRate{attainedAge}) ** timeStep *
							  (1-lapses_AvOver90Pct{policyYear}) ** timeStep;
						mper = mper * (1-maleDeathRate{attainedAge}) ** timeStep *
							  (1-lapses_AvOver90Pct{policyYear}) ** timeStep;
					end;

				end; 
				else do; /* Def > 0 */

					 
					fper = fper * (1-femaleDeathRate{attainedAge}) ** timeStep; 
					mper = mper * (1-maleDeathRate{attainedAge}) ** timeStep; 
				end;

 				accountValue = max(accountValue - actualWithdrawal, 0);
				gwb = max(gwb - actualWithdrawal, 0); 
				benefitCharges = accountValue * (chgs/100) * timeStep * (&stkwt + &bdwt);
				accountValue = max(accountValue - benefitCharges, 0);

 				if (dur - lastStepUpDur) ge (&durperyr * 5) then do;
					if accountValue > gwb then do;
						gwb=max(gwb,accountValue);
						gawa=max(0.05 * gwb, gawa);
						lastStepUpDur = dur;
					end;
				end;

	  		end; 
			mdsurp	= benefitCharges * disc{dur} * mper;
			fdsurp  = benefitCharges * disc{dur} * fper;
    		mddef   = def * disc{dur} * mper;
			fddef   = def * disc{dur} * fper;
			mpvdef  = mpvdef + mddef;
			fpvdef  = fpvdef + fddef;
			mpvsurp = mpvsurp + mdsurp;
			fpvsurp = fpvsurp + fdsurp;
			mpvliab = mpvliab + mddef - mdsurp;
			fpvliab = fpvliab + fddef - fdsurp;
	  
		end;
		output;
	end;
	keep formNumber gwbgrp gawagrp agegrp mpvdef fpvdef mpvsurp fpvsurp fpvliab mpvliab avshock scen;
run;

/***************************************************************************
 *                      END OF PROGRAM CODE SECTION
 ***************************************************************************/

/***************************************************************************
 *                       END OF TEST
 ****************************************************************************/
