import React from 'react';
import EventTimeline from '../components/EventTimeline';
import QueueGauge from '../components/QueueGauge';
import WorkerHealthTable from '../components/WorkerHealthTable';
import DeliveryMetricsChart from '../components/DeliveryMetricsChart';
import ProviderStatusCards from '../components/ProviderStatusCards';
import AlertsPanel from '../components/AlertsPanel';
import DrilldownDetails from '../components/DrilldownDetails';
import SearchBar from '../components/SearchBar';
import RoleSelector from '../components/RoleSelector';

const AnalystView = () => (
  <div>
    <SearchBar />
    <RoleSelector />
    <EventTimeline />
    <QueueGauge />
    <WorkerHealthTable />
    <DeliveryMetricsChart />
    <ProviderStatusCards />
    <AlertsPanel />
    <DrilldownDetails />
  </div>
);
export default AnalystView;
