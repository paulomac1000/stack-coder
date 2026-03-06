#!/bin/bash

echo "============================================"
echo "  GitHub Setup for code-server"
echo "============================================"
echo ""

# Step 1: Restart container to re-run init.sh
echo ">>> Step 1: Restarting code-server container..."
echo "⚠️  WARNING: This will interrupt the current code-server session!"
echo ""
read -p "Continue? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 1
fi

docker restart code-server

echo ">>> Waiting 10 seconds for initialization..."
sleep 10

# Step 2: Show SSH key from logs
echo ""
echo ">>> Step 2: Retrieving SSH key from container logs..."
echo ""

docker logs code-server 2>&1 | grep -A 4 "🔑 SSH KEY GENERATED" || {
    echo "⚠️  Key not found in logs."
    echo "Attempting to retrieve key directly from the container..."
    echo ""
    echo "--- COPY THE KEY BELOW ---"
    docker exec code-server cat /home/coder/.ssh/id_ed25519.pub
    echo "--- END OF KEY ---"
}

echo ""
echo "============================================"
echo "  Next Steps:"
echo "============================================"
echo ""
echo "1. Copy the public key above (the entire line starting with 'ssh-ed25519')"
echo ""
echo "2. Add it to GitHub:"
echo "   https://github.com/settings/ssh/new"
echo "   - Title: code-server@hassio"
echo "   - Key: <paste the copied key>"
echo ""
echo "3. Test the connection (in the code-server terminal):"
echo "   docker exec -it code-server ssh -T git@github.com"
echo "   (it should display: Hi your-username! You've successfully authenticated...)"
echo ""
echo "4. Configure your repository (example for 'hassio'):"
echo "   cd /var/apps/hassio"
echo "   git remote add origin git@github.com:your-username/your-repo.git"
echo "   git branch -M main"
echo ""
echo "5. Create your first commit:"
echo "   git commit -m 'Initial commit'"
echo ""
echo "6. Push to GitHub:"
echo "   git push -u origin main"
echo ""
echo "============================================"
