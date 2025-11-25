# Use GitHub Container Registry to avoid Docker Hub rate limits
ARG NODE_IMAGE=ghcr.io/library/node:18-alpine
FROM ${NODE_IMAGE}

# Set working directory
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy rest of the project files
COPY . .

# Build the Next.js app
RUN npm run build

# Expose the port Next.js runs on
EXPOSE 3000

# Start the Next.js production server
CMD ["npm", "run", "start"]
