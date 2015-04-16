module qvm.clutteredsubstate;
import std.container;
import std.complex;
import qvm.state;
import qvm.substate;
import qvm.expandedsubstate;


class ClutteredSubstate : Substate{
    Array!Coefstate states;        // The states amd the coefficients 
    Positions[int] qubit_positions;// The position dictionary
    private int currentCoefstate;  // For iterating purposes

    this(ref Positions[int] qpos){
        super();
        states.insert(Coefstate(complex(1,0),0));
        qubit_positions = qpos;
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
    void dump(){
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
     * current ClutteredState 
     */
    ExpandedSubstate switchToExpanded(){
        Complex!double[] expstate = new Complex!double[1<<super.num_of_qbits];
        foreach(Coefstate cf; states){
            expstate[cf.state] = cf.coefficient;
        }
        return new ExpandedSubstate(expstate);
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
        if(currentCoefstate==states.length){
            currentCoefstate=0;
            return true;
        }
        return false;
    }

    override
    Coefstate front(){
        return states[currentCoefstate];
    }

    override
    void popFront(){
        currentCoefstate++;
    }
    
}

