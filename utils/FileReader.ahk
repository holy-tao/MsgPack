#Requires AutoHotkey v2.0
#Include BinaryReader.ahk

class FileReader extends BinaryReader {

    /**
     * The file we're reading
     * @type {File}
     */
    _src := unset

    offset{
        get => this._src.Pos
        set => this._src.Seek(value)
    }

    __New(src){
        if(!(src is File)){
            throw TypeError(Format("Expected a File but got a(n) {1}", Type(src)))
        }

        this._src := src
    }

    ReadByte(signed := false){
        return signed? this._src.ReadChar() : this._src.ReadUChar()
    }

    ReadBytes(length){
        buf := Buffer(length, 0)
        this._src.RawRead(buf, length)
        return buf
    }

    ReadString(length, encoding){
        if(length == 0){
            return ""
        }

        ;Need to read in bytes, not characters
        str := StrGet(this.ReadBytes(length),, encoding)
        return str
    }
}