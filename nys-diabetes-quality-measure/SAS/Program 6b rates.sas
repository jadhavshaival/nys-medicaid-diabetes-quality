/* Program_6b_Rates.sas
   Builds qarr.rates from qarr.diab (Program 6).
   Adds: medians, oversized-denominator and implausible-rate flags,
         exclusion notes, use_in_analysis, ci_ok, Wilson 95% intervals.
   Run after Program_6_Analysis_Dataset.sas and before Program_7.sas. */

/* 1. Median denominator and median rate for the same measure, payer,
      category and characteristic across all years */
proc sql;
    create table work.r1 as
    select a.*, b.med_den, b.med_rate
    from qarr.diab a
         left join
         (select measure_std, Payer, Category, Characteristics,
                 median(Denominator) as med_den,
                 median(Rate)        as med_rate
          from qarr.diab
          group by measure_std, Payer, Category, Characteristics) b
      on  a.measure_std     = b.measure_std
      and a.Payer           = b.Payer
      and a.Category        = b.Category
      and a.Characteristics = b.Characteristics;
quit;

/* 2. Row-level flags */
data work.r2;
    set work.r1;
    /* denominator more than 4 times its usual size */
    flag_big_den      = (not missing(Denominator) and Denominator > 4 * med_den);
    /* published rate more than 25 points from its usual level */
    flag_rate_outlier = (not missing(Rate) and abs(Rate - med_rate) > 25);
run;

/* 3. Group-level flags: same measure, payer and year */
proc sql;
    create table work.r3 as
    select a.*,
           (b.n_big >= 2)  as grp_big_den,   /* several oversized denominators in the file */
           (b.n_bad >= 1)  as grp_rate_bad   /* any implausible rate in the file */
    from work.r2 a
         left join
         (select measure_std, Payer, file_year,
                 sum(flag_big_den)      as n_big,
                 sum(flag_rate_outlier) as n_bad
          from work.r2
          group by measure_std, Payer, file_year) b
      on  a.measure_std = b.measure_std
      and a.Payer       = b.Payer
      and a.file_year   = b.file_year;
quit;

/* 4. Exclusions, interval eligibility and Wilson 95% intervals */
data qarr.rates;
    set work.r3;
    length use_note $40;

    if grp_rate_bad = 1 then use_note = 'Excluded: implausible rate';
    /* Urban Rural Status appears in 2020 only, so it cannot show a trend.
       Ethnicity (2024 only) is kept because it goes with the new 2024 measure. */
    else if Category = 'Urban Rural Status' then use_note = 'Excluded: one-year category';
    else if flag_unknown_region = 1 then use_note = 'Excluded: unknown region';
    else use_note = 'OK';

    use_in_analysis = (use_note = 'OK');

    /* No interval where the denominator does not fit the published rate */
    ci_ok = (use_in_analysis = 1 and flag_big_den = 0 and grp_big_den = 0
             and not missing(Rate) and Denominator > 0);

    lcl = .; ucl = .;
    if ci_ok = 1 then do;
        /* Wilson interval from the PUBLISHED rate and reported denominator */
        p      = Rate / 100;
        n      = Denominator;
        z      = 1.96;
        dn     = 1 + z**2 / n;
        center = (p + z**2 / (2 * n)) / dn;
        half   = z * sqrt(p * (1 - p) / n + z**2 / (4 * n**2)) / dn;
        lcl    = 100 * (center - half);
        ucl    = 100 * (center + half);
    end;

    drop p n z dn center half;
run;

/* 5. Checks: expect 1,091 rows; 1,037 OK; 24 / 18 / 12 excluded; 999 with ci_ok = 1 */
proc freq data=qarr.rates;
    tables use_note use_note*ci_ok / nocum nopercent norow nocol;
run;

proc sql;
    title 'Rows with oversized denominators or implausible rates';
    select measure_std, Payer, file_year, Category, Characteristics,
           Denominator, med_den, Rate, med_rate, use_note, ci_ok
    from qarr.rates
    where flag_big_den = 1 or flag_rate_outlier = 1
    order by measure_std, Payer, file_year, Category;
quit;
title;