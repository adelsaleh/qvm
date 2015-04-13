module qvm.IFunc;

interface IFunc{
   int measure(int qubit_id);   
   void applyOperator(R)(Operator op, R qubits);
   void dump();
   void print();
}
