import React,{useEffect,useState} from "react";
import io from "socket.io-client";

const socket = io("http://localhost:8080");

export default function GlobalThreatFeed(){
 const [feeds,setFeeds] = useState([]);
 useEffect(()=>{
  socket.on("globalThreat",(data)=>{
   setFeeds(prev => [data,...prev]);
  });
 },[]);
 return(
 <div className="panel">
  <h3>Global Threat Intelligence</h3>
  {feeds.map((f,i)=>(
   <div key={i}>
     {f.ip} | {f.campaign} | {f.reputation}
   </div>
  ))}
 </div>
 );
}
