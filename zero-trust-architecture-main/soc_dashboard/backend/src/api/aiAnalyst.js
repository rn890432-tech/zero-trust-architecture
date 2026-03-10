async function analyzeAlert(alert){
 // Example: risk scoring based on threat intel
 let score = 0;
 if(alert.threatIntel.reputation === 'malicious') score += 80;
 if(alert.threatIntel.tags.includes('botnet')) score += 10;
 if(alert.threatIntel.tags.includes('phishing')) score += 5;
 return {
   alert,
   riskScore: score,
   notes: `AI Analyst: Risk score ${score}`
 };
}

module.exports = analyzeAlert;
