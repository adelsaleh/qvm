module qvm.clutteredcubstate;
import std.container;
import std.complex;

struct Coefstate{
    Complex!Double coefficient;
    int state;
}

class ClutteredSubstate : Ifunc{
    int num_of_qubits;
    Array!Coefstate states;    

    this(int qubit_id){
        states.insert(Coefstate(complex(1,0),0));
        num_of_qubits = 1;
    }

    int measure(int qubit_index){
    }

    void applyOperator(R)(Operator op, R qubits){
    }

    void dump(){
    }
    
    /**
     * Expands the tensor product of a given cluster and 
     * the cluster that follows it, and saves the result in 
     * the current cluster
     *
     * Params:
     *      cluster_index = the index of the cluster 
     */
    void expand(ClutteredSubstate clut){
        Array!Coefstate expanded;
        foreach(Coefstate cf1; states){
            foreach(Coefstate cf2; clut.states){
                expanded.insert(
                    Coefstate(cf1.coefficient * cf2.coefficient,
                    tensor(cf1.state, cf2.state, clut.num_of_qbits))
                );
            }
        }
        states = expanded;
    }
    
    private int tensor(int state1, int state2, int b){
        state1<<=b;
        state1 = state1 | state2;
        return state1;    
    }

    void print(){
    }
    
    void insertState(Complex!Double coeff, int state){
        states.insert(Coefstate(coeff, state));
    }
    
    void replace(int new_state, Complex!Double new_coeff){
    }
}

