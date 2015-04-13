module qvm.state;
import qvm.exceptions;
import qvm.operators;
import std.range;
import std.container.array;


struct Coefstate{
    double coefficient;
    int state;
}

struct Cluster{
    int number_of_qubits;
    Array!Coefstates states;    
}

alias Array!(Cluster) ClusterList;

/**
 * The current state of the qubits in the current quantum
 * program.
 */
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
        Cluster c = Cluster(1, Array!Coefstate());
        c.states.add(Coefstate(1,0));
        clusters.insert(c);
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

    
    void expand(int cluster_index){
        int counter;
        Cluster c1 = clusters[cluster_index];
        Cluster c2 = clusters[cluster_index++];
        foreach(Coefstate coeff_state_1; clusters[cluster_index].states){
            foreach(Coefstate coeff_state_2; clusters[cluster_index+1].states){
                if(counter < c1.states.length)
                    clusters[cluster_index].states[counter++] =
                        Coefstate(coeff_state_1.coefficient * coeff_state_2.coefficient,
                        tensor(coef_state_1.state, coef_state_2.state, c2.number_of_qubits));
                else {
                    cluster[cluster_index].states.add(
                              Coefstate(coeff_state1.coefficient * coeff_state2.coefficient,
                              tensor(coef_state1.state, coef_state2.state, c2.number_of_qubits))
                             );
                }
            }
        }
        c1.number_of_qubits += c2.number_of_qubits;
        clusters.removeKey(cluster_index++);
    }
    
    private int tensor(int state1, int state2, int b){
        state1<<=b;
        state1 = state1|state2;
        return state1;    
    }

    void expandAll(){
        while(clusters.length!=1){
            expand(0);
        }
    }
}
