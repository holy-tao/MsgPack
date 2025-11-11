#Requires AutoHotkey v2.0

#DllLoad ntdll.dll          ;For RtlCopyMemory
#Include BinaryWriter.ahk

class BufferWriter extends BinaryWriter {

    /**
     * The buffer being written to
     * @type {Buffer}
     */
    buf := unset

    __New(buf?){
        this.offset := 0
        if(!IsSet(buf)){
            this.buf := Buffer(64, 0)
        }
        else{
            if(!(buf is Buffer)){
                throw TypeError(Format("Expected a Buffer but got a(n) {1}", type(buf)), , buf)
            }
            this.buf := buf
        }
    }

    WriteByte(byte){
        if(this.buf.size == this.offset){
            this.buf.Size *= 2
        }

        NumPut("uchar", byte, this.buf, this.offset++)
    }

    WriteBytes(byteBuffer){
        DllCall("ntdll\RtlCopyMemory", "ptr", this.buf.ptr + this.offset, "ptr", byteBuffer, "uint", byteBuffer.Size)
        this.offset += byteBuffer.Size
    }
}