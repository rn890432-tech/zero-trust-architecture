import React, { useState } from 'react';
import axios from 'axios';

export default function LoginPage({ setToken }) {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const res = await axios.post('/token', { username, password });
      setToken(res.data.access_token);
    } catch (err) {
      setError('Login failed');
    }
  };

  return (
    <div className="panel">
      <h3>Login</h3>
      <form onSubmit={handleSubmit}>
        <input type="text" value={username} onChange={e => setUsername(e.target.value)} placeholder="Username" />
        <input type="password" value={password} onChange={e => setPassword(e.target.value)} placeholder="Password" />
        <button type="submit">Login</button>
      </form>
      {error && <div>{error}</div>}
    </div>
  );
}
