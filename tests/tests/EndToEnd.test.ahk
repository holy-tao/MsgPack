#Requires AutoHotkey v2.0
#Include ../../MsgPack.ahk
#Include ../YUnit/Assert.ahk

class EndToEndTests {

    SimpleFileEncodeDecode() {
        path := Format("{1}\{2}.messagepack", A_ScriptDir, A_ThisFunc)
        testFile := FileOpen(path, "w")

        testValue := [
            1, 2, 3, 4, 5,
            Map("A String!", ["An", "Array", "Of", "Strings"]),
            0.5, 0.75, 1.0
        ]

        MsgPack.EncodeToFile(testFile, testValue)
        testFile.Close()
        
        if(!FileExist(path)){
            throw Error("File was not created!", , path)
        }

        decoded := MsgPack.Decode(path)
        Assert.ArraysEqual(testValue, decoded)
    }

    SimpleFilePathEncodeDecode() {
        path := Format("{1}\{2}.messagepack", A_ScriptDir, A_ThisFunc)

        testValue := [
            1, 2, 3, 4, 5,
            Map("A String!", ["An", "Array", "Of", "Strings"]),
            0.5, 0.75, 1.0
        ]

        MsgPack.EncodeToFile(path, testValue)
        
        if(!FileExist(path)){
            throw Error("File was not created!", , path)
        }

        decoded := MsgPack.Decode(path)
        Assert.ArraysEqual(testValue, decoded)
    }

    SimpleFileInvalidArg(){
        Assert.Throws((*) => MsgPack.EncodeToFile({}), TypeError)
    }

    SimpleBufferEncodeDecode(){
        testValue := Map(
            1, ["One", "Unus", "Another word for one, I guess?"],
            "map", Map(
                "funni numbers 💀💀💀", [42, 69, 67],
                "unfunni numbers", [0, -5, 9999, 4.6, 23],
                9.4, ""
            ),
            4, 5
        )

        encoded := MsgPack.EncodeToBuffer(testValue)
        decoded := MsgPack.Decode(encoded)

        Assert.MapsEqual(testValue, decoded)
    }

    VeryLongArrayWithLargeNumbers(){
        path := Format("{1}\{2}.messagepack", A_ScriptDir, A_ThisFunc)
        testFile := FileOpen(path, "w")

        arr := [], arr.Length := 4096
        Loop(arr.length){
            arr[A_Index] := A_Index * A_Index
        }

        MsgPack.EncodeToFile(testFile, arr)
        testFile.Close()

        if(!FileExist(path)){
            throw Error("File was not created!", , path)
        }

        decoded := MsgPack.Decode(path)
        Assert.ArraysEqual(arr, decoded)
    }
}