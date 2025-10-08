#Requires AutoHotkey v2.0

#Include MsgPackType.ahk
#Include Utils\BEReader.ahk
#Include utils\BufferReader.ahk

#DllLoad ntdll.dll  ;For RtlCopyMemory

class MsgPack {

    static Decode(source, strEncoding := "UTF-8"){
        if(source is Buffer){
            return MsgPack.DecodeInner(BufferReader(source), strEncoding)
        }
    }

    ;Endianness:
    /**
     * 
     * @param {BinaryReader} reader 
     * @param {String} encoding encoding to use when decoding strings 
     */
    static DecodeInner(reader, encoding){
        lvByte := reader.ReadByte()

        if(MsgPackType.IsFixArr(lvByte)){
            ;TODO Fixed array
        }
        else if(MsgPackType.IsFixMap(lvByte)){
            ;TODO Fixed map
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

        ;Must be a value type
        switch(lvByte){
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
}