package expo.modules.beacons

import android.Manifest
import android.content.Context
import android.os.Build
import android.util.Log
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import expo.modules.kotlin.Promise
import expo.modules.interfaces.permissions.Permissions

class ExpoBeaconsModule : Module() {
  // Each module class must implement the definition function. The definition consists of components
  // that describes the module's functionality and behavior.
  // See https://docs.expo.dev/modules/module-api for more details about available components.
  private var beaconScanner: BeaconScanner? = null

  private val bluetoothPermissions: Array<String> = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
    arrayOf(
      Manifest.permission.BLUETOOTH,
      Manifest.permission.BLUETOOTH_ADMIN,
      Manifest.permission.ACCESS_FINE_LOCATION,
      Manifest.permission.BLUETOOTH_SCAN,
      Manifest.permission.BLUETOOTH_CONNECT
    )
  } else {
    arrayOf(
      Manifest.permission.BLUETOOTH,
      Manifest.permission.BLUETOOTH_ADMIN,
      Manifest.permission.ACCESS_FINE_LOCATION
    )
  }

  override fun definition() = ModuleDefinition {
    // Sets the name of the module that JavaScript code will use to refer to the module. Takes a string as an argument.
    // Can be inferred from module's class name, but it's recommended to set it explicitly for clarity.
    // The module will be accessible from `requireNativeModule('ExpoBeacons')` in JavaScript.
    Name("ExpoBeacons")

    Events("onBeaconDetected")

    AsyncFunction("getPermissions") { promise: Promise ->
      Log.d("ExpoBeacons", "getting permissions")
      Permissions.getPermissionsWithPermissionsManager(
        appContext.permissions,
        promise,
        *bluetoothPermissions
      )
    }

    AsyncFunction("requestPermissions") { promise: Promise ->
      Log.d("ExpoBeacons", "Request permissions")
      Permissions.askForPermissionsWithPermissionsManager(
        appContext.permissions,
        promise,
        *bluetoothPermissions
      )
    }

    // Async functions to start and stop scanning
    AsyncFunction("startScanning") { uuids: Array<String>, eddystoneServiceUUID: String? ->
      print("Start scan")
      Log.d("ExpoBeacons", "Trying to start scan");
      if (beaconScanner == null) {
        Log.d("ExpoBeacons", "Initializing beacon scanner");
        beaconScanner = BeaconScanner(context)
//        beaconScanner = expo.modules.beacons.BeaconScanner(context, object : expo.modules.beacons.BeaconScanner.BeaconListener {
//          override fun onIBeaconDetected(beaconData: Map<String, Any>) {
//            Log.d("DetectedIBeacon", beaconData.toString())
//            sendEvent("onBeaconDetected", mapOf("type" to "iBeacon", "data" to beaconData))
//          }
//
//          override fun onEddystoneDetected(eddystoneData: Map<String, Any>) {
//            sendEvent("onBeaconDetected", mapOf("type" to "Eddystone", "data" to eddystoneData))
//          }
//        })
      }

      Log.d("ExpoBeacons", "Starting scan");
      beaconScanner?.startScan()
      Log.w("ExpoBeacons", "Scan started");
    }

    AsyncFunction("stopScanning") {
      beaconScanner?.stopScan()
    }
//    AsyncFunction("startScanning") { callback: (Any) -> Unit ->
//      beaconScanner.startScan(callback)
//    }

//    AsyncFunction("stopScanning") {
//      beaconScanner.stopScan()
//    }
//    Function("getTheme") {
//      return@Function "system"
//    }

    // Sets constant properties on the module. Can take a dictionary or a closure that returns a dictionary.
//    Constants(
//      "PI" to Math.PI
//    )

    // Defines event names that the module can send to JavaScript.
//    Events("onChange")

    // Defines a JavaScript synchronous function that runs the native code on the JavaScript thread.
//    Function("hello") {
//      "Hello world! 👋"
//    }

    // Defines a JavaScript function that always returns a Promise and whose native code
    // is by default dispatched on the different thread than the JavaScript runtime runs on.
//    AsyncFunction("setValueAsync") { value: String ->
//      // Send an event to JavaScript.
//      sendEvent("onChange", mapOf(
//        "value" to value
//      ))
//    }
  }

  val context: Context
    get() = requireNotNull(appContext.reactContext) { "React Application Context is null" }


}
