import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'
import fs from 'fs'

// Plugin to serve the shared SQLite DB from the root 'data' directory
const serveSharedDbPlugin = () => ({
  name: 'serve-shared-db',
  configureServer(server) {
    server.middlewares.use('/public_reports.db', (req, res) => {
      const dbPath = path.resolve(__dirname, '../data/public_reports.db');
      
      if (fs.existsSync(dbPath)) {
        const stat = fs.statSync(dbPath);
        res.writeHead(200, {
          'Content-Type': 'application/vnd.sqlite3',
          'Content-Length': stat.size,
          'Access-Control-Allow-Origin': '*'
        });
        fs.createReadStream(dbPath).pipe(res);
      } else {
        res.writeHead(404);
        res.end();
      }
    });
  }
});

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react(), serveSharedDbPlugin()],
  server: {
    fs: {
      // Allow serving files from one level up to access the data folder
      allow: ['..']
    }
  }
})
