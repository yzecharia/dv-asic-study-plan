module factory_demo_top;
    import factory_demo_pkg::*;

    initial begin
        animal animal_h;
        lion lion_h;
        chicken chicken_h;

        animal_h = animal_factory::make_animal(LION, 15, "TOM");
        animal_h.make_sound();
        if(!$cast(lion_h, animal_h)) $fatal(1, "Failed to cast animal_h to lion_h");
        lion_h.thorn_in_paw = 1'b1;
        $display("Lion %s, age %0d, thorn_in_paw=%0b", lion_h.get_name(), lion_h.get_age(), lion_h.thorn_in_paw);

        animal_h = animal_factory::make_animal(CHICKEN, 2, "CLUCKY");
        animal_h.make_sound();
        if(!$cast(chicken_h, animal_h)) $fatal(1, "Failed to cast animal_h to chicken_h");

        if($cast(lion_h, animal_h)) $fatal(1, "Unexpected: chicken handle cast to lion succeeded");

        $display("FACTORY DEMO PASS");
        $finish;
    end

endmodule : factory_demo_top