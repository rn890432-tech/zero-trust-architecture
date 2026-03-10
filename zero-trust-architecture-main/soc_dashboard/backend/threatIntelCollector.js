const axios = require("axios");

async function collectThreatIntel(){
 try{
  const response = await axios.get(
    "https://example-threat-feed.com/api/malicious_ips"
  );
  return response.data;
 }catch(err){
  console.log("Threat feed error:",err);
 }
}

module.exports = collectThreatIntel;
