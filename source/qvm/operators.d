module qvm.operators;

struct Matrix{}
struct Operator {
    int argNum;
    Matrix mat;
}

Operator[] opsAvailable;
