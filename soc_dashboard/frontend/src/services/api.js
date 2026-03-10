// Central API service for SOC dashboard
export async function fetchThreatIntel() {
  const resp = await fetch('/threat-intel');
  return resp.json();
}
export async function fetchAttackGraph() {
  const resp = await fetch('/attack-graph');
  return resp.json();
}
export async function fetchThreatFeed() {
  const resp = await fetch('/api/threat-feed');
  return resp.json();
}
export async function queryEndpointStatus(endpointId) {
  const resp = await fetch(`/api/endpoint/${endpointId}/status`);
  return resp.json();
}
export async function isolateEndpoint(endpointId) {
  const resp = await fetch(`/api/endpoint/${endpointId}/isolate`, { method: 'POST' });
  return resp.json();
}
export async function remediateEndpoint(endpointId) {
  const resp = await fetch(`/api/endpoint/${endpointId}/remediate`, { method: 'POST' });
  return resp.json();
}
export async function sendEventToSIEM(event) {
  const resp = await fetch('/api/siem', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(event)
  });
  return resp.json();
}
