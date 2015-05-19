module qvm.handlers;

import std.stdio;
import std.container.array;
import std.conv;

import qlib.collections;
import qlib.instruction;
import qvm.state;
import qvm.operators;
import qvm.exceptions;

class FunctionPointerNode {
    FunctionPointerNode[] children;
    FunctionPointer fp;
    Operator operator;
    size_t depth;
    size_t expected_qubits;
    bool reachedEnd;
    this(FunctionPointer fp, size_t depth, size_t expected) {
        this.fp = fp;
        this.children = [];
        this.depth = depth;
        operator = null;
        expected_qubits = expected;
        reachedEnd = fp.current.instructions.length == 0;
    }

    Instruction currentInstruction() {
        import qlib.asm_tokens;
        if(fp.current.instructions.length > 0) 
            return fp.current.instructions[fp.instruction];
        else
            return Instruction(Opcode.NULL, 0, 0, 0, 0);
    }

    void toNext() {
        fp.instruction ++;
        if(fp.instruction == fp.current.instructions.length) {
            fp.instruction--;
            reachedEnd = true;
        }
    }

    bool ended() {
        return reachedEnd;
    }
}

class FunctionPointerTree {
    FunctionPointerNode root;
    size_t leaves;

    this(FunctionPointer fp) {
        root = new FunctionPointerNode(fp, 0, 0);
        leaves = 1;
    }

    FunctionPointerNode getLeaf(size_t index, FunctionPointerNode node) {
        if(node.children) {
            for(int i = 0; i < node.children.length; i++) {
                auto res = getLeaf(index, node.children[i]);
                if(res) return res;
                else index--;
            }
            return null;
        }else{
            if(index == 0) {
                return node;
            } else {
                return null;
            }
        }
        assert(0);
    }

    bool terminated(FunctionPointerNode node) {
        bool term = node.reachedEnd;
        for(int i = 0; i < node.children.length; i++) {
            term = terminated(node.children[i]) && term;
        }
        return term;
    }

    bool terminated() {
        return terminated(root);
    }

    bool ready() {
        bool r = true;
        for(int i = 0; i < leaves; i++) {
            if(getLeaf(i).operator is null) {
                r = false;
                break;
            }
        }
        return r;
    }

    Operator constructOperator(FunctionPointerNode node) {
        if(node.children.length == 0) {
            Operator ret = node.operator.dup();
            if(node.expected_qubits - ret.qubits > 0) { 
                ret = ret.tensor(generate_identity(node.expected_qubits-ret.qubits));
            }
            node.operator = null;
            node.fp.queue.collapse();
            return ret;
        }
        if(node.children.length == 1) {
            Operator ret = constructOperator(node.children[0]);
            node.operator = null;
            node.fp.queue.collapse();
            return ret;
        }
        if(node.children.length == 2) {
            Operator op1 = constructOperator(node.children[0]);
            Operator op2 = constructOperator(node.children[1]);
            Operator ret = generate_ifelse(op1, op2);
            writeln("out qubits: ", ret.qubits);
            ret = ret.tensor(generate_identity(node.expected_qubits-ret.qubits));
            node.operator = null;
            node.fp.queue.collapse();
            return ret;
        }
        assert(0);
    }

    Operator constructOperator(size_t qubits) {
        size_t original = root.expected_qubits;
        root.expected_qubits = qubits;
        Operator op = constructOperator(root);
        root.expected_qubits = original;
        return op;
    }

    void createBranch(int index, FunctionPointer[] fps, size_t expected) {
        auto leaf = getLeaf(index);
        if(leaf) {
            leaf.children = new FunctionPointerNode[fps.length];
            for(int i = 0; i < leaf.children.length; i++) {
                leaf.children[i] = new FunctionPointerNode(fps[i], leaf.depth + 1, expected);
            }
            leaves += leaf.children.length-1;
        }else{
            throw new Exception("Index out of bounds");
        }
    }

    void createBranch(FunctionPointerNode node, FunctionPointer[] fps, size_t expected) {
        node.children = new FunctionPointerNode[fps.length];
        for(int i = 0; i < node.children.length; i++) {
            node.children[i] = new FunctionPointerNode(fps[i], node.depth + 1, expected);
        }
        leaves += node.children.length-1;
    }

    string toString(FunctionPointerNode node, string spaces) {
        string ret = "";
        string n = "";
        if(node.operator is null) {
            n = "*";
        }
        size_t ins = node.fp.instruction;
        size_t len = node.fp.current.instructions.length;
        
        ret~= spaces ~ "Function: " ~to!string(node.depth)~" "~to!string(ins)~":"~to!string(len)~":"~to!string(node.reachedEnd)~n~"\n";
        for(int i = 0; i < node.children.length; i++) {
            ret ~= toString(node.children[i], spaces~"   ");
        }
        return ret;
    }

    override
    string toString() {
        return toString(root, "");
    }

    FunctionPointerNode getLeaf(size_t index) {
        if(!root.children && index > 0) {
            throw new Exception("Index out of bounds");
        }
        
        if(root.children.length == 0 && index == 0) {  
            return root;
        }
        return getLeaf(index, root);
    }

    bool prune(FunctionPointerNode node) {
        // If has no children, skip
        // If has children, check if all of them ended
        // If so, remove children
        if(node.children.length == 0) {return node.ended;}
        bool del = true;
        for(int i = 0; i < node.children.length; i++) {
            del &= prune(node.children[i]);
        }
        if(del) {
            leaves -= node.children.length;
            leaves ++;
            node.children = [];
        }
        return del;
    }

    void prune() {
        writeln(this);
        prune(root);
    }
}

unittest {
    writeln("Testing FUNCTIONPOINTERTREE");
    auto t = new FunctionPointerTree(FunctionPointer(Function(), 0));
    t.createBranch(0, [FunctionPointer(Function(), 3), FunctionPointer(Function(), 0)], 3);
    t.createBranch(1, [FunctionPointer(Function(), 3), FunctionPointer(Function(), 0)], 3);

    t = new FunctionPointerTree(FunctionPointer(Function(), 0));
    t.createBranch(0, [FunctionPointer(Function(), 3), FunctionPointer(Function(), 0)], 3);
    t.createBranch(0, [FunctionPointer(Function(), 3), FunctionPointer(Function(), 0)], 2);
    t.root.expected_qubits = 4;
    t.root.children[0].children[0].operator = generate_hadamard(2);
    t.root.children[0].children[1].operator = generate_hadamard(2);
    t.root.children[1].operator = generate_hadamard(2);
}

class Environment {
    FunctionPointerTree tree;
    QProgram p;
    State s;
    bool running;
    
    this() {
        tree = new FunctionPointerTree(FunctionPointer());
        s = new State();
    }   

    this(QProgram p) {
        tree = new FunctionPointerTree(FunctionPointer(p.getMain(), 0, new CollapsingQueue!size_t()));
        this.p = p;
        s = new State();
        running = true;
        qubit_counter = 0;
    }

    void execute() {
        while(!tree.terminated) {
            bool b = false;
            size_t depth = tree.getLeaf(0).depth;
            for(int i = 0; i < tree.leaves; i++) {
                auto node = tree.getLeaf(i);
                assert(node.depth == depth);
                while(node.operator is null && !node.ended && node.children.length == 0) {
                
                    auto ins = node.currentInstruction;
                    handlers[ins.opcode](node, this);
                    node.toNext();
                }
                if(node.children.length > 0) {
                    i = -1;
                    depth += 1;
                }
                if(node.depth != 0 && node.ended && node.operator is null) {
                    node.operator = generate_identity(1);
                }
            }
            if(tree.ready()) {
                
                auto queue = new CollapsingQueue!size_t(tree.root.fp.queue);
                Operator op = tree.constructOperator(queue.size);
                string[] qubits = new string[queue.size];
                for(int i = 0; i < qubits.length; i++) {
                    qubits[i] = to!string(queue.dequeue);
                }
                s.applyOperator(op, qubits);
                tree.prune();
            }
        }
    }

    unittest {
        writeln("TESTING BEGINS HERE");
        QProgram p = new QProgram();
        p.loadFromFile("../test-programs/test_measure.qbin");
        Environment env = new Environment(p);
        env.execute();
        writeln(env.tree);
        writeln(env.s.dump);
        writeln("DONE");
    }

    size_t[size_t] qubit_mapping;
    size_t qubit_counter;

    void addQubit(size_t qubit_id) {
        if(qubit_id in qubit_mapping) {
            throw new Exception("Qubit already exists");
        }
        qubit_mapping[qubit_id] = qubit_id;
        qubit_counter ++;
        tree.root.expected_qubits = qubit_counter;
        s.insertQubit(to!string(qubit_mapping[qubit_id]));

    }

    unittest {
        writeln("Testing ENVIRONMENT");
        Environment env = new Environment();
        writeln(env);
        env.addQubit(3);
        writeln(env);
    }

    void mapQubit(size_t qubit_id, size_t qubit_index) {
        qubit_mapping[qubit_id] = qubit_index;
    }

    CollapsingQueue!size_t queue;

    void branchSingle(FunctionPointerNode node, size_t operator) {
        tree.createBranch(node, [getFp(node, operator)], node.fp.queue.size);
    }

    unittest {
        writeln("Testing BranchSingle in environment");
        Environment env = new Environment();
        
    }

    FunctionPointer getFp(FunctionPointerNode node,size_t op) {
        if(op >= ops_available.length) {
            FunctionPointer fp;
            fp.queue = new CollapsingQueue!size_t(node.fp.queue);
            fp.current = p.functions[cast(int)op];
            return fp;
        }else{
            return FunctionPointer(Function(), 0, new CollapsingQueue!size_t(node.fp.queue));
        }
    }


    void branchDouble(FunctionPointerNode node, size_t op1, size_t op2) {
        writeln("IF OP: ", op2);
        auto arr = [getFp(node, op1), getFp(node, op2)];
        tree.createBranch(node, arr, node.fp.queue.size); 

        if(op1 < ops_available.length) {
            node.children[0].operator = ops_available[op1].dup();
        }
        if(op2 < ops_available.length) {
            node.children[1].operator = ops_available[op2].dup();
        }
    }

}

bool function(FunctionPointerNode, Environment)[] handlers = [
    &processNull,
    &processQubit,
    &processIf,
    &processIfElse,
    &processMeasure,
    &processLoop,
    &processOn,
    &processApply,
    &processLoad];

bool processNull(FunctionPointerNode node, Environment env) {
    if(node.depth == 0) {
        return false;
    }
    if(node.operator is null) {
        node.operator = generate_identity(node.expected_qubits);
    }
    return true;
}

bool processQubit(FunctionPointerNode node, Environment env) {
    auto ins = node.currentInstruction;
    if(node.depth != 0) {
        throw new Exception("Cannot create qubits inside a branch!");
    }
    env.addQubit(ins.qubit);
    return true;
}

bool processOn(FunctionPointerNode node, Environment env) {
    if(node.currentInstruction.qubit !in env.qubit_mapping) {
        throw new Exception("You need to declare a qubit before you can use it");
    }
    node.fp.queue.enqueue(env.qubit_mapping[node.currentInstruction.qubit]);
    return true;
}

bool processApply(FunctionPointerNode node, Environment env) {
    writeln("APPLY CALLED");
    size_t operator = node.currentInstruction.op1;
    if(operator < ops_available.length) {
        node.operator = ops_available[operator];
        assert(node.fp.queue.size == node.operator.qubits);
    }else{
        env.branchSingle(node, node.currentInstruction.op1);
    }
    return true;
}

bool processIf(FunctionPointerNode node, Environment env) {
    size_t operator = node.currentInstruction.op1;
    if(operator < ops_available.length) {
        node.operator = generate_ifelse( generate_identity(env.queue.size), ops_available[operator]);
    }else{
        env.branchDouble(node, 1, operator);
    }
    node.fp.queue.enqueue(node.currentInstruction.qubit);
    return true;
}

bool processIfElse(FunctionPointerNode node, Environment env) {
    size_t op1 = node.currentInstruction.op1;
    size_t op2 = node.currentInstruction.op2;

    if(op1 < ops_available.length && op2 < ops_available.length) {
        node.operator = generate_ifelse(ops_available[op2], ops_available[op2]);
    }else { 
        env.branchDouble(node, op1, op2);
    }
    node.fp.queue.enqueue(node.currentInstruction.qubit);
    return true;
}

bool processMeasure(FunctionPointerNode node, Environment env) {
    if(node.depth > 0) {
        throw new Exception("Cannot perform measurement inside a conditional");
    }
    auto ins = node.currentInstruction;
    writeln("MEASURED=", env.s.measure(to!string(env.qubit_mapping[ins.qubit])));
    return true;
}

bool processLoop(FunctionPointerNode node, Environment env) {
    return true;
}

bool processLoad(FunctionPointerNode node, Environment env) {
    size_t index = node.fp.queue.dequeue();
    env.mapQubit(node.currentInstruction.qubit, index);
    return true;
}

