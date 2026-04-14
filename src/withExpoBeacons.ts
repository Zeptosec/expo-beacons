import {
  ConfigPlugin,
  withAndroidManifest,
  AndroidConfig,
} from '@expo/config-plugins';

const withAndroidPermissions: ConfigPlugin = (config) => {
  return withAndroidManifest(config, async (config) => {
    config.modResults = await setCustomPermissions(config.modResults);
    return config;
  });
};

async function setCustomPermissions(
  androidManifest: AndroidConfig.Manifest.AndroidManifest
) {
  const permissions = [
    'android.permission.BLUETOOTH',
    'android.permission.BLUETOOTH_ADMIN',
    'android.permission.BLUETOOTH_CONNECT',
    'android.permission.BLUETOOTH_SCAN',
    'android.permission.ACCESS_COARSE_LOCATION',
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
      androidManifest.manifest['uses-permission'].push({
        $: { 'android:name': permission },
      });
    }
  }

  return androidManifest;
}

const withExpoBeacons: ConfigPlugin = (config) => {
  return withAndroidPermissions(config);
};

export default withExpoBeacons;
