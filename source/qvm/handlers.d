module qvm.handlers;

import std.stdio;
import std.container.array;

import qlib.collections;
import qlib.instruction;
import qvm.state;
import qvm.operators;

/**
 * Provides an abstraction for scope in
 * different functions.
 */
struct ScopeManager {
    private int[int] qubitMapping;
    private Stack!(Array!int) scopes;
    private Array!int current;

    /**
     * Go down a level in the scope,
     * happens when entering a function.
     */
    void down() {
        scopes.push(current);
        current = Array!int();
    }
    /**
     * Go up a level in the scope,
     * happens when exiting a function.
     */
    void up() {
        foreach(int i; current) {
            qubitMapping.remove(i);
        }
        current = scopes.pop();
    }

    /**
     * Add a qubit to the current scope.
     */
    bool insertQubit(int qubit, int qdesc) {
        if(qubit !in qubitMapping) {
            qubitMapping[qubit] = qdesc;
            return true;
        }
        return false;
    }

    /**
     * Get the descriptor of the qubit
     * in the current scope.
     */
    int qubitDesc(int qubit) {
        return qubitMapping[qubit];
    }


    /**
     * Checks whether whether we're at the
     * top level stack or not.
     */
    bool atTop() {
        return scopes.size == 0L;
    }
}

struct ProgramState {
    Program p;
    State s;
    CollapsingQueue!int q;
    ScopeManager sc;
    

    /**
     * Implements the null instruction.
     * TODO: Implement a function in Program for this check
     */
    void nullHandler() {
        if(sc.atTop) {
            sc.up();
        }else{
            p.terminate();
        }
    }
    // The next three handlers can probably be reduced to on/apply sequences
    // so will leave empty stubs for now.
    void ifHandler() {
        
    }

    void ifelseHandler() {

    }

    void loopHandler() {
        
    }
     /**
     * Implementation of the qubit instruction.
     * Adds a new qubit to the state.
     */
    void qubitHandler() {
      //  int desc = s.insertQubit(p.front.qubit);
      //  sc.insertQubit(p.front.qubit, desc);
    }

    /**
     * Implementation of the measure instruction.
     * Measures the specified qubit and prints it to the console.
     */
    void measureHandler() {
        int desc = sc.qubitDesc(p.front.qubit);
        s.measure(0);
    }

    /**
     * Implementation of the on instruction.
     * Marks a qubit as an argument for a later instruction.
     */
    void onHandler() {
        int desc = sc.qubitDesc(p.front.qubit);
        q.enqueue(desc);
    }


    /**
     * Implementation of the apply instruction.
     * Apply the operator specified on the qubits previously
     * marked with on.
     *
     * TODO: Improve error reporting.
     */
    void applyHandler() {

    }

    /**
     * Implementation of the load instruction.
     * Loads a qubit from the collapsing queue.
     */
    void loadHandler() {
        int qdesc = q.dequeue();
        if(!sc.insertQubit(p.front.qubit, qdesc)) {
            throw new Exception("Qubit declared twice in current scope");
        }
    }
    /**
     * Dump the raw quantum state into stdout.
     * TODO: Allow a log file
     */
    void dumpHandler() {
        writeln(s.dump);
    }
    
    void printHandler() {
    }

    /*
     * *REC instructions need a bit more investigation
     * regarding what they should mean. At this point
     * this is rather unclear.
     */

    void srecHandler() {}
    void erecHandler() {}
    void qsrecHandler() {}
    void qerecHandler() {}

    // Not sure what this one means either
    void fcnotHandler() {}
}


