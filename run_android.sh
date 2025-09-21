#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting HealthMap AI for Android Emulator...${NC}\n"

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

# Update service files for Android emulator (10.0.2.2)
echo -e "${BLUE}Configuring services for Android emulator...${NC}"

# Update .env for Android emulator
if [ -f ".env" ]; then
    sed -i '' "s|API_BASE_URL=.*|API_BASE_URL=http://10.0.2.2:3000/api|g" .env
fi

# Update all service files for Android emulator
find lib/services -name "*.dart" -exec sed -i '' "s|http://[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*:|http://10.0.2.2:|g" {} \;
find lib/widgets -name "*.dart" -exec sed -i '' "s|http://[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*:|http://10.0.2.2:|g" {} \;

echo -e "${GREEN}✅ Configured for Android emulator${NC}\n"

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
cd python_backend
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
    kill $NODE_PID 2>/dev/null
    exit 1
fi

# Check for Android emulator
echo -e "${BLUE}Checking for Android emulator...${NC}"
EMULATOR=$(flutter devices | grep -E "emulator|android" | head -1)

if [ -z "$EMULATOR" ]; then
    echo -e "${YELLOW}No Android emulator running. Starting emulator...${NC}"
    flutter emulators --launch flutter_emulator 2>/dev/null || {
        echo -e "${YELLOW}Couldn't auto-start emulator. Please start it manually.${NC}"
        echo -e "${YELLOW}Available emulators:${NC}"
        flutter emulators
        cleanup
    }
    sleep 10
fi

# Get emulator device ID
DEVICE_ID=$(flutter devices | grep -E "emulator|android" | head -1 | awk '{print $3}')

if [ -n "$DEVICE_ID" ]; then
    echo -e "${GREEN}✅ Found Android device: ${DEVICE_ID}${NC}\n"
else
    echo -e "${RED}❌ No Android device found${NC}"
    cleanup
fi

# Run Flutter on Android
echo -e "${BLUE}Starting Flutter app on Android...${NC}"
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