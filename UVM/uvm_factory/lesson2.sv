/*
The UVM factory is a fundemental part of UVM that enables dynamic creation of objects and components in uvm based testbenches.
It provides a standardized wat to instantiate verification elements allowing flexability, reusability and configurability.

The UVM factory is a mechanism in UVM that is responsible for creating UVM objects and UVM components dynamically. 
Instead of using the new() method for creating instances, the UVM factory uses the factory registration and creation mechanisim that allows polymorphism and factory overrides to 
modify behavior without changing the source code.
*/