import React from 'react';
import { Link } from 'react-router-dom';

const Sidebar = () => (
  <div className="sidebar">
    <ul>
      <li><Link to="/threat-intel">Threat Intelligence</Link></li>
      <li><Link to="/endpoint">Endpoint Actions</Link></li>
      <li><Link to="/siem">SIEM Event</Link></li>
      <li><Link to="/analyst">Analyst View</Link></li>
      <li><Link to="/executive">Executive View</Link></li>
    </ul>
  </div>
);

export default Sidebar;
