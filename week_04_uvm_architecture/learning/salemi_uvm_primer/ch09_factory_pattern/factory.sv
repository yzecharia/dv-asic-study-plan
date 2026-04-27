
virtual class animal;
   protected int age=-1;
   protected string name;

   function new(int a, string n);
      age = a;
      name = n;
   endfunction : new

   function int get_age();
      return age;
   endfunction : get_age

   function string get_name();
      return name;
   endfunction : get_name

   pure virtual function void make_sound();

endclass : animal


class lion extends animal;

   bit thorn_in_paw = 0;

   function new(int age, string n);
      super.new(age, n);
   endfunction : new

   function void make_sound();
      $display ("The lion, %s, says Roar", get_name());
   endfunction : make_sound
   
endclass : lion


class chicken extends animal;

   function new(int age, string n);
      super.new(age, n);
   endfunction : new

   function void make_sound();
      $display ("The Chicken, %s, says BECAWW", get_name());
   endfunction : make_sound


endclass : chicken

class animal_factory;

   static function animal make_animal(string species, 
                                      int age, string name);
      chicken chicken;
      lion lion;
      case (species)
        "lion" : begin
           lion = new(age, name);
           return lion;
        end

        "chicken" : begin
           chicken = new(age, name);
           return chicken;
        end

        default : 
          $fatal (1, {"No such animal: ", species});
        
      endcase 
      
   endfunction : make_animal
   
endclass : animal_factory



class animal_cage #(type T=animal);

   static T cage[$];

   static function void cage_animal(T l);
      cage.push_back(l);
   endfunction : cage_animal

   static function void list_animals();
      $display("Animals in cage:"); 
      foreach (cage[i])
        $display(cage[i].get_name());
   endfunction : list_animals

endclass : animal_cage


module top;


   initial begin
      animal animal_h;
      lion   lion_h;
      chicken  chicken_h;
      bit cast_ok;
      
      animal_h = animal_factory::make_animal("lion", 15, "Mufasa");
      animal_h.make_sound();

      cast_ok = $cast(lion_h, animal_h);
      if ( ! cast_ok) 
        $fatal(1, "Failed to cast animal_h to lion_h");
      
      if (lion_h.thorn_in_paw) $display("He looks angry!"); 
      
      if (!$cast(lion_h, animal_factory::make_animal("lion", 2, "Simba")))
        $fatal(1, "Failed to cast animal from factory to lion_h");
      
      animal_cage#(lion)::cage_animal(lion_h);
      
      if(!$cast(chicken_h ,animal_factory::make_animal("chicken", 1, "Clucker")))
        $fatal(1, "Failed to cast animal factory result to chicken_h");
      
      animal_cage #(chicken)::cage_animal(chicken_h);

      if(!$cast(chicken_h, animal_factory::make_animal("chicken", 1, "Boomer")))
        $fatal(1, "Failed to cast animal factory result to chicken_h");

      animal_cage #(chicken)::cage_animal(chicken_h);

      $display("-- Lions --");
      animal_cage #(lion)::list_animals();
      $display("-- Chickens --");
      animal_cage #(chicken)::list_animals();
   end

endmodule : top




