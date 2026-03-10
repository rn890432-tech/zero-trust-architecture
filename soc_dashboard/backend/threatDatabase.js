let threatDB = [];

function updateThreats(data){
 threatDB = data;
}

function lookupIP(ip){
 return threatDB.find(entry => entry.ip === ip);
}

module.exports = {updateThreats,lookupIP};
