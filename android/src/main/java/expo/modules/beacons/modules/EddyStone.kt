package expo.modules.beacons.modules

data class EddyStone(
    override val uuid: String,
    val address: String,
    val name: String?,
    val namespace: String,
    val instance: String,
    val rssi: Int,
    val txPower: Int,
    val adHex: String,
) : Beacon {
    override fun toMap(): Map<String, Any?> = mapOf(
        "type" to "eddystone",
        "address" to address,
        "uuid" to uuid,
        "name" to name,
        "namespace" to namespace,
        "instance" to instance,
        "rssi" to rssi,
        "txPower" to txPower,
        "adHex" to adHex,
    )
}
