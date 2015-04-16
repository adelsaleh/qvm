module qvm.expandedsubstate;
import qvm.substate;
import qvm.state;
import std.complex;

/**
 * A substate which is greedy in terms of memory.
 */
class ExpandedSubstate : Substate{
    Complex!double[] states;
    Positions[int] qubit_positions;

    this(Complex!double[] states){
        super();
        this.states = states; 
    }

    this(){
        super();
        states= new Complex!double[2];
        states[0]= complex(1,0); 
    }


    override
    int measure(int qubit_index){
        return 0;
    }

    override
    void applyOperator(R)(Operator op, R qubits){
    }

    override
    void dump(){
    }
    
    override
    void print(){
    }

    override
    void expand(Substate sub){
    }

    override
    bool empty(){return false;};
    override
    Coefstate front(){return Coefstate();};
    override
    void popFront(){};
}
