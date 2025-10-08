#Requires AutoHotkey v2.0

/**
 * Abstract class for an object which reads binary data in from a
 * stream, like a file or buffer
 */
class BinaryReader{

    offset := 0

    /**
     * Reads a single byte
     * 
     * @param {Boolean} signed true to interpret the byte as a signed number, false otherwise
     *          (default: false)
     * @returns {Integer}
     */
    ReadByte(signed := false){
        throw MethodError("Not implemented")
    }

    /**
     * Read some number of bytes into a new Buffer
     * 
     * @param {Integer} length the number of bytes to read
     * @returns {Buffer}
     */
    ReadBytes(length){
        throw MethodError("Not implemented")
    }

    /**
     * Read a string from the data source
     * 
     * @param {Integer} length the length of the string in bytes 
     * @param {String} encoding the encoding to use when reading the string 
     */
    ReadString(length, encoding){
        throw MethodError("Not implemented")
    }
}