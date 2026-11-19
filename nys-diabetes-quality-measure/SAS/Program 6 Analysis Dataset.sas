/* Analysis dataset: three measures + 2024 glycemic status (HbA1c testing dropped) */
data qarr.diab;
    set qarr.all_years2;
    where measure_std in ('BP Control <140/90', 'HbA1c Control <8%',
                          'Eye Exam', 'Glycemic Status <8% (2024 only)');

    calc_rate = ifn(Denominator > 0, 100 * Numerator / Denominator, .);

    flag_missing_counts = (missing(Numerator) or missing(Denominator));
    flag_num_gt_den     = (not missing(Numerator) and not missing(Denominator)
                           and Numerator > Denominator);
    flag_small_den      = (not missing(Denominator) and Denominator < 30);
    flag_rate_mismatch  = (not missing(calc_rate) and not missing(Rate)
                           and abs(calc_rate - Rate) > 1);
    flag_unknown_region = (upcase(Category) = 'REGION'
                           and upcase(strip(Characteristics)) = 'UNKNOWN');
run;

/* 1. Flag summary: this table goes in your README */
proc sql;
    title 'Data quality flags by measure and year';
    select measure_std, file_year,
           count(*)                    as n_rows,
           sum(flag_missing_counts)    as missing_counts,
           sum(flag_num_gt_den)        as num_gt_den,
           sum(flag_small_den)         as small_den_lt30,
           sum(flag_rate_mismatch)     as rate_mismatch,
           sum(flag_unknown_region)    as unknown_region
    from qarr.diab
    group by measure_std, file_year
    order by measure_std, file_year;

    /* 2. Duplicate keys (year is part of the key) */
    title 'Duplicate keys (expect none)';
    select measure_std, Payer, Category, Characteristics, file_year, count(*) as n
    from qarr.diab
    group by measure_std, Payer, Category, Characteristics, file_year
    having count(*) > 1;
quit;

/* 3. Rate scale: should run from 0 to 100 */
proc means data=qarr.diab n nmiss min max maxdec=1;
    class measure_std;
    var Rate calc_rate;
run;

/* 4. Look at the rows that disagree with their own counts */
proc print data=qarr.diab (obs=20) noobs;
    where flag_rate_mismatch = 1 or flag_num_gt_den = 1;
    var measure_std file_year Payer Category Characteristics
        Numerator Denominator Rate calc_rate;
run;
title;



/* -------------------------------------- */

data work.mm;
    set qarr.diab;
    absdiff = abs(calc_rate - Rate);
run;

proc sql;
    title 'Size of rate mismatch by category';
    select Category,
           count(*)                       as n_rows,
           mean(absdiff)       format=5.1 as mean_abs_diff,
           max(absdiff)        format=5.1 as max_abs_diff,
           mean(absdiff > 2)   format=percent8.0 as pct_over_2pts
    from work.mm
    group by Category
    order by mean_abs_diff desc;

    title 'Statewide rows only: published vs calculated';
    select measure_std, Payer, file_year, Numerator, Denominator, Rate,
           calc_rate format=5.1, absdiff format=5.1
    from work.mm
    where Category = 'Statewide'
    order by measure_std, Payer, file_year;
quit;
title;