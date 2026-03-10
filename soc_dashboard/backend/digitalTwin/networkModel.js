class NetworkModel {
 constructor(){
  this.assets = [];
 }
 addAsset(asset){
  this.assets.push(asset);
 }
 getAssets(){
  return this.assets;
 }
}
module.exports = new NetworkModel();
