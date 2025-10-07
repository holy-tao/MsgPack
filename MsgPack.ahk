#Requires AutoHotkey v2.0

#Include MsgPackType.ahk
#Include Utils\BEReader.ahk

#DllLoad ntdll.dll  ;For RtlCopyMemory

class MsgPack {

    ;Endianness: 
    static Decode(buf, &offset := 0, strEncode := "UTF-8"){
        lvByte := NumGet(buf, offset++, "uchar")

        if(MsgPackType.IsFixArr(lvByte)){
            ;TODO Fixed array
        }
        else if(MsgPackType.IsFixMap(lvByte)){
            ;TODO Fixed map
        }
        else if(MsgPackType.IsFixStr(lvByte)){
            len := lvByte & 0x1F    ;mask out the top three bits
            val := StrGet(buf.ptr + offset, len, strEncode)
            offset += len
            return val
        }
        else if(MsgPackType.IsNegFixInt(lvByte)){
            ;Coerce to a signed value
            return NumGet(buf, offset - 1, "char")
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
                len := NumGet(buf, offset++, "uchar")
                val := Buffer(len)
                DllCall("ntdll\RtlCopyMemory", "ptr", val, "ptr", buf.ptr + offset, "uint", len)
                offset += len
            case MsgPackType.bin16:
                len := BEReader.ReadUInt16(buf, offset)
                offset += 2
                val := Buffer(len)
                DllCall("ntdll\RtlCopyMemory", "ptr", val, "ptr", buf.ptr + offset, "uint", len)
                offset += len
            case MsgPackType.bin32:
                len := BEReader.ReadUInt32(buf, offset)
                offset += 4
                val := Buffer(len)
                DllCall("ntdll\RtlCopyMemory", "ptr", val, "ptr", buf.ptr + offset, "uint", len)
                offset += len
            case MsgPackType.int8:
                val := NumGet(buf, offset, "char")
                offset++
            case MsgPackType.int16:
                val := BEReader.ReadInt16(buf, offset)
                offset += 2
            case MsgPackType.int32:
                val := BEReader.ReadInt32(buf, offset)
                offset += 4
            case MsgPackType.int64:
                val := BEReader.ReadInt64(buf, offset)
                offset += 8
            case MsgPackType.uint8:
                val := NumGet(buf, offset, "uchar")
                offset++
            case MsgPackType.uint16:
                val := BEReader.ReadUInt16(buf, offset)
                offset += 2
            case MsgPackType.uint32:
                val := BEReader.ReadUInt32(buf, offset)
                offset += 4
            case MsgPackType.uint64:
                val := BEReader.ReadUInt64(buf, offset)
                offset += 8
            case MsgPackType.float32:
                val := BEReader.ReadFloat32(buf, offset)
                offset += 4
            case MsgPackType.float64:
                val := BEReader.ReadFloat64(buf, offset)
                offset += 8
            case MsgPackType.str8:
                len := NumGet(buf, offset++, "uchar")
                val := StrGet(buf.ptr + offset, len, strEncode)
                offset += len
            case MsgPackType.str16:
                len := BEReader.ReadUInt16(buf, offset)
                offset += 2
                val := StrGet(buf.ptr + offset, len, strEncode)
                offset += len
            case MsgPackType.str32:
                len := BEReader.ReadUInt32(buf, offset)
                offset += 4
                val := StrGet(buf.ptr + offset, len, strEncode)
                offset += len
            case MsgPackType.ext8:
                ;TODO
            case MsgPackType.ext16:
                ;TODO
            case MsgPackType.ext32:
                ;TODO
            default:
                throw TypeError(Format("Could not decode leading byte 0x{1:0X} at offset {2}", lvByte, offset - 1))
        }

        return val
    }
}