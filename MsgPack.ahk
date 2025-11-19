#Requires AutoHotkey v2.0

#Include MsgPackType.ahk
#Include Utils\BEReader.ahk
#Include utils\BufferReader.ahk
#Include utils\FileReader.ahk

#Include utils\BEWriter.ahk
#Include utils\BufferWriter.ahk
#Include utils\FileWriter.ahk

class MsgPack {

;@region Options

    /**
     * If true, allows the encoder to use a lossy heuristic to determine whether or not
     * float values can be encoded as Singles. This may result in losing some precision.
     * Default is false
     * @type {Boolean}
     */
    static CompactFloats := false

    /**
     * If true, the boolean values will be decoded as 1 / 0 instead of MsgPack.BTrue or
     * MsgPack.BFalse
     */
    static NativeBools := true

    /**
     * If true, nil values will be decoded as empty strings instead of MsgPack.Nil
     */
    static NativeNils := true
;@endregion Options

;@region Decoding

    /**
     * Decodes the value in a file or buffer
     * @param {Buffer | File | String} source the source to decode. This can either be a
     *          Buffer, a file, or a filepath, which will be opened.
     * @returns {Number | String | Map | Array} the decode value
     */
    static Decode(source){
        if(source is Buffer){
            return MsgPack.DecodeValue(BufferReader(source))
        }
        else if(source is String){
            reader := FileReader(FileOpen(source, "r-d"))
            return MsgPack.DecodeValue(reader)
        }
        else if(source is File){
            return MsgPack.DecodeValue(FileREader(source))
        }

        throw TypeError(Format("Expected a Buffer, File, or filepath, but got a(n) {1}", Type(source)), , source)
    }

    /**
     * Decodes a single value at the current "level" of the message pack. This might
     * not be a value type, for example, if it's an array, this method will also decode
     * its contents.
     * 
     * @param {BinaryReader} reader reader to read values from
     * @returns {Number | String | Map | Array} the decoded value
     */
    static DecodeValue(reader){
        lvByte := reader.ReadByte()

        ; Fix type?
        if(MsgPackType.IsFixArr(lvByte)){
            len := lvByte - 0x90    ;mask out the top three bits
            return MsgPack.DecodeArray(reader, len)
        }
        else if(MsgPackType.IsFixMap(lvByte)){
            len := lvByte - 0x80    ;mask out the top four bits
            return MsgPack.DecodeMap(reader, len)
        }
        else if(MsgPackType.IsFixStr(lvByte)){
            len := lvByte - 0xa0    ;mask out the top three bits
            return reader.ReadString(len, "UTF-8")
        }
        else if(MsgPackType.IsNegFixInt(lvByte)){
            reader.offset--
            return reader.ReadByte(true)
        }
        else if(MsgPackType.IsPosFixInt(lvByte)){
            return lvByte
        }

        ;Must be a type with a leading byte
        switch(lvByte){
            case MsgPackType.array16:
                len := BEReader.ReadUInt16(reader)
                val := MsgPack.DecodeArray(reader, len)
            case MsgPackType.array32:
                len := BEReader.ReadInt32(reader)
                val := MsgPack.DecodeArray(reader, len)
            case MsgPackType.map16:
                len := BEReader.ReadUInt16(reader)
                val := MsgPack.DecodeMap(reader, len)
            case MsgPackType.map32:
                len := BEReader.ReadUInt32(reader)
                val := MsgPack.DecodeMap(reader, len)
            case MsgPackType.nil:
                val := MsgPack.NativeNils ? "" : MsgPack.Nil()
            case MsgPackType.bFalse:
                val := MsgPack.NativeBools ? 0 : MsgPack.BFalse()
            case MsgPackType.bTrue:
                val := MsgPack.NativeBools ? 1 : MsgPack.BTrue()
            case MsgPackType.bin8:
                len := reader.ReadByte()
                val := reader.ReadBytes(len)
            case MsgPackType.bin16:
                len := BEReader.ReadUInt16(reader)
                val := reader.ReadBytes(len)
            case MsgPackType.bin32:
                len := BEReader.ReadUInt32(reader)
                val := reader.ReadBytes(len)
            case MsgPackType.int8:
                val := reader.ReadByte(true)
            case MsgPackType.int16:
                val := BEReader.ReadInt16(reader)
            case MsgPackType.int32:
                val := BEReader.ReadInt32(reader)
            case MsgPackType.int64:
                val := BEReader.ReadInt64(reader)
            case MsgPackType.uint8:
                val := reader.ReadByte()
            case MsgPackType.uint16:
                val := BEReader.ReadUInt16(reader)
            case MsgPackType.uint32:
                val := BEReader.ReadUInt32(reader)
            case MsgPackType.uint64:
                val := BEReader.ReadUInt64(reader)
            case MsgPackType.float32:
                val := BEReader.ReadFloat32(reader)
            case MsgPackType.float64:
                val := BEReader.ReadFloat64(reader)
            case MsgPackType.str8:
                len := reader.ReadByte()
                val := reader.ReadString(len, "UTF-8")
            case MsgPackType.str16:
                len := BEReader.ReadUInt16(reader)
                val := reader.ReadString(len, "UTF-8")
            case MsgPackType.str32:
                len := BEReader.ReadUInt32(reader)
                val := reader.ReadString(len, "UTF-8")
            case MsgPackType.ext8:
                ;TODO
            case MsgPackType.ext16:
                ;TODO
            case MsgPackType.ext32:
                ;TODO
            default:
                throw TypeError(Format("Could not decode leading byte 0x{1:0X} at offset {2}", lvByte, reader.offset - 1))
        }

        return val
    }

    /**
     * Decodes an array and all of its items
     * @param {BinaryReader} reader reader to read values from
     * @param {Integer} length the length of the array 
     * @param {String} encoding encoding for any strings
     * @returns {Array} the decoded array 
     */
    static DecodeArray(reader, length){
        arr := Array(), arr.Length := length

        Loop(length){
            arr[A_Index] := MsgPack.DecodeValue(reader)
        }

        return arr
    }

    /**
     * Decodes a map and all of its keys and values
     * @param {BinaryReader} reader reader to read values from
     * @param {Integer} count the number of key/value pairs in the map
     * @param {String} encoding encoding for any strings
     * @returns {Map} the decoded map
     */
    static DecodeMap(reader, count){
        outMap := Map()

        Loop(count){
            key := MsgPack.DecodeValue(reader)
            val := MsgPack.DecodeValue(reader)

            outMap[key] := val
        }

        return outMap
    }

;@endregion Decoding

;@region Encoding
    static EncodeToFile(dest, val?) => MsgPack.EncodeValue(FileWriter(dest), val?)

    static EncodeToBuffer(val?){
        buf := Buffer(64, 0)
        writer := BufferWriter(buf)
        MsgPack.EncodeValue(writer, val?)
        buf.Size := writer.offset

        return buf
    }

    static EncodeValue(writer, val?){
        if(!IsSet(val) || val is MsgPack.Nil){
            MsgPack.EncodeNil(writer)
        }
        else if (val is String){
            MsgPack.EncodeString(val, writer)
        }
        else if (val is Buffer){
            MsgPack.EncodeBinary(val, writer)
        }
        else if (IsFloat(val)){
            MsgPack.EncodeFloat(val, writer)
        }
        else if (IsInteger(val)){
            MsgPack.EncodeInteger(val, writer)
        }
        else if (val is MsgPack.BTrue || val is MsgPack.BFalse){
            MsgPack.EncodeBoolean(val is MsgPack.BTrue ? 1 : 0, writer)
        }
        else if (val is Map){
            MsgPack.EncodeMap(val, writer)
        }
        else if (val is Array){
            MsgPack.EncodeArray(val, writer)
        }
        else{
            ; TODO extensions
            throw TypeError("Cannot encode value of type " . Type(val), , val)
        }
    }

    /**
     * Encodes an array
     * @param {Array<Primitive|Map|Array>} arr The array to encode
     * @param {BinaryWriter} writer Writer to write data to 
     */
    static EncodeArray(arr, writer){
        if(arr.length <= 15){
            writer.WriteByte(0x3E9 << 4 | arr.length)
        }
        else if(arr.length <= 65535){
            writer.WriteByte(MsgPackType.array16)
            BEWriter.WriteUint16(writer, arr.length)
        }
        else if(arr.length <= 4294967295){
            writer.WriteByte(MsgPackType.array32)
            BEWriter.WriteUInt32(writer, arr.length)
        }
        else{
            throw ValueError("Array too long", , arr.length)
        }

        Loop(arr.Length){
            MsgPack.EncodeValue(writer, arr[A_Index])
        }
    }

    /**
     * Encodes a Map
     * @param {Map<Primitive|Map|Array, Primitive|Map|Array>} val The map to encode
     * @param {BinaryWriter} writer Writer to write data to  
     */
    static EncodeMap(val, writer){
        if(val.count <= 15){
            writer.WriteByte(0x3E8 << 4 | val.count)
        }
        else if(val.count <= 65535){
            writer.WriteByte(MsgPackType.map16)
            BEWriter.WriteUint16(writer, val.count)
        }
        else if(val.count <= 4294967295){
            writer.WriteByte(MsgPackType.map32)
            BEWriter.WriteUInt32(writer, val.count)
        }
        else{
            throw ValueError("Map too large", , val.count)
        }

        for(key, value in val){
            MsgPack.EncodeValue(writer, key)
            MsgPack.EncodeValue(writer, value)
        }
    }

    /**
     * Writes nil to the output
     * @param {BinaryWriter} writer Writer to write data to 
     */
    static EncodeNil(writer){
        writer.WriteByte(MsgPackType.nil)
    }

    /**
     * Encodes a string
     * @param {String} str The string to encode 
     * @param {BinaryWriter} writer Writer to write data to
     */
    static EncodeString(str, writer){
        byteLen := StrPut(str, "UTF-8") - 1   ; Subtract null terminator
        strBuf := Buffer(byteLen)

        if((len := StrLen(str)) == 0){
            ; StrPut complains if you tell it to put 0 characters into a Buffer
            writer.WriteByte(0xA0)
            return
        }

        StrPut(str, strBuf, byteLen, "UTF-8")

        if(strBuf.Size <= 31){
            writer.WriteByte(0xA0 | strBuf.Size)
            writer.WriteBytes(strBuf)
        }
        else if(strBuf.Size <= 255){
            writer.WriteByte(MsgPackType.str8)
            BEWriter.WriteUInt8(writer, strBuf.Size)
            writer.WriteBytes(strBuf)
        }
        else if(strBuf.Size <= 65535){
            writer.WriteByte(MsgPackType.str16)
            BEWriter.WriteUInt16(writer, strBuf.Size)
            writer.WriteBytes(strBuf)
        }
        else if(strBuf.Size <= 4294967295){
            writer.WriteByte(MsgPackType.str32)
            BEWriter.WriteUInt32(writer, strBuf.Size)
            writer.WriteBytes(strBuf)
        }
        else{
            throw ValueError("String too long`nhttps://github.com/msgpack/msgpack/blob/master/spec.md#str-format-family", , strBuf.Size)
        }
    }

    /**
     * Encodes raw binary data
     * @param {Buffer} buf Binary data to encode 
     * @param {BinaryWriter} writer Writer to write data to
     */
    static EncodeBinary(buf, writer){
        if(buf.Size <= 255){
            writer.WriteByte(MsgPackType.bin8)
            BEWriter.WriteUInt8(writer, buf.Size)
            writer.WriteBytes(buf)
        }
        else if(buf.Size <= 65535){
            writer.WriteByte(MsgPackType.bin16)
            BEWriter.WriteUInt16(writer, buf.Size)
            writer.WriteBytes(buf)
        }
        else if(buf.Size <= 4294967295){
            writer.WriteByte(MsgPackType.bin32)
            BEWriter.WriteUInt32(writer, buf.Size)
            writer.WriteBytes(buf)
        }
        else{
            throw ValueError("Buffer too large`nhttps://github.com/msgpack/msgpack/blob/master/spec.md#bin-format-family", , buf.Size)
        }
    }

    /**
     * Encodes a floating-point number. If CompactFloats is on, will try to guess whether it
     * can be encoded as a Single, otherwise, Floats are always encoded as Doubles
     * @param {Float} val Float value to encode
     * @param {BinaryWriter} writer Writer to write data to
     */
    static EncodeFloat(val, writer){
        ; Simple heruistic to guess whether a value can be encoded as a single
        LooksSingle(val) => (Abs(val) <= 3.402823466e38)
        
        if(MsgPack.CompactFloats && LooksSingle(val)){
            writer.WriteByte(MsgPackType.float32)
            BEWriter.WriteFloat(writer, val)
        }
        else{
            writer.WriteByte(MsgPackType.float64)
            BEWriter.WriteDouble(writer, val)
        }
    }

    /**
     * Encodes a boolean value. This method is provided for convenience, but 
     * currently isn't actually used
     * @param {Integer} val Boolean value to encode
     * @param {BinaryWriter} writer Writer to write data to
     */
    static EncodeBoolean(val, writer){
        writer.WriteByte(val ? MsgPackType.bTrue : MsgPackType.bFalse)
    }

    /**
     * Encodes an integer value and writes it to a destination
     * @param {Integer} val Integer to encode
     * @param {BinaryWriter} writer Writer to write data to
     */
    static EncodeInteger(val, writer) {
        if (val >= 0) {
            if (val <= 127) {
                writer.WriteByte(val)  ; positive fixint
            }
            else if (val <= 0xFF) {
                writer.WriteByte(MsgPackType.uint8)
                writer.WriteByte(val)
            }
            else if (val <= 0xFFFF) {
                writer.WriteByte(MsgPackType.uint16)
                BEWriter.WriteUInt16(writer, val)
            }
            else if (val <= 0xFFFFFFFF) {
                writer.WriteByte(MsgPackType.uint32)
                BEWriter.WriteUInt32(writer, val)
            }
            else {
                writer.WriteByte(MsgPackType.uint64)
                BEWriter.WriteUInt64(writer, val)
            }
        }
        else {
            if (val >= -32) {
                writer.WriteByte(0xE0 | (val + 32)) ; negative fixint
            }
            else if (val >= -128) {
                writer.WriteByte(MsgPackType.int8)
                BEWriter.WriteInt8(writer, val)
            }
            else if (val >= -32768) {
                writer.WriteByte(MsgPackType.int16)
                BEWriter.WriteInt16(writer, val)
            }
            else if (val >= -2147483648) {
                writer.WriteByte(MsgPackType.int32)
                BEWriter.WriteInt32(writer, val)
            }
            else {
                writer.WriteByte(MsgPackType.int64)
                BEWriter.WriteInt64(writer, val)
            }
        }
    }


;@endregion Encoding

;@region Utils

    class BFalse {
        ToString() => "false"
        Value => 0
    }

    class BTrue {
        ToString() => "true"
        Value => 1
    }

    class Nil {
        ToString() => "nil"
    }

;@endregion

}