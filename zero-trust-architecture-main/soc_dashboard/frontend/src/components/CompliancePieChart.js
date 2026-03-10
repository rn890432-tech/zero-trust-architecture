import React from 'react';
import { Pie } from 'react-chartjs-2';

const CompliancePieChart = ({ data }) => {
  const passCount = data.filter(d => d.status === 'pass').length;
  const failCount = data.filter(d => d.status === 'fail').length;
  const chartData = {
    labels: ['Pass', 'Fail'],
    datasets: [
      {
        data: [passCount, failCount],
        backgroundColor: ['green', 'red']
      }
    ]
  };
  return <Pie data={chartData} />;
};

export default CompliancePieChart;
