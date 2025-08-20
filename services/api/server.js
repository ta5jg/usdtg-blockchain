
import express from 'express';import cors from 'cors';import bodyParser from 'body-parser';import dotenv from 'dotenv';import { v4 as uuidv4 } from 'uuid';import nodemailer from 'nodemailer';dotenv.config();
const app=express();app.use(cors({origin:process.env.ALLOW_ORIGIN||'*'}));app.use(bodyParser.json());
const orders=new Map();
const mailer = process.env.SMTP_URL ? nodemailer.createTransport(process.env.SMTP_URL) : null;
async function notify(subject, text){
  try{ if(!mailer) return; await mailer.sendMail({from:process.env.MAIL_FROM,to:process.env.MAIL_TO,subject,text}); }catch{}
}
app.get('/health',(req,res)=>res.json({ok:true, service:'usdtg-api'}));
app.post('/purchase', async (req,res)=>{
  const { address, amount, currency } = req.body||{};
  if(!address||!amount) return res.status(400).json({ok:false,error:'address & amount required'});
  const id = uuidv4(); const order={id, address, amount, currency:currency||'USDT', status:'PENDING', created:Date.now()};
  orders.set(id, order); await notify('USDTg order created', JSON.stringify(order));
  return res.json({ok:true, invoiceId:id, status:order.status});
});
app.post('/webhook/payment', async (req,res)=>{
  const { invoiceId, status } = req.body||{}; if(!orders.has(invoiceId)) return res.status(404).json({ok:false});
  const o=orders.get(invoiceId); o.status=status||'PAID'; orders.set(invoiceId,o); await notify('USDTg order updated', JSON.stringify(o));
  return res.json({ok:true});
});
app.get('/order/:id',(req,res)=>{ const o=orders.get(req.params.id); if(!o) return res.status(404).json({ok:false}); res.json({ok:true, order:o}); });
app.listen(process.env.PORT||8080,()=>console.log('API up'));
