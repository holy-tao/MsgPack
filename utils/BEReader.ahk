#Requires AutoHotkey v2.0
#Include BinaryReader.ahk

/**
 * A big-endian binary reader. AutoHotkey doesn's support specifying endianness, so here
 * we are
 */
class BEReader {

    static ReadInt8(reader) => reader.ReadByte(true)
    static ReadInt16(reader) => BEReader.ReadBytesBigEndian(reader, 2, true)    
    static ReadInt32(reader) => BEReader.ReadBytesBigEndian(reader, 4, true)
    static ReadInt64(reader) => BEReader.ReadBytesBigEndian(reader, 8, true)

    static ReadUInt8(reader) => reader.ReadByte()
    static ReadUInt16(reader) => BEReader.ReadBytesBigEndian(reader, 2)
    static ReadUInt32(reader) => BEReader.ReadBytesBigEndian(reader, 4)
    static ReadUInt64(reader) => BEReader.ReadBytesBigEndian(reader, 8)

    static ReadFloat32(reader) => BEReader.ReadFloatBigEndian(reader, false)
    static ReadFloat64(reader) => BEReader.ReadFloatBigEndian(reader, true)

    /**
     * Read a big-endian Integer from a buffer or buffer-like object
     * 
     * @param {BinaryReader} reader reader to read data from
     * @param {Integer} numBytes the number of bytes to read
     * @param {Boolean} isSigned whether or not the value is signed 
     */
    static ReadBytesBigEndian(reader, numBytes, isSigned := false) {
        out := 0

        loop numBytes {
            byte := reader.ReadByte()
            shift := (numBytes - A_Index) * 8
            out |= byte << shift
        }

        if (isSigned) {
            signBit := 1 << ((numBytes * 8) - 1)
            if (out & signBit) {
                ; Avoid overflow: subtract using unsigned arithmetic
                if (numBytes = 8)
                    out := -(0x10000000000000000   - out)  ; 2^64 - out
                else
                    out -= (1 << (numBytes * 8))
            }
        }

        return out
    }

    /**
     * Read a big-endian Float or Double from a buffer
     * @param {BinaryReader} reader reader to read data from
     * @param {Boolean} isDouble whether or not to read a Double (8-byte / 64-bit) value 
     */
    static ReadFloatBigEndian(reader, isDouble := false) {
        static temp := Buffer(8)

        size := isDouble ? 8 : 4
        temp.size := size
        
        ; Copy and reverse byte order
        loop(size){
            NumPut("UChar", reader.ReadByte(), temp, size - A_Index)
        }
        
        return NumGet(temp, 0, isDouble ? "Double" : "Float")
    }

}