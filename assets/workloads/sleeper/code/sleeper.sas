%let start_time=%sysfunc(datetime(),datetime20.);
%let min_sleep_sec=120;
%let max_sleep_sec=120;

/*Sleep for a bit so that this program "runs" for a while*/
data sleep;
   sleepval= &min_sleep_sec + (&max_sleep_sec - &min_sleep_sec) * rand('uniform'); 
   sleeptime=sleep(sleepval,1);
run;

%let stop_time=%sysfunc(datetime(),datetime20.);
