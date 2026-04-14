package expo.modules.beacons.modules

data class IBeacon(
    override val uuid: String,
    val address: String,
    val name: String?,
    val major: Int,
    val minor: Int,
    val rssi: Int,
    val txPower: Int,
    val adHex: String,
    val battery: Int?
): Beacon {

    override fun toMap(): Map<String, Any?> = mapOf(
        "type" to "iBeacon",
        "address" to address,
        "name" to name,
        "uuid" to uuid,
        "major" to major,
        "minor" to minor,
        "rssi" to rssi,
        "txPower" to txPower,
        "adHex" to adHex,
        "battery" to battery
    )
}