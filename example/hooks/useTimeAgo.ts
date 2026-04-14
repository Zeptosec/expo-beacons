import { useEffect, useState } from 'react';

export function useTimeAgo(timestamp: number) {
  const [secondsAgo, setSecondsAgo] = useState(Math.floor((Date.now() - timestamp) / 1000));

  useEffect(() => {
    // Initial sync
    setSecondsAgo(Math.floor((Date.now() - timestamp) / 1000));

    const interval = setInterval(() => {
      setSecondsAgo(Math.floor((Date.now() - timestamp) / 1000));
    }, 1000);

    return () => clearInterval(interval);
  }, [timestamp]);

  if (secondsAgo < 0) return 'Just now';
  if (secondsAgo < 60) return `${secondsAgo}s ago`;
  
  const minutes = Math.floor(secondsAgo / 60);
  if (minutes < 60) return `${minutes}m ago`;
  
  const hours = Math.floor(minutes / 60);
  return `${hours}h ago`;
}
