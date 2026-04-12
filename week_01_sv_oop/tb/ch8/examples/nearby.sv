/*
    If I makea constraint in the extended class with the same name as a constraint in the base class it replaces the base constraint.
*/
class Nearby extends Transaction;
    constraint c_nearby {
        dst inside {[src-100:src+100]};
    }
    // Copy method not shown.

endclass : Nearby