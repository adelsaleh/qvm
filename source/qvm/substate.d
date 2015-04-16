module qvm.substate;
import std.complex;
import std.container;

struct Coefstate{
    Complex!double coefficient;
    int state;
}

abstract class Substate{
   public int num_of_qbits;
   
   this(){
       this.num_of_qbits = 1;
   }  

   abstract int measure(int qubit_id);   
   abstract void applyOperator(R)(Operator op, R qubits);
   abstract void dump();
   abstract void print();
   abstract void expand(Substate sub);
   abstract bool empty();
   abstract Coefstate front();
   abstract void popFront();
}
