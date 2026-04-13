import IOKit.pwr_mgt

enum PowerManager {

    private static var assertionID: IOPMAssertionID = IOPMAssertionID(0)
    private static var assertionActive = false

    static func disableSleep() {
        guard !assertionActive else { return }
        let reason = "CatLock: keyboard locked, preventing sleep" as CFString
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &assertionID
        )
        if result == kIOReturnSuccess {
            assertionActive = true
        }
    }

    static func restoreSleep() {
        guard assertionActive else { return }
        IOPMAssertionRelease(assertionID)
        assertionActive = false
    }
}
