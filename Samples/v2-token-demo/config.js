module.exports = {
    clientId: process.env.CLIENT_ID || "23da092b-d845-4266-9def-8e4d32bf6604",
    authority: process.env.AUTHORITY || "https://login.microsoftonline.com/6229b3b9-0be0-42a0-ab89-34eb864a3589",
    clientSecret: process.env.CLIENT_SECRET || "Vp98Q~9WoBlzxil0UztiX4~KvRqiixYpphzy9cEu",
    redirectUri: process.env.REDIRECT_URI || "http://localhost:3000/auth/callback",
    
    // v2.0 endpoint specific settings
    endpoints: {
        authorizationEndpoint: "https://login.microsoftonline.com/6229b3b9-0be0-42a0-ab89-34eb864a3589/oauth2/v2.0/authorize",
        tokenEndpoint: "https://login.microsoftonline.com/6229b3b9-0be0-42a0-ab89-34eb864a3589/oauth2/v2.0/token",
        endSessionEndpoint: "https://login.microsoftonline.com/6229b3b9-0be0-42a0-ab89-34eb864a3589/oauth2/v2.0/logout"
    },
    
    // Scopes for initial token request
    defaultScopes: [
        "User.Read",
        "Mail.Read",
        "offline_access"  // Required for refresh tokens in v2.0
    ]
};
