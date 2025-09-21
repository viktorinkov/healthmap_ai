#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting HealthMap AI for iPhone...${NC}\n"

# Get local IP address (filter out link-local 169.254.x.x addresses)
LOCAL_IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | grep -v "169.254" | head -1 | awk '{print $2}')
echo -e "${GREEN}📱 Your local IP: ${LOCAL_IP}${NC}"
echo -e "${YELLOW}Make sure your iPhone is on the same WiFi network!${NC}\n"

# Update .env file with current IP if needed
if [ -f ".env" ]; then
    if grep -q "API_BASE_URL" .env; then
        # Update the IP in .env file
        sed -i '' "s|API_BASE_URL=.*|API_BASE_URL=http://${LOCAL_IP}:3000/api|g" .env
        echo -e "${GREEN}✅ Updated .env with current IP${NC}"
    fi
fi

# Function to cleanup on exit
cleanup() {
    echo -e "\n${YELLOW}🛑 Stopping all services...${NC}"
    kill $NODE_PID 2>/dev/null
    kill $PYTHON_PID 2>/dev/null
    kill $FLUTTER_PID 2>/dev/null
    echo -e "${GREEN}✅ All services stopped${NC}"
    exit 0
}

# Trap CTRL+C
trap cleanup INT

# Start Node.js backend
echo -e "${BLUE}Starting Node.js backend on port 3000...${NC}"
cd backend
npm start > ../node_backend.log 2>&1 &
NODE_PID=$!
cd ..

# Wait for Node.js backend to start
echo -e "${YELLOW}Waiting for Node.js backend to start...${NC}"
sleep 3

# Check if Node.js backend is running
if lsof -i:3000 > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Node.js backend running on port 3000${NC}\n"
else
    echo -e "${RED}❌ Failed to start Node.js backend${NC}"
    exit 1
fi

# Start Python backend
echo -e "${BLUE}Starting Python backend on port 5001...${NC}"
cd backend_python
python app.py > ../python_backend.log 2>&1 &
PYTHON_PID=$!
cd ..

# Wait for Python backend to start
echo -e "${YELLOW}Waiting for Python backend to start...${NC}"
sleep 3

# Check if Python backend is running
if lsof -i:5001 > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Python backend running on port 5001${NC}\n"
else
    echo -e "${RED}❌ Failed to start Python backend${NC}"
    echo -e "${YELLOW}Check python_backend.log for details${NC}"
    kill $NODE_PID 2>/dev/null
    exit 1
fi

# Get list of iOS devices
echo -e "${BLUE}Looking for iOS devices...${NC}"
DEVICES=$(flutter devices | grep "iPhone" | head -1)

if [ -z "$DEVICES" ]; then
    echo -e "${RED}❌ No iPhone detected. Please connect your iPhone and ensure it's trusted.${NC}"
    echo -e "${YELLOW}Make sure you have:${NC}"
    echo -e "  1. Connected your iPhone via USB"
    echo -e "  2. Trusted this computer on your iPhone"
    echo -e "  3. Enabled Developer Mode on your iPhone (Settings > Privacy & Security > Developer Mode)"
    cleanup
fi

# Extract device ID (it's the second field after the bullet)
DEVICE_ID=$(echo "$DEVICES" | awk -F'•' '{print $2}' | awk '{print $1}' | tr -d ' ')

echo -e "${GREEN}✅ Found iPhone: ${DEVICE_ID}${NC}\n"

# Update service files with current IP
echo -e "${BLUE}Updating service URLs with current IP...${NC}"

# Update all service files with the current IP
find lib/services -name "*.dart" -exec sed -i '' "s|http://168\.5\.[0-9]*\.[0-9]*:|http://${LOCAL_IP}:|g" {} \;
find lib/widgets -name "*.dart" -exec sed -i '' "s|http://168\.5\.[0-9]*\.[0-9]*:|http://${LOCAL_IP}:|g" {} \;

# Update Info.plist with current IP
sed -i '' "s|<key>168\.5\.[0-9]*\.[0-9]*</key>|<key>${LOCAL_IP}</key>|g" ios/Runner/Info.plist

echo -e "${GREEN}✅ Updated all service URLs${NC}\n"

# Run Flutter on iPhone
echo -e "${BLUE}Starting Flutter app on iPhone...${NC}"
echo -e "${YELLOW}This may take a few minutes on first run...${NC}\n"

flutter run -d "$DEVICE_ID" &
FLUTTER_PID=$!

# Show logs location
echo -e "\n${GREEN}📝 Backend logs:${NC}"
echo -e "  Node.js: tail -f node_backend.log"
echo -e "  Python: tail -f python_backend.log"
echo -e "\n${YELLOW}Press CTRL+C to stop all services${NC}\n"

# Wait for Flutter process
wait $FLUTTER_PID