const network = require("./networkModel");

function simulateAttack(){
 const assets = network.getAssets();
 if(assets.length < 2) return;
 const attacker = assets[0];
 const target = assets[1];
 const simulation = {
  attacker:attacker.id,
  target:target.id,
  technique:"lateral_movement"
 };
 return simulation;
}
module.exports = simulateAttack;
