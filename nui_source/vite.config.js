import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { resolve } from 'node:path'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  base: './',
  build: {
    // Output straight into the resource, with fixed names to match fxmanifest.lua.
    outDir: '../dist',
    emptyOutDir: true,
    rollupOptions: {
      // index.html is the /duty panel, tablet.html the yecoyz_tablet app.
      input: {
        index: resolve(__dirname, 'index.html'),
        tablet: resolve(__dirname, 'tablet.html'),
      },
      output: {
        entryFileNames: 'assets/[name].js',
        chunkFileNames: 'assets/[name].js',
        assetFileNames: 'assets/[name][extname]',
      },
    },
  },
  server: {
    host: '127.0.0.1',
    port: 5173
  }
})
