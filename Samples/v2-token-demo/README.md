# Microsoft Entra ID v2.0 Token Sample

This sample demonstrates the use of Microsoft Entra ID v2.0 tokens with modern authentication practices. It shows how to:
- Acquire v2.0 tokens using MSAL.js 2.0
- Handle token lifecycle
- Use incremental consent
- Access Microsoft Graph with proper scopes

## Key Features

- Uses v2.0 endpoint exclusively
- Implements PKCE (Proof Key for Code Exchange)
- Demonstrates proper scope usage
- Shows token refresh handling
- Includes error handling and logging

## Prerequisites

- Node.js 18.x or later
- Microsoft Entra ID tenant
- Application registration in Microsoft Entra ID portal

## Configuration

1. Register an application in Microsoft Entra ID:
   - Redirect URI: `http://localhost:3000/auth/callback`
   - Enable the following permissions:
     - Microsoft Graph User.Read (delegated)
     - Microsoft Graph Mail.Read (delegated)

2. Update `config.js` with your application details:
   ```javascript
   {
     "clientId": "your-client-id",
     "authority": "https://login.microsoftonline.com/your-tenant-id",
     "redirectUri": "http://localhost:3000/auth/callback"
   }
   ```

## Key Differences from v1.0

1. **Endpoint URLs**:
   - v2.0: `https://login.microsoftonline.com/{tenant}/oauth2/v2.0/authorize`
   - v2.0: `https://login.microsoftonline.com/{tenant}/oauth2/v2.0/token`

2. **Scope Format**:
   - v2.0: `https://graph.microsoft.com/User.Read`
   - v2.0: `offline_access` for refresh tokens

3. **Token Claims**:
   - v2.0 includes additional claims
   - Supports dynamic scopes
   - Better support for consumer accounts

## Running the Sample

1. Install dependencies:
   ```bash
   npm install
   ```

2. Start the application:
   ```bash
   npm start
   ```

3. Navigate to `http://localhost:3000`

## Security Considerations

- Uses PKCE by default
- Implements state parameter validation
- Stores tokens securely
- Implements proper error handling
- Uses secure session management
