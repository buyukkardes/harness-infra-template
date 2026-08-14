import { createServer } from "./server.js";

const PORT = Number(process.env.PORT) || 3000;

const server = createServer();

server.listen(PORT, () => {
  console.log(`Server listening on http://localhost:${PORT}`);
});
