#Requires AutoHotkey v2.0

#Include ../utils/BEReader.ahk
#Include ../utils/BEWriter.ahk
#Include ../MsgPackType.ahk
#Include ../MsgPack.ahk

/**
 * Including this file in your script will define naiive object encoders for all
 * objects. The encoder will encode all properties that are either value types or
 * which have BOTH getters and setters defined (invoking getters in the process)
 * in a Map of property names to values.
 * 
 * The decoder will first read the class name and call Call() on it, then read all
 * of the properties and call object.%prop% := value. The object must implement a
 * zero-argument Call() method.
 * 
 * You can achieve MUCH better performance and space efficiency by defining your
 * own specialized encoders and decoders - in particular, for non generalized use
 * cases, it's not necessary to store property names and should be possible to
 * calculate the required space before encoding.
 * 
 * TypedObjects use the type code 127
*/

Object.Prototype.DefineProp("MsgPackEncode", {Call: (self, writer) => MsgPackTypedObject.Encode(self, writer)})
Object.DefineProp("MsgPackDecode", {Call: (self, reader, length) => MsgPackTypedObject.Decode(reader, length) })
MsgPack.ExtensionTypes[127] := Object

class MsgPackTypedObject {

    static Encode(obj, writer){
        className := obj.__Class
        propMap := Map()

        current := obj

        while(current.__Class != "Any"){
            for(propName in current.OwnProps()){
                if(propMap.Has(propName))
                    continue

                desc := current.GetOwnPropDesc(propName)
                if(desc.HasProp("Value") || (desc.HasProp("Get") && desc.HasProp("Set"))){
                    propMap[propName] := obj.%propName%
                }
            }

            current := current.base
        }

        ; Naiive approach - we can't really know the required size of the data ahead of time
        tempBuf := MsgPack.EncodeToBuffer(propMap)
        if(tempBuf.Size <= (2**8) - 1) {
            writer.WriteByte(MsgPackType.ext8)
            BEWriter.WriteUInt8(writer, tempBuf.Size)
        }
        else if(tempBuf.Size <= (2**16) - 1) {
            writer.WriteByte(MsgPackType.ext16)
            BEWriter.WriteUInt16(writer, tempBuf.Size)
        }
        else if(tempBuf.Size <= (2**32) - 1){
            writer.WriteByte(MsgPackType.ext32)
            BEWriter.WriteUInt32(writer, tempBuf.Size)
        }
        else {
            throw ValueError("Data too large to encode", , tempBuf.Size)
        }

        BEWriter.WriteInt8(writer, 127)
        writer.WriteBytes(tempBuf)
    }

    static Decode(reader, length){
        buf := reader.ReadBytes(length)
        objMap := MsgPack.Decode(buf)

        ; Resolve potentially nested classes
        cls := ""
        for(part in StrSplit(objMap["__Class"], ".")){
            cls := cls is Class ? cls.%part% : %part%
        }

        obj := cls.Call()
        objMap.Delete("__Class")

        for(key, val in objMap){
            obj.%key% := val
        }

        return obj
    }
}