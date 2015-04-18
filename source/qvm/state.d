module qvm.state;
import std.stdio;
import qvm.exceptions;
import qvm.operators;
import qvm.clutteredsubstate;
import qvm.expandedsubstate;
import qvm.substate;
import std.algorithm;
import std.random;
import std.range;
import std.complex;
import std.math;
import std.container;
import std.range: takeOne;
import std.conv;

struct Positions{
    int pos_in_clust; // Position of the qbit in the cluster
    int pos_in_state; // Position of the qbit in the state
}

/**
 * The current state of the qbits in the current quantum
 * program.
 */
class State {
    Positions[int] qbit_positions; // The position dictionary
    Array!(Substate) clusters;     //  THE FUCKING STATES!!!
    
    this() {}

    /**
     * Adds a qbit to the current quantum
     * state initialized to |0>. By default,
     * every cluster is initialized to a ClutteredSubstate
     *
     *
     * Params:
     *      qbit_id = the address of the i: of the given to the qbit.
     */
    void insertQubit(int qbit_id) {
        if(qbit_id in qbit_positions) 
            throw new DuplicateQubitNameException("Qubit name "~to!string(qbit_id)~" already exists");
        qbit_positions[qbit_id] = Positions(qbit_positions.length,0);
        clusters.insert(new ClutteredSubstate(qbit_positions));
    }
    unittest{
    }


    /**
     * Measures the qbit at the provided index and returns
     * the value.
     *
     * Params:
     *      index = The qbit descriptor.
     * Returns:
     *      The value measured(0 or 1)
     * Throws:
     *      A TangledException if the qbit is entangled.
     */
    int measure(int qbit_id) {
        return 
            clusters[qbit_positions[qbit_id].pos_in_state].measure(qbit_positions[qbit_id].pos_in_clust);
    }

    /**
     * Applies the operator op on the list of qbits provided
     * in R. R must be a container of ints.
     *
     * Params:
     *      op = The operator we need to apply.
     *      qbits = The indices of the qbits we're applying
     *                  the operators on
     */
    void applyOperator(R)(Operator op, R qbits) {}
    
    /**
     * Dumps the raw state into a string. 
     * This is for debugging purposes.
     */
    string dump() {
        string s = "|\u03D5 > = ";
        foreach(Substate sub; clusters){
            s ~= "(" ~ sub.dump() ~ ") \u2297\n       ";
        }
        return s[0 .. $-9];
    }
    unittest{
        writeln("Testing dump() in State...");
        Array!Coefstate a;
        Array!Coefstate b;
        auto qbitnum = uniform(1,4);
        for(int i=0; i<pow(2, qbitnum); i++){
            a.insert(Coefstate(
               complex(uniform01!double(),
                       uniform01!double()), i)
            );
            b.insert(Coefstate(
               complex(uniform01!double(),
                       uniform01!double()), i)
            );
        }
        ClutteredSubstate clut1 = new ClutteredSubstate(); 
        ClutteredSubstate clut2 = new ClutteredSubstate(); 
        clut1.states=a;
        clut2.states=b;
        State st = new State();
        st.clusters.insert(clut1);
        st.clusters.insert(clut2);
        writeln(st.dump());
        writeln("Done!\n");
    }


    /**
     * Prints the qbit at the specified index to stdout.
     *
     * Params:
     *      index = The qbit descriptor.
     * Throws:
     *      A TangledException if the qbit is entangled.
     */
    void print(int qdesc){
    }

   
    /**
     * Expands the tensor product of a given cluster and 
     * the cluster that follows it, and saves the result in 
     * the first cluster
     *
     * Params:
     *      cluster_index = the index of the cluster 
     */
    void expand(int cluster_index){
        foreach(int qbit_id; qbit_positions.byKey()){
            if(qbit_positions[qbit_id].pos_in_state==cluster_index+1){
                qbit_positions[qbit_id].pos_in_state -= 1;
                qbit_positions[qbit_id].pos_in_clust +=
                    clusters[cluster_index].num_of_qbits;
            }
        }
        clusters[cluster_index].expand(clusters[cluster_index+1]);
        removeElement(clusters, cluster_index+1);    
    }

    static void removeElement(R)(ref Array!R arr, int index){
        Array!R newArr;
        for(int i=0; i<arr.length; i++){
            if(i!=index)
                newArr.insert(arr[i]);
        }
        arr = newArr;
    }

    unittest {
        writeln("Testing removeElement() in State...");
        Array!int a;
        a.insert(1);
        a.insert(2);
        a.insert(3);
        removeElement(a, 1);
        assert(a==Array!int([1,3]));
        writeln("Done!\n");
    }

    void expand(int from, int to){
    }

    void expandAll(){
        while(clusters.length!=1){
            expand(0);
        }
    }
}
