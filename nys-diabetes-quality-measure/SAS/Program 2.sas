proc sql;
    select memname, nobs, nvar
    from dictionary.tables
    where libname = 'WORK' and memname like 'Y20%'
    order by memname;
quit;

%macro cols;
    %do yr=2018 %to 2024;
        proc contents data=work.y&yr out=work.c&yr(keep=name type length) noprint; run;
        data work.c&yr; set work.c&yr; file_year=&yr; run;
    %end;
%mend;
%cols;

data work.allcols;
    set work.c2018 work.c2019 work.c2020 work.c2021
        work.c2022 work.c2023 work.c2024;
run;

proc sql;
    title 'Columns that are NOT in all 7 years';
    select name, count(distinct file_year) as years_present
    from work.allcols
    group by name
    having count(distinct file_year) < 7;

    title 'Columns whose type changes between years (1=numeric, 2=text)';
    select name, count(distinct type) as n_types
    from work.allcols
    group by name
    having count(distinct type) > 1;
quit;
title;



proc sql noprint;
    select memname into :badyr trimmed
    from dictionary.columns
    where libname='WORK' and upcase(name)='MMEASUREMENT_YEAR';
quit;
%put Typo found in: &badyr;

proc datasets lib=work nolist;
    modify &badyr;
    rename Mmeasurement_Year=Measurement_Year;
quit;