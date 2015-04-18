module qvm.clutteredsubstate;
import std.container;
import std.complex;
import std.math;
import std.conv;
import std.stdio;
import qvm.state;
import qvm.substate;
import std.random;
import qvm.expandedsubstate;

/**
 * A substate that does not store states with 0 coefficients. 
 */
class ClutteredSubstate : Substate{
    Array!Coefstate states;        // The states amd the coefficients 
    Positions[int] qubit_positions;// The position dictionary
    private int currentIndex;  // For iterating purposes

    this(ref Positions[int] qpos){
        super();
        states.insert(Coefstate(complex(1,0),0));
        qubit_positions = qpos;
    }
    this(){
        super();
    }

    override
    int measure(int qubit_index){
        return 0;
    }

    /**
     * Applies the operator op on the list of qubits provided
     * in R. R must be a container of ints.
     *
     * Params:
     *      op = The operator we need to apply.
     *      qubits = The indices of the qubits we're applying
     *                  the operators on
     */
    override
    void applyOperator(R)(Operator op, R qubits){
    }

    /**
     * Dumps the raw state into a string. 
     * This is for debugging purposes.
     */
    override
    string dump(){
        string s =  "(" ~ states[0].coefficient.toString() ~ ")|"~ 
            to!string(states[0].state) ~ ">";
        for(int i=1; i<states.length; i++){
            s ~= " + (" ~ states[i].coefficient.toString() ~ ")|"
              ~ to!string(states[i].state) ~ ">";
        }
        return s;
    }
    unittest{
        Array!Coefstate a;
        a.insert(Coefstate(complex(0.5,0.5),0));
        a.insert(Coefstate(complex(0.5,0),1));
        a.insert(Coefstate(complex(0.5,9),2));
        a.insert(Coefstate(complex(0,1),3));
        ClutteredSubstate clut = new ClutteredSubstate(); 
        clut.states = a;
        assert(clut.dump()==
              "(0.5+0.5i)|0> + (0.5+0i)|1> + (0.5+9i)|2> + (0+1i)|3>");
    }
    

    /**
     * Expands the current cluttered substate with
     * the given substate
     *     
     * Params:
     *      sub = the substate to be expanded with
     */
    override
    void expand(Substate sub){
        Array!Coefstate expanded;
        foreach(Coefstate cf1; this){
            foreach(Coefstate cf2; sub){
                expanded.insert(
                    Coefstate(cf1.coefficient * cf2.coefficient,
                    tensor(cf1.state, cf2.state, sub.num_of_qbits))
                );
            }
        }
        states = expanded;
        super.num_of_qbits += sub.num_of_qbits; 
    }

    /**
     * Returns an ExpandedSubstate clone of the 
     * current ClutteredSubtate 
     */
    ExpandedSubstate switchToExpanded(){
        Complex!double[] expstate = new Complex!double[1<<super.num_of_qbits];
        foreach(Coefstate cf; this.states){
            expstate[cf.state] = cf.coefficient;
        }
        return new ExpandedSubstate(expstate, qubit_positions);
    }
    unittest{
        writeln("Testing switchToExpanded() in ExpandedSubstate...");
        Array!Coefstate a;
        auto qbitnum = uniform(1,4);
        for(int i=0; i<pow(2, qbitnum); i++){
            a.insert(Coefstate(
               complex(uniform01!double(),
                       uniform01!double()), 
                       i)
            );
        }
        ClutteredSubstate clut = new ClutteredSubstate(); 
        clut.states = a;
        clut.num_of_qbits = qbitnum;
        writeln("ClUTTERED: " ~ clut.dump());
        auto b = clut.switchToExpanded();
        writeln("EXPANDED: " ~ b.dump());
        assert(b.num_of_qbits==qbitnum);
        writeln("Done!\n");
        //assert(b.states == );
    }
    

    /**
     * Returns the tensor product of two basis vectors
     * labeled by integers in the Hilbert space.
     *
     * Params:
     *      state1 = the first vector
     *      state2 = the first vector
     *      qbits2 = the number of cubits represented by state 2
     */
    private int tensor(int state1, int state2, int qbits2){
        state1<<=qbits2;
        state1 = state1 | state2;
        return state1;    
    }

    /**
     * Prints the current state
     */
    override
    void print(){
    }

    override
    bool empty(){
        if(currentIndex==states.length){
            currentIndex=0;
            return true;
        }
        return false;
    }

    override
    Coefstate front(){
        return states[currentIndex];
    }

    override
    void popFront(){
        currentIndex++;
    }
    
}

