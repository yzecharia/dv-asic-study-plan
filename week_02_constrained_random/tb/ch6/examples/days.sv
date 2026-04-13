class Days;
    typedef enum {SUN, MON, TUE, WED, THU, FRI, SAT} days_e;
    days_e choices[$];
    rand days_e choice;
    constraint c_days {
        choice inside {choices};
    }
endclass : Days

program automatic test;
    initial begin
        Days days;
        days = new ();
        days.choices = {Days::SUN, Days::SAT};
        assert(days.randomize());
        $display("Random weekend day %s\n", days.choice.name());

        days.choices = {Days::MON, Days::TUE, Days::WED, Days::THU, Days::FRI};
        assert(days.randomize());
        $display("Random week day %s", days.choice.name());
    end
endprogram : test