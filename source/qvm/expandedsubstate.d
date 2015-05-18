module qvm.expandedsubstate;
import std.algorithm.iteration;
import std.range;
import qvm.substate;
import std.stdio;
import qvm.state;
import std.complex;
import std.conv;
import std.math;
import std.random;
import qvm.operators;

/**
 * A substate which is greedy in terms of memory.
 */
class ExpandedSubstate : Substate{
    Complex!double[] states;
    int currentIndex=0;

    /**
     * Constructs an expanded substate given 
     * an array of complex coefficients and qubit
     * position dictionary 
     */
    this(Complex!double[] states){
        super(cast(int)log2(states.length));
        this.states = states; 
    }

    /**
     * Constructs an expanded substate with 
     * one qubit initialized to |0>
     */ 
    this(){
        super();
        states= new Complex!double[2];
        states[0]= complex(1,0); 
    }
    
    override
    int num_of_states(){
        return cast(int)states.length;
    }

    override
    int measure(string qubit_name){
        return 0;
    }

    deprecated
    int measure(int qubit_index){
        writeln("Measuring: ", qubit_index);
        double[] pr = [0.0L, 0.0L];

        foreach(int i, Complex!double coef; states) {
            double r = coef.re;
            double im = coef.im;
            if(i & (1 << qubit_index)) {
                pr[1] += r*r + im*im;
            }else{
                pr[0] += r*r + im*im;
            }
            
        }
        double rand = uniform(0.0L, pr[0]+ pr[1]);
        ubyte measured = 0;
        if(rand > pr[0]) {
            measured = 1;
        }
        foreach(int i, Complex!double coef; states) {
            if((i & (1 << qubit_index)) ^ (measured << qubit_index)) {
                states[i] = Complex!double(0.0, 0.0);
            }else{
                states[i] /= sqrt(pr[measured]);
            }
        }
        return measured;
    }

    unittest {
    }


    void applyOperator(Operator op) {
        assert(op.dimension == this.states.length);
        Complex!double[] new_states = new Complex!double[states.length];
        for(int i = 0; i < op.dimension; i++) {
            Complex!double sum = Complex!double(0.0, 0.0);
            for(int j = 0; j < op.dimension; j++) {
                sum += states[j]*op.get(i, j);
            }
            new_states[i] = sum;
        }
        states = new_states;
    }
    /**
     * Switch the amplitudes of the qubits at index first and index
     * second.
     */
    void switch_qubits(size_t first, size_t second) {
        auto seq = sequence!((a, n) => n)()[0..states.length];
        int[int] swapped;

        foreach(size_t i; seq.filter!(a => (a & (1 << first)))) {
            writeln(i);
            byte first_bit = (i >> first) & 0x1;
            byte second_bit = (i >> second) & 0x1;

            size_t new_i = i & ~(1 << first);
            new_i &= ~(1 << second);
            new_i |= first_bit << second;
            new_i |= second_bit << first;
            writeln(new_i);

            auto tmp = states[i];
            states[i] = states[new_i];
            states[new_i] = tmp;
        }
    }

    unittest {
    }
    override
    void applyOperator(Operator op, string[] qubits){
    }

    unittest {
    }

    /**
     * Dumps the raw state into a string. 
     * This is for debugging purposes.
     */
    override
    string dump(){
        string s = "";
        for(int i=0; i<states.length; i++){
            if(!(states[i].re==0 && states[i].im==0)){
                s ~= " + (" ~ states[i].toString() ~ ")|" ~
                    to!string(i) ~ ">";
            }
        }
        return s[2..$];
    }
    
    override
    void print(){
    }

    override
    void expand(Substate sub){
    }
                    
    override
    bool empty(){
        if(currentIndex >= states.length){
            currentIndex = 0;
            return true;
        }
        return false;
    }

    override
    Coefstate front(){
        return Coefstate(states[currentIndex], currentIndex);
    }

    /**
     * Pop skips entri
     */
    override
    void popFront(){
        if(!(currentIndex+1>=states.length)&&
           !(states[currentIndex+1].re==0 ||
             states[currentIndex+1].im==0)){
             currentIndex++;
         }else{ 
             currentIndex++;
             while(currentIndex<states.length&&
                   states[currentIndex].re==0 && 
                   states[currentIndex].im==0  
                   ){
                 currentIndex++;
             }
        }
    }
}
