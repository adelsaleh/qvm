import std.stdio;
import std.getopt;
import qlib.collections;
import qlib.instruction;
import qlib.asm_tokens;
import qvm.handlers;
import qvm.state;


/**
 * Load a program from a file and execute it.
 *
 * Params:
 *      path = Path of a qbin file to execute.
 */
void executeProgram(string path) {
    Program p = new Program();
    p.loadFromFile(path);
    ProgramState ps;
    ps.p = p;
    ps.s = new State();
    foreach(Instruction ins; p) {
        switch(ins.opcode) {
            case Opcode.NULL:
                ps.nullHandler(); break;
            case Opcode.QUBIT:
                ps.qubitHandler(); break;
            case Opcode.IF:
                ps.ifHandler(); break;
            case Opcode.IFELSE:
                ps.ifelseHandler(); break;
            case Opcode.MEASURE:
                ps.measureHandler(); break;
            case Opcode.LOOP:
                ps.loopHandler(); break;
            case Opcode.DUMP:
                ps.nullHandler(); break;
            case Opcode.SREC:
                ps.srecHandler(); break;
            case Opcode.EREC:
                ps.erecHandler(); break;
            case Opcode.QSREC:
                ps.qsrecHandler(); break;
            case Opcode.QEREC:
                ps.qerecHandler(); break;
            case Opcode.PRINT:
                ps.printHandler(); break;
            case Opcode.FCNOT:
                ps.fcnotHandler(); break;
            default:
                throw new Exception("Invalid qbin file");
        }
    }
}

void main(string[] args) {
    executeProgram(args[1]);
}
