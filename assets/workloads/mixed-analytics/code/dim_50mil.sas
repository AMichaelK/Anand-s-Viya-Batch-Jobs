/******************************************************************************
 * Copyright (c) 2013 by SAS Institute Inc, Cary NC 27511  USA
 * This program is part of the Mixed Analytic Workload repository of
 *   test programs used to evaluate SAS concurrent workload.   
 *
 * PASS NAME: DIM_50mil.sas
 * DESCRIPTION: Star Schema Customer Dimension Extract and Maniuplation				
 *    
 *    
 * SETUP INSTRUCTIONS: None
 * 
 *   OUTPUT:  none
 *
 * SYSTEM REQUIREMENTS:  This test works with default settings.
 *
 * ANTICIPATED RUNTIME:  00:6:48.00  
 * TEST CHARACTERIZATION: I/O, Memory Intensive  
 *
 * SAS PRODUCTS INVOLVED:   BASE 
 * SAS PROCEDURES INVOLVED: DATA,SORT.  
 *
 * DATA SOURCE:   /$asuite/customer_50_mil_#.sas7bdat
 * DATA CHARACTERIZATION: sas datasets   
 *
 * COMMENTS:
 * DISTRIBUTION STATUS:  External
 * CONTRIBUTED BY:   Tom Keefer
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
libname saslib BASE "&suiteloc/output";


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

/* create SAS data table from the external file  */ 
data work.CUSTOMER/ view = work.CUSTOMER; 

   infile "&suiteloc/input/customer_50mil_&sysparm..dat"
          lrecl = 2000
          pad
          firstobs = 1;
   
   attrib cust_id length = 8 informat = 12.; 
   attrib geo_id length = 8 informat = 12.; 
   attrib type_id length = 8 informat = 12.; 
   attrib Customer_Gender length = $1; 
   attrib Customer_Name length = $40 informat = $40.; 
   attrib Customer_FirstName length = $30 informat = $30.; 
   attrib Customer_LastName length = $30 informat = $30.; 
   attrib Customer_BirthDate length = 8 format = date9. informat = date9.; 
   attrib Street_ID length = 8 informat = 8.; 
   attrib Continent length = $25 informat = $25.; 
   attrib Country length = $2; 
   attrib State_Code length = $2; 
   attrib State length = $25 informat = $25.; 
   attrib Region length = $30 informat = $30.; 
   attrib Province length = $30 informat = $30.; 
   attrib County length = $60 informat = $60.; 
   attrib City length = $30 informat = $30.; 
   attrib Postal_Code length = $8 informat = $8.; 
   attrib Street_Name length = $45 informat = $45.; 
   
   input @ 1 cust_id  12.
          @ 13 geo_id  12.
          @ 25 type_id  12.
          @ 37 Customer_Gender  
          @ 38 Customer_Name  $40.
          @ 78 Customer_FirstName  $30.
          @ 108 Customer_LastName  $30.
          @ 138 Customer_BirthDate  date9.
          @ 147 Street_ID  8.
          @ 155 Continent  $25.
          @ 180 Country  
          @ 182 State_Code  
          @ 184 State  $25.
          @ 209 Region  $30.
          @ 239 Province  $30.
          @ 269 County  $60.
          @ 329 City  $30.
          @ 359 Postal_Code  $8.
          @ 367 Street_Name  $45.; 
   
run; 

/* create SAS data table from the external file  */ 
data work.CUST_TYPE/ view = work.CUST_TYPE; 

   infile "&suiteloc/input/customer_type_&sysparm..dat"
          lrecl = 256
          pad
          firstobs = 1;
   
   attrib type_id length = 8 informat = 12.; 
   attrib Customer_Group_ID length = $1 informat = $char1.; 
   attrib Customer_Type length = $40 informat = $40.; 
   attrib Customer_Group length = $40 informat = $40.; 
   
   input @ 1 type_id  12.
          @ 13 Customer_Group_ID  $char1.
          @ 14 Customer_Type  $40.
          @ 53 Customer_Group  $40.; 
   
run; 

/*============================================================================* 
 * Step:          Lookup                                    A53E5ES9.BF0004MV * 
 * Transform:     Lookup                                                      * 
 * Description:                                                               * 
 *                                                                            * 
 * Source Tables: File Reader Target - work.CUST_TYPE        A53E5ES9.BA0004MS * 
 *                File Reader Target - work.CUSTOMER        A53E5ES9.BA0004MR * 
 * Target Table:  Lookup Target - work.W58WQGSZ             A53E5ES9.BA0004MT * 
 *============================================================================*/ 
/*---- Begin DATA step to perform lookups  ----*/ 
DATA  work.W58WQGSZ 
         (keep = cust_rsk start_date end_date cust_id geo_id type_id 
                 Customer_Gender Customer_Name Customer_FirstName 
                 Customer_LastName Customer_BirthDate Street_ID Continent 
                 Country State_Code State Region Province County City 
                 Postal_Code Street_Name Customer_Group_ID Customer_Type 
                 Customer_Group)
      ; 
   
   attrib cust_rsk length=8
          start_date length=8
          end_date length=8
          cust_id length=8
          geo_id length=8
          type_id length=8
          Customer_Gender length=$1
          Customer_Name length=$40
          Customer_FirstName length=$30
          Customer_LastName length=$30
          Customer_BirthDate length=8 format=date9.
          Street_ID length=8
          Continent length=$25
          Country length=$2
          State_Code length=$2
          State length=$25
          Region length=$30
          Province length=$30
          County length=$60
          City length=$30
          Postal_Code length=$8
          Street_Name length=$45
          Customer_Group_ID length=$8
          Customer_Type length=$40
          Customer_Group length=$40
          ; 
   
   length ; 

   retain missing0 0 ; 

   cust_rsk = 1.0 + cust_id;
   start_date = datetime();
   end_date =   '01JAN5999:00:00:00'DT;
   
   /* Build hash objects from lookup tables before reading first source row  */ 
   if (_n_ = 1) then 
   do; 
      cust_rsk = 1.0 + cust_id;
      /* Build hash h0 from lookup table work.CUST_TYPE */ 
      nobs = .; 
      dsid = open("work.CUST_TYPE"); 
      if (dsid > 0) then 
      do; 
         if ( attrc(dsid, 'MTYPE') = 'DATA' ) then 
            nobs = attrn(dsid, 'NOBS'); 
         else 
            nobs = -1; 
         dsid = close(dsid); 
         if (nobs ^= 0) then 
         do; 
            declare hash h0(dataset:"work.CUST_TYPE");
            h0.defineKey("type_id");
            h0.defineData("Customer_Group_ID", "Customer_Type", "Customer_Group");
            h0.defineDone();
         end; 
         else 
         do; 
            put 'NOTE: Lookup table is empty: work.CUST_TYPE' ; 
            put 'NOTE: Abort action indicated, condition= Lookup table is empty: work.CUST_TYPE'; 
            abort 3; 
         end; 
      end; 
      else 
      do; 
         put 'NOTE: Lookup table does not exist or cannot be opened: work.CUST_TYPE'; 
         put 'NOTE: Abort action indicated, condition= Lookup table missing: work.CUST_TYPE'; 
         abort 3; 
      end; 
      
      call missing (type_id, Customer_Group_ID, Customer_Type ); 
   
   end; /* All hash objects have been defined */
   
   /* Read a row from the source table  */ 
   set work.CUSTOMER end = eof;
   
   /* Is the current key value stored in hash h0?  */ 
   rc0 = h0.find();
   
   /* Examine success of lookups  */ 
   if ( rc0=0 ) then 
   do; 
      /* Write row to target  */ 
      output work.W58WQGSZ; 
      return; 
   end; 
   else 
   do; 
      error_total + 1; 
      
      if ( rc0 ^= 0 ) then 
      do; 
         exception_total + 1; 
         /* Check: Lookup value not found-Set target columns to missing  */ 
         call missing (Customer_Group_ID, Customer_Type ); 
         request_write_target = 1; 
      end; 
      
      /* Set target columns to value/missing requested?  */ 
      if ( request_write_target eq 1 ) then 
         /* Write row to target  */ 
         output work.W58WQGSZ; 
   
   end; /* One or more lookups failed */
   
   if ( eof = 1 ) then 
   do; 
      put 'NOTE: Source records with errors: ' error_total ; 
      put 'NOTE: Total lookup exceptions: ' exception_total ; 
   end; 

run; 

/*============================================================================* 
 * Step:          SAS Sort                                  A53E5ES9.BF0004MX * 
 * Transform:     SAS Sort                                                    * 
 * Description:                                                               * 
 *                                                                            * 
 * Source Table:  Lookup Target - work.W58WQGSZ             A53E5ES9.BA0004MT * 
 * Target Table:  Sort Target - dsfact.customer_tdim_ds     A53E5ES9.BA0004MV * 
 *============================================================================*/ 

%let SYSLAST = %nrquote(work.W58WQGSZ); 

proc sort data = &SYSLAST 
          out = saslib.customer_50mil_&sysparm.
          NODUPKEY; 
   by cust_id; 
run; 

/* Anand: changing libname to lib in line below */
proc datasets lib=saslib;
     delete customer_50mil_&sysparm.;
run; 


/***************************************************************************
 *                      END OF PROGRAM CODE SECTION
 ***************************************************************************/

/***************************************************************************
 *                       END OF TEST
 ****************************************************************************/



