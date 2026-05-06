# Build stage
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY src ./src

# TODO: Add the runtime stage
# Requirements:
# - Use node:20-alpine as the base image
# - Copy package*.json and install production dependencies only (npm ci --omit=dev)
# - Copy the src directory from the build stage
# - EXPOSE the application port
# - Add a HEALTHCHECK instruction that tests http://localhost:3000/health
# - Set CMD to start the application
