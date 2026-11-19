data qarr.all_years2;
    set qarr.all_years;
    length measure_std $50;

    /* same category, different capitalisation */
    if upcase(Category) = 'SMI STATUS' then Category = 'SMI Status';

    select (upcase(strip(Measure)));
        when ('DIABETES BP <140/90')           measure_std = 'BP Control <140/90';
        when ('DIABETES HBA1C <8%')            measure_std = 'HbA1c Control <8%';
        when ('DIABETES GLYCEMIC STATUS <8%')  measure_std = 'Glycemic Status <8% (2024 only)';
        when ('DIABETES EYE EXAM')             measure_std = 'Eye Exam';
        when ('DIABETES HBA1C TEST')           measure_std = 'HbA1c Testing (2018-2021)';
        otherwise                              measure_std = '';
    end;
run;

/* 1. Did the crosswalk catch every year? Expect the row counts you saw */
proc freq data=qarr.all_years2;
    where measure_std ne '';
    tables measure_std*file_year / nopercent norow nocol;
run;

/* 2. Why only 24 rows in 2019? Rows per Category by year for the three measures */
proc sql;
    title 'Rows by Category and year';
    select measure_std, Category,
           sum(file_year=2018) as y2018, sum(file_year=2019) as y2019,
           sum(file_year=2020) as y2020, sum(file_year=2021) as y2021,
           sum(file_year=2022) as y2022, sum(file_year=2023) as y2023,
           sum(file_year=2024) as y2024
    from qarr.all_years2
    where measure_std in ('BP Control <140/90','HbA1c Control <8%','Eye Exam')
    group by measure_std, Category
    order by measure_std, Category;

    title 'Rows by Payer and year';
    select measure_std, Payer,
           sum(file_year=2018) as y2018, sum(file_year=2019) as y2019,
           sum(file_year=2020) as y2020, sum(file_year=2021) as y2021,
           sum(file_year=2022) as y2022, sum(file_year=2023) as y2023,
           sum(file_year=2024) as y2024
    from qarr.all_years2
    where measure_std in ('BP Control <140/90','HbA1c Control <8%','Eye Exam')
    group by measure_std, Payer
    order by measure_std, Payer;

    title 'Data collection method by year';
    select measure_std, Method_of_Data_Collection,
           sum(file_year=2018) as y2018, sum(file_year=2019) as y2019,
           sum(file_year=2020) as y2020, sum(file_year=2021) as y2021,
           sum(file_year=2022) as y2022, sum(file_year=2023) as y2023,
           sum(file_year=2024) as y2024
    from qarr.all_years2
    where measure_std in ('BP Control <140/90','HbA1c Control <8%','Eye Exam')
    group by measure_std, Method_of_Data_Collection
    order by measure_std, Method_of_Data_Collection;
quit;
title;