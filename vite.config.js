import { defineConfig } from 'vite';

export default defineConfig({
  build: {
    outDir: 'public-modern',
    rollupOptions: {
      input: {
        app: 'modern/main.js'
      },
      output: {
        entryFileNames: 'javascripts/rbs.modern.js',
        assetFileNames: (assetInfo) => {
          if (assetInfo.name && assetInfo.name.endsWith('.css')) return 'stylesheets/rbs.modern.css';
          return 'assets/[name]-[hash][extname]';
        }
      }
    }
  }
});
