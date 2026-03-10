import React from 'react';
import { Line } from 'react-chartjs-2';

const IncidentTrendChart = ({ data }) => {
  const chartData = {
    labels: data.map(d => d.date),
    datasets: [
      {
        label: 'Incident Count',
        data: data.map(d => d.count),
        fill: false,
        borderColor: 'rgb(75, 192, 192)',
        tension: 0.1
      }
    ]
  };
  return <Line data={chartData} />;
};

export default IncidentTrendChart;
