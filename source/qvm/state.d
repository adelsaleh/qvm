module qvm.state;

import qvm.operators;
import std.range;
import std.container.array;

/**
 * The current state of the qubits in the current quantum
 * program.
 */
class State {
    
    this() {}
    /**
     * Adds a qubit to the current quantum
     * state initialized to |0>
     *
     * Params:
     *      index = The index given to the qubit added.
     */
 
    void addQubit(int index) {
        
    }

    /**
     * Measures the qubit at the provided index and returns
     * the value.
     *
     * Params:
     *      index = The index of the qubit to measure.
     *
     * Returns:
     *      The value measured(0 or 1)
     * Throws:
     *      An exception if the qubit is entangled.
     */
    int measure(int index) {
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
    void applyOperator(R)(Operator op, R qubits) 
                                if(isRandomAccessRange!R){}
    
    /**
     * Dumps the raw state into stdout. This is for debugging
     * purposes.
     */
    void dump() {}

    /**
     * Prints the qubit at the specified index to stdout.
     *
     * Params:
     *      index = The index of the qubit to print.
     * Throws:
     *      An exception if the qubit is entangled.
     */
    void print(int index){}
}
