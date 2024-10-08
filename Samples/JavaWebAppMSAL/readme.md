### Creating the JavaWebAppMSAL Application

Since you requested assistance in creating the **JavaWebAppMSAL** application, here's a detailed step-by-step guide to help you set it up.

#### Prerequisites

- **Java Development Kit (JDK)**: Ensure JDK 8 or above is installed.
- **Maven**: Installed on your system.
- **IDE**: An IDE like IntelliJ IDEA, Eclipse, or Visual Studio Code.

#### Step-by-Step Instructions

1. **Clone or Create the Project Directory**

   Create a directory for your project:

   ```bash
   mkdir JavaWebAppMSAL
   cd JavaWebAppMSAL
   ```

2. **Initialize a Maven Project**

   Create a basic Maven project structure:

   ```bash
   mvn archetype:generate -DgroupId=com.example -DartifactId=JavaWebAppMSAL -DarchetypeArtifactId=maven-archetype-quickstart -DinteractiveMode=false
   cd JavaWebAppMSAL
   ```

3. **Update `pom.xml`**

   Replace the contents of `pom.xml` with the following:

   ```xml
   <!-- pom.xml -->

   <project xmlns="http://maven.apache.org/POM/4.0.0"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
            http://maven.apache.org/xsd/maven-4.0.0.xsd">
       <modelVersion>4.0.0</modelVersion>
       <groupId>com.example</groupId>
       <artifactId>JavaWebAppMSAL</artifactId>
       <version>1.0.0</version>
       <packaging>jar</packaging>
       <name>JavaWebAppMSAL</name>

       <properties>
           <java.version>1.8</java.version>
           <spring.boot.version>2.5.4</spring.boot.version>
       </properties>

       <dependencies>
           <!-- Spring Boot Starter -->
           <dependency>
               <groupId>org.springframework.boot</groupId>
               <artifactId>spring-boot-starter-web</artifactId>
               <version>${spring.boot.version}</version>
           </dependency>
           <!-- Thymeleaf -->
           <dependency>
               <groupId>org.springframework.boot</groupId>
               <artifactId>spring-boot-starter-thymeleaf</artifactId>
               <version>${spring.boot.version}</version>
           </dependency>
           <!-- MSAL4J -->
           <dependency>
               <groupId>com.microsoft.azure</groupId>
               <artifactId>msal4j</artifactId>
               <version>1.11.0</version>
           </dependency>
       </dependencies>

       <build>
           <plugins>
               <plugin>
                   <groupId>org.springframework.boot</groupId>
                   <artifactId>spring-boot-maven-plugin</artifactId>
                   <version>${spring.boot.version}</version>
               </plugin>
           </plugins>
       </build>
   </project>
   ```

4. **Create the Project Structure**

   ```
   src/
   ├── main/
   │   ├── java/
   │   │   └── com/example/
   │   │       ├── controllers/
   │   │       │   └── AuthController.java
   │   │       └── MsalApp.java
   │   └── resources/
   │       ├── application.properties
   │       └── templates/
   │           ├── index.html
   │           └── welcome.html
   ```

5. **Implement the Application**

   - **MsalApp.java**

     ```java
     package com.example;

     import org.springframework.boot.SpringApplication;
     import org.springframework.boot.autoconfigure.SpringBootApplication;

     @SpringBootApplication
     public class MsalApp {
         public static void main(String[] args) {
             SpringApplication.run(MsalApp.class, args);
         }
     }
     ```

   - **AuthController.java**

     ```java
     package com.example.controllers;

     import com.microsoft.aad.msal4j.*;
     import org.springframework.beans.factory.annotation.Value;
     import org.springframework.stereotype.Controller;
     import org.springframework.ui.Model;
     import org.springframework.web.bind.annotation.GetMapping;
     import org.springframework.web.bind.annotation.RequestParam;

     import javax.servlet.http.HttpSession;
     import java.net.URI;
     import java.util.Collections;

     @Controller
     public class AuthController {

         @Value("${azure.activedirectory.client-id}")
         private String clientId;

         @Value("${azure.activedirectory.client-secret}")
         private String clientSecret;

         @Value("${azure.activedirectory.tenant-id}")
         private String tenantId;

         @Value("${azure.activedirectory.redirect-uri}")
         private String redirectUri;

         private static final String AUTHORITY_FORMAT = "https://login.microsoftonline.com/%s";

         @GetMapping("/")
         public String index() {
             return "index";
         }

         @GetMapping("/login")
         public String login(HttpSession session) throws Exception {
             String authority = String.format(AUTHORITY_FORMAT, tenantId);

             ConfidentialClientApplication app = ConfidentialClientApplication.builder(clientId,
                     ClientCredentialFactory.createFromSecret(clientSecret))
                     .authority(authority)
                     .build();

             String authorizationCodeUrl = app.getAuthorizationRequestUrl(Collections.singleton("User.Read"))
                     .redirectUri(redirectUri)
                     .build()
                     .toString();

             return "redirect:" + authorizationCodeUrl;
         }

         @GetMapping("/redirect")
         public String redirect(@RequestParam("code") String code, HttpSession session, Model model) throws Exception {
             String authority = String.format(AUTHORITY_FORMAT, tenantId);

             ConfidentialClientApplication app = ConfidentialClientApplication.builder(clientId,
                     ClientCredentialFactory.createFromSecret(clientSecret))
                     .authority(authority)
                     .build();

             AuthorizationCodeParameters parameters = AuthorizationCodeParameters.builder(code, new URI(redirectUri))
                     .scopes(Collections.singleton("User.Read"))
                     .build();

             IAuthenticationResult result = app.acquireToken(parameters).get();

             session.setAttribute("username", result.account().username());
             model.addAttribute("username", result.account().username());

             return "welcome";
         }
     }
     ```

6. **Configure Application Properties**

   - Create **`src/main/resources/application.properties`**

     ```properties
     azure.activedirectory.client-id=YOUR_CLIENT_ID
     azure.activedirectory.client-secret=YOUR_CLIENT_SECRET
     azure.activedirectory.tenant-id=YOUR_TENANT_ID
     azure.activedirectory.redirect-uri=http://localhost:8080/redirect
     ```

     Replace `YOUR_CLIENT_ID`, `YOUR_CLIENT_SECRET`, and `YOUR_TENANT_ID` with actual values from your app registration in Entra ID.

7. **Create HTML Templates**

   - **index.html**

     ```html
     <!-- src/main/resources/templates/index.html -->

     <!DOCTYPE html>
     <html xmlns:th="http://www.thymeleaf.org">
     <head>
         <meta charset="UTF-8">
         <title>Java MSAL Sample</title>
     </head>
     <body>
         <h1>Welcome to the Java MSAL Sample Application</h1>
         <a href="/login">Sign In</a>
     </body>
     </html>
     ```

   - **welcome.html**

     ```html
     <!-- src/main/resources/templates/welcome.html -->

     <!DOCTYPE html>
     <html xmlns:th="http://www.thymeleaf.org">
     <head>
         <meta charset="UTF-8">
         <title>Java MSAL Sample</title>
     </head>
     <body>
         <h1>Welcome, <span th:text="${username}">User</span></h1>
         <a href="/">Home</a>
     </body>
     </html>
     ```

8. **Register the Application in Entra ID**

   - **Sign in** to the [Azure Portal](https://portal.azure.com/).
   - Navigate to **Azure Active Directory** > **App registrations** > **New registration**.
   - Fill in the details:
     - **Name**: `JavaWebAppMSAL`
     - **Supported account types**: Choose based on your scenario.
     - **Redirect URI**: Set the type to **Web** and enter `http://localhost:8080/redirect`.
   - **Click** **Register**.
   - **Copy** the **Application (client) ID** and **Directory (tenant) ID**.
   - **Create a Client Secret**:
     - Under **Certificates & secrets**, click **New client secret**.
     - Provide a description and expiration period.
     - Click **Add** and copy the secret value.
   - Update **`application.properties`** with these values.

9. **Run the Application**

   - Build and run the application:

     ```bash
     mvn spring-boot:run
     ```

     Alternatively, you can package it:

     ```bash
     mvn clean package
     java -jar target/JavaWebAppMSAL-1.0.0.jar
     ```

   - Open a browser and navigate to `http://localhost:8080/`.
   - Click on **Sign In** to authenticate with Microsoft Entra ID.
   - Upon successful login, you should see a welcome message with your username.

#### Notes

- **Security Considerations**:
  - Never expose client secrets in source code or commit them to source control.
  - Use environment variables or secure configuration mechanisms in production.

- **HTTPS**:
  - For production environments, always use HTTPS to protect sensitive data.

- **Dependencies**:
  - Ensure that you have the correct versions of dependencies specified in the `pom.xml`.

- **Troubleshooting**:
  - If you encounter issues, check the console logs for errors.
  - Verify that all configuration values are correct.

#### Additional Resources

- [Spring Boot Documentation](https://spring.io/projects/spring-boot)
- [MSAL4J GitHub Repository](https://github.com/AzureAD/microsoft-authentication-library-for-java)
- [Azure AD Java Web App Getting Started](https://docs.microsoft.com/azure/active-directory/develop/tutorial-v2-java-webapp-msal)
