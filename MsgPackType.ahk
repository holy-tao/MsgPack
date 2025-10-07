#Requires AutoHotkey v2.0

/**
 * Enum of all valid MsgPack types. See spec: https://github.com/msgpack/msgpack/blob/master/spec.md#overview
 */
class MsgPackType {
    
    static nil => 0xc0  

    static bFalse => 0xc2

    static bTrue => 0xc3

    static bin8 => 0xc4

    static bin16 => 0xc5

    static bin32 => 0xc6

    static ext8 => 0xc7

    static ext16 => 0xc8

    static ext32 => 0xc9

    static float32 => 0xca

    static float64 => 0xcb

    static uint8 => 0xcc

    static uint16 => 0xcd

    static uint32 => 0xce

    static uint64 => 0xcf

    static int8 => 0xd0

    static int16 => 0xd1

    static int32 => 0xd2

    static int64 => 0xd3

    static fixext1 => 0xd4

    static fixext2 => 0xd5

    static fixext4 => 0xd6

    static fixext8 => 0xd7

    static fixext16 => 0xd8

    static str8 => 0xd9

    static str16 => 0xda

    static str32 => 0xdb

    static array16 => 0xdc

    static array32 => 0xdd

    static map16 => 0xde

    static map32 => 0xdf

    static IsPosFixInt(byte) {
        return 0x00 <= byte && byte <= 0x7F
    }

    static IsNegFixInt(byte) {
        return 0xE0 <= byte && byte <= 0xFF
    }

    static IsFixStr(byte) {
        return 0xA0 <= byte && byte <= 0xBF
    }

    static IsFixMap(byte) {
        return 0x80 <= byte && byte <= 0x8F
    }

    static IsFixArr(byte) {
        return 0x90 <= byte && byte <= 0x9F
    }
}