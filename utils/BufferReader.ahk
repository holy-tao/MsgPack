#Requires AutoHotkey v2.0
#Include BinaryReader.ahk

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
        target := Buffer(length)
        DllCall("ntdll\RtlCopyMemory", "ptr", target, "ptr", this._buf.ptr + this.offset, "uint", length)
        this.offset += length

        return target
    }

    ReadString(length, encoding){
        ;Read bytes, not characters
        strBuf := this.ReadBytes(length)
        str := StrGet(strBuf,, encoding)

        return str
    }
}