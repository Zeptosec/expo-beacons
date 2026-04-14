import React from 'react';
import { Platform, StyleSheet, Text, View } from 'react-native';
import { DetectedBeacons } from '../hooks/useDetectedBeacons';
import { useTimeAgo } from '../hooks/useTimeAgo';

interface BeaconInfoProps {
  detectedBeacon: DetectedBeacons;
}

export default function BeaconInfo({ detectedBeacon }: BeaconInfoProps) {
  const { beacon, lastSeen } = detectedBeacon;
  const timeAgo = useTimeAgo(lastSeen);

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.type}>{beacon.type.toUpperCase()}</Text>
        <Text style={styles.name}>{beacon.name || 'Unknown name'}</Text>
      </View>

      <View style={styles.row}>
        <View style={styles.stat}>
          <Text style={styles.label}>RSSI</Text>
          <Text style={styles.value}>{beacon.rssi} dBm</Text>
        </View>
        <View style={styles.stat}>
          <Text style={styles.label}>TX POWER</Text>
          <Text style={styles.value}>{beacon.txPower} dBm</Text>
        </View>
        <View style={styles.stat}>
          <Text style={styles.label}>LAST SEEN</Text>
          <Text style={styles.value}>{timeAgo}</Text>
        </View>
      </View>

      <View style={styles.details}>
        <Text style={styles.label}>UUID / ID</Text>
        <Text style={styles.idText}>{beacon.uuid}</Text>
      </View>

      {beacon.type === 'iBeacon' && (
        <View style={styles.row}>
          <View style={styles.stat}>
            <Text style={styles.label}>MAJOR</Text>
            <Text style={styles.value}>{beacon.major}</Text>
          </View>
          <View style={styles.stat}>
            <Text style={styles.label}>MINOR</Text>
            <Text style={styles.value}>{beacon.minor}</Text>
          </View>
        </View>
      )}

      {beacon.type === 'eddystone' && (
        <View style={styles.row}>
          <View style={styles.stat}>
            <Text style={styles.label}>NAMESPACE</Text>
            <Text style={styles.value}>{beacon.namespace}</Text>
          </View>
          <View style={styles.stat}>
            <Text style={styles.label}>INSTANCE</Text>
            <Text style={styles.value}>{beacon.instance}</Text>
          </View>
        </View>
      )}

      <View style={styles.adHexContainer}>
        <Text style={styles.label}>ADVERTISEMENT DATA (HEX)</Text>
        <Text style={styles.adHexText}>{beacon.adHex}</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: '#f8f9fa',
    borderRadius: 8,
    padding: 12,
    marginVertical: 6,
    borderWidth: 1,
    borderColor: '#e9ecef',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  type: {
    fontSize: 10,
    fontWeight: 'bold',
    color: '#fff',
    backgroundColor: '#007bff',
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
  },
  name: {
    fontSize: 14,
    fontWeight: '600',
    color: '#212529',
  },
  row: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 8,
  },
  stat: {
    flex: 1,
  },
  label: {
    fontSize: 10,
    color: '#6c757d',
    marginBottom: 2,
    fontWeight: '500',
  },
  value: {
    fontSize: 12,
    color: '#343a40',
    fontWeight: '600',
  },
  details: {
    marginBottom: 8,
  },
  idText: {
    fontSize: 11,
    fontFamily: Platform.OS === 'ios' ? 'Courier' : 'monospace',
    color: '#495057',
  },
  adHexContainer: {
    backgroundColor: '#e9ecef',
    padding: 6,
    borderRadius: 4,
  },
  adHexText: {
    fontSize: 9,
    fontFamily: Platform.OS === 'ios' ? 'Courier' : 'monospace',
    color: '#6c757d',
  },
});
