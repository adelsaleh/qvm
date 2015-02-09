import std.stdio;
import std.getopt;
import qlib.collections;
import qlib.instruction;
import qvm.handlers;


/**
 * Load a program from a file and execute it.
 *
 * Params:
 *      path = Path of a qbin file to execute.
 */
void executeProgram(string path) {
    Program p = new Program();
    p.loadFromFile(path);
    foreach(Instruction ins; p) {
        handlers[ins.opcode].execute(p, ins);
    }
}

void main(string[] args) {
    executeProgram(args[1]);
}
