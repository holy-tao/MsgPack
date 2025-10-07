#Requires AutoHotkey v2.0

#Include tests\PrimitiveDecodingTests.ahk
#Include YUnit\Yunit.ahk
#Include YUnit\JUnit.ahk
#Include YUnit\Stdout.ahk
#Include YUnit\ResultCounter.ahk

tester := Yunit.Use(YunitStdOut, YUnitJUnit, YunitResultCounter)
tester.Test(PrimitiveDecodingTests)

Exit(YunitResultCounter.failures > 0)