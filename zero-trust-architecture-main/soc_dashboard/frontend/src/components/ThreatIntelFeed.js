import React,{useEffect,useState} from "react";
import io from "socket.io-client";

const socket = io("http://localhost:8080");

export default function ThreatIntelFeed(){
 const [intel,setIntel] = useState([]);
 useEffect(()=>{
   socket.on("intel",(data)=>{
     setIntel(prev => [data,...prev]);
   });
 },[]);
 return(
 <div className="panel">
  <h3>Threat Intelligence Feed</h3>
  {intel.map((i,index)=>(
   <div key={index}>
     IP: {i.ip} | Reputation: {i.reputation}
   </div>
  ))}
 </div>
 );
}
