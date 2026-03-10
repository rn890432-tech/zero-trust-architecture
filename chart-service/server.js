import express from "express";
import { ChartJSNodeCanvas } from "chartjs-node-canvas";

const app = express();
app.use(express.json());

const canvas = new ChartJSNodeCanvas({ width: 800, height: 400 });

app.post("/render", async (req, res) => {
  const config = req.body.config;
  const buffer = await canvas.renderToBuffer(config);
  res.json({ image_base64: buffer.toString("base64") });
});

app.listen(3000, () => console.log("Chart service running on port 3000"));
