import React from 'react';
import DeliveryMetricsChart from '../components/DeliveryMetricsChart';
import ProviderStatusCards from '../components/ProviderStatusCards';
import AlertsPanel from '../components/AlertsPanel';
import WorkerHealthTable from '../components/WorkerHealthTable';

const ExecutiveView = () => (
  <div>
    <DeliveryMetricsChart />
    <ProviderStatusCards />
    <AlertsPanel />
    <WorkerHealthTable />
  </div>
);
export default ExecutiveView;
