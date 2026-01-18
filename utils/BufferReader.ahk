#Requires AutoHotkey v2.0
#Include BinaryReader.ahk

#DllLoad ntdll.dll

/**
 * A reader that "streams" data in from a Buffer already in memory
 */
class BufferReader extends BinaryReader {

    /**
     * The buffer to read from
     * @type {Buffer}
     */
    _buf := unset

    __New(buf){
        if(!(buf is Buffer)){
            throw TypeError(Format("Expected a Buffer but got a(n) {1}", type(buf)), , buf)
        }

        this.offset := 0
        this._buf := buf
    }

    ReadByte(signed := false){
        return NumGet(this._buf, this.offset++, signed? "char" : "uchar")
    }

    ReadBytes(length){
        static methodName := A_PtrSize == 8 ? "ntdll\RtlCopyMemory" : "ntdll\RtlMoveMemory"

        target := Buffer(length)
        DllCall(methodName, "ptr", target, "ptr", this._buf.ptr + this.offset, "uint", length)
        this.offset += length

        return target
    }

    ReadString(length, encoding){
        if(length == 0){
            return ""
        }

        ;Read bytes, not characters
        strBuf := this.ReadBytes(length)
        str := StrGet(strBuf,, encoding)

        return str
    }
}