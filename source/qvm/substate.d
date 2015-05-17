module qvm.substate;
import std.complex;
import std.container;
import qvm.operators;

struct Coefstate{
    Complex!double coefficient;
    int state;
}

abstract class Substate{
   int num_of_qubits;
   
   this(){
       this.num_of_qubits = 1;
   }  
   this(int num_of_qubits){
       this.num_of_qubits = num_of_qubits;
   }

   abstract void measure(int qubit_id);   
   abstract void applyOperator(Operator op, size_t[] qubits);
   abstract string dump();
   abstract void print();
   abstract void expand(Substate sub);
   abstract bool empty();
   abstract Coefstate front();
   abstract void popFront();
   abstract int num_of_states();
}
