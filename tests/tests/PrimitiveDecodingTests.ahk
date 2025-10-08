#Requires AutoHotkey v2.0
#Include ../../MsgPack.ahk
#Include ../YUnit/Assert.ahk

/**
 * Super simple test harness for testing decoding. Will want to move to unit tests for
 * GitHub actions at some point
 * 
 * @see https://github.com/kawanet/msgpack-test-suite/
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

        result := MsgPack.Decode(buf)
        if (expected is Primitive && result != expected){
            msg := Format("Decode {1} as {2}, expected {3}", hex, String(result), String(expected))
            throw Error(msg)
        }
        else if(expected is Buffer){
            Assert.IsType(result, Buffer)
            Assert.BuffersEqual(result, expected)
        }
        else if(expected is Array){
            Assert.IsType(result, Array)
            Assert.ArraysEqual(result, expected)
        }
        else if(expected is Map){
            Assert.IsType(result, Map)
            Assert.MapsEqual(result, expected)
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

    StringEmpty(){
        DecodingTester.Test("c4 00", "")
        DecodingTester.Test("c5 00 00", "")
        DecodingTester.Test("c6 00 00 00 00", "")
    }

    StringEmoji(){
        ;Requires UTF-8 (the default)
        DecodingTester.Test("a4 f0 9f 8d ba", "🍺")
        DecodingTester.Test("d9 04 f0 9f 8d ba", "🍺")
    }

    StringNonEnglish(){
        ;Requires UTF-8 (the default)
        DecodingTester.Test("ac e3 81 b2 e3 82 89 e3 81 8c e3 81 aa", "ひらがな")
        DecodingTester.Test("d9 0c e3 81 b2 e3 82 89 e3 81 8c e3 81 aa", "ひらがな")

        DecodingTester.Test("b2 d0 9a d0 b8 d1 80 d0 b8 d0 bb d0 bb d0 b8 d1 86 d0 b0", "Кириллица")
        DecodingTester.Test("d9 12 d0 9a d0 b8 d1 80 d0 b8 d0 bb d0 bb d0 b8 d1 86 d0 b0", "Кириллица")
    }

    StringLong(){
        expected := "1234567890123456789012345678901"   ;Okay, not _that_ long...

        DecodingTester.Test("bf 31 32 33 34 35 36 37 38 39 30 31 32 33 34 35 36 37 38 39 30 31 32 33 34 35 36 37 38 39 30 31", expected)
        DecodingTester.Test("d9 1f 31 32 33 34 35 36 37 38 39 30 31 32 33 34 35 36 37 38 39 30 31 32 33 34 35 36 37 38 39 30 31", expected)
        DecodingTester.Test("da 00 1f 31 32 33 34 35 36 37 38 39 30 31 32 33 34 35 36 37 38 39 30 31 32 33 34 35 36 37 38 39 30 31", expected)        
    }
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

    ;------------------------------------------------------------
    ; MAPS
    ;------------------------------------------------------------
    MapEmpty(){
        DecodingTester.Test("80", Map())
        DecodingTester.Test("de 00 00", Map())
        DecodingTester.Test("df 00 00 00 00", Map())
    }

    MapStringInt(){
        DecodingTester.Test("81 A1 61 01", Map("a", 1)) 
        DecodingTester.Test("DE 00 01 A1 61 01", Map("a", 1))
        DecodingTester.Test("DF 00 00 00 01 A1 61 01", Map("a", 1))
    }

    MapStringString(){
        DecodingTester.Test("81 A1 61 A1 41", Map("a", "A"))
        DecodingTester.Test("DE 00 01 A1 61 A1 41", Map("a", "A"))
        DecodingTester.Test("DF 00 00 00 01 A1 61 A1 41", Map("a", "A"))
    }

    ;------------------------------------------------------------
    ; ARRAYS
    ;------------------------------------------------------------
    ArrayEmpty(){
        DecodingTester.Test("90", [])
        DecodingTester.Test("DC 00 00", [])
        DecodingTester.Test("DD 00 00 00 00", [])
    }

    Array1(){
        DecodingTester.Test("91 01", [1])
        DecodingTester.Test("DC 00 01 01", [1])
        DecodingTester.Test("DD 00 00 00 01 01", [1])
    }

    Array15(){
        expected := [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]
        
        DecodingTester.Test("9f 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f", expected)
        DecodingTester.Test("dc 00 0f 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f", expected)
        DecodingTester.Test("dd 00 00 00 0f 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f", expected)
    }

    Array16(){
        expected := [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16]

        DecodingTester.Test("dc 00 10 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f 10", expected)
        DecodingTester.Test("dd 00 00 00 10 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f 10", expected)
    }

    ArrayString(){
        DecodingTester.Test("91 a1 61", ["a"])
        DecodingTester.Test("dc 00 01 a1 61", ["a"])
        DecodingTester.Test("dd 00 00 00 01 a1 61", ["a"])
    }

    ;------------------------------------------------------------
    ; NESTING
    ;------------------------------------------------------------
    ArrayOfArrays(){
        DecodingTester.Test("91 90", [[]])
        DecodingTester.Test("dc 00 01 dc 00 00", [[]])
        DecodingTester.Test("dd 00 00 00 01 dd 00 00 00 00", [[]])
    }

    ArrayOfMaps(){
        DecodingTester.Test("91 80", [Map()])
        DecodingTester.Test("dc 00 01 80", [Map()])
        DecodingTester.Test("dd 00 00 00 01 80", [Map()])
    }

    MapOfMaps(){
        DecodingTester.Test("81 a1 61 80", Map("a", Map()))
        DecodingTester.Test("de 00 01 a1 61 de 00 00", Map("a", Map()))
        DecodingTester.Test("df 00 00 00 01 a1 61 df 00 00 00 00", Map("a", Map()))
    }

    MapOfArrays(){
        DecodingTester.Test("81 a1 61 90", Map("a", []))
        DecodingTester.Test("de 00 01 a1 61 90", Map("a", []))
        DecodingTester.Test("df 00 00 00 01 a1 61 90", Map("a", []))
    }
}