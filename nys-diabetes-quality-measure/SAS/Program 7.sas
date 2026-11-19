/* Medicaid minus commercial gap, statewide, by measure and year */
proc sql;
    /* Statewide rows only, usable rows only */
    create table work.sw as
    select measure_std, Payer, file_year, Rate, Denominator, ci_ok,
           (Rate/100) * (1 - Rate/100) / Denominator as var_p
    from qarr.rates
    where Category = 'Statewide' and use_in_analysis = 1;

    /* Pair Medicaid with each commercial payer in the same measure and year */
    create table qarr.payer_gap as
    select m.measure_std,
           c.Payer         as comparison,
           m.file_year,
           m.Rate          as medicaid_rate,
           c.Rate          as comp_rate,
           m.Rate - c.Rate as gap format=5.1,
           case when m.ci_ok = 1 and c.ci_ok = 1
                then (m.Rate - c.Rate) - 1.96 * 100 * sqrt(m.var_p + c.var_p)
           end as gap_lcl format=5.1,
           case when m.ci_ok = 1 and c.ci_ok = 1
                then (m.Rate - c.Rate) + 1.96 * 100 * sqrt(m.var_p + c.var_p)
           end as gap_ucl format=5.1
    from work.sw m
         inner join work.sw c
           on  m.measure_std = c.measure_std
           and m.file_year   = c.file_year
    where m.Payer = 'Medicaid Managed Care'
      and c.Payer like 'Commercial%'
    order by m.measure_std, comparison, m.file_year;

    title 'Medicaid minus commercial gap (percentage points), statewide';
    select * from qarr.payer_gap;
quit;
title;