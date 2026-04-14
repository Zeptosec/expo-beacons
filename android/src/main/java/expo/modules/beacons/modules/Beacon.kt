package expo.modules.beacons.modules

interface Beacon {
    val uuid: String
    fun toMap(): Map<String, Any?>
}