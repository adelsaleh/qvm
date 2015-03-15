module qvm.state;
import qvm.exceptions;
import qvm.operators;
import std.range;
import std.container.array;

/**
 * The current state of the qubits in the current quantum
 * program.
 */

alias Array!(Array!int) ClusterList;
class State {
    int[string] qubit_positions;
    ClusterList clusters;
    
    this() {}
    /**
     * Adds a qubit to the current quantum
     * state initialized to |0>
     *
     * Params:
     *      qubit_name = the name of the given to the qubit.
     */
 
    void addQubit(string qubit_name) {
        if(qubit_name in qubit_positions) 
            throw new DuplicateQubitNameException("Qubit name "~qubit_name~" already exists");
        qubit_positions[qubit_name] = qubit_positions.length;
        clusters.insert(Array!double);

    }

    /**
     * Measures the qubit at the provided index and returns
     * the value.
     *
     * Params:
     *      index = The qubit descriptor.
     * Returns:
     *      The value measured(0 or 1)
     * Throws:
     *      A TangledException if the qubit is entangled.
     */
    int measure(int qdesc) {
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
    void applyOperator(R)(Operator op, R qubits) {}
    
    /**
     * Dumps the raw state into a string. 
     * This is for debugging purposes.
     */
    string dump() {return "";}

    /**
     * Prints the qubit at the specified index to stdout.
     *
     * Params:
     *      index = The qubit descriptor.
     * Throws:
     *      A TangledException if the qubit is entangled.
     */
    void print(int qdesc){}
}
