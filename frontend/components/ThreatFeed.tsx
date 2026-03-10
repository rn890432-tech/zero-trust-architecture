import React, { useEffect, useState } from 'react';

const ThreatFeed = () => {
  const [feeds, setFeeds] = useState<any>({});

  useEffect(() => {
    // Fetch threat intelligence feeds from backend
    fetch('/api/threat_feeds')
      .then(res => res.json())
      .then(data => setFeeds(data));
  }, []);

  return (
    <div>
      <h2>Threat Intelligence Feed</h2>
      <pre>{JSON.stringify(feeds, null, 2)}</pre>
    </div>
  );
};

export default ThreatFeed;
