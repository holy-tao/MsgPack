#Requires AutoHotkey v2.0

#Include MsgPackType.ahk
#Include Utils\BEReader.ahk
#Include utils\BufferReader.ahk
#Include utils\FileReader.ahk

#DllLoad ntdll.dll  ;For RtlCopyMemory

class MsgPack {

    /**
     * Decodes the value in a file or buffer
     * @param {Buffer | File | String} source the source to decode. This can either be a
     *          Buffer, a file, or a filepath, which will be opened.
     * @param {String} strEncoding string encoding with which to decode string values 
     * @returns {Number | String | Map | Array} the decode value
     */
    static Decode(source, strEncoding := "UTF-8"){
        if(source is Buffer){
            return MsgPack.DecodeValue(BufferReader(source), strEncoding)
        }
        else if(source is String){
            reader := FileReader(FileOpen(source, "r-d"))
            return MsgPack.DecodeValue(reader, strEncoding)
        }
        else if(source is File){
            return MsgPack.DecodeValue(FileREader(source), strEncoding)
        }

        throw TypeError(Format("Expected a Buffer, File, or filepath, but got a(n) {1}", Type(source)), , source)
    }

    /**
     * Decodes a single value at the current "level" of the message pack. This might
     * not be a value type, for example, if it's an array, this method will also decode
     * its contents.
     * 
     * @param {BinaryReader} reader reader to read values from
     * @param {String} encoding encoding to use when decoding strings
     * @returns {Number | String | Map | Array} the decoded value
     */
    static DecodeValue(reader, encoding){
        lvByte := reader.ReadByte()

        ; Fix type?
        if(MsgPackType.IsFixArr(lvByte)){
            len := lvByte - 0x90    ;mask out the top three bits
            return MsgPack.DecodeArray(reader, len, encoding)
        }
        else if(MsgPackType.IsFixMap(lvByte)){
            len := lvByte - 0x80    ;mask out the top four bits
            return MsgPack.DecodeMap(reader, len, encoding)
        }
        else if(MsgPackType.IsFixStr(lvByte)){
            len := lvByte & 0x1F    ;mask out the top three bits
            return reader.ReadString(len, encoding)
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
                val := MsgPack.DecodeArray(reader, len, encoding)
            case MsgPackType.array32:
                len := BEReader.ReadInt32(reader)
                val := MsgPack.DecodeArray(reader, len, encoding)
            case MsgPackType.map16:
                len := BEReader.ReadUInt16(reader)
                val := MsgPack.DecodeMap(reader, len, encoding)
            case MsgPackType.map32:
                len := BEReader.ReadUInt32(reader)
                val := MsgPack.DecodeMap(reader, len, encoding)
            case MsgPackType.nil:
                val := ""
            case MsgPackType.bFalse:
                val := 0
            case MsgPackType.bTrue:
                val := 1
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
                val := reader.ReadString(len, encoding)
            case MsgPackType.str16:
                len := BEReader.ReadUInt16(reader)
                val := reader.ReadString(len, encoding)
            case MsgPackType.str32:
                len := BEReader.ReadUInt32(reader)
                val := reader.ReadString(len, encoding)
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
    static DecodeArray(reader, length, encoding){
        arr := Array(), arr.Length := length

        Loop(length){
            arr[A_Index] := MsgPack.DecodeValue(reader, encoding)
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
    static DecodeMap(reader, count, encoding){
        outMap := Map()

        Loop(count){
            key := MsgPack.DecodeValue(reader, encoding)
            val := MsgPack.DecodeValue(reader, encoding)

            outMap[key] := val
        }

        return outMap
    }
}