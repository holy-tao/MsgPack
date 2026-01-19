#Requires AutoHotkey v2.0
#Include ../../MsgPack.ahk
#Include ../YUnit/Assert.ahk

;@ahkunit-ignore
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

    class Nils {
        NilUnset() => EncodingTester.Test(, "C0")   ; Unset value
        NilObject() => EncodingTester.Test(MsgPack.Nil(), "C0")   ; Unset value
    }

    class Booleans {
        False() => EncodingTester.Test(MsgPack.BFalse(), "C2")
        True() => EncodingTester.Test(MsgPack.BTrue(), "C3")
    }

    class Ints {
        class FixInt {
            PositiveFixInt0() => EncodingTester.Test(0, "00")
            PositiveFixInt42() => EncodingTester.Test(42, "2A")
            PositiveFixInt127() => EncodingTester.Test(127, "7F")

            NegativeFixIntMinus1()   => EncodingTester.Test(-1,  "FF")
            NegativeFixIntMinus32()  => EncodingTester.Test(-32, "E0")
        }

        class Int16 {
            Int16Pos() => EncodingTester.Test(256, "CD 01 00")
            Int16Neg() => EncodingTester.Test(-129, "D1 FF 7F") ; -129 = 0xFF7F
        }

        class Int32 {
            Int32Pos() => EncodingTester.Test(65536, "CE 00 01 00 00")
            Int32Neg() => EncodingTester.Test(-32769, "D2 FF FF 7F FF")
        }

        class Int64 {
            Int64Pos() => EncodingTester.Test(0x100000000, "CF 00 00 00 01 00 00 00 00")
            Int64Neg() => EncodingTester.Test(-0x100000000, "D3 FF FF FF FF 00 00 00 00")
        }
    }

    class Strings {
        class FixStr {
            FixStrEmpty() => EncodingTester.Test("", "A0")
            FixStr1() => EncodingTester.Test("A", "A1 41")
            FixStr31() {
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
        }

        String8() {
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

        StringNonEnglish1() => EncodingTester.Test("ひらがな", "ac e3 81 b2 e3 82 89 e3 81 8c e3 81 aa")
        StringNonEnglish2() => EncodingTester.Test("Кириллица", "b2 d0 9a d0 b8 d1 80 d0 b8 d0 bb d0 bb d0 b8 d1 86 d0 b0")
        StringEmoji() => EncodingTester.Test("🍺", "a4 f0 9f 8d ba")
    }

    class Floats {
        Float32Positive(){
            MsgPack.CompactFloats := true
            EncodingTester.Test(1.0, "CA 3F 80 00 00")
        }
        Float32Negative(){
            MsgPack.CompactFloats := true
            EncodingTester.Test(-2.0, "CA C0 00 00 00")
        }

        Float64_Zero(){
            MsgPack.CompactFloats := false
            EncodingTester.Test(0.0, "CB 00 00 00 00 00 00 00 00")
        } 
        Float64_One(){
            MsgPack.CompactFloats := false
            EncodingTester.Test(1.0, "CB 3F F0 00 00 00 00 00 00")
        } 
        Float64_Pi(){
            MsgPack.CompactFloats := false
            EncodingTester.Test(3.141592653589793, "CB 40 09 21 FB 54 44 2D 18")
        }
    }
    
    class BinaryData {
        Bin8() {
            buf := Buffer(3, 0x11)
            EncodingTester.Test(buf, "C4 03 11 11 11")
        }

        Bin16() {
            buf := Buffer(300, 0x22)
            hex := "C5 01 2C "
            Loop(300){
                hex .= "22"
                if(A_Index < 300)
                    hex .= " "
            }
            EncodingTester.Test(buf, hex)
        }
    }

    ;------------------------------------------------------------
    ; ARRAYS
    ;------------------------------------------------------------
    class Collections {
        class Arrays {
            ArrayFixInt() {
            arr := [0, 0, 0]
            EncodingTester.Test(arr, "93 00 00 00")
            }

            ArrayFixStr() {
                arr := ["A", "A", "A"]
                EncodingTester.Test(arr, "93 A1 41 A1 41 A1 41")
            }

            ArrayEmpty() {
                arr := []
                EncodingTester.Test(arr, "90")
            }

            ArrayNested() {
                arr := [
                    ["A", "A", "A"],
                    [0, 0, 0],
                    ["B", "B", "B"]
                ]
                EncodingTester.Test(arr, "93 93 A1 41 A1 41 A1 41 93 00 00 00 93 A1 42 A1 42 A1 42")
            }
        }

        class Maps {
            MapFixIntSimple() {
                test := Map(0, 1)
                EncodingTester.Test(test, "81 00 01")
            }

            MapEmpty() {
                test := Map()
                EncodingTester.Test(test, "80")
            }

            MapFixStr() {
                test := Map(1, "A", 2, "B", 3, "C")
                EncodingTester.Test(test, "83 01 A1 41 02 A1 42 03 A1 43")
            }

            MapNested() {
                test := Map(
                    Map(1, "A"), Map(2, "B")
                )
                EncodingTester.Test(test, "81 81 01 A1 41 81 02 A1 42")
            }
        }

        class Nested {
            ArrayInMap() {
                test := Map(
                    1, [1, 1, 1],
                    2, [2, 2, 2]
                )

                EncodingTester.Test(test, "82 01 93 01 01 01 02 93 02 02 02")
            }

            MapsInArray() {
                test := [
                    Map(1, "A"),
                    Map(),
                    Map(3, "C")
                ]

                EncodingTester.Test(test, "93 81 01 A1 41 80 81 03 A1 43")
            }
        }
    }
}