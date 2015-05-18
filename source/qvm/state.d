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
    Positions[string] qbit_positions; 
   
    this() {}

    /**
     * Adds a qubits to the current quantum
     * state initialized to |0>. By default,
     * every cluster is initialized to a ClutteredSubstate
     */
    void insertQubit(string qubit_name) {
        qbit_positions[qubit_name] = Positions(1,qbit_positions.length);
        clusters.insert(new ClutteredSubstate(qbit_positions));
    }

    unittest{
        writeln("Testing insertQubit() in State...");
        State s=new State();
        s.insertQubit("a");
        s.insertQubit("b");
        s.insertQubit("c"); 
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
    void measure(string qubit_name) {

        // This is the part where you factor out the qubit that has been
        // measured into a new cluster 
        
    }
    unittest {
        writeln("\nTesting measurement in State...");
        writeln("Done!\n");
    }

    /**
     *
     *
     */
    deprecated
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
        s.insertQubit("a");
        s.insertQubit("b");
        writeln(s.dump);
        
        writeln("ClusterAAA: ", s.find_cluster(0));
        writeln("ClusterAAA: ", s.find_cluster(1),"\n");
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
    void applyOperator(Operator op, string[] qubits) {
        switch(op.name) {
            case "hadamard": 
                // Search for clusters on which to apply Hadamard
                string[][int] clustered;
                foreach(string name; qubits){
                    clustered[qbit_positions[name].pos_in_state] ~= name;
                }

                // Applies Hadamard to each cluster containing a qubit
                // from qubits
                foreach(int index; clustered.byKey()){
                    clusters[index].applyOperator(
                            generate_hadamard(clustered[index].length), 
                            clustered[index]); 
                }
                break;
            case "fcnot":
                break;
            default:
                int min=32;
                int max=0;
                foreach(string name; qubits){
                    if(qbit_positions[name].pos_in_state >= max){
                        max = qbit_positions[name].pos_in_state; 
                    }
                }
                foreach(string name; qubits) {
                    if(qbit_positions[name].pos_in_state <= min) {
                        min = qbit_positions[name].pos_in_state; 
                    }
                }
                
                while(max>min){
                    expand(min);
                    max--;
                }
                clusters[min].applyOperator(op, qubits);
                break;  
        }
    }
    unittest {
        writeln("Testing applyOperator in state");
        State s = new State();
        s.insertQubit("a");
        s.insertQubit("b");
        s.insertQubit("c"); 
        writeln("Initial:" ,s.dump());
        writeln("Dict:", s.qbit_positions);
        auto op = new SillyOperator();
        op.name = "hadamard";
        s.applyOperator(op,["a","b","c"]);
        writeln("H1: ", s.dump());
        s.applyOperator(op,["b"]);
        writeln("H2: ", s.dump());
        s.applyOperator(generate_toffoli,["a", "b", "c"]); 
        writeln("Toffoli: ", s.dump());
        writeln("Done!\n");
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
        // Updates the position dictionary of the qubits
        foreach(string qbit_name; qbit_positions.byKey()){
            if(qbit_positions[qbit_name].pos_in_state==cluster_index+1){
                qbit_positions[qbit_name].pos_in_state -= 1;
                qbit_positions[qbit_name].pos_in_clust +=
                    clusters[cluster_index].num_of_qubits;
            } else if(qbit_positions[qbit_name].pos_in_state>cluster_index) {
                qbit_positions[qbit_name].pos_in_state -= 1;
            }

        }
        // Expands the states
        clusters[cluster_index].expand(clusters[cluster_index + 1]);

        // Remove the no longer needed cluster
        for(size_t j = cluster_index+2; j < clusters.length; j++) {
            clusters[j-1] = clusters[j];
        }
        clusters.removeBack();
    }
    unittest {
        writeln("Testing expand in State...");
        State s = new State();
        s.insertQubit("a");
        s.insertQubit("b");
        s.insertQubit("c"); 
        writeln(s.dump());
        s.expand(0);
        writeln(s.dump());
        auto op = new SillyOperator();
        op.name = "hadamard";
        s.applyOperator(op,["a","b","c"]);
        writeln(s.dump());
        writeln("Done!\n");
    }

    /**
     *
     *
     */
    void expandAll(){
        while(clusters.length!=1){
            expand(0);
        }
    }

    unittest {
        writeln("\nTesting expandAll...");
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
        st.expandAll();
        writeln(st.dump());
        writeln("Done!");
    }
}
