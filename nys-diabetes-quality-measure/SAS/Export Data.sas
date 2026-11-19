%let path = path/to/your/data;

data work.rates_exp;      set qarr.rates;       format _numeric_; run;
data work.payer_gap_exp;  set qarr.payer_gap;   format _numeric_; run;
data work.region_gap_exp; set qarr.region_gap;  format _numeric_; run;

proc export data=work.rates_exp      outfile="&path/rates.csv"      dbms=csv replace; run;
proc export data=work.payer_gap_exp  outfile="&path/payer_gap.csv"  dbms=csv replace; run;
proc export data=work.region_gap_exp outfile="&path/region_gap.csv" dbms=csv replace; run;