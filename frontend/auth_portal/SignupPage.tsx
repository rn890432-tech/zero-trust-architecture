import React, { useState } from 'react';

export default function SignupPage() {
  const [email, setEmail] = useState('');
  const [company, setCompany] = useState('');
  const [password, setPassword] = useState('');
  const handleSignup = (e: React.FormEvent) => {
    e.preventDefault();
    // TODO: Call backend signup API
  };
  return (
    <form onSubmit={handleSignup}>
      <h2>Sign Up</h2>
      <input type="text" value={company} onChange={e => setCompany(e.target.value)} placeholder="Company Name" required />
      <input type="email" value={email} onChange={e => setEmail(e.target.value)} placeholder="Email" required />
      <input type="password" value={password} onChange={e => setPassword(e.target.value)} placeholder="Password" required />
      <button type="submit">Sign Up</button>
    </form>
  );
}
