import React from 'react';
import { Bar } from 'react-chartjs-2';

const ComplianceStatusChart = ({ data }) => {
  const chartData = {
    labels: data.map(d => d.policy),
    datasets: [
      {
        label: 'Compliance',
        data: data.map(d => d.status === 'pass' ? 1 : 0),
        backgroundColor: data.map(d => d.status === 'pass' ? 'green' : 'red')
      }
    ]
  };
  return <Bar data={chartData} />;
};

export default ComplianceStatusChart;
