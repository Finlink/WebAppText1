# -------------------------------
# Stage 1: Build the Flutter Web App
# -------------------------------
FROM debian:stable-slim AS build-env

# Install required packages for Flutter
RUN apt-get update && apt-get install -y \
  curl git unzip xz-utils zip libglu1-mesa \
  && rm -rf /var/lib/apt/lists/*

# Create a non-root user for better security
RUN useradd -m flutter
USER flutter
WORKDIR /home/flutter

# Clone the Flutter SDK (stable version)
RUN git clone https://github.com/flutter/flutter.git --branch stable
# Add Flutter to PATH
ENV PATH="/home/flutter/flutter/bin:$PATH"

# Disable Flutter usage analytics and ensure web support is enabled
RUN flutter config --no-analytics && flutter config --enable-web

# Copy the entire Flutter project into the container
COPY --chown=flutter . .

# Clean previous builds, install packages, and build the web release
RUN flutter clean && flutter pub get && flutter build web --release

# -------------------------------
# Stage 2: Serve the app with NGINX
# -------------------------------
FROM nginx:alpine

# Remove default NGINX files
RUN rm -rf /usr/share/nginx/html/*
  
# Copy built Flutter web app
COPY --from=build-env /home/flutter/build/web /usr/share/nginx/html
  
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
