const threatDB = {
 "185.22.10.5":{
   reputation:"malicious",
   tags:["botnet","malware"],
   campaign:"DarkHydra"
 },
 "91.210.14.2":{
   reputation:"suspicious",
   tags:["phishing"]
 }
}

function lookupIP(ip){
 if(threatDB[ip]){
   return threatDB[ip]
 }
 return {
  reputation:"unknown",
  tags:[]
 }
}

module.exports = lookupIP;
