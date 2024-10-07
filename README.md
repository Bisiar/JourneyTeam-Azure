# Microsoft Entra ID Integration Guide

This repository provides comprehensive guides and sample applications to help development teams integrate their applications with **Microsoft Entra ID** (formerly Azure Active Directory) using various authentication protocols.

---

## Table of Contents

- [Microsoft Entra ID Integration Guide](#microsoft-entra-id-integration-guide)
  - [Table of Contents](#table-of-contents)
  - [Introduction](#introduction)
  - [Prerequisites](#prerequisites)
  - [Authentication Patterns](#authentication-patterns)
    - [Common Authentication Patterns](#common-authentication-patterns)
    - [OpenID Connect (OIDC) Integration](#openid-connect-oidc-integration)
      - [Steps:](#steps)
      - [C# Example](#c-example)
    - [SAML Integration](#saml-integration)
      - [Steps:](#steps-1)
      - [C# Example](#c-example-1)
    - [Header-Based Authentication](#header-based-authentication)
      - [Implementation Examples](#implementation-examples)
  - [Authorization Patterns](#authorization-patterns)
    - [Common Authorization Strategies](#common-authorization-strategies)
    - [Implementing Authorization](#implementing-authorization)
    - [Examples](#examples)
      - [C# (ASP.NET Core)](#c-aspnet-core)
      - [JavaScript (Node.js with Express)](#javascript-nodejs-with-express)
  - [User Lifecycle Management](#user-lifecycle-management)
    - [Common User Lifecycle Management Methods](#common-user-lifecycle-management-methods)
    - [Just-in-Time (JIT) Provisioning](#just-in-time-jit-provisioning)
    - [SCIM (System for Cross-domain Identity Management)](#scim-system-for-cross-domain-identity-management)
    - [LDAP Integration](#ldap-integration)
    - [Manual Provisioning](#manual-provisioning)
  - [Best Practices for Integrating with Microsoft Entra ID](#best-practices-for-integrating-with-microsoft-entra-id)
  - [Azure Hosting Scenarios](#azure-hosting-scenarios)
  - [Samples](#samples)
    - [Available Samples](#available-samples)
  - [Additional Resources](#additional-resources)
  - [License](#license)
  - [Acknowledgments](#acknowledgments)

---

## Introduction

**Microsoft Entra ID** is a cloud-based identity and access management service that helps your employees sign in and access resources. Integrating your applications with Entra ID allows for secure authentication and authorization using industry-standard protocols like **SAML** and **OpenID Connect (OIDC)**.

This guide provides detailed instructions and code examples to help development teams connect their applications to Entra ID using **SAML**, **OIDC**, or **header-based authentication**. Additionally, it covers authentication patterns, authorization strategies, and user lifecycle management options.

---

## Prerequisites

- **Microsoft Entra ID Tenant**: Access to an Entra ID tenant where you can register your application.
- **Application Registration**: Your application must be registered in Entra ID.
- **Development Environment**: Set up for C#, JavaScript, or Python.
- **Basic Knowledge**: Understanding of authentication protocols and the programming language you're using.

---

## Authentication Patterns

Authentication is the process of verifying the identity of a user or system. Microsoft Entra ID supports several authentication patterns to accommodate various application types and scenarios.

### Common Authentication Patterns

- **OpenID Connect (OIDC)**: Suitable for modern web applications and APIs, providing authentication and authorization in a simple and standardized way.
- **SAML (Security Assertion Markup Language)**: Often used in enterprise applications for single sign-on (SSO) scenarios.
- **Header-Based Authentication**: Used in scenarios where a trusted intermediary handles authentication and passes user information via HTTP headers.

---

### OpenID Connect (OIDC) Integration

OIDC is a simple identity layer on top of the OAuth 2.0 protocol. It allows clients to verify the identity of the end-user based on the authentication performed by an authorization server.

#### Steps:

1. **Register your application in Entra ID**.
2. **Configure application settings**.
3. **Implement authentication logic**.

#### C# Example

*(Previously provided content remains the same.)*

---

### SAML Integration

SAML allows service providers and identity providers to securely exchange user authentication and authorization data. It's widely adopted for enterprise single sign-on.

#### Steps:

1. **Register your application for SAML in Entra ID**.
2. **Configure the SAML settings in your application**.
3. **Implement the SAML authentication flow**.

#### C# Example

*(Previously provided content remains the same.)*

---

### Header-Based Authentication

Header-based authentication involves passing user identity information in HTTP headers. This method is less secure than OIDC or SAML and is generally used in internal networks or when fronted by a trusted proxy that handles authentication.

#### Implementation Examples

*(Previously provided content remains the same.)*

---

## Authorization Patterns

Authorization determines what authenticated users are allowed to do within an application. Microsoft Entra ID can provide user and group information, roles, and permissions that your application can use to enforce authorization policies.

### Common Authorization Strategies

1. **Role-Based Access Control (RBAC)**:
   - Assign roles to users or groups.
   - Use roles to control access to resources or functionalities within the application.
   - Roles can be defined in Entra ID and assigned via application registration.

2. **Claims-Based Access Control**:
   - Use claims in the authentication token to make authorization decisions.
   - Claims can include user attributes, groups, roles, or custom data.
   - Application reads claims from the token and enforces policies accordingly.

3. **Policy-Based Access Control**:
   - Define policies that determine access based on conditions (e.g., user attributes, environmental context).
   - Policies can be enforced within the application or using a policy engine like Azure AD Conditional Access.

4. **Attribute-Based Access Control (ABAC)**:
   - Decisions are made based on attributes of the user, resource, and environment.
   - Provides fine-grained access control.

### Implementing Authorization

- **In Code**: Check user roles or claims within your application code before performing actions or displaying content.
- **Using Middleware**: Employ middleware to enforce authorization rules globally or on specific routes.
- **Using Entra ID Groups**:
  - Synchronize Entra ID groups into your application.
  - Use group membership to control access.

### Examples

#### C# (ASP.NET Core)

```csharp
// Startup.cs
services.AddAuthorization(options =>
{
    options.AddPolicy("AdminOnly", policy => policy.RequireRole("Admin"));
});

// Controller
[Authorize(Policy = "AdminOnly")]
public IActionResult AdminOnlyAction()
{
    return View();
}
```

#### JavaScript (Node.js with Express)

```javascript
function ensureAdmin(req, res, next) {
  if (req.user && req.user.roles.includes('Admin')) {
    return next();
  }
  res.status(403).send('Forbidden');
}

app.get('/admin', ensureAuthenticated, ensureAdmin, (req, res) => {
  res.send('Welcome Admin');
});
```

---

## User Lifecycle Management

User lifecycle management involves handling user accounts from creation to deletion, including updates and provisioning. Effective user management ensures that the right users have appropriate access at the right time.

### Common User Lifecycle Management Methods

1. **Just-in-Time (JIT) Provisioning**
2. **SCIM (System for Cross-domain Identity Management)**
3. **LDAP Integration**
4. **Manual Provisioning**

---

### Just-in-Time (JIT) Provisioning

**Overview**

- JIT provisioning automatically creates user accounts in your application upon successful authentication.
- Eliminates the need for pre-provisioning users in the application database.
- User attributes are extracted from the authentication token and used to create the user profile.

**Implementation Steps**

1. **Configure your application** to extract user attributes from the authentication token.
2. **Implement logic** to create user accounts or update existing ones during the login process.
3. **Map attributes** from the token to your application's user model.

**Advantages**

- Simplifies user onboarding.
- Reduces administrative overhead.
- Ensures user information is up-to-date.

**Considerations**

- Ensure that mandatory user attributes are included in the token.
- Implement security measures to prevent unauthorized account creation.

---

### SCIM (System for Cross-domain Identity Management)

**Overview**

- SCIM is an open standard for automating the exchange of user identity information between identity domains or IT systems.
- SCIM 2.0 is supported by Microsoft Entra ID for user and group provisioning.

**Implementation Steps**

1. **Implement SCIM Endpoint**: Develop a RESTful API in your application that conforms to the SCIM protocol specifications.
2. **Configure SCIM in Entra ID**:
   - In your app registration, navigate to **Provisioning**.
   - Set the **Provisioning Mode** to **Automatic** and provide the SCIM endpoint URL and credentials.
3. **Define Attribute Mappings**: Map Entra ID user attributes to your application's user schema.

**Advantages**

- Automates user provisioning and deprovisioning.
- Keeps user data synchronized between Entra ID and your application.
- Supports group management.

**Considerations**

- Implement error handling and logging for provisioning actions.
- Secure your SCIM endpoint with proper authentication and authorization.

**Resources**

- [SCIM API Guidelines](https://docs.microsoft.com/azure/active-directory/app-provisioning/use-scim-to-provision-users-and-groups)

---

### LDAP Integration

**Overview**

- LDAP (Lightweight Directory Access Protocol) is a protocol for accessing and maintaining distributed directory information services.
- Microsoft Entra ID Domain Services (managed domain) can provide LDAP access to Entra ID data.

**Implementation Steps**

1. **Enable Entra ID Domain Services**:
   - Set up an instance of Entra ID Domain Services in your Azure environment.

2. **Connect to LDAP**:
   - Configure your application to connect to the Entra ID Domain Services LDAP endpoint.
   - Use secure LDAP (LDAPS) for encrypted communication.

3. **Authenticate Users**:
   - Use LDAP binds or queries to authenticate users and retrieve user information.

**Advantages**

- Supports legacy applications that require LDAP.
- Provides compatibility with applications designed for on-premises Active Directory.

**Considerations**

- **Security**: Ensure secure LDAP (LDAPS) is used.
- **Network Access**: Applications must be within the virtual network or have connectivity to it.
- **Maintenance**: Entra ID Domain Services incurs additional cost and management overhead.

**Resources**

- [Azure Active Directory Domain Services](https://docs.microsoft.com/azure/active-directory-domain-services/overview)

---

### Manual Provisioning

**Overview**

- Involves manually creating user accounts in your application.
- Suitable for small applications or when automated provisioning is not feasible.

**Implementation Steps**

1. **Create Administrative Interfaces**:
   - Provide tools or interfaces for administrators to add, update, and remove users.

2. **Synchronize with Entra ID**:
   - Periodically sync user information from Entra ID using scripts or manual processes.
   - Export user data from Entra ID and import it into your application.

**Advantages**

- Simple to implement.
- Complete control over user data.

**Considerations**

- **Scalability**: Not suitable for large organizations or frequent changes.
- **Data Consistency**: Risk of outdated or inconsistent user information.
- **Administrative Overhead**: Requires ongoing manual effort.

---

## Best Practices for Integrating with Microsoft Entra ID

*(Previously provided content remains the same.)*

---

## Azure Hosting Scenarios

*(Previously provided content remains the same.)*

---

## Samples

The `Samples` folder contains sample applications demonstrating how to integrate with Microsoft Entra ID using various languages and frameworks.

### Available Samples

- **Plain JavaScript Application using MSAL.js**
  - **Folder**: [`Samples/JavaScriptSinglePageApp`](Samples/JavaScriptSinglePageApp)
  - **Description**: A simple single-page application using vanilla JavaScript and the MSAL.js library to authenticate users with Microsoft Entra ID. Demonstrates how to sign in users and display basic user information.

- **React Application using MSAL React**
  - **Folder**: [`Samples/ReactSinglePageApp`](Samples/ReactSinglePageApp)
  - **Description**: A React application that utilizes the MSAL React library for authenticating users with Microsoft Entra ID. Shows how to implement authentication flows, manage user sessions, and display user data in a React app.

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

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Acknowledgments

- Microsoft Documentation
- Community Contributions

---

**Maintainers**:
- [Your Name](mailto:your.email@example.com)
- [Project Team](mailto:project.team@example.com)

Feel free to contribute to this guide by submitting a pull request or opening an issue.

---

Happy coding!