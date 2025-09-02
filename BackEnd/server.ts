import http from "http";
import { app } from "./app";

const port = process.env.PORT || 7777;
const server = http.createServer(app);

server.listen(port, () => {
  console.log(`Server is started on port ${port}`);
});

server.on("error", (error) => {
  console.error(error);
});
