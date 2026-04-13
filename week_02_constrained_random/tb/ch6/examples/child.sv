class Child;
    rand bit [7:0] age;
    constraint c_teenager {
        age > 12;
        age < 20;
    } 
    
endclass : Child