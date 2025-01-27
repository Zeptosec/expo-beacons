# Expo beacons
IBeacon and Eddystone scanner for **iOS platform** in expo projects. Many other libraries work for android, but i couldn't get them to work with iOS. This package is for detecting iBeacons in specified regions and Eddystones.

# Install
```sh
npx expo install expo-beacons
```

# Example
```js
import * as Beacons from 'expo-beacons';

useEffect(() => {
    async function start() {
      // request permissions for scanning beacons
      const granted = await Beacons.requestPermissionsAsync();

      if (!granted) {
        console.log("Permission for scanning was not granted!");
        return;
      }

      // if permissions were granted start the scan
      await Beacons.startScanning([]);
    }

    start()

    // listen for detected beacons
    const listener = Beacons.addBeaconListener(({ data }) => {
      if ("namespace" in data) {
        // detected eddystone
        console.log("Eddystone: ", data)
      } else if ("major" in data) {
        //detected ibeacon
        console.log("iBeacon: ", data)
      }
    });

    // restart eddystone scanning for consistent detection intervals
    const restartInterval = setInterval(Beacons.restartScanning, 60 * 1000);

    return () => {
      listener.remove();
      clearInterval(restartInterval)
    }
}, [])

function updateIBeaconRegions(uuids: string[]) {
    // update iBeacon monitored regions
    Beacons.updateMonitoredRegions(uuids);
}

async function stopScanning(){
    await Beacons.stopScanning();
}
```

# Develop
Сlone the repository, then `cd expo-beacons`. Here run `npm run build` then open another terminal and `cd expo-beacons/example` and run `npm start`. After that open another terminal and `xed expo-beacons/example/ios` and run the project on physical device from Xcode.