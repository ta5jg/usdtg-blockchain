
import express from 'express'; import axios from 'axios'; import dotenv from 'dotenv'; dotenv.config();
const app = express();
const windowSize = Number(process.env.WINDOW || 12); // samples
const series = [];
function pushSample(x){ series.push(x); while(series.length>windowSize){ series.shift(); } }
function avg(arr){ if(!arr.length) return Number(process.env.FALLBACK || 1); return arr.reduce((a,b)=>a+b,0)/arr.length }
async function fetchSources(){
  const urls = (process.env.SOURCES||'').split(',').map(s=>s.trim()).filter(Boolean);
  const prices = [];
  for (const u of urls){
    try{
      const r = await axios.get(u, { timeout: 3000 });
      // naive extraction for common schemas
      const d = r.data;
      if (d.price) prices.push(Number(d.price));
      else if (d.tick && d.tick.close) prices.push(Number(d.tick.close));
      else if (d.data && d.data.price) prices.push(Number(d.data.price));
    }catch{}
  }
  return prices;
}
setInterval(async ()=>{
  const ps = await fetchSources();
  if (ps.length){ pushSample(avg(ps)); }
}, 5000);
app.get('/price', async (req,res)=>{
  const ps = await fetchSources();
  const point = ps.length ? avg(ps) : Number(process.env.FALLBACK || 1);
  pushSample(point);
  res.json({ ok:true, price: avg(series), samples: series.length });
});
app.listen(process.env.PORT||8090, ()=> console.log('Oracle up'));
