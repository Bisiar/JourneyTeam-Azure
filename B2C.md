
# Introduction to Microsoft Entra External ID and Azure AD B2C

## What is Microsoft Entra External ID?

Microsoft Entra External ID combines powerful solutions for working with people outside of your organization. With External ID capabilities, you can allow external identities to securely access your apps and resources. Whether you’re working with external partners, consumers, or business customers, users can bring their own identities. These identities can range from corporate or government-issued accounts to social identity providers like Google or Facebook.

![Microsoft Entra External ID Overview](https://learn.microsoft.com/en-us/entra/external-id/media/external-identities-overview/external-identities-overview.png)

---

## What is Azure Active Directory B2C?

Azure Active Directory B2C (Azure AD B2C) is a business-to-customer identity as a service solution, allowing customers to use their preferred identities for single sign-on access to applications and APIs. Azure AD B2C supports millions of users and provides robust security and scalability.

![Infographic of Azure AD B2C identity providers and downstream applications](https://github.com/MicrosoftDocs/azure-docs/raw/main/articles/active-directory-b2c/media/overview/azureadb2c-overview.png)

![Infographic of Azure AD B2C architecture](https://github.com/MicrosoftDocs/azure-docs/blob/main/articles/active-directory-b2c/media/b2c-global-identity-solutions/b2c-architecture.png?raw=true)

![Infographic of Azure AD B2C with api](https://github.com/MicrosoftDocs/azure-docs/blob/main/articles/active-directory-b2c/media/configure-authentication-sample-web-app-with-api/web-app-with-api-architecture.png?raw=true)

![Infographic of Azure AD B2C with application insights](https://github.com/MicrosoftDocs/azure-docs/blob/main/articles/active-directory-b2c/media/analytics-with-application-insights/app-ins-graphic.png?raw=true)

## Comparison of Microsoft Entra External ID, Azure AD B2C, and Regular Azure AD Users

| Feature/Aspect             | Azure AD B2C Users | Microsoft Entra External ID Users | Regular Azure AD Users |
|----------------------------|--------------------|-----------------------------------|------------------------|
| **Primary Scenario**       | Customer-facing applications for sign-in/sign-up. | External collaboration and customer CIAM for apps. | Internal organizational use. |
| **Account Types**          | Local and social accounts. | Social, corporate, and partner identities. | Work or school accounts. |
| **Customization**          | Extensive branding and user journey customization. | Custom sign-in for external scenarios. | Limited customization. |
| **SSO Support**            | SSO for apps connected to Azure AD B2C. | SSO for apps registered in external tenant configuration. | SSO to Microsoft 365 and enterprise apps. |
| **User Management**        | Separate directory for consumer identities. | Managed in workforce/external tenant configurations. | Managed within organization directory. |

---

## Use Case Examples and Code Samples

### 1. Updating a User Attribute

**Use Case:** Update a user's display name using Microsoft Graph.

#### C# Example

```csharp
using Microsoft.Graph;
using System.Threading.Tasks;

public async Task UpdateUserDisplayName(GraphServiceClient graphClient, string userId, string newDisplayName)
{
    var user = new User
    {
        DisplayName = newDisplayName
    };

    await graphClient.Users[userId]
        .Request()
        .UpdateAsync(user);
}
```

#### JavaScript Example

```javascript
const graphClient = MicrosoftGraph.Client.init({
    authProvider: (done) => {
        done(null, accessToken);
    }
});

const userId = "user-id";
graphClient
    .api(`/users/${userId}`)
    .update({ displayName: "New Display Name" })
    .then(response => {
        console.log("User's display name updated:", response);
    })
    .catch(error => {
        console.error("Error updating user's display name:", error);
    });
```

#### PowerShell Example

```powershell
Connect-AzureAD
$UserId = "user-id"
Set-AzureADUser -ObjectId $UserId -DisplayName "New Display Name"
```

---

### 2. Linking a User to an External Identity

**Use Case:** Link a user to a social identity using Microsoft Graph API.

#### C# Example

```csharp
using Microsoft.Graph;
using System.Threading.Tasks;

public async Task LinkUserToExternalIdentity(GraphServiceClient graphClient, string userId, string issuer, string issuerUserId)
{
    var externalIdentity = new ObjectIdentity
    {
        SignInType = "federated",
        Issuer = issuer,
        IssuerAssignedId = issuerUserId
    };

    var user = await graphClient.Users[userId]
        .Request()
        .GetAsync();

    user.Identities.Add(externalIdentity);

    await graphClient.Users[userId]
        .Request()
        .UpdateAsync(user);
}
```

#### JavaScript Example

```javascript
const graphClient = MicrosoftGraph.Client.init({
    authProvider: (done) => {
        done(null, accessToken);
    }
});

const userId = "user-id";
const identity = {
    signInType: "federated",
    issuer: "google.com",
    issuerAssignedId: "external-user-id"
};

graphClient
    .api(`/users/${userId}`)
    .patch({ identities: [identity] })
    .then(response => {
        console.log("User linked to external identity:", response);
    })
    .catch(error => {
        console.error("Error linking user:", error);
    });
```

#### PowerShell Example

```powershell
Connect-AzureAD
$UserId = "user-id"
$Identity = @{
    SignInType = "federated"
    Issuer = "google.com"
    IssuerAssignedId = "external-user-id"
}
Set-AzureADUser -ObjectId $UserId -Identities @($Identity)
```

---

### 3. Converting a Local Account to a Social Account

**Use Case:** Convert a user's local account to a social account by linking and optionally removing local identity.

#### C# Example

```csharp
using Microsoft.Graph;
using System.Threading.Tasks;

public async Task ConvertLocalToSocialAccount(GraphServiceClient graphClient, string userId, string issuer, string issuerUserId)
{
    var user = await graphClient.Users[userId]
        .Request()
        .GetAsync();

    var socialIdentity = new ObjectIdentity
    {
        SignInType = "federated",
        Issuer = issuer,
        IssuerAssignedId = issuerUserId
    };

    user.Identities.Add(socialIdentity);

    await graphClient.Users[userId]
        .Request()
        .UpdateAsync(user);
}
```

#### JavaScript Example

```javascript
const graphClient = MicrosoftGraph.Client.init({
    authProvider: (done) => {
        done(null, accessToken);
    }
});

const userId = "user-id";
const newSocialIdentity = {
    signInType: "federated",
    issuer: "facebook.com",
    issuerAssignedId: "external-user-id"
};

graphClient
    .api(`/users/${userId}`)
    .patch({ identities: [newSocialIdentity] })
    .then(response => {
        console.log("User converted to social account:", response);
    })
    .catch(error => {
        console.error("Error converting user:", error);
    });
```

#### PowerShell Example

```powershell
Connect-AzureAD
$UserId = "user-id"
$NewIdentity = @{
    SignInType = "federated"
    Issuer = "facebook.com"
    IssuerAssignedId = "external-user-id"
}
Set-AzureADUser -ObjectId $UserId -Identities @($NewIdentity)
```

---

## Additional Resources
- [Azure AD B2C Documentation](https://learn.microsoft.com/en-us/azure/active-directory-b2c/overview)
- [Microsoft Entra External ID Overview](https://learn.microsoft.com/en-us/entra/external-id/overview)
