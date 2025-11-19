#Requires AutoHotkey v2.0
#Include ../../MsgPack.ahk
#Include ../YUnit/Assert.ahk

class EncodingTester{

    /**
     * Takes a value and encodes it to a Buffer via MsgPack.EncodeToBuffer.
     * If the encoded buffer does not match the expected buffer, throws an error
     * 
     * @param {Number | String | Buffer} test the value to encode
     * @param {String} expected the expected value in hex
     */
    static Test(test?, expected := "???") {
        if(!(expected is Buffer))
            expected := EncodingTester.BufferFrom(expected)

        result := MsgPack.EncodeToBuffer(test?)

        Assert.IsType(result, Buffer)
        Assert.BuffersEqual(expected, result)
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

class PrimitiveEncodingTests {

    ;------------------------------------------------------------
    ; NIL + BOOLEAN
    ;------------------------------------------------------------
    NilUnset(*) => EncodingTester.Test(, "C0")   ; Unset value
    NilObject(*) => EncodingTester.Test(MsgPack.Nil(), "C0")   ; Unset value

    False(*) => EncodingTester.Test(MsgPack.BFalse(), "C2")
    True(*) => EncodingTester.Test(MsgPack.BTrue(), "C3")

    ;------------------------------------------------------------
    ; POSITIVE FIXINT (0x00–0x7F)
    ;------------------------------------------------------------
    PositiveFixInt0(*) => EncodingTester.Test(0, "00")
    PositiveFixInt42(*) => EncodingTester.Test(42, "2A")
    PositiveFixInt127(*) => EncodingTester.Test(127, "7F")

    ;------------------------------------------------------------
    ; NEGATIVE FIXINT (0xE0–0xFF)
    ;------------------------------------------------------------
    NegativeFixIntMinus1(*)   => EncodingTester.Test(-1,  "FF")
    NegativeFixIntMinus32(*)  => EncodingTester.Test(-32, "E0")

    ;------------------------------------------------------------
    ; INT16
    ;------------------------------------------------------------
    Int16Pos(*) => EncodingTester.Test(256, "CD 01 00")
    Int16Neg(*) => EncodingTester.Test(-129, "D1 FF 7F") ; -129 = 0xFF7F

    ;------------------------------------------------------------
    ; INT32
    ;------------------------------------------------------------
    Int32Pos(*) => EncodingTester.Test(65536, "CE 00 01 00 00")
    Int32Neg(*) => EncodingTester.Test(-32769, "D2 FF FF 7F FF")

    ;------------------------------------------------------------
    ; INT64
    ;------------------------------------------------------------
    Int64Pos(*) => EncodingTester.Test(0x100000000, "CF 00 00 00 01 00 00 00 00")
    Int64Neg(*) => EncodingTester.Test(-0x100000000, "D3 FF FF FF FF 00 00 00 00")

    FixStrEmpty(*) => EncodingTester.Test("", "A0")
    FixStr1(*) => EncodingTester.Test("A", "A1 41")
    FixStr31(*) {
        s := "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
        hex := "BF "
        Loop(31) {
            hex .= Format("{1:02X}", Ord("A"))
            if(A_Index < 31){
                hex .= " "
            }
        }
        
        EncodingTester.Test(s, hex)
    }

    ;------------------------------------------------------------
    ; FLOAT TYPES
    ;------------------------------------------------------------
    Float32Positive(*){
        MsgPack.CompactFloats := true
        EncodingTester.Test(1.0, "CA 3F 80 00 00")
    }
    Float32Negative(*){
        MsgPack.CompactFloats := true
        EncodingTester.Test(-2.0, "CA C0 00 00 00")
    }

    Float64_Zero(*){
        MsgPack.CompactFloats := false
        EncodingTester.Test(0.0, "CB 00 00 00 00 00 00 00 00")
    } 
    Float64_One(*){
        MsgPack.CompactFloats := false
        EncodingTester.Test(1.0, "CB 3F F0 00 00 00 00 00 00")
    } 
    Float64_Pi(*){
        MsgPack.CompactFloats := false
        EncodingTester.Test(3.141592653589793, "CB 40 09 21 FB 54 44 2D 18")
    }

    ;------------------------------------------------------------
    ; STRING TYPES
    ;------------------------------------------------------------
    String8(*){
        test := ""
        Loop(250){
            test .= "A"
        }

        expected := "D9 FA "
        Loop(250){
            expected .= "41"
            if(A_Index < 250)
                expected .= " "
        }

        EncodingTester.Test(test, expected)
    }

    ;------------------------------------------------------------
    ; BINARY DATA
    ;------------------------------------------------------------
    Bin8(*) {
        buf := Buffer(3, 0x11)
        EncodingTester.Test(buf, "C4 03 11 11 11")
    }

    Bin16(*) {
        buf := Buffer(300, 0x22)
        hex := "C5 01 2C "
        Loop(300){
            hex .= "22"
            if(A_Index < 300)
                hex .= " "
        }
        EncodingTester.Test(buf, hex)
    }

    ;------------------------------------------------------------
    ; ARRAYS
    ;------------------------------------------------------------
    ArrayFixInt(*) {
        arr := [0, 0, 0]
        EncodingTester.Test(arr, "93 00 00 00")
    }

    ArrayFixStr(*) {
        arr := ["A", "A", "A"]
        EncodingTester.Test(arr, "93 A1 41 A1 41 A1 41")
    }

    ArrayEmpty(*) {
        arr := []
        EncodingTester.Test(arr, "90")
    }

    ArrayNested(*) {
        arr := [
            ["A", "A", "A"],
            [0, 0, 0],
            ["B", "B", "B"]
        ]
        EncodingTester.Test(arr, "93 93 A1 41 A1 41 A1 41 93 00 00 00 93 A1 42 A1 42 A1 42")
    }
}