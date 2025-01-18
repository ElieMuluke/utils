#!/bin/bash

# Function to prompt the user for confirmation
confirm() {
    read -r -p "$1 [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY])
            true
            ;;
        *)
            false
            ;;
    esac
}

# Function to detect if the project uses TypeScript
uses_typescript() {
    if [ -f "tsconfig.json" ] || [ -n "$(find src -name '*.ts' -o -name '*.tsx')" ]; then
        return 0
    else
        return 1
    fi
}

# Step 1: Uninstall react-scripts
if confirm "Do you want to uninstall react-scripts?"; then
    if [ -f "yarn.lock" ]; then
        yarn remove react-scripts
    else
        npm uninstall react-scripts
    fi
    echo "react-scripts uninstalled."
else
    echo "Skipping uninstallation of react-scripts."
fi

# Step 2: Install Vite and necessary plugins
if confirm "Do you want to install Vite and necessary plugins?"; then
    if [ -f "yarn.lock" ]; then
        yarn add --dev vite @vitejs/plugin-react vite-tsconfig-paths vite-plugin-svgr
    else
        npm install --save-dev vite @vitejs/plugin-react vite-tsconfig-paths vite-plugin-svgr
    fi
    echo "Vite and plugins installed."
else
    echo "Skipping installation of Vite and plugins."
fi

# Step 3: Create vite.config.mjs
if confirm "Do you want to create vite.config.mjs?"; then
    cat <<EOL > vite.config.mjs
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import tsconfigPaths from 'vite-tsconfig-paths';
import svgr from 'vite-plugin-svgr';

export default defineConfig({
  plugins: [
    react(),
    tsconfigPaths(),
    svgr({
      include: '**/*.svg',
    }),
  ],
  build: {
    outDir: 'build',
  },
  server: {
    open: true,
    port: 3000,
  },
  resolve: {
    alias: {
      // Define your path aliases here
    },
  },
});
EOL
    echo "vite.config.mjs created."
else
    echo "Skipping creation of vite.config.mjs."
fi

# Step 4: Move index.html to root directory
if confirm "Do you want to move index.html to the root directory?"; then
    if [ -f "public/index.html" ]; then
        mv public/index.html .
        echo "index.html moved to root directory."
    else
        echo "public/index.html not found. Skipping."
    fi
else
    echo "Skipping moving of index.html."
fi

# Step 5: Update index.html
if confirm "Do you want to update index.html?"; then
    if [ -f "index.html" ]; then
        sed -i.bak 's|%PUBLIC_URL%|/|g' index.html
        # Determine the correct entry point
        if [ -f "src/index.tsx" ]; then
            entry_point="src/index.tsx"
        elif [ -f "src/index.jsx" ]; then
            entry_point="src/index.jsx"
        elif [ -f "src/index.ts" ]; then
            entry_point="src/index.ts"
        elif [ -f "src/index.js" ]; then
            entry_point="src/index.js"
        else
            echo "No entry point found. Please ensure you have an index.js, index.jsx, index.ts, or index.tsx file in the src directory."
            exit 1
        fi
        sed -i.bak "/<div id=\"root\"><\/div>/a\\
    <script type=\"module\" src=\"/$entry_point\"></script>" index.html
        rm index.html.bak
        echo "index.html updated."
    else
        echo "index.html not found in the root directory. Skipping."
    fi
else
    echo "Skipping update of index.html."
fi

# Step 6: Rename entry files
if confirm "Do you want to rename entry files?"; then
    if [ -f "src/index.js" ]; then
        mv src/index.js src/index.jsx
        echo "Renamed src/index.js to src/index.jsx."
    elif [ -f "src/index.ts" ]; then
        mv src/index.ts src/index.tsx
        echo "Renamed src/index.ts to src/index.tsx."
    else
        echo "No index.js or index.ts found. Skipping."
    fi

    if [ -f "src/App.js" ]; then
        mv src/App.js src/App.jsx
        echo "Renamed src/App.js to src/App.jsx."
    elif [ -f "src/App.ts" ]; then
        mv src/App.ts src/App.tsx
        echo "Renamed src/App.ts to src/App.tsx."
    else
        echo "No App.js or App.ts found. Skipping."
    fi
else
    echo "Skipping renaming of entry files."
fi

# Step 7: Update or create tsconfig.json for TypeScript projects
if uses_typescript; then
    if confirm "Do you want to update or create tsconfig.json?"; then
        cat <<EOL > tsconfig.json
{
  "compilerOptions": {
    "target": "ESNext",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": false,
    "skipLibCheck": true,
    "esModuleInterop": true,
    "allowSyntheticDefaultImports": true,
    "strict": true,
    "forceConsistentCasingInFileNames": true,
    "module": "esnext",
    "moduleResolution": "node",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "noFallthroughCasesInSwitch": true,
    "jsx": "react-jsx",
    "types": ["vite/client", "vite-plugin-svgr/client"]
  },
  "include": ["src"]
}
EOL
        echo "tsconfig.json updated or created."
    else
        echo "Skipping update or creation of tsconfig.json."
    fi
else
    echo "TypeScript not detected. Skipping tsconfig.json update."
fi

# Step 8: Update package.json scripts
if confirm "Do you want to update package.json scripts?"; then
    if [ -f "package.json" ]; then
        if [ -f "tsconfig.json" ]; then
            # TypeScript project
            sed -i.bak 's|"start": "react-scripts start"|"start": "vite"|g; s|"build": "react-scripts build"|"build": "tsc && vite build"|g; s|"test": "react-scripts test"|"serve": "vite preview"|g' package.json
        else
            # JavaScript project
            sed -i.bak 's|"start": "react-scripts start"|"start": "vite"|g; s|"build": "react-scripts build"|"build": "vite build"|g; s|"test": "react-scripts test"|"serve": "vite preview"|g' package.json
        fi
        rm package.json.bak
        echo "package.json scripts updated."
    else
        echo "package.json not found. Skipping."
    fi
else
    echo "Skipping update of package.json"
fi