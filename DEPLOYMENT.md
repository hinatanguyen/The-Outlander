# Deployment Instructions for The Outlander

## Azure Static Web Apps Deployment

Your project is now configured for Azure Static Web Apps deployment via GitHub Actions.

### Steps to Complete Deployment:

1. **Get Your Azure Deployment Token:**
   - Go to the Azure Portal: https://portal.azure.com
   - Navigate to your Static Web App resource
   - In the left menu, click on "Settings" > "Configuration"
   - Under "Deployment token", click "Manage deployment token"
   - Copy the token value

2. **Add the Token to GitHub Secrets:**
   - Go to your GitHub repository: https://github.com/hinatanguyen/The-Outlander
   - Click on "Settings" tab
   - In the left sidebar, click "Secrets and variables" > "Actions"
   - Click "New repository secret"
   - Name: `AZURE_STATIC_WEB_APPS_API_TOKEN`
   - Value: Paste the deployment token you copied from Azure
   - Click "Add secret"

3. **Push Changes to GitHub:**
   Run these commands:
   ```bash
   git add .
   git commit -m "Add Azure Static Web Apps deployment configuration"
   git push origin Host-Website
   ```

4. **Monitor Deployment:**
   - Go to your GitHub repository's "Actions" tab
   - You should see a workflow running
   - Wait for it to complete (usually 2-5 minutes)
   - Once successful, your site will be live at: https://proud-cliff-07af08a00.4.azurestaticapps.net

### File Structure:
- `index.html` - Main entry point (renamed from final.html)
- `final.js` - Game JavaScript
- `final.pck` - Godot game package
- `final.audio.worklet.js` - Audio processing
- `final.audio.position.worklet.js` - Audio positioning

### Troubleshooting:
- If deployment fails, check the Actions logs on GitHub
- Ensure all game assets are committed to the repository
- Verify the deployment token is correctly added to GitHub Secrets
