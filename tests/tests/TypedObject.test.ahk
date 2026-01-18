#Requires AutoHotkey v2.0

#Include ../../MsgPack.ahk
#Include ../YUnit/Assert.ahk
#Include ../../extensiontypes/TypedObject.ahk

class TypedObjectTests {
    class RoundTrip {
        AnonymousObject() {
            original := {str: "test", int: 0, float: 0.45, arr: [1, 2, 3, 4, 5]}

            encoded := MsgPack.EncodeToBuffer(original)
            decoded := MsgPack.Decode(encoded)

            Assert.IsType(decoded, Object)
            Assert.Equals(String(original), String(decoded))
        }

        TypedObject(){
            original := TestType("one", "two")

            encoded := MsgPack.EncodeToBuffer(original)
            decoded := MsgPack.Decode(encoded)

            Assert.IsType(decoded, TestType)
            Assert.Equals(String(original), String(decoded))
        }

        Subclass() {
            original := TestSubType("two", "three")

            encoded := MsgPack.EncodeToBuffer(original)
            decoded := MsgPack.Decode(encoded)

            Assert.IsType(decoded, TestSubType)
            Assert.Equals(String(original), String(decoded))
        }

        NestedClass() {
            original := TestType.Nested("nested value")

            encoded := MsgPack.EncodeToBuffer(original)
            decoded := MsgPack.Decode(encoded)

            Assert.IsType(decoded, TestType.Nested)
            Assert.Equals(String(original), String(decoded))
        }

        NestedObjects() {
            original := {
                str: "test", 
                int: 0, 
                float: 0.45, 
                arr: [1, 2, 3, 4, 5],
                typedObject: TestSubType("Two", "Three"),
                anonObject: {anon1: "Anonymous", anon2: "Anonymous"}
            }

            encoded := MsgPack.EncodeToBuffer(original)
            decoded := MsgPack.Decode(encoded)

            Assert.IsType(decoded, Object)
            Assert.IsType(decoded.typedObject, TestSubType)
            Assert.Equals(String(original), String(decoded))
        }
    }
}

;@ahkunit-ignore
class TestType {
    __New(prop1 := "", prop2 := ""){
        this.prop1 := prop1
        this.prop2 := prop2
    }

    class Nested {
        __New(val := ""){
            this.nestedVal := val
        }
    }
}

;@ahkunit-ignore
class TestSubType extends TestType {
    __New(prop2 := "", prop3 := ""){
        super.__New("Property One", prop2)

        this.prop2 := prop2
        this.prop3 := prop3
    }
}