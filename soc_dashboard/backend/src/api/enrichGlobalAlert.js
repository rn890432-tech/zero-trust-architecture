const {lookupIP} = require('../../threatDatabase');

function enrichAlert(alert){
 const intel = lookupIP(alert.ip);
 if(intel){
  alert.globalThreat = intel;
 }
 return alert;
}

module.exports = enrichAlert;
