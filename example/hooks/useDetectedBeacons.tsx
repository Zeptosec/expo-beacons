import ExpoBeacons, { Beacon } from "expo-beacons";
import { useCallback, useEffect, useRef, useState } from "react";

export type DetectedBeacons = {
  beacon: Beacon;
  lastSeen: number;
}

export default function useDetectedBeacons() {
  const beaconsRef = useRef<Map<string, DetectedBeacons>>(new Map());
  const [beacons, setBeacons] = useState<DetectedBeacons[]>([]);

  const clearBeacons = useCallback(() => {
    beaconsRef.current.clear();
    setBeacons([]);
  }, [])

  useEffect(() => {
    const listener = ExpoBeacons.addListener("onBeaconDetected", data => {
      beaconsRef.current.set(data.uuid, {
        beacon: data,
        lastSeen: Date.now(),
      });
    });

    const interval = setInterval(() => {
      setBeacons(Array.from(beaconsRef.current.values()));
    }, 1000);

    return () => {
      listener.remove();
      clearInterval(interval);
    }
  }, [])

  return {
    beacons,
    clearBeacons
  }
}