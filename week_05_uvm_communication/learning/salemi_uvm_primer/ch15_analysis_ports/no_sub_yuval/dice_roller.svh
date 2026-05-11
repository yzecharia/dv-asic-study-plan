class dice_roller extends uvm_component;
    rand byte die1, die2;

    constraint d6 {
        die1 >= 1; die1 <= 6;
        die2 >= 1; die2 <= 6;
    }

    function new (string name = "dice_roller", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    function byte two_dice();
        byte the_roll;
        void`(randomize());
        the_roll = die1 + die2;
        return the_roll;
    endfunction : two_dice
endclass : dice_roller