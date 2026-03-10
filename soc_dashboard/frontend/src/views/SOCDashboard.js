import React from 'react';
import QueueGauge from '../components/QueueGauge';
import WorkerHealthTable from '../components/WorkerHealthTable';
import DeliveryMetricsChart from '../components/DeliveryMetricsChart';
import ProviderStatusCards from '../components/ProviderStatusCards';
import AlertsPanel from '../components/AlertsPanel';

export default function SOCDashboard() {
  return (
    <div>
      <QueueGauge />
      <WorkerHealthTable />
      <DeliveryMetricsChart />
      <ProviderStatusCards />
      <AlertsPanel />
    </div>
  );
}
