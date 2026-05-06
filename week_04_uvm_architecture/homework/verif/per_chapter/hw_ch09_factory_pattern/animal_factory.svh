class animal_factory;
    typedef enum {LION, CHICKEN} species_e;
    static function animal make_animal(species_e spe, int age, string name);
        chicken chicken_h;
        lion lion_h;
        case(spe)
            LION: begin
                lion_h = new(age, name);
                return lion_h;
            end
            CHICKEN: begin
                chicken_h = new(age, name);
                return chicken_h;
            end
            default: $fatal(1, "unknown species: %s", spe.name());
        endcase
    endfunction : make_animal


endclass : animal_factory