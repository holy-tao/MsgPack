#Requires AutoHotkey v2.0

#Requires AutoHotkey v2.0
#Include ../../MsgPack.ahk
#Include ../YUnit/Assert.ahk
#Include ./PrimitiveEncodingTests.ahk
#Include ./PrimitiveDecodingTests.ahk

class TimestampTester{

    /**
     * Takes a hex string, puts it in a Buffer, and decodes that using MsgPack.Decode.
     * If the decode value is not equal to "expected", throws an error
     * 
     * @param {String} hex hex to test decoding
     */
    static TestDecode(hex, seconds, nanoseconds) {
        buf := TimestampTester.BufferFrom(hex)

        result := MsgPack.Decode(buf)
        Assert.IsType(result, MsgPackTimestamp)
        Assert.Equals(result.seconds, seconds)
        Assert.Equals(result.nanoseconds, nanoseconds)
    }

    static TestEncode(hex, seconds, nanoseconds) {
        timestamp := MsgPackTimestamp()
        timestamp.seconds := seconds
        timestamp.nanoseconds := nanoseconds

        buf := MsgPack.EncodeToBuffer(timestamp)
        expected := TimestampTester.BufferFrom(hex)
        Assert.BuffersEqual(expected, buf)
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

class TimestampEncodingDecodingTests {

    ; Decoding - https://github.com/kawanet/msgpack-test-suite/blob/master/src/50.timestamp.yaml
    Decode32_1(*) => TimestampTester.TestDecode("d6 ff 5a 4a f6 a5", 1514862245, 0)
    Decode64_1(*) => TimestampTester.TestDecode("d7 ff a1 dc d7 c8 5a 4a f6 a5", 1514862245, 678901234)
    Decode64_Boundary(*) => TimestampTester.TestDecode("d7 ff ee 6b 27 fc 7f ff ff ff", 2147483647, 999999999)
    Decode64_No_Nanoseconds(*) => TimestampTester.TestDecode("d6 ff 80 00 00 00", 2147483648, 0)
    Decode32_Large(*) => TimestampTester.TestDecode("d6 ff ff ff ff ff", 4294967295, 0)
    Decode64_Large_2(*) => TimestampTester.TestDecode("d7 ff ee 6b 27 fc ff ff ff ff", 4294967295, 999999999)
    Decode64_Large_3(*) => TimestampTester.TestDecode("d7 ff 00 00 00 01 00 00 00 00", 4294967296, 0)
    Decode64_Large_4(*) => TimestampTester.TestDecode("d7 ff ee 6b 27 ff ff ff ff ff", 17179869183, 999999999)
    Decode96_Large(*) => TimestampTester.TestDecode("c7 0c ff 00 00 00 00 00 00 00 04 00 00 00 00", 17179869184, 0)
    Decode96_NegOne(*) => TimestampTester.TestDecode("c7 0c ff 00 00 00 00 ff ff ff ff ff ff ff ff", -1, 0)
    Decode96_NegOneLarge(*) => TimestampTester.TestDecode("c7 0c ff 3b 9a c9 ff ff ff ff ff ff ff ff ff", -1, 999999999)
    Decode32_Zero(*) => TimestampTester.TestDecode("d6 ff 00 00 00 00", 0, 0)
    Decode64_ZeroOne(*) => TimestampTester.TestDecode("d7 ff 00 00 00 04 00 00 00 00", 0, 1)
    Decode32_OneZero(*) => TimestampTester.TestDecode("d6 ff 00 00 00 01", 1, 0)
    Decode96_VerySmallVeryLarge(*) => TimestampTester.TestDecode("c7 0c ff 3b 9a c9 ff ff ff ff ff 7c 55 81 7f", -2208988801, 999999999)
    Decode96_VerySmallZero(*) => TimestampTester.TestDecode("c7 0c ff 00 00 00 00 ff ff ff ff 7c 55 81 80", -2208988800, 0)
    Decode96_VerySmallZero2(*) => TimestampTester.TestDecode("c7 0c ff 00 00 00 00 ff ff ff f1 86 8b 84 00", -62167219200, 0)
    Decode96_Boundary(*) => TimestampTester.TestDecode("c7 0c ff 3b 9a c9 ff 00 00 00 3a ff f4 41 7f", 253402300799, 999999999)

    ; Encoding - largely the same as above
    Encode32_1(*) => TimestampTester.TestEncode("d6 ff 5a 4a f6 a5", 1514862245, 0)
    Encode64_1(*) => TimestampTester.TestEncode("d7 ff a1 dc d7 c8 5a 4a f6 a5", 1514862245, 678901234)
    Encode64_Boundary(*) => TimestampTester.TestEncode("d7 ff ee 6b 27 fc 7f ff ff ff", 2147483647, 999999999)
    Encode64_No_Nanoseconds(*) => TimestampTester.TestEncode("d6 ff 80 00 00 00", 2147483648, 0)
    Encode32_Large(*) => TimestampTester.TestEncode("d6 ff ff ff ff ff", 4294967295, 0)
    Encode64_Large_2(*) => TimestampTester.TestEncode("d7 ff ee 6b 27 fc ff ff ff ff", 4294967295, 999999999)
    Encode64_Large_3(*) => TimestampTester.TestEncode("d7 ff 00 00 00 01 00 00 00 00", 4294967296, 0)
    Encode64_Large_4(*) => TimestampTester.TestEncode("d7 ff ee 6b 27 ff ff ff ff ff", 17179869183, 999999999)
    Encode96_Large(*) => TimestampTester.TestEncode("c7 0c ff 00 00 00 00 00 00 00 04 00 00 00 00", 17179869184, 0)
    Encode96_NegOne(*) => TimestampTester.TestEncode("c7 0c ff 00 00 00 00 ff ff ff ff ff ff ff ff", -1, 0)
    Encode96_NegOneLarge(*) => TimestampTester.TestEncode("c7 0c ff 3b 9a c9 ff ff ff ff ff ff ff ff ff", -1, 999999999)
    Encode32_Zero(*) => TimestampTester.TestEncode("d6 ff 00 00 00 00", 0, 0)
    Encode64_ZeroOne(*) => TimestampTester.TestEncode("d7 ff 00 00 00 04 00 00 00 00", 0, 1)
    Encode32_OneZero(*) => TimestampTester.TestEncode("d6 ff 00 00 00 01", 1, 0)
    Encode96_VerySmallVeryLarge(*) => TimestampTester.TestEncode("c7 0c ff 3b 9a c9 ff ff ff ff ff 7c 55 81 7f", -2208988801, 999999999)
    Encode96_VerySmallZero(*) => TimestampTester.TestEncode("c7 0c ff 00 00 00 00 ff ff ff ff 7c 55 81 80", -2208988800, 0)
    Encode96_VerySmallZero2(*) => TimestampTester.TestEncode("c7 0c ff 00 00 00 00 ff ff ff f1 86 8b 84 00", -62167219200, 0)
    Encode96_Boundary(*) => TimestampTester.TestEncode("c7 0c ff 3b 9a c9 ff 00 00 00 3a ff f4 41 7f", 253402300799, 999999999)

    EndToEndRandom(*){
        Loop(500){
            timestamp := MsgPackTimestamp()
            timestamp.seconds := Random(-(2^63), 2^63 - 1)
            timestamp.nanoseconds := Random(0, 2^31)

            encoded := MsgPack.EncodeToBuffer(timestamp)
            decoded := MsgPack.Decode(encoded)

            Assert.Equals(timestamp.seconds, decoded.seconds)
            Assert.Equals(timestamp.nanoseconds, decoded.nanoseconds)
        }
    }
}

class TimestampFunctionalTests {

    Now_Always_GetsNow(){
        Assert.Equals(MsgPackTimestamp.Now().ToAhkTimestamp(), A_NowUTC)
    }
}