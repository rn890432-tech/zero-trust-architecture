import React, { useEffect, useState } from "react";
import { Line } from "react-chartjs-2";

function IncidentVsSLAChart() {
  const [data, setData] = useState([]);

  useEffect(() => {
    fetch("/api/incidents_vs_sla")
      .then(res => res.json())
      .then(setData);
  }, []);

  const labels = data.map(d => d.day);

  return (
    <div>
      <h2>Incident Volume vs SLA Breaches</h2>
      <Line
        data={{
          labels,
          datasets: [
            {
              label: "Incidents",
              data: data.map(d => d.incidents),
              borderColor: "blue",
              yAxisID: "y"
            },
            {
              label: "SLA Breaches",
              data: data.map(d => d.breaches),
              borderColor: "red",
              yAxisID: "y1"
            }
          ]
        }}
        options={{
          scales: {
            y: { type: "linear", position: "left" },
            y1: { type: "linear", position: "right" }
          }
        }}
      />
    </div>
  );
}

export default IncidentVsSLAChart;
