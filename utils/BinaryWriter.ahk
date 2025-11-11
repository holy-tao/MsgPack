#Requires AutoHotkey v2.0

/**
 * Abstract class for writing binary data to some destination
 */
class BinaryWriter {

    /**
     * Current position of the writer
     * @type {Integer}
     */
    offset := 0

    /**
     * Write a single byte to the destination
     */
    WriteByte(byte){
        throw MethodError("Not implemented")
    }

    /**
     * Write many bytes to the destination
     */
    WriteBytes(byteBuffer){
        throw MethodError(("Not implemented"))
    }
}