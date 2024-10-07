# Microsoft Entra ID Integration Guide

This repository provides comprehensive guides and sample applications to help development teams integrate their applications with **Microsoft Entra ID** (formerly Azure Active Directory) using various authentication protocols.

---

## Table of Contents

1. [Introduction](#introduction)
2. [Prerequisites](#prerequisites)
3. [OpenID Connect (OIDC) Integration](#openid-connect-oidc-integration)
   - [C# Example](#c-example)
   - [JavaScript Example](#javascript-example)
   - [Python Example](#python-example)
4. [SAML Integration](#saml-integration)
   - [C# Example](#c-example-1)
   - [JavaScript Example](#javascript-example-1)
   - [Python Example](#python-example-1)
5. [Header-Based Authentication](#header-based-authentication)
   - [Implementation Examples](#implementation-examples)
6. [Best Practices for Integrating with Microsoft Entra ID](#best-practices-for-integrating-with-microsoft-entra-id)
7. [Azure Hosting Scenarios](#azure-hosting-scenarios)
8. [Samples](#samples)
   - [Plain JavaScript Application using MSAL.js](#plain-javascript-sample-using-msaljs)
   - [React Application using MSAL React](#react-sample-using-msal-react)
9. [Additional Resources](#additional-resources)

---

## Introduction

**Microsoft Entra ID** is a cloud-based identity and access management service that helps your employees sign in and access resources. Integrating your applications with Entra ID allows for secure authentication using industry-standard protocols like **SAML** and **OpenID Connect (OIDC)**.

This guide provides detailed instructions and code examples to help development teams connect their applications to Entra ID using **SAML**, **OIDC**, or **header-based authentication**.

---

## Prerequisites

- **Microsoft Entra ID Tenant**: Access to an Entra ID tenant where you can register your application.
- **Application Registration**: Your application must be registered in Entra ID.
- **Development Environment**: Set up for C#, JavaScript, or Python.
- **Basic Knowledge**: Understanding of authentication protocols and the programming language you're using.

---

## OpenID Connect (OIDC) Integration

OIDC is a simple identity layer on top of the OAuth 2.0 protocol. It allows clients to verify the identity of the end-user.

### Steps:

1. **Register your application in Entra ID**.
2. **Configure application settings**.
3. **Implement authentication logic**.

---

### C# Example

**Using ASP.NET Core and `Microsoft.Identity.Web`**

#### 1. Install NuGet Packages

```bash
dotnet add package Microsoft.Identity.Web
dotnet add package Microsoft.Identity.Web.UI
```

#### 2. Configure `appsettings.json`

```json
{
  "AzureAd": {
    "Instance": "https://login.microsoftonline.com/",
    "Domain": "yourdomain.onmicrosoft.com",
    "TenantId": "your-tenant-id",
    "ClientId": "your-client-id",
    "CallbackPath": "/signin-oidc"
  }
}
```

#### 3. Update `Startup.cs`

```csharp
using Microsoft.Identity.Web;
using Microsoft.Identity.Web.UI;
using Microsoft.AspNetCore.Authentication.OpenIdConnect;

public void ConfigureServices(IServiceCollection services)
{
    services.AddAuthentication(OpenIdConnectDefaults.AuthenticationScheme)
            .AddMicrosoftIdentityWebApp(Configuration.GetSection("AzureAd"));

    services.AddControllersWithViews()
            .AddMicrosoftIdentityUI();
}

public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
{
    app.UseAuthentication();
    app.UseAuthorization();

    app.UseEndpoints(endpoints =>
    {
        endpoints.MapControllers();
        endpoints.MapRazorPages();
    });
}
```

#### 4. Protect Your Controllers

```csharp
using Microsoft.AspNetCore.Authorization;

[Authorize]
public class SecureController : Controller
{
    public IActionResult Index()
    {
        return View();
    }
}
```

---

### JavaScript Example

**Using Node.js and Passport.js**

#### 1. Install Dependencies

```bash
npm install express passport passport-azure-ad express-session
```

#### 2. Configure `app.js`

```javascript
const express = require('express');
const session = require('express-session');
const passport = require('passport');
const OIDCStrategy = require('passport-azure-ad').OIDCStrategy;

const app = express();

// Session middleware
app.use(session({ secret: 'your_secret_value', resave: false, saveUninitialized: false }));

// Passport initialization
app.use(passport.initialize());
app.use(passport.session());

// OIDC Strategy
passport.use(new OIDCStrategy(
  {
    identityMetadata: 'https://login.microsoftonline.com/your-tenant-id/v2.0/.well-known/openid-configuration',
    clientID: 'your-client-id',
    responseType: 'code',
    responseMode: 'form_post',
    redirectUrl: 'http://localhost:3000/auth/openid/return',
    allowHttpForRedirectUrl: true, // Set to false in production
    clientSecret: 'your-client-secret',
    scope: ['profile', 'email']
  },
  function (iss, sub, profile, accessToken, refreshToken, done) {
    return done(null, profile);
  }
));

// Serialization
passport.serializeUser((user, done) => {
  done(null, user);
});
passport.deserializeUser((obj, done) => {
  done(null, obj);
});

// Routes
app.get('/login', passport.authenticate('azuread-openidconnect', { failureRedirect: '/' }));

app.post('/auth/openid/return',
  passport.authenticate('azuread-openidconnect', { failureRedirect: '/' }),
  function (req, res) {
    res.redirect('/secure');
  }
);

app.get('/secure', ensureAuthenticated, (req, res) => {
  res.send(`Hello, ${req.user.displayName}`);
});

function ensureAuthenticated(req, res, next) {
  if (req.isAuthenticated()) { return next(); }
  res.redirect('/');
}

app.listen(3000, () => console.log('App listening on port 3000'));
```

---

### Python Example

**Using Flask and MSAL**

#### 1. Install Dependencies

```bash
pip install Flask msal
```

#### 2. Create `app.py`

```python
from flask import Flask, redirect, url_for, session, request
import msal
import json

app = Flask(__name__)
app.config['SECRET_KEY'] = 'your_secret_key'

CLIENT_ID = "your-client-id"
CLIENT_SECRET = "your-client-secret"
AUTHORITY = "https://login.microsoftonline.com/your-tenant-id"
REDIRECT_PATH = "/getAToken"
ENDPOINT = 'https://graph.microsoft.com/v1.0/users'
SCOPE = ["User.Read"]

@app.route("/")
def index():
    if not session.get("user"):
        return redirect(url_for("login"))
    return f"Hello, {session['user']['name']}"

@app.route("/login")
def login():
    session["flow"] = _build_auth_code_flow()
    return redirect(session["flow"]["auth_uri"])

@app.route("/getAToken")
def authorized():
    cache = msal.SerializableTokenCache()
    result = _build_msal_app(cache=cache).acquire_token_by_auth_code_flow(
        session.get("flow", {}), request.args)
    if "error" in result:
        return f"Error: {result['error']}"
    session["user"] = result.get("id_token_claims")
    return redirect(url_for("index"))

def _build_auth_code_flow():
    return _build_msal_app().initiate_auth_code_flow(
        SCOPE,
        redirect_uri=url_for("authorized", _external=True))

def _build_msal_app(cache=None):
    return msal.ConfidentialClientApplication(
        CLIENT_ID, authority=AUTHORITY,
        client_credential=CLIENT_SECRET, token_cache=cache)

if __name__ == "__main__":
    app.run()
```

---

## SAML Integration

SAML allows service providers and identity providers to securely exchange user authentication and authorization data.

### Steps:

1. **Register your application for SAML in Entra ID**.
2. **Configure the SAML settings in your application**.
3. **Implement the SAML authentication flow**.

---

### C# Example

**Using `Sustainsys.Saml2`**

#### 1. Install NuGet Package

```bash
dotnet add package Sustainsys.Saml2.AspNetCore2
```

#### 2. Configure `Startup.cs`

```csharp
using Sustainsys.Saml2;
using Sustainsys.Saml2.Metadata;
using Microsoft.AspNetCore.Authentication.Cookies;

public void ConfigureServices(IServiceCollection services)
{
    services.AddAuthentication(options =>
    {
        options.DefaultScheme = CookieAuthenticationDefaults.AuthenticationScheme;
        options.DefaultSignInScheme = CookieAuthenticationDefaults.AuthenticationScheme;
    })
    .AddCookie()
    .AddSaml2(options =>
    {
        options.SPOptions.EntityId = new EntityId("https://yourapp.example.com/SAML");
        options.IdentityProviders.Add(
            new IdentityProvider(
                new EntityId("https://sts.windows.net/your-tenant-id/"),
                options.SPOptions)
            {
                MetadataLocation = "https://login.microsoftonline.com/your-tenant-id/federationmetadata/2007-06/federationmetadata.xml",
                LoadMetadata = true
            });
    });
}
```

---

### JavaScript Example

**Using `saml2-js`**

#### 1. Install Dependencies

```bash
npm install saml2-js express express-session
```

#### 2. Configure SAML in `app.js`

```javascript
const saml2 = require('saml2-js');
const express = require('express');
const session = require('express-session');
const fs = require('fs');

const app = express();
app.use(session({ secret: 'your_secret_value', resave: false, saveUninitialized: false }));
app.use(express.urlencoded({ extended: true }));

// Create service provider
const sp_options = {
  entity_id: "https://yourapp.example.com/metadata.xml",
  private_key: fs.readFileSync("key.pem").toString(),
  certificate: fs.readFileSync("cert.pem").toString(),
  assert_endpoint: "https://yourapp.example.com/assert"
};
const sp = new saml2.ServiceProvider(sp_options);

// Create identity provider
const idp_options = {
  sso_login_url: "https://login.microsoftonline.com/your-tenant-id/saml2",
  certificates: ["MIIDdzCCAl+gAwIBAgIE..."]
};
const idp = new saml2.IdentityProvider(idp_options);

// Endpoint to retrieve metadata
app.get("/metadata.xml", function(req, res) {
  res.type('application/xml');
  res.send(sp.create_metadata());
});

// Starting point for login
app.get("/login", function(req, res) {
  sp.create_login_request_url(idp, {}, function(err, login_url) {
    if (err != null) return res.status(500).send(err);
    res.redirect(login_url);
  });
});

// Assert endpoint for when login completes
app.post("/assert", function(req, res) {
  const options = { request_body: req.body };
  sp.post_assert(idp, options, function(err, response) {
    if (err != null) return res.status(500).send(err);
    req.session.user = response.user;
    res.redirect("/secure");
  });
});

app.get("/secure", ensureAuthenticated, function(req, res) {
  res.send(`Hello ${req.session.user.name_id}`);
});

function ensureAuthenticated(req, res, next) {
  if (req.session.user) { return next(); }
  res.redirect('/login');
}

app.listen(3000);
```

**Note**: Replace the `certificates` value in `idp_options` with the certificate from Entra ID.

---

### Python Example

**Using `python3-saml`**

#### 1. Install Dependencies

```bash
pip install python3-saml Flask
```

#### 2. Create `settings.json`

```json
{
  "sp": {
    "entityId": "https://yourapp.example.com/metadata/",
    "assertionConsumerService": {
      "url": "https://yourapp.example.com/?acs",
      "binding": "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
    }
  },
  "idp": {
    "entityId": "https://sts.windows.net/your-tenant-id/",
    "singleSignOnService": {
      "url": "https://login.microsoftonline.com/your-tenant-id/saml2",
      "binding": "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect"
    },
    "x509cert": "MIIC8DCC...="
  }
}
```

#### 3. Implement in Flask (`app.py`)

```python
from flask import Flask, request, redirect, session
from onelogin.saml2.auth import OneLogin_Saml2_Auth
from importlib import import_module

app = Flask(__name__)
app.secret_key = 'your_secret_key'

def init_saml_auth(req):
    auth = OneLogin_Saml2_Auth(req, custom_base_path='path_to_saml_folder')
    return auth

@app.route('/')
def index():
    if 'samlUserdata' in session:
        return 'Logged in as ' + session['samlNameId']
    else:
        return redirect('/saml/login')

@app.route('/saml/login')
def saml_login():
    req = prepare_flask_request(request)
    auth = init_saml_auth(req)
    return redirect(auth.login())

@app.route('/saml/acs', methods=['POST'])
def saml_acs():
    req = prepare_flask_request(request)
    auth = init_saml_auth(req)
    auth.process_response()
    errors = auth.get_errors()
    if not errors:
        session['samlUserdata'] = auth.get_attributes()
        session['samlNameId'] = auth.get_nameid()
        return redirect('/')
    else:
        return ', '.join(errors)

def prepare_flask_request(request):
    url_data = request.get_data().decode('utf-8')
    return {
        'https': 'on' if request.scheme == 'https' else 'off',
        'http_host': request.host,
        'server_port': request.environ.get('SERVER_PORT'),
        'script_name': request.path,
        'get_data': request.args.copy(),
        'post_data': request.form.copy(),
        'query_string': request.query_string.decode('utf-8'),
        'body': url_data,
    }

if __name__ == '__main__':
    app.run()
```

---

## Header-Based Authentication

Header-based authentication involves passing user identity information in HTTP headers. This method is less secure than OIDC or SAML and is generally used in internal networks or when fronted by a trusted proxy.

### Implementation Examples

**Note**: Implementing header-based authentication varies greatly depending on your environment and security requirements. It's crucial to ensure that headers cannot be spoofed by external users.

---

**C# (ASP.NET Core Middleware):**

```csharp
public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
{
    app.Use(async (context, next) =>
    {
        if (context.Request.Headers.ContainsKey("X-User"))
        {
            var username = context.Request.Headers["X-User"];
            var claims = new List<Claim> { new Claim(ClaimTypes.Name, username) };
            var identity = new ClaimsIdentity(claims, "HeaderAuthentication");
            context.User = new ClaimsPrincipal(identity);
        }
        await next.Invoke();
    });

    app.UseRouting();
    app.UseAuthorization();
    app.UseEndpoints(endpoints => { endpoints.MapControllers(); });
}
```

---

**JavaScript (Express.js Middleware):**

```javascript
app.use((req, res, next) => {
  if (req.headers['x-user']) {
    req.user = { name: req.headers['x-user'] };
  }
  next();
});

app.get('/secure', (req, res) => {
  if (req.user) {
    res.send(`Hello, ${req.user.name}`);
  } else {
    res.status(401).send('Unauthorized');
  }
});
```

---

**Python (Flask Middleware):**

```python
from flask import Flask, request, g

app = Flask(__name__)

@app.before_request
def before_request():
    if 'X-User' in request.headers:
        g.user = request.headers.get('X-User')

@app.route('/secure')
def secure():
    user = getattr(g, 'user', None)
    if user:
        return f'Hello, {user}'
    else:
        return 'Unauthorized', 401
```

---

## Best Practices for Integrating with Microsoft Entra ID

When integrating applications with Microsoft Entra ID, following best practices ensures secure, efficient, and maintainable solutions. Below are recommended practices your development teams should consider:

### 1. Utilize Official Libraries and SDKs

- **Use Microsoft Authentication Libraries (MSAL)**: MSAL provides a consistent and reliable way to integrate with Entra ID across different platforms.
- **Stay Updated**: Regularly update libraries and dependencies to benefit from security patches and new features.
- **Avoid Deprecated APIs**: Use the latest APIs and protocols (e.g., OIDC over OAuth 2.0) and avoid using deprecated ones.

### 2. Securely Manage Secrets and Certificates

- **Never Hardcode Secrets**: Do not store client secrets, certificates, or keys in source code or configuration files checked into source control.
- **Use Secure Secret Storage**:
  - **Azure Key Vault**: Store secrets, keys, and certificates securely.
  - **Environment Variables**: Use secured environment variables in deployment environments.
- **Rotate Secrets Regularly**: Implement a process for regularly rotating secrets and certificates.

### 3. Adhere to Security Principles

- **Principle of Least Privilege**: Assign the minimal necessary permissions to applications and users.
- **Validate Tokens**:
  - Verify token signatures and issuer.
  - Check token expiration (`exp` claim).
  - Validate token audience (`aud` claim).
- **Protect Against Common Threats**:
  - Implement CSRF protection.
  - Validate all inputs to prevent injection attacks.
  - Ensure redirect URIs are properly validated.

### 4. Implement Robust Error Handling

- **User-Friendly Messages**: Display generic error messages to end-users without exposing sensitive details.
- **Logging**:
  - Log errors and exceptions with sufficient detail for troubleshooting.
  - Avoid logging sensitive information like access tokens or personal data.
- **Monitoring**: Use logging and monitoring tools to detect and respond to authentication issues.

### 5. Optimize User Experience

- **Single Sign-On (SSO)**: Implement SSO to provide seamless access across multiple applications.
- **Session Management**:
  - Properly manage session timeouts.
  - Handle session revocation appropriately.

### 6. Compliance and Governance

- **Regulatory Compliance**: Ensure your authentication implementation complies with data protection regulations like GDPR or HIPAA.
- **Documentation**: Maintain up-to-date documentation of authentication flows, configurations, and dependencies.

### 7. Testing and Validation

- **Automated Testing**: Include authentication flows in your automated testing.
- **Security Testing**:
  - Conduct regular security assessments and penetration testing.
  - Use tools to scan for vulnerabilities in your authentication implementation.

### 8. Leverage Entra ID Features

- **Conditional Access**:
  - Implement Conditional Access policies for enhanced security.
- **Multi-Factor Authentication (MFA)**:
  - Require MFA for sensitive operations or roles.
- **Identity Protection**:
  - Utilize Entra ID's identity protection features to detect and remediate identity-based risks.

### 9. Scalability and Performance

- **Token Caching**: Cache tokens appropriately to reduce latency and network calls.
- **Asynchronous Calls**: Use asynchronous programming models where applicable.
- **Load Testing**: Perform load testing to ensure the authentication system can handle expected traffic.

### 10. Use Managed Identities

- **Azure Managed Identities**:
  - Use Managed Service Identity (MSI) to let Azure manage the identity of applications, avoiding manual secret management.
  - This is particularly useful when accessing Azure resources like Key Vault, Storage Accounts, etc.

---

## Azure Hosting Scenarios

Hosting applications on Azure provides seamless integration with Entra ID and leverages Azure services to enhance security and scalability.

### Overview

- **Integrated Authentication**: Azure services like App Service and Azure Functions provide built-in authentication capabilities.
- **Managed Services**: Offload infrastructure and identity management to Azure services to focus on application logic.
- **Scalability and Reliability**: Azure provides automatic scaling and high availability options.

---

### 1. Azure App Service Authentication

Azure App Service offers built-in authentication and authorization capabilities (also known as **Easy Auth**).

#### Key Features

- **Zero Code Changes**: Implement authentication without modifying your application code.
- **Multiple Identity Providers**: Supports Entra ID, Facebook, Google, Twitter, and Microsoft Accounts.
- **Token Store**: Automatically stores tokens for authenticated users.

#### Configuration Steps

1. **Enable Authentication**:
   - Go to your App Service in the Azure portal.
   - Under **Settings**, select **Authentication/Authorization**.
   - Turn on **App Service Authentication**.

2. **Configure Identity Provider**:
   - Choose **Log in with Azure Active Directory**.
   - Configure the Azure Active Directory settings:
     - **Express**: Quick setup with default settings.
     - **Advanced**: Custom configuration.
   - Provide necessary details like Client ID and Issuer URL.

3. **Access User Claims**:
   - User claims are available in HTTP headers.
   - Verify the header `X-MS-CLIENT-PRINCIPAL`.

#### Code Example (Accessing User Claims)

**C# (ASP.NET Core)**:

```csharp
// Inside a controller action or middleware
var principalHeader = Request.Headers["X-MS-CLIENT-PRINCIPAL"];
if (!StringValues.IsNullOrEmpty(principalHeader))
{
    var decoded = Convert.FromBase64String(principalHeader);
    var json = Encoding.UTF8.GetString(decoded);
    var principal = JsonConvert.DeserializeObject<Dictionary<string, object>>(json);
    // Access user details from the principal dictionary
}
```

---

### 2. Azure Functions Authentication

Azure Functions can also leverage Easy Auth for securing serverless functions.

#### Steps

- **Enable Authentication**: Similar to App Service, enable authentication in the Azure portal.
- **Set Authorization Level**: In your function, set the authorization level to `Function`, `Anonymous`, or `Admin` as required.
- **Access User Information**: Use the same method to access user claims via headers.

---

### 3. Azure Application Gateway with Entra ID Integration

Azure Application Gateway can provide authentication through integration with Entra ID.

#### Scenarios

- **Centralized Authentication**: Offload authentication to the gateway for all backend services.
- **Web Application Firewall (WAF)**: Protect against common web vulnerabilities.

#### Configuration

1. **Create an Application Gateway**:
   - Configure frontend IP, listeners, and backend pools.

2. **Set Up OAuth 2.0 Authentication**:
   - In the HTTP settings, enable **Azure Active Directory** authentication.
   - Provide client ID and client secret of your Entra ID application.

3. **Backend Configuration**:
   - Ensure backend services accept traffic from the gateway.
   - Remove authentication logic from backend if offloading to the gateway.

---

### 4. Azure Front Door Service

Azure Front Door offers global load balancing and can integrate with Entra ID for authentication.

#### Steps

- **Enable Forwarding**: Configure Front Door to forward requests to your backend services.
- **Integrate with Entra ID**:
  - Use **Azure Front Door Standard/Premium** with **Private Link** and WAF policies.
  - Configure custom domain and SSL certificates.
- **Implement Custom Authentication**:
  - Since Front Door doesn't natively support Entra ID authentication, implement authentication at the backend or use a custom solution.

---

### 5. Azure API Management (APIM)

APIM allows you to publish APIs to internal and external consumers securely.

#### Entra ID Integration

- **Authentication Policies**: Use built-in policies to enforce Entra ID authentication for API access.
- **Developer Portal**: Customize the portal to require Entra ID sign-in for developers.

#### Configuration

1. **Register an Application in Entra ID**: For APIM to use.
2. **Configure OAuth 2.0** Settings in APIM:
   - Set up the OAuth 2.0 authorization server in APIM.
   - Reference the authorization server in API policies.
3. **Apply Authentication Policies**:
   - Use `validate-jwt` policy to enforce token validation.

---

### 6. Azure Kubernetes Service (AKS)

For applications hosted in AKS:

- **Ingress Controllers**: Use ingress controllers that support Entra ID authentication (e.g., NGINX Ingress Controller with OIDC).
- **Pod Identity**:
  - Use **Azure AD Workload Identity** to grant pods access to Entra ID protected resources.
- **Role-Based Access Control**:
  - Implement Kubernetes RBAC using Entra ID identities.

---

### 7. Azure Virtual Machines and VM Scale Sets

For applications running on VMs:

- **Managed Identities**:
  - Assign system-assigned or user-assigned managed identities to VMs.
  - Use these identities to authenticate to Azure services without credentials.
- **Entra ID Domain Services**:
  - Join VMs to Entra ID Domain Services for LDAP and Kerberos support.

---

### 8. Managed Identity for Azure Resources

Leverage Managed Identities to access Azure resources securely.

#### Benefits

- **Credential Management**: Azure handles the credential rotation automatically.
- **Security**: Reduces the risk of credential exposure.
- **Simplicity**: Simplifies code by eliminating the need for explicit secrets.

#### Usage

- **System-Assigned Managed Identity**: Tied to the lifecycle of the service instance.
- **User-Assigned Managed Identity**: Independent of the service instance, reusable across multiple services.

---

### 9. Application Insights and Monitoring

For applications hosted on Azure, use Application Insights to:

- **Monitor Performance**: Track response times, request rates, and failure rates.
- **Track Dependencies**: Monitor calls to external services.
- **Custom Events and Metrics**: Collect application-specific telemetry.

---

### 10. Azure B2C for Customer-Facing Applications

If your application is intended for external users:

- **Azure Active Directory B2C**:
  - Provides identity management for customer-facing apps.
  - Supports various identity providers (social accounts, email sign-up).
  - Highly customizable user experience.

#### Integration Steps

1. **Create an Azure B2C Tenant**.
2. **Register Your Application**:
   - Configure reply URLs and scopes.
3. **Configure User Flows**:
   - Create sign-up and sign-in policies.
   - Customize UI and branding.

---

## Samples

The `Samples` folder contains sample applications demonstrating how to integrate with Microsoft Entra ID using various languages and frameworks.

### Available Samples

- [Plain JavaScript Application using MSAL.js](#plain-javascript-sample-using-msaljs)
- [React Application using MSAL React](#react-sample-using-msal-react)

---

## Plain JavaScript Sample using MSAL.js

**Folder**: [`Samples/JavaScriptSinglePageApp`](Samples/JavaScriptSinglePageApp)

**Description**: A simple single-page application using vanilla JavaScript and the MSAL.js library to authenticate users with Microsoft Entra ID. Demonstrates how to sign in users and display basic user information.

### Running the Sample

1. **Register the Application**: Follow the instructions to register the app in Entra ID.

2. **Install Dependencies**:

   ```bash
   npm install
   ```

3. **Configure `authConfig.js`**: Replace `"YOUR_CLIENT_ID"` with your actual client ID.

4. **Run the Application**:

   ```bash
   node server.js
   ```

5. **Access the Application**: Navigate to `http://localhost:3000/` in your browser.

---

## React Sample using MSAL React

**Folder**: [`Samples/ReactSinglePageApp`](Samples/ReactSinglePageApp)

**Description**: A React application that utilizes the MSAL React library for authenticating users with Microsoft Entra ID. Shows how to implement authentication flows, manage user sessions, and display user data in a React app.

### Running the Sample

1. **Register the Application**: Follow the instructions to register the app in Entra ID.

2. **Install Dependencies**:

   ```bash
   npm install
   ```

3. **Configure `authConfig.js`**: Replace `"YOUR_CLIENT_ID"` with your actual client ID.

4. **Run the Application**:

   ```bash
   npm start
   ```

5. **Access the Application**: Navigate to `http://localhost:3000/` in your browser.

---

### Notes for Both Samples

- **Replace Placeholders**: Ensure all placeholders like `"YOUR_CLIENT_ID"` are replaced with actual values from your Entra ID app registration.
- **CORS Policies**: Ensure that your Entra ID app registration allows requests from `http://localhost:3000/`.
- **HTTPS**: While these samples use HTTP for simplicity, it's recommended to use HTTPS in production environments.

---

## Additional Resources

- **Microsoft Entra ID Documentation**:  
  [Microsoft Identity Platform](https://docs.microsoft.com/azure/active-directory/develop/)

- **MSAL Libraries**:  
  [MSAL Overview](https://docs.microsoft.com/azure/active-directory/develop/msal-overview)

- **SAML Authentication with Entra ID**:  
  [Tutorial: Azure Active Directory single sign-on (SSO) integration](https://docs.microsoft.com/azure/active-directory/saas-apps/saml-toolkit-tutorial)

- **OIDC Implementation Samples**:  
  - [Microsoft.Identity.Web Samples](https://github.com/AzureAD/microsoft-identity-web/tree/master/samples)
  - [Passport-Azure-AD Samples](https://github.com/AzureAD/passport-azure-ad/tree/master/samples)

- **Azure Hosting Scenarios**:  
  - [App Service Authentication](https://docs.microsoft.com/azure/app-service/overview-authentication-authorization)
  - [Azure Functions Authentication](https://docs.microsoft.com/azure/azure-functions/functions-secure-your-function)
  - [Azure API Management Authentication Policies](https://docs.microsoft.com/azure/api-management/api-management-access-restriction-policies#ValidateJWT)

---

For any further assistance or specific implementation details, please consult the official documentation or reach out to the project maintainers.

---

**Maintainers**:
- [Your Name](mailto:your.email@example.com)
- [Project Team](mailto:project.team@example.com)

Feel free to contribute to this guide by submitting a pull request or opening an issue.

---

# License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

# Acknowledgments

- Microsoft Documentation
- Community Contributions

---

Happy coding!