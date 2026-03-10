import React, { useEffect, useState } from 'react';
import { fetchThreatActorAttribution } from '../services/api';

const ThreatActorAttributionPanel = () => {
  const [actors, setActors] = useState([]);
  useEffect(() => {
    fetchThreatActorAttribution().then(data => setActors(data));
  }, []);
  return (
    <div>
      <h2>Threat Actor Attribution</h2>
      <ul>
        {actors.map((actor, idx) => (
          <li key={idx}>{actor.name} - {actor.profile}</li>
        ))}
      </ul>
    </div>
  );
};

export default ThreatActorAttributionPanel;
