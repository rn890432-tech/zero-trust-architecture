import React, { useState } from 'react';
import { queryEndpointStatus, isolateEndpoint, remediateEndpoint } from '../services/api';

const EndpointPanel = () => {
  const [endpointId, setEndpointId] = useState('');
  const [status, setStatus] = useState(null);
  const [actionResult, setActionResult] = useState(null);

  const handleQuery = async () => {
    setStatus(await queryEndpointStatus(endpointId));
    setActionResult(null);
  };
  const handleIsolate = async () => {
    setActionResult(await isolateEndpoint(endpointId));
  };
  const handleRemediate = async () => {
    setActionResult(await remediateEndpoint(endpointId));
  };

  return (
    <div>
      <h2>Endpoint Actions</h2>
      <input
        type="text"
        placeholder="Endpoint ID"
        value={endpointId}
        onChange={e => setEndpointId(e.target.value)}
      />
      <button onClick={handleQuery}>Query Status</button>
      <button onClick={handleIsolate}>Isolate</button>
      <button onClick={handleRemediate}>Remediate</button>
      {status && (
        <div>
          <h4>Status</h4>
          <pre>{JSON.stringify(status, null, 2)}</pre>
        </div>
      )}
      {actionResult && (
        <div>
          <h4>Action Result</h4>
          <pre>{JSON.stringify(actionResult, null, 2)}</pre>
        </div>
      )}
    </div>
  );
};

export default EndpointPanel;
