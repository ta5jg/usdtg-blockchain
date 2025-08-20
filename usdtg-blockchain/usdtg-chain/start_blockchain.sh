#!/bin/bash

echo "🚀 USDTg Blockchain Startup Script"
echo "=================================="

# Kill any existing processes
echo "🔄 Killing existing processes..."
pkill -f usdtgd
sleep 3

# Check if port 8080 is free
if lsof -i :8080 > /dev/null 2>&1; then
    echo "❌ Port 8080 is still in use. Force killing..."
    lsof -ti :8080 | xargs kill -9
    sleep 2
fi

# Start blockchain backend
echo "🚀 Starting USDTg Blockchain backend..."
./usdtgd &
BACKEND_PID=$!
echo "✅ Backend started with PID: $BACKEND_PID"

# Wait for backend to start
echo "⏳ Waiting for backend to start..."
sleep 5

# Check if backend is running and responding
echo "🔍 Checking backend health..."
if curl -s http://localhost:8080/health > /dev/null; then
    echo "✅ Backend is running successfully!"
    echo "🌐 API available at: http://localhost:8080"
    echo "🏥 Health check: http://localhost:8080/health"
    echo "📊 Backend PID: $BACKEND_PID"
    
    # Keep script running and monitor backend
    while true; do
        if ! ps -p $BACKEND_PID > /dev/null; then
            echo "❌ Backend stopped! Restarting..."
            exec "$0" "$@"
        fi
        
        if ! curl -s http://localhost:8080/health > /dev/null; then
            echo "❌ Backend not responding! Restarting..."
            kill $BACKEND_PID 2>/dev/null
            sleep 2
            exec "$0" "$@"
        fi
        
        echo "🔄 Backend is healthy... (PID: $BACKEND_PID)"
        sleep 30
    done
else
    echo "❌ Failed to start backend!"
    echo "🔍 Checking backend logs..."
    if ps -p $BACKEND_PID > /dev/null; then
        echo "Backend process exists but not responding"
        kill $BACKEND_PID
    fi
    exit 1
fi
