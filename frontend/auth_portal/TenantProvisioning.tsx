import React, { useState } from 'react';

export default function TenantProvisioning() {
  const [company, setCompany] = useState('');
  const [email, setEmail] = useState('');
  const handleProvision = (e: React.FormEvent) => {
    e.preventDefault();
    // TODO: Call backend provisioning API
  };
  return (
    <form onSubmit={handleProvision}>
      <h2>Provision New Tenant</h2>
      <input type="text" value={company} onChange={e => setCompany(e.target.value)} placeholder="Company Name" required />
      <input type="email" value={email} onChange={e => setEmail(e.target.value)} placeholder="Admin Email" required />
      <button type="submit">Provision</button>
    </form>
  );
}
