options validvarname=v7;

%let path = path/to/your/data;
libname QARR "&path";

%macro load(yr, file);
    proc import datafile="&path/&file" out=work.y&yr dbms=csv replace;
        guessingrows=max; getnames=yes;
    run;
%mend;

%macro loadraw;
    %do yr=2018 %to 2024;
        %load(&yr, QARR_Health_Disparities_&yr..csv);
    %end;
%mend;
%loadraw;