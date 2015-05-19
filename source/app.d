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
	QProgram p = new QProgram();
	p.loadFromFile(path);
	Environment env = new Environment(p);	
	env.execute();
}

void main(string[] args) {
    executeProgram(args[1]);
}
