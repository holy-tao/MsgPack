#Requires AutoHotkey v2.0
#Include BinaryWriter.ahk

/**
 * Helper class that writes numbers in big-endian format
 */
class BEWriter {

    static WriteInt8(writer, num) => writer.WriteByte(num)
    static WriteInt16(writer, num) => BEWriter.WriteBytes(writer, num, 2, "short")    
    static WriteInt32(writer, num) => BEWriter.WriteBytes(writer, num, 4, "int")
    static WriteInt64(writer, num) => BEWriter.WriteBytes(writer, num, 8, "int64")

    static WriteUInt8(writer, num) => writer.WriteByte(num)
    static WriteUInt16(writer, num) => BEWriter.WriteBytes(writer, num, 2, "ushort")
    static WriteUInt32(writer, num) => BEWriter.WriteBytes(writer, num, 4, "uint")
    static WriteUInt64(writer, num) => BEWriter.WriteBytes(writer, num, 8, "uint64")

    /**
     * Write a 32-bit floating point number in big-endian format
     * 
     * @param {BinaryWriter} writer writer to actually write bytes with 
     * @param {Float} num number to write
     */
    static WriteFloat(writer, num){
        static temp := Buffer(4), reversed := Buffer(4)

        NumPut("float", num, temp)
        BEWriter._ReverseBuffer(temp, reversed)
        writer.WriteBytes(reversed)
    }

    /**
     * Write a 64-bit floating point number in big-endian format
     * 
     * @param {BinaryWriter} writer writer to actually write bytes with 
     * @param {Double} num number to write
     */
    static WriteDouble(writer, num){
        static temp := Buffer(8), reversed := Buffer(8)

        NumPut("double", num, temp)
        BEWriter._ReverseBuffer(temp, reversed)
        writer.WriteBytes(reversed)
    }

    /**
     * Write a non-decimal number in big-endian format
     * 
     * @param {BinaryWriter} writer writer to actually write bytes with 
     * @param {Integer} num number to write
     * @param {Integer} length length of the number (max 8)
     */
    static WriteBytes(writer, num, length, dllCallType){
        static temp := Buffer(0, 0), reversed := Buffer(0, 0)

        temp.Size := length, reversed.Size := length
        NumPut(dllCallType, num, temp, 0)

        BEWriter._ReverseBuffer(temp, reversed)

        writer.WriteBytes(reversed)
    }

    /**
     * Puts the bytes in `src` into `dest` in reverse order
     * @param {Buffer} src buffer with bytes to reverse
     * @param {Buffer} dest buffer to put reversed bytes into
     */
    static _ReverseBuffer(src, dest){
        Loop(src.Size){
            NumPut("uchar", NumGet(src, A_Index - 1, "uchar"), dest, src.Size - A_Index)
        }
    }
}