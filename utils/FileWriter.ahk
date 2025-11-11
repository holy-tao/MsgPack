#Requires AutoHotkey v2.0

#Include BufferWriter.ahk

class FileWriter extends BinaryWriter {

    /**
     * @type {File}
     */
    dest := unset

    offset{
        get => this.dest.Pos
        set => this.dest.Seek(value)
    }

    __New(dest){
        if(!(dest is File)){
            throw TypeError(Format("Expected a File but got a(n) {1}", Type(dest)))
        }

        this.dest := dest
    }

    WriteByte(byte){
        this.dest.WriteUChar(byte)
    }

    WriteBytes(byteBuffer){
        this.dest.RawWrite(byteBuffer, byteBuffer.Size)
    }
}