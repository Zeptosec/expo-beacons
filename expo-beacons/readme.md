# Expo beacons
IBeacon scanner iOS platform in expo projects. Many other libraries work for android, but i couldn't get them to work with iOS. This package helps to get detect if beacon by specified regions is in range or not. That's it.
```js
import * as Beacons from 'expo-beacons';

async function start() {
    // req permissions
    const perms = await Beacons.requestPermissionsAsync();
    console.log(perms);

    await Beacons.startScanning(["16967031-4a76-9c35-886d-000050000035"]);
    console.log("started scan");
    const listener = Beacons.addBeaconListener((event) => {
        console.log(event.data);
    })
}
```