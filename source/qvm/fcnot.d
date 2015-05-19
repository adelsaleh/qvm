module qvm.fcnot;


import vibe.d;
import std.bitmanip;

struct BBParams {
    size_t in_bits;
    size_t out_bits;
}

class FcnotWrapper {
    ushort port;
    string url;
    TCPConnection conn;
    this(string url, ushort port) {
        this.url = url;
        this.port = port;

        conn = connectTCP(url, port);
    }

    BBParams getParams(int index) {
        ubyte[] message = [cast(ubyte)0x01];
        message ~= nativeToLittleEndian(index);
        
        conn.write(message);
        conn.flush();
        ubyte[] arr = new ubyte[8];
        conn.read(arr);
        BBParams params;
        params.in_bits = littleEndianToNative!int(arr[0..4]);
        params.out_bits = littleEndianToNative!int(arr[4..8]);
        return params;
    }

    int fcnotNetworkHandler(int index, int input) {
        conn.write(cast(ubyte[])[0x02] ~ nativeToLittleEndian!int(index) ~ nativeToLittleEndian!int(input));
        ubyte[4] arr;
        conn.read(arr);
        return littleEndianToNative!(int)(arr);
    }
}

