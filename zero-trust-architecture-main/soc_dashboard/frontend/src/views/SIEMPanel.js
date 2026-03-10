import React, { useState } from 'react';
import { sendEventToSIEM } from '../services/api';

const SIEMPanel = () => {
  const [event, setEvent] = useState('{"type": "alert", "message": "Test event"}');
  const [result, setResult] = useState(null);

  const handleSend = async () => {
    try {
      const parsed = JSON.parse(event);
      setResult(await sendEventToSIEM(parsed));
    } catch (e) {
      setResult({ error: 'Invalid JSON' });
    }
  };

  return (
    <div>
      <h2>Send Event to SIEM</h2>
      <textarea
        rows={5}
        cols={50}
        value={event}
        onChange={e => setEvent(e.target.value)}
      />
      <br />
      <button onClick={handleSend}>Send Event</button>
      {result && (
        <div>
          <h4>Result</h4>
          <pre>{JSON.stringify(result, null, 2)}</pre>
        </div>
      )}
    </div>
  );
};

export default SIEMPanel;
