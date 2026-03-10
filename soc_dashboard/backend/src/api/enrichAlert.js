const lookupIP = require('../../threatIntel/intelEngine');

async function processAlert(alert){
 const intel = lookupIP(alert.ip);
 alert.threatIntel = intel;
 return alert;
}

module.exports = processAlert;
