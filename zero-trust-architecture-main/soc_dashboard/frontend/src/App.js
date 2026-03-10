import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';

import AnalystView from './views/AnalystView';
import ExecutiveView from './views/ExecutiveView';
import ThreatIntelPanel from './views/ThreatIntelPanel';
import EndpointPanel from './views/EndpointPanel';
import SIEMPanel from './views/SIEMPanel';
import Sidebar from './components/Sidebar';
import SummaryCards from './components/SummaryCards';
import AlertNotification from './components/AlertNotification';

function App() {
  // Example metrics, replace with live data fetch
  const metrics = { alerts: 12, compliance: 85, risk: 0.72 };
  return (
    <Router>
      <div className="app-layout">
        <Sidebar />
        <div className="main-panel">
          <SummaryCards metrics={metrics} />
          <AlertNotification />
          <Routes>
            <Route path="/threat-intel" element={<ThreatIntelPanel />} />
            <Route path="/endpoint" element={<EndpointPanel />} />
            <Route path="/siem" element={<SIEMPanel />} />
            <Route path="/analyst" element={<AnalystView />} />
            <Route path="/executive" element={<ExecutiveView />} />
            <Route path="/" element={<AnalystView />} />
          </Routes>
        </div>
      </div>
    </Router>
  );
}
export default App;
