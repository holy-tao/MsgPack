# MsgPack
[![Unit Tests](https://github.com/holy-tao/MsgPack/actions/workflows/unit-tests.yml/badge.svg)](https://github.com/holy-tao/MsgPack/actions/workflows/unit-tests.yml)

A [MessagePack](https://msgpack.io/) implementation in pure AutoHotkey v2. 

> MessagePack is an efficient binary serialization format. It lets you exchange data among multiple languages like JSON. But it's faster and smaller. Small integers are encoded into a single byte, and typical short strings require only one extra byte in addition to the strings themselves.

The `MsgPack` class implements static functions which allow you to decode from and encode to [Buffers](https://www.autohotkey.com/docs/v2/lib/Buffer.htm) and [Files](https://www.autohotkey.com/docs/v2/lib/File.htm#RawRead).

```autohotkey
decoded := MsgPack.Decode(myFile)
```

Values are decoded as primitives or as native [Map](https://www.autohotkey.com/docs/v2/lib/Map.htm) or [Array](https://www.autohotkey.com/docs/v2/lib/Array.htm) objects.

### Type Notes
AutoHotkey's type system does not map perfectly onto that of the MessagePack specification. There are a few notable differences listed here.

#### Boolean Values
AutoHotkey has no explicit boolean type. As such, the values `true` and `false` will be encoded as the integers 1 and 0. To explicitly encode boolean values, use the `MsgPack.BTrue` and `MsgPack.BFalse` classes.

Boolean values are decoded as integers by default. To decode them as `MsgPack.BTrue` and `MsgPack.BFalse` objects, set `MsgPack.NativeBools` to `false`.

#### Nil Values
[Unset](https://www.autohotkey.com/docs/v2/Language.htm#unset) variables are encoded as `Nil`. This is primarilly to allow the encoder to work with sparse arrays. You can also use the `MsgPack.Nil` object to deliberately encode Nil values.

By default, Nil values are decoded as empty Strings. To decode them as `MsgPack.Nil` objects, set `MsgPack.NativeNils` to `false`.

#### Floats and Doubles
All AutoHotkey numbers are 64-bit. However, the MessagePack specification makes a distinction between 32-bit and 64-bit floating-point numbers ("Floats" vs "Doubles"). Both of these are always decoded as 64-bit [floats](https://www.autohotkey.com/docs/v2/lib/Float.htm). 

By default, all floats (as determined by [`IsFloat`](https://www.autohotkey.com/docs/v2/lib/Is.htm#float)) are encoded as 64-bit Doubles. However, if the `MsgPack.CompactFloats` value is truthy, the encoder will use a lossy heuristic to guess whether or not a float can be safelty encoded in 32 bits. This may result in lost precision and should only be used where that precision doesn't matter and where you are encoding *a lot* of floats. In most cases, you can spare the 4 bytes.

### Extension Types
[Ext format family](https://github.com/msgpack/msgpack/blob/master/spec.md#ext-format-family) stores a tuple of an integer and a byte array. These values are identified with a length prefix and a type integer. Negative values are reserved for spec-specified types.

You can make an object encodable and decodable by implementing an instance `MsgPackEncode` and a static `MsgPackDecode` method:
```autohotkey
class EncodableObject {
    MsgPackEncode(writer) => Any

    static MsgPackDecode(writer, length) => EncodableObject
}
```

Before decoding data with extension types, register type's [class](https://www.autohotkey.com/docs/v2/lib/Class.htm) with MsgPack. This is not required to merely encode data:
```autohotkey
MsgPack.ExtensionTypes[1] := EncodableClass
```

Encoder and decoder methods take `BinaryWriter` and `BinaryReader` objects with which they an read binary data. The underlying data source is unknown to the object. Encode is responsible for writing both the prefix, type, and data array, while decode begins with the prefix and type already consumed.

> [!IMPORTANT]
> **The ext prefix and type must be encoded in Big-Endian format.** This is convention for MessagePack in general. You can use the `BEWriter` class to write numbers in big-endian format like so:
> ```autohotkey
> BEWriter.WriteInt32(writer, 123465) ; or WriteInt16, WriteDouble, etc
> ```
> The format of the data array has no requirements, and its endianness is not defined.

See the `MsgPackTimestamp` type for an example.