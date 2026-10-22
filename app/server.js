const http = require("http");
const fs = require("fs");
const path = require("path");

const port = process.env.PORT || 8080;
const indexFile = path.join(__dirname, "public", "index.html");

const server = http.createServer((request, response) => {
  if (request.url === "/health") {
    response.writeHead(200, { "Content-Type": "application/json" });
    response.end(JSON.stringify({ status: "healthy" }));
    return;
  }

  if (request.url === "/") {
    fs.readFile(indexFile, (error, content) => {
      if (error) {
        response.writeHead(500, { "Content-Type": "text/plain" });
        response.end("Application page could not be loaded.");
        return;
      }

      response.writeHead(200, { "Content-Type": "text/html" });
      response.end(content);
    });
    return;
  }

  response.writeHead(404, { "Content-Type": "text/plain" });
  response.end("Not found");
});

server.listen(port, () => {
  console.log(`SRE GitOps lab app listening on port ${port}`);
});
