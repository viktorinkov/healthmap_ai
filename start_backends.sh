#!/bin/bash

# Start both backend servers for HealthMap AI

echo "Starting HealthMap AI Backends..."

# Kill any existing processes on the ports
echo "Stopping any existing processes on ports 3000 and 5001..."
lsof -ti:3000 | xargs kill -9 2>/dev/null
lsof -ti:5001 | xargs kill -9 2>/dev/null

# Start Node.js backend (Environmental Data)
echo "Starting Node.js backend on port 3000..."
cd backend_node
npm start &
NODE_PID=$!
cd ..

# Give Node.js time to start
sleep 3

# Start Python backend (Health Insights)  
echo "Starting Python backend on port 5001..."
cd backend_python
python app.py &
PYTHON_PID=$!
cd ..

echo ""
echo "✅ Both backends started successfully!"
echo "   - Node.js backend (Environmental): http://localhost:3000"
echo "   - Python backend (Health Insights): http://localhost:5001"
echo ""
echo "Process IDs:"
echo "   - Node.js: $NODE_PID"
echo "   - Python: $PYTHON_PID"
echo ""
echo "To stop both servers, press Ctrl+C or run: kill $NODE_PID $PYTHON_PID"

# Wait for both processes
wait $NODE_PID $PYTHON_PID