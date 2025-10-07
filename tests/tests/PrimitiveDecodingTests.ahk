#Requires AutoHotkey v2.0
#Include ../../MsgPack.ahk
#Include ../YUnit/Assert.ahk

/**
 * Super simple test harness for testing decoding. Will want to move to unit tests for
 * GitHub actions at some point
 */
class DecodingTester{

    /**
     * Takes a hex string, puts it in a Buffer, and decodes that using MsgPack.Decode.
     * If the decode value is not equal to "expected", throws an error
     * 
     * @param {String} hex hex to test decoding
     * @param {Primitive | Buffer} expected the expected value 
     */
    static Test(hex, expected) {
        buf := DecodingTester.BufferFrom(hex)

        result := MsgPack.Decode(buf, &off := 0)
        if (expected is Primitive && result != expected){
            msg := Format("Assertion failed: Expected {1} -> {2}, expected {3}", hex, String(result), String(expected))
            throw Error(msg)
        }
        else if(expected is Buffer){
            Assert.BuffersEqual(expected, result)
        }
    }

    /**
     * Encodes and writes a hex string to a buffer
     * @param {String} hex hex string to write 
     */
    static BufferFrom(hex) {
        buf := Buffer(StrSplit(hex, " ").Length)
        Loop Parse hex, " "
            NumPut("UChar", "0x" A_LoopField, buf, A_Index - 1)
        return buf
    }
}

class PrimitiveDecodingTests {
    ;------------------------------------------------------------
    ; NIL + BOOLEAN
    ;------------------------------------------------------------
    Nil(*) => DecodingTester.Test("C0", "")
    False(*) => DecodingTester.Test("C2", 0)
    True(*) => DecodingTester.Test("C3", 1)

    ;------------------------------------------------------------
    ; POSITIVE FIXINT (0x00–0x7F)
    ;------------------------------------------------------------
    PositiveFixInt0(*) => DecodingTester.Test("00", 0)
    PositiveFixInt42(*) => DecodingTester.Test("2A", 42)
    PositiveFixInt127(*) => DecodingTester.Test("7F", 127)

    ;------------------------------------------------------------
    ; NEGATIVE FIXINT (0xE0–0xFF)
    ;------------------------------------------------------------
    NegativeFixInt32(*) => DecodingTester.Test("E0", -32)
    NegativeFixInt1(*) => DecodingTester.Test("FF", -1)

    ;------------------------------------------------------------
    ; UINT TYPES
    ;------------------------------------------------------------
    Uint8(*) => DecodingTester.Test("CC FF", 255)
    Uint16(*) => DecodingTester.Test("CD 01 00", 256)
    Uint32(*) => DecodingTester.Test("CE 00 01 00 00", 65536)
    Uint64(*) => DecodingTester.Test("CF 00 00 00 00 00 00 01 00", 256)

    ;------------------------------------------------------------
    ; INT TYPES
    ;------------------------------------------------------------
    Int8(*) => DecodingTester.Test("D0 FF", -1)
    Int16(*) => DecodingTester.Test("D1 FF 7F", -129)
    Int32(*) => DecodingTester.Test("D2 FF FF FF 80", -128)
    Int64(*) => DecodingTester.Test("D3 FF FF FF FF FF FF FF 80", -128)

    ;------------------------------------------------------------
    ; FLOAT TYPES
    ;------------------------------------------------------------
    Float32Positive(*) => DecodingTester.Test("CA 3F 80 00 00", 1.0)
    Float32Negative(*) => DecodingTester.Test("CA C0 00 00 00", -2.0)
    Float64Positive(*) => DecodingTester.Test("CB 3F F0 00 00 00 00 00 00", 1.0)
    Float64Negative(*) => DecodingTester.Test("CB C0 00 00 00 00 00 00 00", -2.0)

    ;------------------------------------------------------------
    ; STRING TYPES
    ;------------------------------------------------------------
    String8(*) => DecodingTester.Test("D9 03 41 42 43", "ABC")
    String16(*) => DecodingTester.Test("DA 00 03 41 42 43", "ABC")
    String32(*) => DecodingTester.Test("DB 00 00 00 03 41 42 43", "ABC")

    ;------------------------------------------------------------
    ; FIXSTR (0xA0–0xBF, length = lower 5 bits)
    ;------------------------------------------------------------
    FixStrEmpty(*) => DecodingTester.Test("A0", "")
    FixStrShort(*) => DecodingTester.Test("A1 41", "A")
    FixStr3Chars(*) => DecodingTester.Test("A3 41 42 43", "ABC")

    ;------------------------------------------------------------
    ; BIN TYPES
    ;------------------------------------------------------------
    Binary8(*) => DecodingTester.Test("C4 03 41 42 43", DecodingTester.BufferFrom("41 42 43"))
    Binary16(*) => DecodingTester.Test("C5 00 03 41 42 43", DecodingTester.BufferFrom("41 42 43"))
    Binary32(*) => DecodingTester.Test("C6 00 00 00 03 41 42 43", DecodingTester.BufferFrom("41 42 43"))
}