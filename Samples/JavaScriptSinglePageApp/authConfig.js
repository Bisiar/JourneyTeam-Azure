// authConfig.js

const msalConfig = {
  auth: {
    clientId: "YOUR_CLIENT_ID",
    authority: "https://login.microsoftonline.com/common",
    redirectUri: "http://localhost:3000/",
  },
};

const loginRequest = {
  scopes: ["User.Read"],
};
