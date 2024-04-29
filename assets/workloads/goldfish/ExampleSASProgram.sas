/* Specify the path to your CSV file */
filename csvfile '/mnt/viya-share/data/TempExample.csv';

/* Define the data step to read the CSV file */
data csvdata;
    /* Infile statement to specify the CSV file */
    infile csvfile delimiter=',' dsd firstobs=2;

    /* Input statement to read the fields from the CSV file */
    input 
        field1 $
        field2 $
        field3 $
        /* Add more fields as needed */
    ;

    /* Display the field you want */
    put field1; /* Or any other field you want to display */
    
    /* You can add more put statements to display other fields */
    
run;
