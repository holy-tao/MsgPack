#Requires AutoHotkey v2.0

/**
 * A big-endian binary reader. AutoHotkey doesn's support specifying endianness, so here
 * we are
 */
class BEReader {

    static ReadInt8(buf, offset) => NumGet(buf, offset, "char")
    static ReadInt16(buf, offset) => BEReader.ReadBytesBigEndian(buf, offset, 2, true)    
    static ReadInt32(buf, offset) => BEReader.ReadBytesBigEndian(buf, offset, 4, true)
    static ReadInt64(buf, offset) => BEReader.ReadBytesBigEndian(buf, offset, 8, true)

    static ReadUInt8(buf, offset) => NumGet(buf, offset, "uchar")
    static ReadUInt16(buf, offset) => BEReader.ReadBytesBigEndian(buf, offset, 2)
    static ReadUInt32(buf, offset) => BEReader.ReadBytesBigEndian(buf, offset, 4)
    static ReadUInt64(buf, offset) => BEReader.ReadBytesBigEndian(buf, offset, 8)

    static ReadFloat32(buf, offset) => BEReader.ReadFloatBigEndian(buf, offset)
    static ReadFloat64(buf, offset) => BEReader.ReadFloatBigEndian(buf, offset, true)

    /**
     * Read a big-endian Integer from a buffer or buffer-like object
     * 
     * @param {Buffer | Buffer-like Object} buf buffer to read data from
     * @param {Integer} offset offset in `buf` to read at
     * @param {Integer} numBytes the number of bytes to read
     * @param {Boolean} isSigned whether or not the value is signed 
     */
    static ReadBytesBigEndian(buf, offset, numBytes, isSigned := false) {
        out := 0

        loop numBytes {
            byte := NumGet(buf, offset + (A_Index - 1), "UChar")
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
     * @param {Buffer | Buffer-like Object} buf buffer to read data from
     * @param {Integer} offset offset in `buf` to read at
     * @param {Boolean} isDouble whether or not to read a Double (8-byte / 64-bit) value 
     */
    static ReadFloatBigEndian(buf, offset, isDouble := false) {
        size := isDouble ? 8 : 4
        temp := Buffer(size)
        
        ; Copy and reverse byte order
        loop(size){
            NumPut("UChar", NumGet(buf, offset + (size - A_Index), "UChar"), temp, A_Index - 1)
        }
        
        return NumGet(temp, 0, isDouble ? "Double" : "Float")
    }

}