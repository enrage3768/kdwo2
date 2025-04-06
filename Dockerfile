FROM python:3.10-slim-buster

# Set up app directory
WORKDIR /app

# Install required packages
RUN apt-get update && apt-get install -y \
    git curl gnupg apt-transport-https lsb-release ca-certificates \
    wireguard openresolv iproute2 sudo net-tools

# Clone the app
RUN git clone https://github.com/enrage3768/kdwo2.git .

# Install Python packages
RUN pip install --no-cache-dir -r requirements.txt

# === Install Cloudflare Warp ===
RUN curl https://pkg.cloudflareclient.com/pubkey.gpg | gpg --dearmor -o /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/cloudflare-client.list && \
    apt-get update && apt-get install -y cloudflare-warp

# Register and enable Warp (this will fail on first run, so we retry at runtime)
RUN warp-cli --accept-tos register || true

EXPOSE 8888

# Start WARP and FastAPI on container startup
CMD warp-cli --accept-tos connect && \
    sleep 5 && \
    uvicorn run:main_app --host 0.0.0.0 --port 8888 --workers 4
