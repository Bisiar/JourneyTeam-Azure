const express = require('express');
const session = require('express-session');
const msal = require('@azure/msal-node');
const axios = require('axios');
const crypto = require('crypto');
const config = require('./config');

const app = express();

// Configure session middleware
app.use(session({
    secret: crypto.randomBytes(32).toString('hex'),
    resave: false,
    saveUninitialized: false,
    cookie: {
        secure: process.env.NODE_ENV === 'production',
        httpOnly: true
    }
}));

// Initialize MSAL application
const msalConfig = {
    auth: {
        clientId: config.clientId,
        authority: config.authority,
        clientSecret: config.clientSecret
    },
    system: {
        loggerOptions: {
            loggerCallback(loglevel, message) {
                console.log(message);
            },
            piiLoggingEnabled: false,
            logLevel: "Info"
        }
    }
};

const msalInstance = new msal.ConfidentialClientApplication(msalConfig);

// MSAL token cache middleware
app.use((req, res, next) => {
    if (!req.session.tokenCache) {
        req.session.tokenCache = {};
    }
    next();
});

// Root route
app.get('/', (req, res) => {
    res.send(`
        <h1>V2 Token Test App</h1>
        <p>Click below to login and see token details:</p>
        <a href="/login">Login</a>
    `);
});

// Authentication routes
app.get('/login', async (req, res) => {
    // Generate PKCE
    const pkce = {
        verifier: crypto.randomBytes(32).toString('base64url'),
        challenge: undefined
    };
    
    pkce.challenge = crypto.createHash('sha256')
        .update(pkce.verifier)
        .digest('base64url');

    // Save PKCE verifier
    req.session.pkceVerifier = pkce.verifier;

    const authCodeUrlParameters = {
        scopes: ["User.Read", "Mail.Read"],
        redirectUri: config.redirectUri,
        codeChallenge: pkce.challenge,
        codeChallengeMethod: "S256"
    };

    try {
        const authUrl = await msalInstance.getAuthCodeUrl(authCodeUrlParameters);
        res.redirect(authUrl);
    } catch (error) {
        console.error('Auth URL Error:', error);
        res.status(500).send(error);
    }
});

app.get('/auth/callback', async (req, res) => {
    if (req.query.error) {
        return res.status(400).send(`Authentication error: ${req.query.error_description}`);
    }

    try {
        const tokenRequest = {
            code: req.query.code,
            scopes: ["User.Read", "Mail.Read"],
            redirectUri: config.redirectUri,
            codeVerifier: req.session.pkceVerifier
        };

        const response = await msalInstance.acquireTokenByCode(tokenRequest);
        req.session.tokenCache = response;
        
        // Debug token information
        const tokenInfo = {
            accessToken: {
                raw: response.accessToken,
                decoded: JSON.parse(Buffer.from(response.accessToken.split('.')[1], 'base64').toString()),
            },
            idToken: response.idToken ? {
                raw: response.idToken,
                decoded: JSON.parse(Buffer.from(response.idToken.split('.')[1], 'base64').toString()),
            } : null
        };

        res.send(`
            <h1>Token Details</h1>
            <h2>Access Token</h2>
            <p>Version: ${tokenInfo.accessToken.decoded.ver || 'Not specified'}</p>
            <pre>${JSON.stringify(tokenInfo.accessToken.decoded, null, 2)}</pre>
            
            <h2>ID Token</h2>
            <pre>${JSON.stringify(tokenInfo.idToken?.decoded || 'No ID token', null, 2)}</pre>
            
            <p><a href="/profile">View Profile</a></p>
        `);
    } catch (error) {
        console.error('Token acquisition error:', error);
        res.status(500).send(error);
    }
});

// Protected route
app.get('/profile', async (req, res) => {
    if (!req.session.tokenCache) {
        return res.redirect('/login');
    }

    try {
        // Get access token from cache or refresh if expired
        const account = req.session.tokenCache.account;
        const silentRequest = {
            account: account,
            scopes: ["User.Read"]
        };

        const token = await msalInstance.acquireTokenSilent(silentRequest);

        // Call Microsoft Graph
        const graphResponse = await axios.get('https://graph.microsoft.com/v2.0/me', {
            headers: {
                Authorization: `Bearer ${token.accessToken}`
            }
        });

        res.json(graphResponse.data);
    } catch (error) {
        if (error instanceof msal.InteractionRequiredAuthError) {
            return res.redirect('/login');
        }
        console.error('Profile error:', error);
        res.status(500).send(error);
    }
});

// Token refresh route
app.post('/refresh', async (req, res) => {
    if (!req.session.tokenCache) {
        return res.status(401).send('No token cache found');
    }

    try {
        const account = req.session.tokenCache.account;
        const silentRequest = {
            account: account,
            scopes: ["User.Read", "Mail.Read"]
        };

        const response = await msalInstance.acquireTokenSilent(silentRequest);
        req.session.tokenCache = response;
        res.json({ success: true });
    } catch (error) {
        console.error(error);
        res.status(500).send(error);
    }
});

// Logout route
app.get('/logout', (req, res) => {
    req.session.destroy(() => {
        res.redirect('/');
    });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
