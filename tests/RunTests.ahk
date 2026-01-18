#Requires AutoHotkey v2.0

#Include tests\PrimitiveDecoding.test.ahk
#Include tests\PrimitiveEncoding.test.ahk
#Include tests\EndToEnd.test.ahk
#Include tests\Timestamp.test.ahk
#Include tests\TypedObject.test.ahk

#Include YUnit\Yunit.ahk
#Include YUnit\JUnit.ahk
#Include YUnit\Stdout.ahk
#Include YUnit\ResultCounter.ahk

tester := Yunit.Use(YunitStdOut, YUnitJUnit, YunitResultCounter)
tester.Test(
    PrimitiveDecodingTests, 
    PrimitiveEncodingTests, 
    EndToEndTests, 
    TimestampEncodingDecodingTests, 
    TimestampFunctionalTests,
    TypedObjectTests
)

Exit(YunitResultCounter.failures > 0)