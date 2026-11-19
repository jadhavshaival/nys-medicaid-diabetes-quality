/* Truncation, missing values, and the 18 rows with no Category */
proc sql;
    title 'Longest values vs lengths you set (300/300/150/150/100)';
    select max(length(Measure_Description)) as max_desc,
           max(length(Measure))              as max_measure,
           max(length(Sub_Domain))           as max_sub,
           max(length(Characteristics))      as max_char,
           max(length(Domain))               as max_dom
    from qarr.all_years;

    title 'Missing Numerator / Denominator / Rate by year';
    select file_year, count(*) as n_rows,
           sum(missing(Numerator))   as miss_num,
           sum(missing(Denominator)) as miss_den,
           sum(missing(Rate))        as miss_rate
    from qarr.all_years group by file_year;

    title 'Rows with missing Category';
    select file_year, Payer, Measure_Description, Characteristics,
           Numerator, Denominator, Rate
    from qarr.all_years where missing(Category);
quit;

/* Do region names stay the same across years? */
proc freq data=qarr.all_years;
    where upcase(Category) in ('REGION','STATEWIDE');
    tables Category*Characteristics*file_year / list nocum nopercent;
run;

/* Where do diabetes measures live? */
proc freq data=qarr.all_years;
    tables Domain*Sub_Domain / list nocum nopercent;
run;

/* Diabetes crosswalk across every descriptive column */
proc sql;
    title 'Diabetes-related measures by year';
    select Domain, Sub_Domain, Measure_Description, Measure, file_year, count(*) as n_rows
    from qarr.all_years
    where upcase(catx(' ', Domain, Sub_Domain, Measure_Description, Measure)) contains 'DIABET'
       or upcase(catx(' ', Domain, Sub_Domain, Measure_Description, Measure)) contains 'HBA1C'
    group by Domain, Sub_Domain, Measure_Description, Measure, file_year
    order by Measure_Description, Measure, file_year;
quit;
title;