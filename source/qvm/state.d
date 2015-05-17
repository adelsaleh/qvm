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
import qlib.collections;

struct Positions{
    int pos_in_clust; // Position of the qubits in the cluster
    int pos_in_state; // Position of the qubits in the state
}

/**
 * The current state of the qubits in the current quantum
 * program.
 */
class State {
    Array!(Substate) clusters;     //  THE FUCKING STATES!!!
    
    this() {}

    /**
     * Adds a qubits to the current quantum
     * state initialized to |0>. By default,
     * every cluster is initialized to a ClutteredSubstate
     *
     *
     */
    void insertQubit() {
        clusters.insert(new ClutteredSubstate());
    }

    unittest{
        writeln("Testing insertQubit() in State...");
        State s=new State();
        s.insertQubit();
        s.insertQubit();
        s.insertQubit(); 
        writeln(s.dump());
        writeln("Done!\n");
    }


    /**
     * Measures the qubits at the provided index and returns
     * the value.
     *
     * Params:
     *      index = The qubits descriptor.
     */
    void measure(int qubit_index) {
        int qubits = 0;
        int i = 0;
        for(i = 0; i < clusters.length; i++) {
            if(qubits+clusters[i].num_of_qubits > qubit_index) {
                break;
            }
            qubits += clusters[i].num_of_qubits;
        }
        clusters[i].measure(qubit_index - qubits);
    }

    unittest {
        writeln("Testing measurement in State");
        double s = 1/sqrt(2.0L);
        State state = new State();
        Complex!double[] bellStates = [Complex!double(s, 0)
                                    ,Complex!double(0, 0)
                                    ,Complex!double(0, 0)
                                    ,Complex!double(s, 0)];


        Complex!double[] invBellStates = [Complex!double(s, 0)
                                       ,Complex!double(0, 0)
                                       ,Complex!double(0, 0)
                                       ,Complex!double(-s, 0)];
        state.clusters.insert(new ExpandedSubstate(bellStates));
        state.clusters.insert(new ExpandedSubstate(invBellStates));
        writeln(state.clusters[0].num_of_qubits);
        state.measure(3);
        writeln(state.dump);
    }

    size_t find_cluster(size_t qubit) {
        int qubits = 0;
        for(int i = 0; i < clusters.length; i++) {
            qubits += clusters[i].num_of_qubits;
            if(qubits > qubit) {
                return i;
                
            }
        }

        throw new Exception("Cluster not found");
    }
    unittest {
        writeln("Testing find_cluster");
        State s = new State();
        s.insertQubit();
        s.insertQubit();
        writeln(s.dump);
        
        writeln("ClusterAAA: ", s.find_cluster(0));
        writeln("ClusterAAA: ", s.find_cluster(1));
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

    void applyOperator(Operator op, size_t[] qubits) {
        size_t min_cluster = find_cluster(qubits[0]);
        size_t max_cluster = min_cluster;
        foreach(qubit; qubits) {
            size_t cl = find_cluster(qubit);
            if (cl < min_cluster) {
                min_cluster = cl;
            } else if(cl > max_cluster) {
                max_cluster = cl;
            }
        }

        while(max_cluster > min_cluster) {
            expand(min_cluster);
            max_cluster--;
        }

        for(int i = 0; i < qubits.length; i++) {
            qubits[i] -= min_cluster;
        }
        clusters[min_cluster].applyOperator(op, qubits);
    }

    unittest {
        writeln("Testing applyOperator");
        State s = new State();
        s.insertQubit();
        s.insertQubit();
        s.insertQubit();
        writeln(s.dump);
        s.applyOperator(generate_hadamard(2), [0, 2]);
        writeln(s.dump);
    }
    
    /**
     * Dumps the raw state into a string. 
     * This is for debugging purposes.
     */
    string dump() {
        string s = "|phi> = ";
        foreach(Substate sub; clusters){
            s ~= sub.num_of_states()==1 
                 ? 
                 sub.dump() ~ " x  "
                 :
                 "(" ~ sub.dump() ~ ") x  ";
        }
        return s[0 .. $-3];
    }


    unittest{
        writeln("Testing dump() in State...");
        Array!Coefstate a;
        Array!Coefstate b;
        auto qubitsnum = uniform(1,4);
        for(int i=0; i<pow(2, qubitsnum); i++){
            a.insert(Coefstate(
               complex(pow(-1.0,i%2)*uniform01!double(),
                       uniform01!double()), i)
            );
            b.insert(Coefstate(
               complex(uniform01!double(),
                       pow(-1.0,i%2)*uniform01!double()), i)
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
     * Expands the tensor product of a given cluster and 
     * the cluster that follows it, and saves the result in 
     * the first cluster
     *
     * Params:
     *      cluster_index = the index of the cluster 
     */
    void expand(size_t cluster_index){
        ClutteredSubstate cs = new ClutteredSubstate();
        cs.num_of_qubits = clusters[cluster_index].num_of_qubits + 
                            clusters[cluster_index + 1].num_of_qubits;
        cs.states = Array!Coefstate();
        int i = 0;
        foreach(Coefstate cfs; clusters[cluster_index]) {
            foreach( Coefstate cfs1; clusters[cluster_index + 1]) {
                auto prod = cfs.coefficient * cfs.coefficient;
                if(prod.re != 0 || prod.im != 0)
                    cs.states.insert(Coefstate(cfs.coefficient * cfs1.coefficient, i));
                i++;
            }
        }
        for(size_t j = cluster_index+2; j < clusters.length; j++) {
            clusters[j-1] = clusters[j];
        }
        clusters.removeBack();
        clusters[cluster_index] = cs;
    }

    unittest {
        import qvm.operators;
        writeln("TESTING STATE EXPAND");
        State s = new State();
        s.insertQubit();
        s.insertQubit();
        s.clusters[1].applyOperator(generate_hadamard(1), [0]);
        s.expand(0);
        writeln(s.dump);
    }

    void expandAll(){
        while(clusters.length!=1){
            expand(0);
        }
    }
}
