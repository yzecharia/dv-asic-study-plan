// Bad dff design

module dff(
    output logic q,
    input  logic d, clk, rst_n
);

    assign q = d;   /

    ERROR_q_did_not_follow_d: assert property (@(posedge clk) disable iff (!rst_n) (q == $past(d))); // When using a label no need for else $display too the discription is in the label and will show in waveform display
        //else $display("ERROR: q did not follow d");
endmodule


/*
assert property (
    @(sample_signal)
    disable iff ( expression ) // optional disable condition (used to disable mostly after reset)
    propert_expression_or_sequence
);

Each property can be declared individually and seperatly asserted:
property p1;
    @sample_signal
    disable iff ( expression ) // optional
    property_expression_or_sequence
endproperty

assert property ( p1 ) optional_action_block;

1. assert - To specify that the given property of the design is true in simulation
2. assume - To specify that the given property is an assumption and used by formal tools to generate input stimulus
3. cover - To evaluate the property for functional coverage
4. restrict - To specify the property as a constraint on formal verification computations and is ignored by simulators

// Sequence syntac
sequence <name_of_sequence>
    <test_expression>
endsequence

// Assert the sequence
assert property (<name_of_sequence>)

// Property syntax
property <name_of_property>
  <test expression> or
  <sequence expressions>
endproperty

// Assert the property
assert property (<name_of_property>);

*/