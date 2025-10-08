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
            return MsgPack.DecodeInner(BufferReader(source), strEncoding)
        }
        else if(source is String){
            reader := FileReader(FileOpen(source, "r-d"))
            return MsgPack.DecodeInner(reader, strEncoding)
        }
        else if(source is File){
            return MsgPack.DecodeInner(FileREader(source), strEncoding)
        }

        throw TypeError(Format("Expected a Buffer, File, or filepath, but got a(n) {1}", Type(source)), , source)
    }

    /**
     * Inner decode method
     * @param {BinaryReader} reader reader to read values from
     * @param {String} encoding encoding to use when decoding strings
     * @returns {Number | String | Map | Array} the decode value
     */
    static DecodeInner(reader, encoding){
        lvByte := reader.ReadByte()

        ; Fix type?
        if(MsgPackType.IsFixArr(lvByte)){
            len := lvByte & 0x1F    ;mask out the top three bits
            return MsgPack.DecodeArray(reader, len, encoding)
        }
        else if(MsgPackType.IsFixMap(lvByte)){
            len := lvByte & 0xF0    ;mask out the top four bits
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

    static DecodeArray(reader, length, encoding){
        arr := Array(), arr.Length := length

        Loop(length){
            arr[A_Index] := MsgPack.DecodeInner(reader, encoding)
        }

        return arr
    }

    static DecodeMap(reader, length, encoding){
        outMap := Map()

        Loop(length){
            key := MsgPack.DecodeInner(reader, encoding)
            val := MsgPack.DecodeInner(reader, encoding)

            outMap[key] := val
        }

        return outMap
    }
}