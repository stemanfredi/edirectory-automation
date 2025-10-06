#!/bin/bash
set -e

echo "Stopping all running containers..."
RUNNING=$(docker ps -q)
[ -n "$RUNNING" ] && docker stop $RUNNING

echo "Removing all containers..."
ALL=$(docker ps -aq)
[ -n "$ALL" ] && docker rm $ALL

echo "Removing all volumes..."
VOLUMES=$(docker volume ls -q)
[ -n "$VOLUMES" ] && docker volume rm $VOLUMES

echo "Cleanup complete. Images preserved."
