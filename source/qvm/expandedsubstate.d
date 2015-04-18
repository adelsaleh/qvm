module qvm.expandedsubstate;
import qvm.substate;
import qvm.state;
import std.complex;
import std.conv;
import std.math;

/**
 * A substate which is greedy in terms of memory.
 */
class ExpandedSubstate : Substate{
    Complex!double[] states;
    Positions[int] qubit_positions;
    int currentIndex;

    /**
     * Constructs an expanded substate given 
     * an array of complex coefficients and qubit
     * position dictionary 
     */
    this(Complex!double[] states, Positions[int] qubit_positions){
        super(cast(int)log2(states.length));
        this.states = states; 
        this.qubit_positions = qubit_positions;
    }

    /**
     * Constructs an expanded substate with 
     * one qubit initialized to |0>
     */ 
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

    /**
     * Dumps the raw state into a string. 
     * This is for debugging purposes.
     */
    override
    string dump(){
        string s = "";
        for(int i=0; i<states.length; i++){
            if(!(states[i].re==0 && states[i].im==0)){
                s ~= " + (" ~ states[i].toString() ~ ")|" ~
                    to!string(i) ~ ">";
            }
        }
        return s[2..$];
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
