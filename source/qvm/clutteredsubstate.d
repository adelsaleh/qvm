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
import qvm.operators;

/**
 * A substate that does not store states with 0 coefficients. 
 */
class ClutteredSubstate : Substate{
    Array!Coefstate states;        // The states amd the coefficients 
    private int currentIndex;  // For iterating purposes

    this(){
        super();
        states.insert(Coefstate(complex(1,0),0));
    }
    override
    int num_of_states(){
        return cast(int)states.length;
    }    

    override
    void measure(int qubit_index){
        double[] pr = [0.0L, 0.0L];

        foreach(Coefstate cs; states) {
            double r = cs.coefficient.re;
            double i = cs.coefficient.im;
            if(cs.state & (1 << qubit_index)) {
                pr[1] += r*r + i*i;
            }else{
                pr[0] += r*r + i*i;
            }
            
        }
        double rand = uniform(0.0L, pr[0]+ pr[1]);
        ubyte measured = 0;
        if(rand > pr[0]) {
            measured = 1;
        }
        for(int i = 0; i < states.length; i++) {
            auto cs = states[i];
            writeln((cs.state & (1 << qubit_index)));
            writeln((cs.state & (1 << qubit_index)) ^ (measured << qubit_index) );
            if((cs.state & (1 << qubit_index)) != (measured << qubit_index)) {
                states[i] = Coefstate(Complex!double(0.0, 0.0), cs.state);
            }else{
                states[i] = Coefstate(cs.coefficient / sqrt(pr[measured]), cs.state);
            }
        }
    }

    unittest {
        writeln("Testing ClutteredSubstate measurement");
        auto ss = new ClutteredSubstate();
        double s = 1/sqrt(2.0L);
        ss.states[0] = Coefstate(Complex!double(s, 0), 0);
        ss.states.insert(Coefstate(complex!double(s, 0), 3));
        ss.measure(1);
        writeln(ss.dump());
        writeln("Done");
        
    }

    void applyOperator(Operator op) {
        assert(op.dimension == (1 << super.num_of_qubits));
        Array!Coefstate new_states;
        for(int i = 0; i < op.dimension; i++) {
            Complex!double sum = Complex!double(0.0, 0.0);
            for(int j = 0; j < states.length; j++) {
                sum += states[j].coefficient*op.get(i, states[j].state);
            }
            if(sum.im != 0 || sum.re != 0) {
                new_states.insert(Coefstate(sum, i));
            }
        }
        states = new_states;
    }

    unittest {
        auto ss = new ClutteredSubstate();
        ss.applyOperator(generate_hadamard(1));
    }

    /**
     * Switch the amplitudes of the qubits at index first and index
     * second.
     */
    void switch_qubits(size_t first, size_t second) {

        for(int idx = 0; idx < states.length; idx++) {
            Coefstate cs = states[idx];
            size_t i = cs.state;
            byte first_bit = (i >> first) & 0x1;
            byte second_bit = (i >> second) & 0x1;

            size_t new_i = i & ~(1 << first);
            new_i &= ~(1 << second);
            new_i |= first_bit << second;
            new_i |= second_bit << first;
            writeln(new_i);
            states[idx] = Coefstate(cs.coefficient, cast(int)new_i);

        }
    }
    unittest {
        writeln("Testing switch for CLUTTEREDSubstate");
        double s = 1/sqrt(2.0);
        Complex!double[] init = [Complex!double(s*s, 0)
                                ,Complex!double(0, 0)
                                ,Complex!double(s*s, 0)
                                ,Complex!double(s, 0)
                                ,Complex!double(0, 0)
                                ,Complex!double(0, 0)
                                ,Complex!double(0, 0)
                                ,Complex!double(0, 0)];
        auto ss = new ClutteredSubstate();
        ss.states[0] = Coefstate(Complex!double(s*s, 0), 0);
        ss.states.insert(Coefstate(Complex!double(s*s, 0), 2));
        ss.states.insert(Coefstate(Complex!double(s, 0), 3));
        writeln(ss.dump);
        ss.switch_qubits(1, 2);
        writeln(ss.dump);
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
   void applyOperator(Operator op, size_t[] qubits){
        if(op.qubits != qubits.length) {
            throw new Exception("Invalid number of qubits");
        }
        for(int i = 0; i < qubits.length; i++) {
            switch_qubits(i, qubits[i]);
        }
        applyOperator(generate_identity(super.num_of_qubits-qubits.length).tensor(op));
        writeln("Applied operator: ", dump());
        for(int i = 0; i < qubits.length; i++) {
            switch_qubits(i, qubits[i]);
        }
    }



    /**
     * Dumps the raw state into a string. 
     * This is for debugging purposes.
     */
    override
    string dump(){
        string s =  "";
        for(int i=0; i<states.length; i++){
            if(states[i].coefficient.re == 0 &&
               states[i].coefficient.im == 0){
            }else if(states[i].coefficient.re == 0){
                s ~= states[i].coefficient.im == 1 
                    ? 
                    " + i|" ~to!string(states[i].state)~">" 
                    :
                    " + " ~ to!string(states[i].coefficient.im) ~ "i|" ~
                    to!string(states[i].state)~">";
            }else if(states[i].coefficient.im == 0) {
                s ~= states[i].coefficient.re == 1 
                    ? 
                    " + |" ~to!string(states[i].state)~">" 
                    :
                    " + " ~ to!string(states[i].coefficient.re) ~ "|" ~
                    to!string(states[i].state)~">";
                
            } else{  
                s ~= " + (" ~ states[i].coefficient.toString() ~ ")|"
                  ~ to!string(states[i].state) ~ ">";
            }
        }
        return s[3..$];
    }
    unittest{
        writeln("Testing dump() in ClutteredSubstate...");
        Array!Coefstate a;
        a.insert(Coefstate(complex(0.5,0.5),0));
        a.insert(Coefstate(complex(0.5,0),1));
        a.insert(Coefstate(complex(0.5,9),2));
        a.insert(Coefstate(complex(0,1),3));
        ClutteredSubstate clut = new ClutteredSubstate(); 
        clut.states = a;
        writeln(clut.dump());
        assert(clut.dump()==
              "(0.5+0.5i)|0> + 0.5|1> + (0.5+9i)|2> + i|3>");
        writeln("Done!\n");
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
                    tensor(cf1.state, cf2.state, sub.num_of_qubits))
                );
            
            }
        }
        this.states = expanded;
        super.num_of_qubits += sub.num_of_qubits; 
    }
    unittest{
        writeln("Testing expand() in ClutteredSubstate...");
        Array!Coefstate a;
        Array!Coefstate b;
        auto qbitnum = uniform(2,6);
        for(int i=0; i< uniform(0, pow(2,qbitnum)); i++){
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
        clut1.num_of_qubits = qbitnum;
        clut2.num_of_qubits = qbitnum;
        //writeln("|\u03D51> = " ~ clut1.dump());
        auto exp_clut2 = clut2.switchToExpanded();
        //writeln("|\u03D52> = " ~ exp_clut2.dump());
        //writeln(exp_clut2.states);
        clut1.expand(exp_clut2);
        //writeln("|\u03D51,\u03D52> = " ~ clut1.dump());
        writeln("Done!\n");
    }


    /**
     * Returns an ExpandedSubstate clone of the 
     * current ClutteredSubtate 
     */
    ExpandedSubstate switchToExpanded(){
        Complex!double[] expstate = new 
            Complex!double[pow(2, super.num_of_qubits)];
        for(int i=0;i<expstate.length;i++){
            expstate[i].re = 0.0;
            expstate[i].im = 0.0;
        }
        foreach(Coefstate cf; this.states){
            expstate[cf.state] = cf.coefficient;
        }
        return new ExpandedSubstate(expstate);
    }
    unittest{
        writeln("Testing switchToExpanded() in ClutteredSubstate...");
        Array!Coefstate a;
        auto qbitnum = uniform(1,5);
        for(int i=0; i<pow(2, qbitnum); i++){
            a.insert(Coefstate(
               complex(pow(-1.0, i%2)*uniform01!double(),
                       uniform01!double()), 
                       i)
            );
        }
        ClutteredSubstate clut = new ClutteredSubstate(); 
        clut.states = a;
        clut.num_of_qubits = qbitnum;
        writeln("ClUTTERED: " ~ clut.dump());
        auto b = clut.switchToExpanded();
        writeln("EXPANDED: " ~ b.dump());
        assert(b.num_of_qubits==qbitnum);
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
     *      qubits2 = the number of cubits represented by state 2
     */
    private int tensor(int state1, int state2, int qubits2){
        state1<<=qubits2;
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
        return this.states[currentIndex];
    }

    override
    void popFront(){
        currentIndex++;
    }
}

