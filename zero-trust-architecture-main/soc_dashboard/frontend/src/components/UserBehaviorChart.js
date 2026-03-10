import React from 'react';
import { Bar } from 'react-chartjs-2';

const UserBehaviorChart = ({ data }) => {
  const chartData = {
    labels: data.map(d => d.user),
    datasets: [
      {
        label: 'Actions',
        data: data.map(d => d.actions),
        backgroundColor: 'blue'
      }
    ]
  };
  return <Bar data={chartData} />;
};

export default UserBehaviorChart;
