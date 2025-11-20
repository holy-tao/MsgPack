#Requires AutoHotkey v2.0

#Include ../MsgPackType.ahk
#Include ../utils/BEReader.ahk
#Include ../utils/BEWriter.ahk

/**
 * Stores the number of seconds and optionally nanoseconds that have elapsed since 1970-01-01 00:00:00 UTC
 * @See {@link https://www.autohotkey.com/docs/v2/Variables.htm#NowUTC `A_NowUTC`}
 */
class MsgPackTimestamp {

    seconds := 0
    nanoseconds := 0

    /**
     * The timestamp 1970-01-01 00:00:00 in {@link https://www.autohotkey.com/docs/v2/lib/FileSetTime.htm#YYYYMMDD|YYYYMMDDHH24MISS format}
     * @type {String}
     */
    static UNIX_EPOCH_AHK => "19700101"
    
    /**
     * Creates and returns a MsgPackTimestamp for the current time. Nanoseconds are populated, but
     * are only accurate to 100-nanosecond intervals.
     */
    static Now(){
        static UNIX_EPOCH_AS_FILETIME := 116444736000000000

        ; 100-nanosecond intervals since January 1, 1601 UTC
        DllCall("GetSystemTimeAsFileTime", "uint64*", &ftCurrentTime := 0)
        nanoseconds := (ftCurrentTime - UNIX_EPOCH_AS_FILETIME) * 100

        return MsgPackTimestamp.FromAhkTimestamp(A_NowUTC, nanoseconds)
    }

    /**
     * Constructs a MsgPackTimestamp from an AutoHotkey Timestamp. Recall that MessagePack
     * timestamps use UTC time.
     * @param {String} timestamp the date and time in {@link https://www.autohotkey.com/docs/v2/lib/FileSetTime.htm#YYYYMMDD|YYYYMMDDHH24MISS format}
     * @param {Integer} nanoseconds the number of nanoseconds since Jan 1. 1970
     */
    static FromAhkTimestamp(timestamp, nanoseconds := 0){
        out := MsgPackTimestamp()
        out.seconds := DateDiff(timestamp, MsgPackTimestamp.UNIX_EPOCH_AHK, "Seconds")
        out.nanoseconds := nanoseconds

        return out
    }

    /**
     * Converts the timestamp to a {@link https://www.autohotkey.com/docs/v2/lib/FileSetTime.htm#YYYYMMDD|YYYYMMDDHH24MISS}
     * UTC timestamp. Note that this cannot include nanoseconds, so that information is lost.
     */
    ToAhkTimestamp(){
        return DateAdd(MsgPackTimestamp.UNIX_EPOCH_AHK, this.seconds, "Seconds")
    }

    /**
     * Encodes the timestamp to a MessagePack
     * @param {BinaryWriter} writer writer to write data to
     */
    MsgPackEncode(writer) {
        if(this.seconds >>> 34 == 0){
            data64 := (this.nanoseconds << 34) | this.seconds
            if (data64 & 0xffffffff00000000 == 0) {
                ; timestamp 32
                writer.WriteByte(MsgPackType.fixext4)
                BEWriter.WriteInt8(writer, -1)
                BEWriter.WriteUInt32(writer, data64)
            }
            else {
                ; timestamp 64
                writer.WriteByte(MsgPackType.fixext8)
                BEWriter.WriteInt8(writer, -1)
                BEWriter.WriteUInt64(writer, data64)
            }
        }
        else{
            ; timestamp 96
            writer.WriteByte(MsgPackType.ext8)
            BEWriter.WriteUInt8(writer, 12)
            BEWriter.WriteInt8(writer, -1)
            BEWriter.WriteUInt32(writer, this.nanoseconds)
            BEWriter.WriteInt64(writer, this.seconds)
        }
    }

    /**
     * Decodes the timestamp from MessagePack format
     * @param {BinaryReader} reader the reader to read data from
     * @param {Integer} length the number of bytes in the serialized data block
     */
    MsgPackDecode(reader, length) {
        switch length{
            case 4:
                this.nanoseconds := 0
                this.seconds := BEReader.ReadUInt32(reader)
            case 8:
                data64 := BEReader.ReadUInt64(reader)
                ; Literal bit shift, NOT logical - we'll almost always run into AHK-has-no-uint64 problems otherwise
                this.nanoseconds := data64 >>> 34 
                this.seconds := data64 & 0x00000003ffffffff
            case 12:
                this.nanoseconds := BEReader.ReadUInt32(reader)
                this.seconds := BEReader.ReadInt64(reader)
            default:
                throw ValueError("Invalid length for MessagePack Timestamp", , length)
        }
    }
}