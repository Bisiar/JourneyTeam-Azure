// app.js

// Create an instance of PublicClientApplication
const msalInstance = new msal.PublicClientApplication(msalConfig);

let account;

function selectAccount() {
  const currentAccounts = msalInstance.getAllAccounts();
  if (currentAccounts.length === 0) {
    return;
  } else {
    account = currentAccounts[0];
    welcomeUser(account);
  }
}

function welcomeUser(account) {
  const welcome = document.getElementById("content");
  welcome.innerHTML = `<p>Welcome, ${account.username}</p>`;
  document.getElementById("signIn").style.display = "none";
  document.getElementById("signOut").style.display = "block";
}

// Sign-in button event handler
document.getElementById("signIn").onclick = () => {
  msalInstance.loginPopup(loginRequest)
    .then((loginResponse) => {
      account = loginResponse.account;
      welcomeUser(account);
    })
    .catch((error) => {
      console.error(error);
    });
};

// Sign-out button event handler
document.getElementById("signOut").onclick = () => {
  const logoutRequest = {
    account: account,
    postLogoutRedirectUri: msalConfig.auth.redirectUri,
  };
  msalInstance.logoutPopup(logoutRequest);
};

window.onload = () => {
  selectAccount();
};
