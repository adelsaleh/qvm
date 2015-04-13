module qvm.exceptions;

class DuplicateQubitNameException : Exception {

    this (string message){
        super(message);
    }
}
