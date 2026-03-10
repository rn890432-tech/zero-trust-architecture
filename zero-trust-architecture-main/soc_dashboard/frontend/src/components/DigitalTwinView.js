import React,{useEffect,useState} from "react";
import ForceGraph2D from "react-force-graph-2d";

export default function DigitalTwinView(){
 const [graph,setGraph] = useState({
  nodes:[
   {id:"workstation01"},
   {id:"webserver01"},
   {id:"database01"}
  ],
  links:[
   {source:"workstation01",target:"webserver01"},
   {source:"webserver01",target:"database01"}
  ]
 });
 return(
  <div className="panel">
   <h3>Cyber Digital Twin Network</h3>
   <ForceGraph2D graphData={graph}/>
  </div>
 );
}
