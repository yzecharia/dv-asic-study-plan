module factory_demo_top;
    import uvm_pkg::*;
    import factory_demo_pkg::*;

    initial begin
        // Creating the animals
        animal a = animal::type_id::create("Bob animal");
        lion l = lion::type_id::create("Mufasa");
        chicken c = chicken::type_id::create("Mr.Cook");

        // setting the age of the animals
        a.set_age(11);
        l.set_age(67);
        c.set_age(21);

        // displaying animals age and name
        $display("Animal: name=%s, age=%d", a.get_name(), a.get_age());
        $display("Lion: name=%s, age=%d", l.get_name(), l.get_age());
        $display("Chicken: name=%s, age=%d", c.get_name(), c.get_age());

        // animal sounds
        a.make_sound();
        l.make_sound();
        c.make_sound();

        // factory override
        // whenever createing a lion a chicken will be created insted
        // for this to work the objects cannot be siblings
        // the parent class is the one "creating" the object but creating a child object instead
        animal::type_id::set_type_override(chicken::get_type());
        begin
            animal a2 = animal::type_id::create("Simba");
            $display("Animal after override to chicken: ");
            a2.make_sound();
        end
        
    end

endmodule : factory_demo_top