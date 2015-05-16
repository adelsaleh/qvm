module qvm.expandedsubstate;
import qvm.substate;
import std.stdio;
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
    int currentIndex=0;

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
    int num_of_states(){
        return cast(int)states.length;
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
    bool empty(){
        if(currentIndex == states.length){
            currentIndex = 0;
            return true;
        }
        return false;
    }

    override
    Coefstate front(){
        return Coefstate(states[currentIndex], currentIndex);
    }

    /**
     * Pop skips entri
     */
    override
    void popFront(){
        if(!(states[currentIndex+1].re==0 &&
             states[currentIndex+1].im==0)){
             currentIndex++;
         }else{ 
             currentIndex++;
             while(currentIndex<states.length&&
                   states[currentIndex].re==0 && 
                   states[currentIndex].im==0  
                   ){
                 currentIndex++;
             }
        }
    }
}
