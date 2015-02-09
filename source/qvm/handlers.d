module qvm.handlers;

import std.stdio;

import qlib.collections;
import qlib.instruction;
import qvm.state;

/**
 * An interface that implements a handler for a specific set
 * of instructions, typically instructions with a specific
 * opcode e.g. QubitHandler, OnHandler
 */
interface InstructionHandler {
    /**
     * Execute the provided instruction.
     */
    void execute(Program p, State s, Instruction ins);
}


InstructionHandler[] handlers = [];

/**
 * Implementation of the qubit instruction.
 * Adds a new qubit to the state.
 */
void qubitHandler(Program p, State s, Instruction ins) {
    s.addQubit(ins.qubit);
}

/**
 * Implementation of the measure instruction.
 * Measures the specified qubit and prints it to the console.
 */
void measureHandler(Program p, State s, Instruction ins) {
    write(s.measure(ins.qubit));
}
//TODO: Add a CollapsingQueue to qlib.Program

/**
 * Implementation of the on instruction.
 * Marks a qubit as an argument for a later instruction.
 */
void onHandler(Program p, State s, Instruction ins) {

}


/**
 * Implementation of the apply instruction.
 * Apply the operator specified on the qubits previously
 * marked with on.
 */
void applyHandler(Program p, State s, Instruction ins) {

}

/**
 * Implementation of the apply `
 */
