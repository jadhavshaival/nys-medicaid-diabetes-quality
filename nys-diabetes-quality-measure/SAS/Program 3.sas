%macro clean(yr);
    data work.y&yr.c;
        set work.y&yr(rename=(Numerator=n_in Denominator=d_in Rate=r_in
                              Measurement_Year=my_in));
        length source_file $60;
        source_file = "QARR_Health_Disparities_&yr..csv";
        file_year   = &yr;
        Numerator        = input(compress(vvalue(n_in), ', '),  ?? best32.);
        Denominator      = input(compress(vvalue(d_in), ', '),  ?? best32.);
        Rate             = input(compress(vvalue(r_in), ', %'), ?? best32.);
        Measurement_Year = input(compress(vvalue(my_in)),       ?? best32.);
        drop n_in d_in r_in my_in;
    run;
%mend;

%macro cleanall;
    %do yr=2018 %to 2024;
        %clean(&yr);
    %end;
%mend;
%cleanall;

data qarr.all_years;
    length Payer $60 Domain $100 Sub_Domain $150 Measure_Description $300
           Measure $300 Method_of_Data_Collection $60 Category $60
           Characteristics $150 Measure_Code $40 source_file $60;
    set work.y2018c work.y2019c work.y2020c work.y2021c
        work.y2022c work.y2023c work.y2024c;
    Payer = strip(Payer);
    Category = strip(Category);
    Characteristics = strip(Characteristics);
    Measure_Description = strip(Measure_Description);
run;

proc freq data=qarr.all_years;
    tables file_year*Measurement_Year / list missing;
    tables file_year*Payer / list nocum;
    tables Category / nocum;
run;