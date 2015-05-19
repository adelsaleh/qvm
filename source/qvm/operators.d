module qvm.operators;

import std.complex;
import std.math;
import std.stdio;



/**
 * An operator that can evolve the state of the quantum system.
 */
class Operator {
    string name;
    /**
     * Get the element of the matrix at position i, j
     *
     * Params:
     *      i = The row the value is in
     *      j = The column the value is in
     *
     * Returns:
     *      The value at i, j
     */
     abstract Complex!double get(size_t i, size_t j);

     /**
      * Set the element of the matrix at position i, j
      * 
      * Params:
      *     i = The row of the value to set
      *     j = The column of the value to set
      *     val = The value to set
      */

    abstract void set(size_t i, size_t j, Complex!double val);
        
    /**
     * Should be obvious
     */
    override
    abstract string toString();

    /**
     * The dimension of the operator.
     */
    abstract size_t dimension();

    /**
     * The number of qubits in the state on which
     * we can apply this operator. An operator of
     * 2 qubits can only be applied on a state of 
     * two qubits.
     */
    abstract size_t qubits();
    abstract Operator dup();
}

Operator create_operator(size_t dim) {
    return new SillyOperator(dim);
}

Operator clone_operator(Operator op) {
    return new SillyOperator(cast(SillyOperator)op);
}

/**
 * Applies the tensor product to this operator, 
 * the input being the right.
 *
 * Params:
 *    op = The second tensor operator
 *
 * Returns:
 *    this tensor op. May be in place
 */
Operator tensor(Operator op1, Operator op2) {
    Operator ret = create_operator(op1.qubits + op2.qubits);
    for(size_t c_i = 0; c_i < ret.dimension; c_i++) {
        for(size_t c_j = 0; c_j < ret.dimension; c_j++) {
            size_t a_i = c_i/op2.dimension;
            size_t a_j = c_j/op2.dimension;
            size_t b_i = c_i-a_i*op2.dimension;
            size_t b_j = c_j-a_j*op2.dimension;

            Complex!double cval = op1.get(a_i, a_j) * op2.get(b_i, b_j);
            ret.set(c_i, c_j, cval);
        }
    }
    return ret;
}

unittest {
}

/**
 * A silly operator, completely suboptimal for simplicity
 * Size is always 2**qubits x 2**qubits
 */
class SillyOperator : Operator {
    public Complex!double[] matrix;
    protected size_t _qubits;
    protected size_t dim;
    this(size_t _qubits) {
        this._qubits = _qubits;
        dim = 1 << _qubits;
        matrix = new Complex!double[dim*dim];
    }

    this(SillyOperator op) {
        _qubits = op._qubits;
        dim = op.dim;
        matrix = op.matrix[];
    }

    Complex!double get(ulong i, ulong j) {
        return matrix[i*dimension + j];
    }

    override
    void set(size_t i, size_t j, Complex!double val) {
        matrix[i*dimension + j] = val;
    }

    override
    string toString() {
        string ret = "";
        for(size_t i = 0; i < dim; i++ ){
            ret ~= "[";
            if(matrix[i*dim] != Complex!double(0, 0)) {
                ret ~= ", "~matrix[i*dim].toString();
            }else{
                ret ~= ",     ";
            }
            for(size_t j = 1; j < dim; j++) {
                if(matrix[i*dim + j] != Complex!double(0, 0)) {
                    ret ~= ", "~matrix[i*dim + j].toString();
                }else{
                    ret ~= ",     ";
                }
            }
            ret ~= "]\n";
        }
        return ret;
    }


   
    override
    public size_t qubits() {
        return _qubits;
    }

    override
    public size_t dimension() {
        return dim;
    }

    override 
    Operator dup(){
        auto newop = new SillyOperator(this._qubits);
        newop.matrix = this.matrix.dup();
        return newop; 
    }
}

// Create known operators here

/**
 * Generates the hadamard operator for an N-Qubit system.
 *
 * Params:
 *      n = The number of qubits we want to superpose.
 */

// TODO: OPTIMIZE THIS SHIT
Operator generate_hadamard(size_t n) {
    Operator op = create_operator(1);
    Operator op1 = create_operator(1);
    double s = 1/sqrt(2.0L);
    op.set(0, 0, Complex!double(s, 0));
    op.set(0, 1, Complex!double(s, 0));
    op.set(1, 0, Complex!double(s, 0));
    op.set(1, 1, Complex!double(-s, 0));
    op1.set(0, 0, Complex!double(s, 0));
    op1.set(0, 1, Complex!double(s, 0));
    op1.set(1, 0, Complex!double(s, 0));
    op1.set(1, 1, Complex!double(-s, 0));
    for(int i = 1; i < n; i++) {
        op = op.tensor(op1);
    }
    op.name = "hadamard";
    return op;
}

Operator generate_ifelse(Operator op1, Operator op2) {
    assert(op1.dimension == op2.dimension);
    Operator ret = create_operator(op1.qubits + 1);
    for(int i = 0; i < op1.dimension; i++) {
        for(int j = 0; j < op1.dimension; j++) {
            ret.set(i, j, op1.get(i, j));
            ret.set(i+op2.dimension, j+op2.dimension, op2.get(i, j));
            ret.set(i+op1.dimension, j, Complex!double(0, 0));
            ret.set(i, j+op1.dimension, Complex!double(0, 0));
        }
    }
   return ret;
}

/**
 * Generate an fcnot operator from the given black box.
 * What this means is that |x>|y> is mapped to |x>|y + f(x) mod out_bits>
 *
 * Params:
 *     black_box = A function that takes a bitstring and transforms it into another one.
 *     in_bits = The size of the input bit string
 *     out_bits = The size of the output bit string
 *
 * Returns:
 *      A quantum operator representing the function black_box
 */
Operator generate_fcnot(int delegate(int) black_box, size_t in_bits, size_t out_bits) {
    Operator op = create_operator(in_bits + out_bits); 
    for(int i =0; i < op.dimension; i++) {
        for(int j = 0; j < op.dimension; j++) {
            op.set(i, j, Complex!double(0, 0));
        }
    }
    for(int i = 0; i < op.dimension; i++) {
        int x = i >> out_bits;
        int y = (i & ((1 << in_bits)-1));
        int fx = cast(int)((black_box(x) + y) % (1 << out_bits));
        op.set(i, (x << out_bits) | fx, Complex!double(1, 0));
    }
    op.name = "fcnot";
    return op;
}

unittest {
    /*
    import std.functional;
    int test_func(int i) {
        if(i > 1) return 1;
        return 0;
    }
    writeln(generate_fcnot(toDelegate(&test_func), 2, 1));
    */
}


/**
 * Generate the identity matrix
 */
Operator generate_identity(size_t n) {
    Operator op = create_operator(n);
    for(int i = 0; i < (1<<n); i++) {
        for(int j = 0; j < (1<<n); j++) {
            op.set(i, j, Complex!double(0, 0));
        }
    }
    for(int i = 0; i < (1<<n); i++) {
        op.set(i, i, Complex!double(1, 0));
    }
    return op;
}

/**
 * Generate the swap matrix
 */

Operator generate_swap() {
    Operator op = create_operator(1);
    op.set(0, 0, Complex!double(0, 0));
    op.set(0, 1, Complex!double(1, 0));
    op.set(1, 0, Complex!double(1, 0));
    op.set(1, 1, Complex!double(0, 0));
    return op;
}

/**
 * Generate the Y operator
 */

Operator generate_Y() {
    Operator op = create_operator(1);
    op.set(0, 0, Complex!double(0, 0));
    op.set(0, 1, Complex!double(0, -1));
    op.set(1, 0, Complex!double(0, 1));
    op.set(1, 1, Complex!double(0, 0));
    return op;
}

/**
 * Generate the Z operator
 */
Operator generate_Z() {
    Operator op = create_operator(1);
    op.set(0, 0, Complex!double(1, 0));
    op.set(0, 1, Complex!double(0, 0));
    op.set(1, 0, Complex!double(0, 0));
    op.set(1, 1, Complex!double(-1, 0));
    return op;
}

/**
 * Generate an instance of a fredkin operator
 */
Operator generate_fredkin() {
    Operator op = create_operator(3);
    for(int i = 0; i < op.dimension; i++) {
        for(int j = 0; j < op.dimension; j++) {
            op.set(i, j, Complex!double(0, 0));
        }
    }

    for(int i = 0; i < 5; i++) {
        op.set(i, i, Complex!double(1, 0));
    }
    op.set(5, 6, Complex!double(1, 0));
    op.set(6, 5, Complex!double(1, 0));
    op.set(7, 7, Complex!double(1, 0));
    return op;
}

/**
 * Generate an instance of the toffoli operator
 */
Operator generate_toffoli() {
    Operator op = create_operator(3);
    for(int i = 0; i < op.dimension; i++) {
        for(int j = 0; j < op.dimension; j++) {
            op.set(i, j, Complex!double(0, 0));
        }
    }

    for(int i = 0; i < 6; i++) {
        op.set(i, i, Complex!double(1, 0));
    }
    op.set(6, 7, Complex!double(1, 0));
    op.set(7, 6, Complex!double(1, 0));
    return op;
}

/**
 * Generate a rotation by a certain angle
 */
Operator generate_rotation(double theta) {
    Operator op = create_operator(1);
    op.set(0, 0, Complex!double(cos(theta), 0));
    op.set(0, 1, Complex!double(-sin(theta), 0));
    op.set(1, 0, Complex!double(sin(theta), 0));
    op.set(1, 1, Complex!double(cos(theta), 0));
    return op;
}


Operator[] ops_available = [null, generate_identity(1)
                           ,generate_hadamard(1)
                           ,generate_swap()
                           ,generate_Y()
                           ,generate_Z()
                           ,generate_fredkin()
                           ,generate_toffoli()
                           ,generate_rotation(PI/4)
                           ,generate_rotation(PI/8)
                           ,generate_rotation(PI/3)];
