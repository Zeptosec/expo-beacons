const { withAndroidManifest, withInfoPlist } = require('@expo/config-plugins');

const withAndroidPermissions = (config) => {
  return withAndroidManifest(config, (config) => {
    config.modResults = setCustomPermissions(config.modResults);
    return config;
  });
};

const withIosPermissions = (config, { bluetoothAlwaysPermission, locationAlwaysPermission, locationWhenInUsePermission } = {}) => {
  return withInfoPlist(config, (config) => {
    config.modResults.NSBluetoothAlwaysUsageDescription =
      bluetoothAlwaysPermission ||
      config.modResults.NSBluetoothAlwaysUsageDescription ||
      'Allow $(PRODUCT_NAME) to use Bluetooth';

    config.modResults.NSLocationAlwaysAndWhenInUseUsageDescription =
      locationAlwaysPermission ||
      config.modResults.NSLocationAlwaysAndWhenInUseUsageDescription ||
      'Allow $(PRODUCT_NAME) to use location to detect beacons';

    config.modResults.NSLocationWhenInUseUsageDescription =
      locationWhenInUsePermission ||
      config.modResults.NSLocationWhenInUseUsageDescription ||
      'Allow $(PRODUCT_NAME) to use location to detect beacons';

    return config;
  });
};

function setCustomPermissions(androidManifest) {
  const permissions = [
    'android.permission.BLUETOOTH',
    'android.permission.BLUETOOTH_ADMIN',
    'android.permission.BLUETOOTH_CONNECT',
    'android.permission.BLUETOOTH_SCAN',
    'android.permission.ACCESS_FINE_LOCATION',
  ];

  if (!androidManifest.manifest['uses-permission']) {
    androidManifest.manifest['uses-permission'] = [];
  }

  for (const permission of permissions) {
    if (
      !androidManifest.manifest['uses-permission'].some(
        (e) => e.$['android:name'] === permission
      )
    ) {
      androidManifest.manifest.push({
        $: { 'android:name': permission },
      });
    }
  }

  return androidManifest;
}

module.exports = (config, props) => {
  config = withAndroidPermissions(config);
  config = withIosPermissions(config, props);
  return config;
};

