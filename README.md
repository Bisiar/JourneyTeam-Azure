# Microsoft Entra ID Integration Guide

This repository provides comprehensive guides and sample applications to help development teams integrate their applications with **Microsoft Entra ID** (formerly Azure Active Directory), with a primary focus on Java implementations while also supporting other platforms.

[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat)](http://makeapullrequest.com)
[![Documentation Status](https://readthedocs.org/projects/ansicolortags/badge/?version=latest)](http://ansicolortags.readthedocs.io/?badge=latest)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/your/repo/graphs/commit-activity)

## Introduction to Microsoft Identity

Microsoft Identity Platform provides enterprise-grade identity services that seamlessly integrate with your applications. This guide focuses on implementing secure authentication and authorization using Java, while also providing examples in other languages to support heterogeneous environments.

### Core Components

The platform consists of several key components:

1. **Authentication Service**: Handles user and application authentication, providing secure token issuance and validation.
2. **Authorization Framework**: Manages access control and permissions across your applications.
3. **User Management**: Provides comprehensive identity lifecycle management.

## Prerequisites

### Java Development Environment

1. **Java Requirements**
   ```xml
   <!-- Minimum requirements in pom.xml -->
   <properties>
       <java.version>11</java.version>
       <spring-boot.version>2.7.0</spring-boot.version>
       <msal4j.version>1.13.0</msal4j.version>
   </properties>
   
   <dependencies>
       <!-- Microsoft Authentication Library for Java -->
       <dependency>
           <groupId>com.microsoft.azure</groupId>
           <artifactId>msal4j</artifactId>
           <version>${msal4j.version}</version>
       </dependency>
       
       <!-- Spring Boot Starter -->
       <dependency>
           <groupId>org.springframework.boot</groupId>
           <artifactId>spring-boot-starter-oauth2-client</artifactId>
           <version>${spring-boot.version}</version>
       </dependency>
       
       <!-- Microsoft Graph SDK -->
       <dependency>
           <groupId>com.microsoft.graph</groupId>
           <artifactId>microsoft-graph</artifactId>
           <version>5.65.0</version>
       </dependency>
   </dependencies>
   ```

2. **Configuration Setup**
   ```yaml
   # application.yml
   spring:
     security:
       oauth2:
         client:
           registration:
             azure:
               client-id: ${AZURE_CLIENT_ID}
               client-secret: ${AZURE_CLIENT_SECRET}
               scope:
                 - openid
                 - profile
                 - email
                 - User.Read
           provider:
             azure:
               issuer-uri: https://login.microsoftonline.com/${AZURE_TENANT_ID}/v2.0
   ```

### Alternative Platforms Support

While our primary focus is Java, here are the requirements for other supported platforms:

- **.NET**: .NET 6.0 or later
- **Node.js**: Version 14.x or later
- **Python**: Version 3.8 or later

## Getting Started

### Basic Java Configuration

1. **Initialize Authentication Configuration**
   ```java
   @Configuration
   @EnableWebSecurity
   public class SecurityConfig extends WebSecurityConfigurerAdapter {
       
       @Override
       protected void configure(HttpSecurity http) throws Exception {
           http
               .authorizeRequests()
                   .antMatchers("/", "/login", "/public/**").permitAll()
                   .anyRequest().authenticated()
               .and()
               .oauth2Login()
                   .userInfoEndpoint()
                   .oidcUserService(oidcUserService());
       }
       
       @Bean
       public OAuth2UserService<OidcUserRequest, OidcUser> oidcUserService() {
           return new CustomOidcUserService();
       }
   }
   ```

2. **Create Custom User Service**
   ```java
   @Service
   @Slf4j
   public class CustomOidcUserService extends DefaultOAuth2UserService {
       
       @Autowired
       private UserRepository userRepository;
       
       @Override
       public OAuth2User loadUser(OAuth2UserRequest userRequest) 
           throws OAuth2AuthenticationException {
           
           OAuth2User user = super.loadUser(userRequest);
           
           try {
               return processOAuth2User(userRequest, user);
           } catch (Exception ex) {
               log.error("Failed to process user registration", ex);
               throw new InternalAuthenticationServiceException(ex.getMessage(), ex);
           }
       }
       
       private OAuth2User processOAuth2User(OAuth2UserRequest request, OAuth2User user) {
           String email = user.getAttribute("email");
           
           Optional<User> userOptional = userRepository.findByEmail(email);
           User userEntity;
           
           if (userOptional.isPresent()) {
               userEntity = userOptional.get();
               userEntity = updateExistingUser(userEntity, user);
           } else {
               userEntity = registerNewUser(request, user);
           }
           
           return UserPrincipal.create(userEntity, user.getAttributes());
       }
   }
   ```

## Authentication vs. Authorization

Understanding the distinction between authentication and authorization is crucial for implementing secure applications. Let's explore this through practical implementations in Java, C#, and Python.

### Authentication Implementation

#### Java (Spring Boot)
```java
@Configuration
@EnableWebSecurity
public class SecurityConfiguration extends WebSecurityConfigurerAdapter {
    
    @Autowired
    private CustomOidcUserService oidcUserService;
    
    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http
            .authorizeRequests()
                .antMatchers("/public/**").permitAll()
                .anyRequest().authenticated()
            .and()
                .oauth2Login()
                    .userInfoEndpoint()
                        .oidcUserService(oidcUserService)
                    .and()
                    .successHandler(customAuthenticationSuccessHandler())
            .and()
                .sessionManagement()
                    .maximumSessions(1)
                    .expiredUrl("/login?expired");
    }

    @Bean
    public AuthenticationSuccessHandler customAuthenticationSuccessHandler() {
        return (request, response, authentication) -> {
            OAuth2User oAuth2User = (OAuth2User) authentication.getPrincipal();
            
            // Extract user details
            String email = oAuth2User.getAttribute("email");
            String name = oAuth2User.getAttribute("name");
            
            // Log successful authentication
            log.info("User authenticated: {}", email);
            
            // Perform additional post-login actions
            postLoginActions(oAuth2User);
            
            response.sendRedirect("/dashboard");
        };
    }

    private void postLoginActions(OAuth2User user) {
        // Audit logging
        auditService.logAuthentication(
            user.getAttribute("sub"),
            AuthenticationEvent.LOGIN_SUCCESS,
            LocalDateTime.now()
        );

        // Session security settings
        SecurityContextHolder.getContext()
            .setAuthentication(createSecureAuthentication(user));
    }
}
```

#### C# (ASP.NET Core)
```csharp
public class Startup
{
    public void ConfigureServices(IServiceCollection services)
    {
        services.AddAuthentication(options =>
        {
            options.DefaultScheme = CookieAuthenticationDefaults.AuthenticationScheme;
            options.DefaultChallengeScheme = OpenIdConnectDefaults.AuthenticationScheme;
        })
        .AddMicrosoftIdentityWebApp(Configuration.GetSection("AzureAd"))
        .EnableTokenAcquisition();

        services.AddAuthorization(options =>
        {
            options.FallbackPolicy = options.DefaultPolicy;
        });
    }

    public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
    {
        app.UseAuthentication();
        app.UseAuthorization();
    }
}
```

#### Python (Flask)
```python
from flask import Flask, session
from msal import ConfidentialClientApplication
import logging

app = Flask(__name__)
app.config.from_object('config.Config')

class MSALAuthenticator:
    def __init__(self, app_config):
        self.msal_instance = ConfidentialClientApplication(
            app_config['CLIENT_ID'],
            authority=app_config['AUTHORITY'],
            client_credential=app_config['CLIENT_SECRET']
        )
        self.logger = logging.getLogger(__name__)

    def authenticate_user(self, auth_code):
        try:
            result = self.msal_instance.acquire_token_by_authorization_code(
                auth_code,
                scopes=['User.Read'],
                redirect_uri=app_config['REDIRECT_URI']
            )
            
            if 'access_token' in result:
                session['user'] = result.get('id_token_claims')
                return True
            return False
            
        except Exception as e:
            self.logger.error(f"Authentication failed: {str(e)}")
            return False

@app.route('/login')
def login():
    auth = MSALAuthenticator(app.config)
    # Generate auth URL and redirect user
    auth_url = auth.msal_instance.get_authorization_request_url(
        ['User.Read'],
        redirect_uri=app.config['REDIRECT_URI']
    )
    return redirect(auth_url)
```

### Token Management

Secure token handling is essential across all platforms. Here's how to implement it:

#### Java Token Manager
```java
@Service
@Slf4j
public class TokenManager {
    
    private final TokenStore tokenStore;
    private final EncryptionService encryptionService;
    
    @Autowired
    public TokenManager(TokenStore tokenStore, EncryptionService encryptionService) {
        this.tokenStore = tokenStore;
        this.encryptionService = encryptionService;
    }

    public void storeTokens(String userId, TokenSet tokens) {
        try {
            // Encrypt tokens before storage
            String encryptedAccessToken = encryptionService.encrypt(tokens.getAccessToken());
            String encryptedRefreshToken = encryptionService.encrypt(tokens.getRefreshToken());

            TokenRecord tokenRecord = TokenRecord.builder()
                .userId(userId)
                .accessToken(encryptedAccessToken)
                .refreshToken(encryptedRefreshToken)
                .expiresAt(calculateExpiryTime(tokens.getExpiresIn()))
                .build();

            tokenStore.save(tokenRecord);
            
        } catch (Exception e) {
            log.error("Failed to store tokens for user: {}", userId, e);
            throw new TokenStorageException("Token storage failed", e);
        }
    }

    public Optional<String> getAccessToken(String userId) {
        try {
            return tokenStore.findByUserId(userId)
                .filter(this::isTokenValid)
                .map(TokenRecord::getAccessToken)
                .map(encryptionService::decrypt);
                
        } catch (Exception e) {
            log.error("Failed to retrieve token for user: {}", userId, e);
            return Optional.empty();
        }
    }

    private boolean isTokenValid(TokenRecord record) {
        return LocalDateTime.now().isBefore(record.getExpiresAt());
    }

    private LocalDateTime calculateExpiryTime(long expiresIn) {
        return LocalDateTime.now().plusSeconds(expiresIn - 300); // 5-minute buffer
    }
}
```

## Authorization Patterns

Authorization in enterprise applications requires careful consideration of security, scalability, and maintainability. While authentication verifies who a user is, authorization determines what they can do. Modern applications often require sophisticated authorization schemes that can handle complex business rules while remaining performant and maintainable.

### Role-Based Access Control (RBAC)

Role-Based Access Control represents one of the most widely implemented authorization patterns. In RBAC, permissions are grouped into roles, and users are assigned to these roles rather than being assigned permissions directly. This approach simplifies permission management and reduces the likelihood of security misconfiguration.

When implementing RBAC with Microsoft Entra ID, you can leverage both application roles defined in your app registration and directory roles from Entra ID itself. This flexibility allows for a layered approach to authorization that can accommodate both broad organizational roles and application-specific permissions.

#### Java Implementation (Spring Security)
```java
@Configuration
@EnableGlobalMethodSecurity(
    prePostEnabled = true,
    securedEnabled = true,
    jsr250Enabled = true
)
public class RbacConfiguration {

    @Bean
    public RoleHierarchy roleHierarchy() {
        RoleHierarchyImpl hierarchy = new RoleHierarchyImpl();
        hierarchy.setHierarchy("""
            ROLE_ADMIN > ROLE_MANAGER
            ROLE_MANAGER > ROLE_USER
            ROLE_USER > ROLE_GUEST
        """);
        return hierarchy;
    }

    @Bean
    public DefaultWebSecurityExpressionHandler webSecurityExpressionHandler() {
        DefaultWebSecurityExpressionHandler expressionHandler = 
            new DefaultWebSecurityExpressionHandler();
        expressionHandler.setRoleHierarchy(roleHierarchy());
        return expressionHandler;
    }
}

@Service
@Slf4j
public class RoleBasedAuthorizationService {
    
    private final RoleRepository roleRepository;
    private final AuditService auditService;

    @Autowired
    public RoleBasedAuthorizationService(
            RoleRepository roleRepository,
            AuditService auditService) {
        this.roleRepository = roleRepository;
        this.auditService = auditService;
    }

    @PreAuthorize("hasRole('ADMIN')")
    public void assignRole(String userId, String roleName) {
        log.info("Assigning role {} to user {}", roleName, userId);
        
        try {
            Role role = roleRepository.findByName(roleName)
                .orElseThrow(() -> new RoleNotFoundException(roleName));

            validateRoleAssignment(userId, role);
            performRoleAssignment(userId, role);
            
            auditService.logRoleAssignment(userId, roleName);
            
        } catch (Exception e) {
            log.error("Role assignment failed", e);
            throw new AuthorizationException("Failed to assign role", e);
        }
    }

    private void validateRoleAssignment(String userId, Role role) {
        // Implement role assignment validation logic
        if (role.isPrivileged()) {
            requiresAdditionalApproval(userId, role);
        }
    }
}
```

#### C# Implementation
```csharp
public class AuthorizationConfiguration
{
    public static void ConfigureAuthorization(IServiceCollection services)
    {
        services.AddAuthorization(options =>
        {
            options.AddPolicy("RequireAdminRole", policy =>
                policy.RequireRole("Admin")
                     .RequireClaim("Department", "IT")
                     .RequireAuthenticatedUser());

            options.AddPolicy("DataAccess", policy =>
                policy.Requirements.Add(new DataAccessRequirement()));
        });

        services.AddScoped<IAuthorizationHandler, DataAccessHandler>();
    }
}

public class DataAccessHandler : AuthorizationHandler<DataAccessRequirement>
{
    private readonly ILogger<DataAccessHandler> _logger;
    private readonly IDataAccessValidator _validator;

    protected override async Task HandleRequirementAsync(
        AuthorizationHandlerContext context,
        DataAccessRequirement requirement)
    {
        var user = context.User;
        
        try
        {
            if (await _validator.ValidateAccess(user))
            {
                context.Succeed(requirement);
                _logger.LogInformation("Access granted to user {User}", 
                    user.Identity.Name);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Access validation failed");
            context.Fail();
        }
    }
}
```

#### Python Implementation
```python
from functools import wraps
from flask import current_app, request, jsonify
from flask_login import current_user

def rbac_required(role):
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            if not current_user.is_authenticated:
                return jsonify({"error": "Authentication required"}), 401
            
            if not current_user.has_role(role):
                current_app.logger.warning(
                    f"Access denied: User {current_user.id} attempted to access "
                    f"resource requiring role {role}"
                )
                return jsonify({"error": "Insufficient permissions"}), 403
                
            current_app.logger.info(
                f"Access granted: User {current_user.id} accessed resource "
                f"with role {role}"
            )
            return f(*args, **kwargs)
        return decorated_function
    return decorator

class RoleManager:
    def __init__(self, db_session, audit_logger):
        self.db_session = db_session
        self.audit_logger = audit_logger

    def assign_role(self, user_id, role_name):
        try:
            user = self.db_session.query(User).get(user_id)
            role = self.db_session.query(Role).filter_by(name=role_name).first()

            if not user or not role:
                raise ValueError("User or role not found")

            user.roles.append(role)
            self.db_session.commit()

            self.audit_logger.log_role_assignment(user_id, role_name)
            
        except Exception as e:
            self.db_session.rollback()
            current_app.logger.error(f"Role assignment failed: {str(e)}")
            raise
```

### Claims-Based Authorization

Claims-based authorization provides a more flexible approach than traditional role-based systems. Claims represent attributes about the user or context that can be used to make fine-grained authorization decisions. This approach is particularly valuable when authorization requirements extend beyond simple role checks to include factors like user attributes, resource ownership, or environmental conditions.

## Claims-Based Authorization

Claims-based authorization provides a sophisticated approach to managing access control by leveraging assertions about a user's identity and attributes. Unlike simple role-based systems, claims can represent any type of user attribute, organizational relationship, or contextual information, enabling more nuanced authorization decisions.

### Understanding Claims in Enterprise Applications

In enterprise environments, claims often need to represent complex organizational structures and business rules. For example, a claim might indicate a user's department, geographic location, security clearance level, or project assignments. These claims can then be used in combination to make detailed access control decisions.

### Implementing Claims-Based Authorization

#### Java Implementation
```java
@Service
@Slf4j
public class ClaimsAuthorizationService {
    
    private final SecurityPolicyEvaluator policyEvaluator;
    private final ClaimsEnricher claimsEnricher;
    private final AuditLogger auditLogger;

    @Autowired
    public ClaimsAuthorizationService(
            SecurityPolicyEvaluator policyEvaluator,
            ClaimsEnricher claimsEnricher,
            AuditLogger auditLogger) {
        this.policyEvaluator = policyEvaluator;
        this.claimsEnricher = claimsEnricher;
        this.auditLogger = auditLogger;
    }

    public AuthorizationResult evaluateAccess(
            Authentication authentication, 
            String resourceId, 
            String requiredAction) {
            
        try {
            // Enrich claims with additional context
            Map<String, Object> enrichedClaims = claimsEnricher
                .enrichClaims(authentication.getClaims());

            // Build authorization context
            AuthorizationContext context = AuthorizationContext.builder()
                .claims(enrichedClaims)
                .resourceId(resourceId)
                .action(requiredAction)
                .timestamp(LocalDateTime.now())
                .environment(getCurrentEnvironment())
                .build();

            // Evaluate against security policies
            PolicyEvaluationResult result = policyEvaluator
                .evaluatePolicy(context);

            // Audit the decision
            auditLogger.logAuthorizationDecision(
                authentication.getName(),
                resourceId,
                requiredAction,
                result.isAllowed(),
                result.getReason()
            );

            return new AuthorizationResult(
                result.isAllowed(),
                result.getReason()
            );

        } catch (Exception e) {
            log.error("Authorization evaluation failed", e);
            throw new AuthorizationException("Failed to evaluate access", e);
        }
    }

    @Component
    public class SecurityPolicyEvaluator {
        
        public PolicyEvaluationResult evaluatePolicy(
                AuthorizationContext context) {
                
            // Example policy evaluation logic
            if (!meetsSecurityClearance(context)) {
                return PolicyEvaluationResult.denied(
                    "Insufficient security clearance");
            }

            if (!isWithinAllowedTimeWindow(context)) {
                return PolicyEvaluationResult.denied(
                    "Access not permitted at this time");
            }

            if (!isFromAllowedLocation(context)) {
                return PolicyEvaluationResult.denied(
                    "Access not permitted from this location");
            }

            return PolicyEvaluationResult.allowed();
        }

        private boolean meetsSecurityClearance(AuthorizationContext context) {
            String requiredClearance = getRequiredClearance(
                context.getResourceId());
                
            String userClearance = (String) context.getClaims()
                .get("securityClearance");

            return compareClearanceLevels(userClearance, requiredClearance);
        }
    }
}
```

#### C# Implementation
```csharp
public class ClaimsAuthorizationService
{
    private readonly ISecurityPolicyEvaluator _policyEvaluator;
    private readonly IClaimsEnricher _claimsEnricher;
    private readonly ILogger<ClaimsAuthorizationService> _logger;

    public async Task<AuthorizationResult> EvaluateAccessAsync(
        ClaimsPrincipal user, 
        string resourceId, 
        string requiredAction)
    {
        try
        {
            var enrichedClaims = await _claimsEnricher
                .EnrichClaimsAsync(user.Claims);

            var context = new AuthorizationContext
            {
                Claims = enrichedClaims,
                ResourceId = resourceId,
                Action = requiredAction,
                Timestamp = DateTime.UtcNow,
                Environment = GetCurrentEnvironment()
            };

            var result = await _policyEvaluator
                .EvaluatePolicyAsync(context);

            await _auditLogger.LogAuthorizationDecisionAsync(
                user.Identity.Name,
                resourceId,
                requiredAction,
                result.IsAllowed,
                result.Reason);

            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Authorization evaluation failed");
            throw new AuthorizationException("Failed to evaluate access", ex);
        }
    }
}

public class CustomClaimsTransformer : IClaimsTransformation
{
    private readonly IGraphService _graphService;

    public async Task<ClaimsPrincipal> TransformAsync(ClaimsPrincipal principal)
    {
        var identity = principal.Identity as ClaimsIdentity;
        
        if (identity == null || !identity.IsAuthenticated)
            return principal;

        try
        {
            var userGroups = await _graphService
                .GetUserGroupsAsync(identity.Name);

            foreach (var group in userGroups)
            {
                identity.AddClaim(new Claim("group", group.Id));
            }

            var departmentInfo = await _graphService
                .GetUserDepartmentAsync(identity.Name);
            identity.AddClaim(new Claim("department", departmentInfo));

            return principal;
        }
        catch (Exception ex)
        {
            // Log error but don't fail authentication
            return principal;
        }
    }
}
```

#### Python Implementation
```python
from dataclasses import dataclass
from typing import Dict, Optional
import logging
from datetime import datetime

@dataclass
class AuthorizationContext:
    claims: Dict[str, any]
    resource_id: str
    action: str
    timestamp: datetime
    environment: Dict[str, any]

class ClaimsAuthorizationService:
    def __init__(self, policy_evaluator, claims_enricher, audit_logger):
        self.policy_evaluator = policy_evaluator
        self.claims_enricher = claims_enricher
        self.audit_logger = audit_logger
        self.logger = logging.getLogger(__name__)

    async def evaluate_access(self, user, resource_id: str, 
            required_action: str) -> bool:
        try:
            # Enrich claims with additional context
            enriched_claims = await self.claims_enricher.enrich_claims(
                user.claims)

            # Build authorization context
            context = AuthorizationContext(
                claims=enriched_claims,
                resource_id=resource_id,
                action=required_action,
                timestamp=datetime.utcnow(),
                environment=self.get_current_environment()
            )

            # Evaluate against security policies
            result = await self.policy_evaluator.evaluate_policy(context)

            # Audit the decision
            await self.audit_logger.log_authorization_decision(
                user.id,
                resource_id,
                required_action,
                result.is_allowed,
                result.reason
            )

            return result

        except Exception as e:
            self.logger.error(f"Authorization evaluation failed: {str(e)}")
            raise AuthorizationException("Failed to evaluate access") from e

    def get_current_environment(self) -> Dict[str, any]:
        # Implement environment context collection
        return {
            "ip_address": request.remote_addr,
            "user_agent": request.user_agent.string,
            "timestamp": datetime.utcnow(),
            "request_id": request.headers.get("X-Request-ID")
        }
```

### Enhancing Security with Claims Transformation

Claims transformation allows you to augment or modify claims after authentication but before authorization decisions are made. This can be particularly useful for adding organization-specific claims or integrating with external systems for additional context.

## Advanced Authorization Patterns

Enterprise applications often require sophisticated authorization mechanisms that go beyond simple role or claims-based checks. Advanced authorization patterns help handle complex business rules, hierarchical permissions, and dynamic access control requirements while maintaining security and performance.

### Hierarchical Permission Management

Hierarchical permissions allow organizations to model complex organizational structures and inheritance patterns. This approach is particularly useful when dealing with departmental hierarchies, project team structures, or document management systems where permissions flow from parent to child resources.

#### Java Implementation
```java
@Service
@Slf4j
public class HierarchicalPermissionService {
    
    private final PermissionRepository permissionRepository;
    private final ResourceHierarchyService hierarchyService;
    private final PermissionCache permissionCache;

    @Autowired
    public HierarchicalPermissionService(
            PermissionRepository permissionRepository,
            ResourceHierarchyService hierarchyService,
            PermissionCache permissionCache) {
        this.permissionRepository = permissionRepository;
        this.hierarchyService = hierarchyService;
        this.permissionCache = permissionCache;
    }

    @Transactional(readOnly = true)
    public boolean hasPermission(String userId, String resourceId, 
            String permission) {
        try {
            // Check cache first
            String cacheKey = buildCacheKey(userId, resourceId, permission);
            Boolean cachedResult = permissionCache.get(cacheKey);
            if (cachedResult != null) {
                return cachedResult;
            }

            // Get resource hierarchy path
            List<String> resourceHierarchy = hierarchyService
                .getResourceHierarchy(resourceId);

            // Check permissions along the hierarchy
            boolean hasPermission = checkHierarchicalPermission(
                userId, 
                resourceHierarchy, 
                permission
            );

            // Cache the result
            permissionCache.put(cacheKey, hasPermission);
            
            return hasPermission;

        } catch (Exception e) {
            log.error("Permission check failed", e);
            throw new PermissionEvaluationException(
                "Failed to evaluate permission", e);
        }
    }

    private boolean checkHierarchicalPermission(
            String userId, 
            List<String> resourceHierarchy, 
            String permission) {
            
        // Check direct permissions first
        if (hasDirectPermission(userId, 
                resourceHierarchy.get(0), permission)) {
            return true;
        }

        // Check inherited permissions
        for (String ancestorId : resourceHierarchy) {
            if (hasInheritedPermission(userId, ancestorId, permission)) {
                logPermissionInheritance(userId, ancestorId, permission);
                return true;
            }
        }

        return false;
    }

    @Transactional
    public void grantPermission(String userId, String resourceId, 
            String permission) {
            
        validatePermissionGrant(userId, resourceId, permission);

        PermissionGrant grant = PermissionGrant.builder()
            .userId(userId)
            .resourceId(resourceId)
            .permission(permission)
            .grantedAt(LocalDateTime.now())
            .build();

        permissionRepository.save(grant);
        invalidatePermissionCache(userId, resourceId);
        
        log.info("Granted permission {} on resource {} to user {}", 
            permission, resourceId, userId);
    }

    private void validatePermissionGrant(
            String userId, 
            String resourceId, 
            String permission) {
            
        // Check if granter has permission to grant
        if (!canGrantPermission(SecurityUtils.getCurrentUser(), 
                resourceId, permission)) {
            throw new InsufficientPrivilegesException(
                "No permission to grant access");
        }

        // Validate resource exists and is active
        if (!resourceExists(resourceId)) {
            throw new ResourceNotFoundException(
                "Resource not found: " + resourceId);
        }

        // Check for circular inheritance
        if (wouldCreateCircularInheritance(resourceId, permission)) {
            throw new InvalidPermissionGrantException(
                "Would create circular inheritance");
        }
    }
}
```

#### C# Implementation
```csharp
public class HierarchicalPermissionService
{
    private readonly IPermissionRepository _permissionRepository;
    private readonly IResourceHierarchyService _hierarchyService;
    private readonly IDistributedCache _cache;
    private readonly ILogger<HierarchicalPermissionService> _logger;

    public async Task<bool> HasPermissionAsync(
        string userId, 
        string resourceId, 
        string permission)
    {
        try
        {
            var cacheKey = $"perm_{userId}_{resourceId}_{permission}";
            
            // Check cache
            var cachedResult = await _cache.GetAsync<bool?>(cacheKey);
            if (cachedResult.HasValue)
                return cachedResult.Value;

            // Get resource hierarchy
            var hierarchy = await _hierarchyService
                .GetResourceHierarchyAsync(resourceId);

            // Evaluate permissions
            var hasPermission = await CheckHierarchicalPermissionAsync(
                userId, 
                hierarchy, 
                permission);

            // Cache result
            await _cache.SetAsync(cacheKey, hasPermission, 
                TimeSpan.FromMinutes(10));

            return hasPermission;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, 
                "Failed to evaluate permission for user {UserId} " + 
                "on resource {ResourceId}", userId, resourceId);
            throw;
        }
    }

    private async Task<bool> CheckHierarchicalPermissionAsync(
        string userId,
        IEnumerable<string> resourceHierarchy,
        string permission)
    {
        // Check each level in the hierarchy
        foreach (var resourceId in resourceHierarchy)
        {
            var permissionGrant = await _permissionRepository
                .GetPermissionGrantAsync(userId, resourceId);

            if (permissionGrant != null && 
                PermissionIncludes(permissionGrant.Permission, permission))
            {
                await _auditLogger.LogPermissionCheckAsync(
                    userId, 
                    resourceId,
                    permission, 
                    true,
                    "Inherited from hierarchy");
                return true;
            }
        }

        return false;
    }
}
```

#### Python Implementation
```python
from dataclasses import dataclass
from typing import List, Optional
import logging
from datetime import datetime

@dataclass
class PermissionGrant:
    user_id: str
    resource_id: str
    permission: str
    granted_at: datetime
    granted_by: str

class HierarchicalPermissionService:
    def __init__(self, permission_repository, hierarchy_service, 
            cache_service, logger):
        self.permission_repository = permission_repository
        self.hierarchy_service = hierarchy_service
        self.cache_service = cache_service
        self.logger = logger

    async def has_permission(self, user_id: str, resource_id: str, 
            permission: str) -> bool:
        try:
            # Check cache
            cache_key = f"perm_{user_id}_{resource_id}_{permission}"
            cached_result = await self.cache_service.get(cache_key)
            
            if cached_result is not None:
                return cached_result

            # Get resource hierarchy
            hierarchy = await self.hierarchy_service.get_resource_hierarchy(
                resource_id)

            # Check permissions
            has_permission = await self.check_hierarchical_permission(
                user_id, 
                hierarchy, 
                permission)

            # Cache result
            await self.cache_service.set(
                cache_key, 
                has_permission, 
                expire=600)  # 10 minutes

            return has_permission

        except Exception as e:
            self.logger.error(
                f"Permission check failed: {str(e)}", 
                exc_info=True)
            raise PermissionError("Failed to evaluate permission") from e

    async def grant_permission(self, granter_id: str, user_id: str, 
            resource_id: str, permission: str):
        try:
            # Validate grant
            await self.validate_permission_grant(
                granter_id, 
                user_id, 
                resource_id, 
                permission)

            # Create grant
            grant = PermissionGrant(
                user_id=user_id,
                resource_id=resource_id,
                permission=permission,
                granted_at=datetime.utcnow(),
                granted_by=granter_id
            )

            # Save grant
            await self.permission_repository.save_grant(grant)

            # Invalidate cache
            await self.invalidate_permission_cache(user_id, resource_id)

            # Log grant
            await self.audit_logger.log_permission_grant(
                granter_id, 
                user_id, 
                resource_id, 
                permission)

        except Exception as e:
            self.logger.error(
                f"Permission grant failed: {str(e)}", 
                exc_info=True)
            raise PermissionError("Failed to grant permission") from e
```

## Dynamic Access Control and Conditional Authorization

Modern enterprise applications require flexible authorization systems that can adapt to changing conditions and complex business rules. Dynamic access control allows authorization decisions to be made based on runtime conditions, user context, resource state, and environmental factors.

### Conditional Access Policies

Conditional access extends beyond simple permission checks to include contextual factors such as user location, device state, time of access, and risk levels. This approach provides granular control over resource access while maintaining security compliance.

#### Java Implementation
```java
@Service
@Slf4j
public class ConditionalAccessService {
    
    private final SecurityPolicyProvider policyProvider;
    private final RiskAssessmentService riskAssessment;
    private final DeviceComplianceService deviceCompliance;
    private final GeolocationService geolocation;

    @Autowired
    public ConditionalAccessService(
            SecurityPolicyProvider policyProvider,
            RiskAssessmentService riskAssessment,
            DeviceComplianceService deviceCompliance,
            GeolocationService geolocation) {
        this.policyProvider = policyProvider;
        this.riskAssessment = riskAssessment;
        this.deviceCompliance = deviceCompliance;
        this.geolocation = geolocation;
    }

    @Transactional(readOnly = true)
    public AccessDecision evaluateAccess(AccessRequest request) {
        try {
            // Build evaluation context
            AccessContext context = buildAccessContext(request);
            
            // Get applicable policies
            List<SecurityPolicy> policies = policyProvider
                .getApplicablePolicies(context);

            // Evaluate all conditions
            List<PolicyEvaluation> evaluations = policies.stream()
                .map(policy -> evaluatePolicy(policy, context))
                .collect(Collectors.toList());

            // Process results
            return makeAccessDecision(evaluations, context);

        } catch (Exception e) {
            log.error("Access evaluation failed", e);
            throw new AccessEvaluationException(
                "Failed to evaluate access conditions", e);
        }
    }

    private AccessContext buildAccessContext(AccessRequest request) {
        // Collect all contextual information
        UserContext userContext = buildUserContext(request.getUserId());
        DeviceContext deviceContext = buildDeviceContext(
            request.getDeviceId());
        EnvironmentContext envContext = buildEnvironmentContext(request);
        
        // Assess risk level
        RiskAssessment risk = riskAssessment.assessRisk(
            userContext, 
            deviceContext, 
            envContext);

        return AccessContext.builder()
            .user(userContext)
            .device(deviceContext)
            .environment(envContext)
            .resource(request.getResourceId())
            .action(request.getAction())
            .riskLevel(risk.getLevel())
            .timestamp(LocalDateTime.now())
            .build();
    }

    private PolicyEvaluation evaluatePolicy(
            SecurityPolicy policy, 
            AccessContext context) {
            
        try {
            // Check location-based conditions
            if (!evaluateLocationPolicy(policy, context)) {
                return PolicyEvaluation.denied(
                    "Location not permitted");
            }

            // Check time-based conditions
            if (!evaluateTimePolicy(policy, context)) {
                return PolicyEvaluation.denied(
                    "Access not permitted at this time");
            }

            // Check device compliance
            if (!evaluateDeviceCompliance(policy, context)) {
                return PolicyEvaluation.denied(
                    "Device not compliant");
            }

            // Check risk level
            if (!evaluateRiskLevel(policy, context)) {
                return PolicyEvaluation.denied(
                    "Risk level too high");
            }

            return PolicyEvaluation.allowed();

        } catch (Exception e) {
            log.error("Policy evaluation failed", e);
            throw new PolicyEvaluationException(
                "Failed to evaluate policy", e);
        }
    }

    private boolean evaluateLocationPolicy(
            SecurityPolicy policy, 
            AccessContext context) {
            
        if (policy.hasLocationRestrictions()) {
            GeoLocation userLocation = geolocation
                .resolveLocation(context.getEnvironment().getIpAddress());
                
            return policy.getAllowedLocations()
                .stream()
                .anyMatch(location -> 
                    locationMatchesPolicy(userLocation, location));
        }
        return true;
    }

    @Scheduled(fixedRate = 300000) // Every 5 minutes
    public void updateDynamicPolicies() {
        try {
            // Fetch current threat levels
            ThreatLevel currentThreatLevel = 
                riskAssessment.getCurrentThreatLevel();

            // Adjust policies based on threat level
            List<SecurityPolicy> policies = 
                policyProvider.getAllPolicies();

            for (SecurityPolicy policy : policies) {
                adjustPolicyForThreatLevel(policy, currentThreatLevel);
            }

        } catch (Exception e) {
            log.error("Failed to update dynamic policies", e);
        }
    }
}
```

#### C# Implementation
```csharp
public class ConditionalAccessService
{
    private readonly ISecurityPolicyProvider _policyProvider;
    private readonly IRiskAssessmentService _riskAssessment;
    private readonly IDeviceComplianceService _deviceCompliance;
    private readonly IGeolocationService _geolocation;
    private readonly ILogger<ConditionalAccessService> _logger;

    public async Task<AccessDecision> EvaluateAccessAsync(
        AccessRequest request)
    {
        try
        {
            var context = await BuildAccessContextAsync(request);
            
            var policies = await _policyProvider
                .GetApplicablePoliciesAsync(context);

            var evaluations = await Task.WhenAll(
                policies.Select(policy => 
                    EvaluatePolicyAsync(policy, context)));

            return MakeAccessDecision(evaluations, context);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, 
                "Failed to evaluate access for request {RequestId}", 
                request.Id);
            throw;
        }
    }

    private async Task<PolicyEvaluation> EvaluatePolicyAsync(
        SecurityPolicy policy, 
        AccessContext context)
    {
        var evaluations = new List<(bool Success, string Reason)>();

        // Location check
        if (policy.HasLocationRestrictions)
        {
            var locationCompliant = await CheckLocationComplianceAsync(
                policy, 
                context);
            evaluations.Add((locationCompliant, "Location restrictions"));
        }

        // Device compliance
        if (policy.RequiresDeviceCompliance)
        {
            var deviceCompliant = await _deviceCompliance
                .IsDeviceCompliantAsync(context.DeviceId);
            evaluations.Add((deviceCompliant, "Device compliance"));
        }

        // Risk assessment
        var riskAcceptable = await _riskAssessment
            .IsRiskAcceptableAsync(context);
        evaluations.Add((riskAcceptable, "Risk level"));

        return CreateEvaluationResult(evaluations);
    }

    private async Task<bool> CheckLocationComplianceAsync(
        SecurityPolicy policy, 
        AccessContext context)
    {
        var userLocation = await _geolocation
            .ResolveLocationAsync(context.IpAddress);

        return policy.AllowedLocations
            .Any(allowed => LocationCompliant(userLocation, allowed));
    }
}
```

#### Python Implementation
```python
from dataclasses import dataclass
from datetime import datetime
from typing import List, Optional
import logging
from enum import Enum

class RiskLevel(Enum):
    LOW = "LOW"
    MEDIUM = "MEDIUM"
    HIGH = "HIGH"
    CRITICAL = "CRITICAL"

@dataclass
class AccessContext:
    user_id: str
    device_id: str
    ip_address: str
    resource_id: str
    action: str
    timestamp: datetime
    risk_level: RiskLevel

class ConditionalAccessService:
    def __init__(self, policy_provider, risk_assessment, 
            device_compliance, geolocation, logger):
        self.policy_provider = policy_provider
        self.risk_assessment = risk_assessment
        self.device_compliance = device_compliance
        self.geolocation = geolocation
        self.logger = logger

    async def evaluate_access(self, request) -> AccessDecision:
        try:
            # Build context
            context = await self._build_access_context(request)
            
            # Get applicable policies
            policies = await self.policy_provider.get_applicable_policies(
                context)

            # Evaluate policies
            evaluations = await asyncio.gather(*[
                self._evaluate_policy(policy, context) 
                for policy in policies
            ])

            # Make decision
            return self._make_access_decision(evaluations, context)

        except Exception as e:
            self.logger.error(
                f"Access evaluation failed: {str(e)}", 
                exc_info=True)
            raise AccessEvaluationError(
                "Failed to evaluate access conditions") from e

    async def _evaluate_policy(self, policy, context):
        try:
            evaluations = []

            # Location check
            if policy.has_location_restrictions:
                location_compliant = await self._check_location_compliance(
                    policy, 
                    context)
                evaluations.append(
                    (location_compliant, "Location restrictions"))

            # Device compliance
            if policy.requires_device_compliance:
                device_compliant = await self.device_compliance\
                    .is_device_compliant(
                        context.device_id)
                evaluations.append(
                    (device_compliant, "Device compliance"))

            # Risk assessment
            risk_acceptable = await self.risk_assessment\
                .is_risk_acceptable(context)
            evaluations.append((risk_acceptable, "Risk level"))

            return self._create_evaluation_result(evaluations)

        except Exception as e:
            self.logger.error(
                f"Policy evaluation failed: {str(e)}", 
                exc_info=True)
            raise PolicyEvaluationError(
                "Failed to evaluate policy") from e
```

## Advanced Security Features and Threat Detection

Modern enterprise applications require sophisticated security measures beyond basic authentication and authorization. Implementing advanced security features and real-time threat detection helps protect against evolving security threats while maintaining application usability.

### Adaptive Authentication

Adaptive authentication adjusts security requirements based on user behavior, risk levels, and environmental factors. This approach provides an optimal balance between security and user experience by applying additional authentication steps only when necessary.

#### Java Implementation
```java
@Service
@Slf4j
public class AdaptiveAuthenticationService {
    
    private final RiskEngine riskEngine;
    private final UserBehaviorAnalyzer behaviorAnalyzer;
    private final AuthenticationStrengthener authStrengthener;
    private final SecurityEventPublisher eventPublisher;

    @Autowired
    public AdaptiveAuthenticationService(
            RiskEngine riskEngine,
            UserBehaviorAnalyzer behaviorAnalyzer,
            AuthenticationStrengthener authStrengthener,
            SecurityEventPublisher eventPublisher) {
        this.riskEngine = riskEngine;
        this.behaviorAnalyzer = behaviorAnalyzer;
        this.authStrengthener = authStrengthener;
        this.eventPublisher = eventPublisher;
    }

    @Transactional
    public AuthenticationResponse evaluateAuthenticationRisk(
            AuthenticationRequest request) {
            
        try {
            // Build risk context
            RiskContext riskContext = buildRiskContext(request);
            
            // Analyze user behavior
            UserBehaviorProfile behavior = behaviorAnalyzer
                .analyzeUserBehavior(request.getUserId());
            
            // Calculate risk score
            RiskAssessment risk = riskEngine.evaluateRisk(
                riskContext, 
                behavior);

            // Determine required authentication strength
            AuthenticationLevel requiredLevel = 
                determineRequiredAuthLevel(risk);

            // Apply additional authentication if needed
            if (requiresStepUp(requiredLevel, request.getCurrentLevel())) {
                return handleStepUpAuthentication(request, requiredLevel);
            }

            return AuthenticationResponse.allowed();

        } catch (Exception e) {
            log.error("Risk evaluation failed", e);
            throw new SecurityEvaluationException(
                "Failed to evaluate authentication risk", e);
        }
    }

    private RiskContext buildRiskContext(AuthenticationRequest request) {
        return RiskContext.builder()
            .userId(request.getUserId())
            .ipAddress(request.getIpAddress())
            .deviceId(request.getDeviceId())
            .userAgent(request.getUserAgent())
            .location(request.getLocation())
            .timestamp(LocalDateTime.now())
            .previousActivity(loadRecentActivity(request.getUserId()))
            .build();
    }

    private AuthenticationLevel determineRequiredAuthLevel(
            RiskAssessment risk) {
            
        switch (risk.getLevel()) {
            case HIGH:
                return AuthenticationLevel.MULTI_FACTOR_WITH_BIOMETRIC;
            case MEDIUM:
                return AuthenticationLevel.MULTI_FACTOR;
            case LOW:
                return AuthenticationLevel.SINGLE_FACTOR;
            default:
                return AuthenticationLevel.BASIC;
        }
    }

    @Async
    public void processAnomalyDetection(AuthenticationRequest request) {
        try {
            // Analyze for anomalies
            List<SecurityAnomaly> anomalies = behaviorAnalyzer
                .detectAnomalies(request);

            for (SecurityAnomaly anomaly : anomalies) {
                // Log anomaly
                log.warn("Security anomaly detected: {}", anomaly);

                // Publish security event
                SecurityEvent event = SecurityEvent.builder()
                    .type(SecurityEventType.ANOMALY_DETECTED)
                    .severity(anomaly.getSeverity())
                    .userId(request.getUserId())
                    .details(anomaly.getDetails())
                    .timestamp(LocalDateTime.now())
                    .build();

                eventPublisher.publishEvent(event);

                // Take immediate action if needed
                if (anomaly.requiresImediateAction()) {
                    handleImmediateSecurityResponse(anomaly);
                }
            }
        } catch (Exception e) {
            log.error("Anomaly detection failed", e);
        }
    }

    private void handleImmediateSecurityResponse(SecurityAnomaly anomaly) {
        switch (anomaly.getType()) {
            case IMPOSSIBLE_TRAVEL:
                lockAccountTemporarily(anomaly.getUserId());
                notifySecurityTeam(anomaly);
                break;
            case BRUTE_FORCE_ATTEMPT:
                incrementFailedAttempts(anomaly.getUserId());
                applyProgressiveDelays(anomaly.getUserId());
                break;
            case SUSPICIOUS_IP:
                requireAdditionalVerification(anomaly.getUserId());
                logSecurityIncident(anomaly);
                break;
            default:
                log.warn("Unhandled anomaly type: {}", anomaly.getType());
        }
    }
}
```

#### C# Implementation
```csharp
public class AdaptiveAuthenticationService
{
    private readonly IRiskEngine _riskEngine;
    private readonly IUserBehaviorAnalyzer _behaviorAnalyzer;
    private readonly IAuthenticationStrengthener _authStrengthener;
    private readonly ISecurityEventPublisher _eventPublisher;
    private readonly ILogger<AdaptiveAuthenticationService> _logger;

    public async Task<AuthenticationResponse> EvaluateAuthenticationRiskAsync(
        AuthenticationRequest request)
    {
        try
        {
            var riskContext = await BuildRiskContextAsync(request);
            
            var behaviorProfile = await _behaviorAnalyzer
                .AnalyzeUserBehaviorAsync(request.UserId);

            var riskAssessment = await _riskEngine
                .EvaluateRiskAsync(riskContext, behaviorProfile);

            var requiredLevel = DetermineRequiredAuthLevel(riskAssessment);

            if (RequiresStepUp(requiredLevel, request.CurrentLevel))
            {
                return await HandleStepUpAuthenticationAsync(
                    request, 
                    requiredLevel);
            }

            return AuthenticationResponse.Allowed();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, 
                "Failed to evaluate authentication risk for user {UserId}", 
                request.UserId);
            throw;
        }
    }

    private async Task<RiskContext> BuildRiskContextAsync(
        AuthenticationRequest request)
    {
        var recentActivity = await LoadRecentActivityAsync(request.UserId);

        return new RiskContext
        {
            UserId = request.UserId,
            IpAddress = request.IpAddress,
            DeviceId = request.DeviceId,
            UserAgent = request.UserAgent,
            Location = request.Location,
            Timestamp = DateTime.UtcNow,
            PreviousActivity = recentActivity
        };
    }

    public async Task ProcessAnomalyDetectionAsync(
        AuthenticationRequest request)
    {
        try
        {
            var anomalies = await _behaviorAnalyzer
                .DetectAnomaliesAsync(request);

            foreach (var anomaly in anomalies)
            {
                _logger.LogWarning(
                    "Security anomaly detected: {AnomalyType} for user {UserId}", 
                    anomaly.Type, request.UserId);

                var securityEvent = new SecurityEvent
                {
                    Type = SecurityEventType.AnomalyDetected,
                    Severity = anomaly.Severity,
                    UserId = request.UserId,
                    Details = anomaly.Details,
                    Timestamp = DateTime.UtcNow
                };

                await _eventPublisher.PublishEventAsync(securityEvent);

                if (anomaly.RequiresImmediateAction)
                {
                    await HandleImmediateSecurityResponseAsync(anomaly);
                }
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, 
                "Anomaly detection failed for user {UserId}", 
                request.UserId);
        }
    }
}
```

## Session Management and Security Monitoring

Session management and security monitoring are critical components of enterprise applications. Proper session handling ensures secure user interactions, while comprehensive monitoring helps detect and respond to security incidents promptly.

### Secure Session Management

Modern session management must handle various scenarios including distributed systems, mobile devices, and multiple concurrent sessions while maintaining security and user experience.

#### Java Implementation
```java
@Service
@Slf4j
public class SecureSessionManager {
    
    private final SessionRepository sessionRepository;
    private final TokenService tokenService;
    private final SecurityEventPublisher eventPublisher;
    private final UserActivityTracker activityTracker;

    @Value("${session.timeout.minutes}")
    private int sessionTimeoutMinutes;

    @Value("${session.max-concurrent}")
    private int maxConcurrentSessions;

    @Autowired
    public SecureSessionManager(
            SessionRepository sessionRepository,
            TokenService tokenService,
            SecurityEventPublisher eventPublisher,
            UserActivityTracker activityTracker) {
        this.sessionRepository = sessionRepository;
        this.tokenService = tokenService;
        this.eventPublisher = eventPublisher;
        this.activityTracker = activityTracker;
    }

    @Transactional
    public SessionContext createSession(
            Authentication authentication, 
            HttpServletRequest request) {
            
        try {
            String userId = authentication.getName();
            
            // Check concurrent sessions
            handleConcurrentSessions(userId);

            // Create new session
            UserSession session = UserSession.builder()
                .userId(userId)
                .sessionId(generateSecureSessionId())
                .createdAt(LocalDateTime.now())
                .lastAccessedAt(LocalDateTime.now())
                .deviceInfo(extractDeviceInfo(request))
                .ipAddress(extractIpAddress(request))
                .securityContext(buildSecurityContext(authentication))
                .build();

            // Generate session tokens
            SessionTokens tokens = tokenService.generateSessionTokens(session);
            session.setTokenHash(hashToken(tokens.getRefreshToken()));

            // Save session
            sessionRepository.save(session);

            // Log session creation
            publishSessionEvent(
                SessionEventType.CREATED, 
                session);

            return SessionContext.builder()
                .session(session)
                .tokens(tokens)
                .build();

        } catch (Exception e) {
            log.error("Session creation failed", e);
            throw new SessionManagementException(
                "Failed to create session", e);
        }
    }

    private void handleConcurrentSessions(String userId) {
        List<UserSession> activeSessions = sessionRepository
            .findActiveSessionsByUserId(userId);

        if (activeSessions.size() >= maxConcurrentSessions) {
            // Terminate oldest session
            UserSession oldestSession = activeSessions.stream()
                .min(Comparator.comparing(UserSession::getLastAccessedAt))
                .orElseThrow();

            terminateSession(oldestSession.getSessionId(), 
                TerminationReason.CONCURRENT_SESSION_LIMIT);
        }
    }

    @Transactional
    public void updateSession(String sessionId, 
            SessionUpdateContext updateContext) {
            
        UserSession session = sessionRepository
            .findById(sessionId)
            .orElseThrow(() -> new SessionNotFoundException(sessionId));

        // Verify session is still valid
        validateSession(session);

        // Update session attributes
        session.setLastAccessedAt(LocalDateTime.now());
        session.setLastActivityType(updateContext.getActivityType());

        if (updateContext.getNewSecurityContext() != null) {
            updateSessionSecurity(session, 
                updateContext.getNewSecurityContext());
        }

        sessionRepository.save(session);

        // Track user activity
        activityTracker.trackActivity(session.getUserId(), 
            updateContext.getActivityType());
    }

    @Scheduled(fixedRate = 300000) // Every 5 minutes
    public void cleanupExpiredSessions() {
        try {
            LocalDateTime expirationThreshold = LocalDateTime.now()
                .minusMinutes(sessionTimeoutMinutes);

            List<UserSession> expiredSessions = sessionRepository
                .findExpiredSessions(expirationThreshold);

            for (UserSession session : expiredSessions) {
                terminateSession(session.getSessionId(), 
                    TerminationReason.EXPIRED);
            }

        } catch (Exception e) {
            log.error("Session cleanup failed", e);
        }
    }

    @Transactional
    public void terminateSession(String sessionId, 
            TerminationReason reason) {
            
        try {
            UserSession session = sessionRepository
                .findById(sessionId)
                .orElseThrow(() -> new SessionNotFoundException(sessionId));

            // Invalidate session tokens
            tokenService.revokeSessionTokens(session);

            // Update session status
            session.setStatus(SessionStatus.TERMINATED);
            session.setTerminatedAt(LocalDateTime.now());
            session.setTerminationReason(reason);

            sessionRepository.save(session);

            // Publish session termination event
            publishSessionEvent(SessionEventType.TERMINATED, session);

        } catch (Exception e) {
            log.error("Session termination failed", e);
            throw new SessionManagementException(
                "Failed to terminate session", e);
        }
    }

    private void publishSessionEvent(
            SessionEventType eventType, 
            UserSession session) {
            
        SessionEvent event = SessionEvent.builder()
            .type(eventType)
            .sessionId(session.getSessionId())
            .userId(session.getUserId())
            .timestamp(LocalDateTime.now())
            .deviceInfo(session.getDeviceInfo())
            .ipAddress(session.getIpAddress())
            .build();

        eventPublisher.publishEvent(event);
    }

    private void validateSession(UserSession session) {
        if (session.getStatus() != SessionStatus.ACTIVE) {
            throw new InvalidSessionException(
                "Session is not active: " + session.getSessionId());
        }

        if (isSessionExpired(session)) {
            terminateSession(session.getSessionId(), 
                TerminationReason.EXPIRED);
            throw new SessionExpiredException(
                "Session has expired: " + session.getSessionId());
        }
    }

    private boolean isSessionExpired(UserSession session) {
        return session.getLastAccessedAt()
            .plusMinutes(sessionTimeoutMinutes)
            .isBefore(LocalDateTime.now());
    }
}
```

#### C# Implementation
```csharp
public class SecureSessionManager
{
    private readonly ISessionRepository _sessionRepository;
    private readonly ITokenService _tokenService;
    private readonly ISecurityEventPublisher _eventPublisher;
    private readonly IUserActivityTracker _activityTracker;
    private readonly ILogger<SecureSessionManager> _logger;

    public async Task<SessionContext> CreateSessionAsync(
        ClaimsPrincipal user, 
        HttpContext httpContext)
    {
        try
        {
            var userId = user.FindFirst(ClaimTypes.NameIdentifier).Value;

            // Handle concurrent sessions
            await HandleConcurrentSessionsAsync(userId);

            // Create new session
            var session = new UserSession
            {
                UserId = userId,
                SessionId = GenerateSecureSessionId(),
                CreatedAt = DateTime.UtcNow,
                LastAccessedAt = DateTime.UtcNow,
                DeviceInfo = ExtractDeviceInfo(httpContext),
                IpAddress = ExtractIpAddress(httpContext),
                SecurityContext = BuildSecurityContext(user)
            };

            // Generate tokens
            var tokens = await _tokenService.GenerateSessionTokensAsync(
                session);
            session.TokenHash = HashToken(tokens.RefreshToken);

            // Save session
            await _sessionRepository.SaveAsync(session);

            // Publish event
            await PublishSessionEventAsync(
                SessionEventType.Created, 
                session);

            return new SessionContext
            {
                Session = session,
                Tokens = tokens
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, 
                "Failed to create session for user {UserId}", 
                user.Identity.Name);
            throw;
        }
    }

    private async Task HandleConcurrentSessionsAsync(string userId)
    {
        var activeSessions = await _sessionRepository
            .GetActiveSessionsAsync(userId);

        if (activeSessions.Count >= _maxConcurrentSessions)
        {
            var oldestSession = activeSessions
                .OrderBy(s => s.LastAccessedAt)
                .First();

            await TerminateSessionAsync(
                oldestSession.SessionId,
                TerminationReason.ConcurrentSessionLimit);
        }
    }
}
```

## Security Event Monitoring and Audit Logging

Comprehensive security monitoring and audit logging are essential for maintaining security compliance and detecting potential threats. A well-implemented monitoring system provides visibility into authentication events, authorization decisions, and user activities while supporting security investigations and compliance requirements.

### Security Event Monitoring

Security event monitoring should capture relevant security events, analyze patterns, and trigger appropriate responses when suspicious activities are detected.

#### Java Implementation
```java
@Service
@Slf4j
public class SecurityMonitoringService {
    
    private final SecurityEventRepository eventRepository;
    private final AlertingService alertingService;
    private final AnomalyDetector anomalyDetector;
    private final ComplianceReporter complianceReporter;

    @Value("${security.monitoring.retention-days}")
    private int eventRetentionDays;

    @Autowired
    public SecurityMonitoringService(
            SecurityEventRepository eventRepository,
            AlertingService alertingService,
            AnomalyDetector anomalyDetector,
            ComplianceReporter complianceReporter) {
        this.eventRepository = eventRepository;
        this.alertingService = alertingService;
        this.anomalyDetector = anomalyDetector;
        this.complianceReporter = complianceReporter;
    }

    @Async
    public void processSecurityEvent(SecurityEvent event) {
        try {
            // Enrich event with additional context
            SecurityEventContext enrichedEvent = enrichEventContext(event);

            // Analyze for anomalies
            List<SecurityAnomaly> anomalies = anomalyDetector
                .analyzeEvent(enrichedEvent);

            // Store event
            storeSecurity Event(enrichedEvent, anomalies);

            // Handle any detected anomalies
            handleAnomalies(anomalies);

            // Update compliance records
            updateComplianceRecords(enrichedEvent);

        } catch (Exception e) {
            log.error("Failed to process security event", e);
            alertingService.sendAlert(
                AlertLevel.ERROR,
                "Security event processing failure",
                e.getMessage()
            );
        }
    }

    private SecurityEventContext enrichEventContext(SecurityEvent event) {
        return SecurityEventContext.builder()
            .baseEvent(event)
            .userContext(loadUserContext(event.getUserId()))
            .deviceContext(loadDeviceContext(event.getDeviceId()))
            .locationContext(loadLocationContext(event.getIpAddress()))
            .previousEvents(loadRelevantPreviousEvents(event))
            .riskScore(calculateEventRiskScore(event))
            .build();
    }

    @Transactional
    public void storeSecurityEvent(
            SecurityEventContext enrichedEvent,
            List<SecurityAnomaly> anomalies) {
            
        SecurityEventRecord record = SecurityEventRecord.builder()
            .eventType(enrichedEvent.getType())
            .userId(enrichedEvent.getUserId())
            .timestamp(enrichedEvent.getTimestamp())
            .deviceInfo(enrichedEvent.getDeviceContext())
            .location(enrichedEvent.getLocationContext())
            .riskScore(enrichedEvent.getRiskScore())
            .anomalies(anomalies)
            .eventDetails(enrichedEvent.getDetails())
            .build();

        eventRepository.save(record);

        // If this is a high-risk event, create an immediate alert
        if (isHighRiskEvent(enrichedEvent)) {
            alertingService.sendHighRiskEventAlert(enrichedEvent);
        }
    }

    private void handleAnomalies(List<SecurityAnomaly> anomalies) {
        for (SecurityAnomaly anomaly : anomalies) {
            switch (anomaly.getSeverity()) {
                case CRITICAL:
                    handleCriticalAnomaly(anomaly);
                    break;
                case HIGH:
                    handleHighSeverityAnomaly(anomaly);
                    break;
                case MEDIUM:
                    handleMediumSeverityAnomaly(anomaly);
                    break;
                default:
                    logAnomaly(anomaly);
            }
        }
    }

    private void handleCriticalAnomaly(SecurityAnomaly anomaly) {
        // Immediate response actions
        accountSecurityService.lockAccount(anomaly.getUserId());
        
        // Notify security team
        alertingService.sendUrgentAlert(
            AlertLevel.CRITICAL,
            "Critical Security Anomaly Detected",
            buildAnomalyAlert(anomaly)
        );
        
        // Create incident ticket
        incidentManager.createIncident(
            IncidentPriority.HIGH,
            "Critical Security Anomaly",
            anomaly
        );
    }

    @Scheduled(cron = "0 0 * * * *") // Every hour
    public void generateSecurityMetrics() {
        try {
            LocalDateTime endTime = LocalDateTime.now();
            LocalDateTime startTime = endTime.minusHours(1);

            SecurityMetrics metrics = SecurityMetrics.builder()
                .totalEvents(countEventsByTimeRange(startTime, endTime))
                .eventsByType(aggregateEventsByType(startTime, endTime))
                .averageRiskScore(calculateAverageRiskScore(startTime, endTime))
                .anomalyCount(countAnomalies(startTime, endTime))
                .topRiskyUsers(identifyTopRiskyUsers(startTime, endTime))
                .suspiciousIPs(identifySuspiciousIPs(startTime, endTime))
                .build();

            // Store metrics
            metricsRepository.save(metrics);

            // Check for concerning trends
            analyzeTrendsAndAlert(metrics);

        } catch (Exception e) {
            log.error("Failed to generate security metrics", e);
            alertingService.sendAlert(
                AlertLevel.ERROR,
                "Security metrics generation failed",
                e.getMessage()
            );
        }
    }

    @Scheduled(cron = "0 0 0 * * *") // Daily at midnight
    public void cleanupOldEvents() {
        try {
            LocalDateTime retentionDate = LocalDateTime.now()
                .minusDays(eventRetentionDays);

            // Archive events before deletion
            archiveOldEvents(retentionDate);

            // Delete old events
            int deletedCount = eventRepository
                .deleteEventsOlderThan(retentionDate);

            log.info("Cleaned up {} old security events", deletedCount);

        } catch (Exception e) {
            log.error("Failed to cleanup old security events", e);
            alertingService.sendAlert(
                AlertLevel.ERROR,
                "Security event cleanup failed",
                e.getMessage()
            );
        }
    }
}
```

#### C# Implementation
```csharp
public class SecurityMonitoringService
{
    private readonly ISecurityEventRepository _eventRepository;
    private readonly IAlertingService _alertingService;
    private readonly IAnomalyDetector _anomalyDetector;
    private readonly IComplianceReporter _complianceReporter;
    private readonly ILogger<SecurityMonitoringService> _logger;

    public async Task ProcessSecurityEventAsync(SecurityEvent @event)
    {
        try
        {
            // Enrich event context
            var enrichedEvent = await EnrichEventContextAsync(@event);

            // Analyze for anomalies
            var anomalies = await _anomalyDetector
                .AnalyzeEventAsync(enrichedEvent);

            // Store event
            await StoreSecurityEventAsync(enrichedEvent, anomalies);

            // Handle anomalies
            await HandleAnomaliesAsync(anomalies);

            // Update compliance records
            await UpdateComplianceRecordsAsync(enrichedEvent);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, 
                "Failed to process security event: {EventType}", 
                @event.Type);
            
            await _alertingService.SendAlertAsync(
                AlertLevel.Error,
                "Security event processing failure",
                ex.Message);
        }
    }

    private async Task HandleAnomaliesAsync(
        IEnumerable<SecurityAnomaly> anomalies)
    {
        foreach (var anomaly in anomalies)
        {
            switch (anomaly.Severity)
            {
                case AnomalySeverity.Critical:
                    await HandleCriticalAnomalyAsync(anomaly);
                    break;
                case AnomalySeverity.High:
                    await HandleHighSeverityAnomalyAsync(anomaly);
                    break;
                default:
                    await LogAnomalyAsync(anomaly);
                    break;
            }
        }
    }

    [JobScheduler("0 0 * * * *")] // Every hour
    public async Task GenerateSecurityMetricsAsync()
    {
        try
        {
            var endTime = DateTime.UtcNow;
            var startTime = endTime.AddHours(-1);

            var metrics = new SecurityMetrics
            {
                TotalEvents = await CountEventsByTimeRangeAsync(
                    startTime, endTime),
                EventsByType = await AggregateEventsByTypeAsync(
                    startTime, endTime),
                AverageRiskScore = await CalculateAverageRiskScoreAsync(
                    startTime, endTime),
                AnomalyCount = await CountAnomaliesAsync(
                    startTime, endTime),
                TopRiskyUsers = await IdentifyTopRiskyUsersAsync(
                    startTime, endTime),
                SuspiciousIPs = await IdentifySuspiciousIPsAsync(
                    startTime, endTime)
            };

            await _metricsRepository.SaveAsync(metrics);
            await AnalyzeTrendsAndAlertAsync(metrics);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to generate security metrics");
            await _alertingService.SendAlertAsync(
                AlertLevel.Error,
                "Security metrics generation failed",
                ex.Message);
        }
    }
}
```

## Compliance Reporting and Audit Trail Management

Enterprise applications must maintain comprehensive audit trails and generate compliance reports to meet regulatory requirements. This section covers implementing robust audit logging and compliance reporting mechanisms that satisfy common regulatory frameworks like GDPR, HIPAA, and SOX.

### Audit Trail Implementation

A properly implemented audit trail should capture all security-relevant events while ensuring the integrity and non-repudiation of audit records.

#### Java Implementation
```java
@Service
@Slf4j
public class AuditTrailService {
    
    private final AuditRepository auditRepository;
    private final ComplianceService complianceService;
    private final DataEncryptionService encryptionService;
    private final IntegrityVerifier integrityVerifier;

    @Value("${audit.retention.years}")
    private int auditRetentionYears;

    @Autowired
    public AuditTrailService(
            AuditRepository auditRepository,
            ComplianceService complianceService,
            DataEncryptionService encryptionService,
            IntegrityVerifier integrityVerifier) {
        this.auditRepository = auditRepository;
        this.complianceService = complianceService;
        this.encryptionService = encryptionService;
        this.integrityVerifier = integrityVerifier;
    }

    @Transactional
    public void logAuditEvent(AuditableAction action, 
            Principal principal, 
            AuditContext context) {
        try {
            // Create audit record
            AuditRecord record = AuditRecord.builder()
                .eventId(generateEventId())
                .timestamp(LocalDateTime.now())
                .actionType(action.getType())
                .userId(principal.getName())
                .resourceId(context.getResourceId())
                .actionDetails(encryptSensitiveData(action.getDetails()))
                .ipAddress(context.getIpAddress())
                .userAgent(context.getUserAgent())
                .previousValue(context.getPreviousValue())
                .newValue(context.getNewValue())
                .resultStatus(action.getResult())
                .build();

            // Add integrity signature
            record.setIntegritySignature(
                generateIntegritySignature(record));

            // Store audit record
            auditRepository.save(record);

            // Check if action requires immediate compliance reporting
            if (requiresImmediateReporting(action)) {
                complianceService.reportAuditEvent(record);
            }

        } catch (Exception e) {
            log.error("Failed to log audit event", e);
            throw new AuditLoggingException(
                "Audit logging failed", e);
        }
    }

    private String generateIntegritySignature(AuditRecord record) {
        // Create a canonical form of the audit record
        String canonicalForm = createCanonicalForm(record);
        
        // Sign the canonical form
        return integrityVerifier.signRecord(canonicalForm);
    }

    private String createCanonicalForm(AuditRecord record) {
        return new StringBuilder()
            .append(record.getEventId())
            .append(record.getTimestamp())
            .append(record.getActionType())
            .append(record.getUserId())
            .append(record.getResourceId())
            .append(record.getActionDetails())
            .append(record.getIpAddress())
            .toString();
    }

    private Map<String, Object> encryptSensitiveData(
            Map<String, Object> details) {
        Map<String, Object> encryptedDetails = new HashMap<>();
        
        for (Map.Entry<String, Object> entry : details.entrySet()) {
            if (isSensitiveField(entry.getKey())) {
                encryptedDetails.put(
                    entry.getKey(),
                    encryptionService.encrypt(entry.getValue().toString())
                );
            } else {
                encryptedDetails.put(entry.getKey(), entry.getValue());
            }
        }
        
        return encryptedDetails;
    }

    @Transactional(readOnly = true)
    public AuditTrail retrieveAuditTrail(AuditTrailRequest request) {
        validateRequest(request);

        // Apply filters
        AuditTrailSpecification spec = new AuditTrailSpecification(
            request.getStartDate(),
            request.getEndDate(),
            request.getUserId(),
            request.getActionTypes(),
            request.getResourceId()
        );

        // Retrieve records
        List<AuditRecord> records = auditRepository
            .findAll(spec, request.getPageable());

        // Verify integrity of each record
        verifyRecordIntegrity(records);

        // Decrypt sensitive data if authorized
        if (isAuthorizedForSensitiveData(request.getPrincipal())) {
            decryptSensitiveData(records);
        }

        return AuditTrail.builder()
            .records(records)
            .totalRecords(auditRepository.count(spec))
            .queryTimestamp(LocalDateTime.now())
            .build();
    }

    @Scheduled(cron = "0 0 1 * * *") // Daily at 1 AM
    public void generateComplianceReport() {
        try {
            LocalDateTime endDate = LocalDateTime.now();
            LocalDateTime startDate = endDate.minusDays(1);

            ComplianceReport report = ComplianceReport.builder()
                .reportId(generateReportId())
                .reportingPeriod(new DateRange(startDate, endDate))
                .generatedAt(LocalDateTime.now())
                .auditSummary(generateAuditSummary(startDate, endDate))
                .securityMetrics(generateSecurityMetrics(startDate, endDate))
                .complianceViolations(
                    identifyComplianceViolations(startDate, endDate))
                .recommendations(generateRecommendations())
                .build();

            // Store report
            complianceService.storeReport(report);

            // Notify compliance officers
            notifyComplianceOfficers(report);

        } catch (Exception e) {
            log.error("Failed to generate compliance report", e);
            alertComplianceTeam(e);
        }
    }

    private AuditSummary generateAuditSummary(
            LocalDateTime startDate, 
            LocalDateTime endDate) {
            
        return AuditSummary.builder()
            .totalEvents(countEventsByDateRange(startDate, endDate))
            .eventsByType(aggregateEventsByType(startDate, endDate))
            .userActivity(analyzeUserActivity(startDate, endDate))
            .resourceAccess(analyzeResourceAccess(startDate, endDate))
            .securityIncidents(
                identifySecurityIncidents(startDate, endDate))
            .build();
    }

    public class AuditTrailExporter {
        
        public void exportAuditTrail(
                AuditTrailRequest request, 
                ExportFormat format,
                OutputStream outputStream) {
                
            AuditTrail trail = retrieveAuditTrail(request);
            
            switch (format) {
                case PDF:
                    exportToPdf(trail, outputStream);
                    break;
                case CSV:
                    exportToCsv(trail, outputStream);
                    break;
                case JSON:
                    exportToJson(trail, outputStream);
                    break;
                default:
                    throw new UnsupportedOperationException(
                        "Unsupported export format: " + format);
            }
        }

        private void exportToPdf(
                AuditTrail trail, 
                OutputStream outputStream) {
            // Implementation for PDF export
        }

        private void exportToCsv(
                AuditTrail trail, 
                OutputStream outputStream) {
            // Implementation for CSV export
        }

        private void exportToJson(
                AuditTrail trail, 
                OutputStream outputStream) {
            // Implementation for JSON export
        }
    }
}
```

## Integration Testing and Security Validation

Comprehensive testing of Entra ID integration is crucial for ensuring security and functionality. This section covers implementing thorough integration tests and security validation procedures.

### Integration Testing Framework

#### Java Implementation
```java
@SpringBootTest
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
public class EntraIdIntegrationTest {
    
    @Autowired
    private AuthenticationService authenticationService;
    
    @Autowired
    private TokenService tokenService;
    
    @Autowired
    private MockEntraIdServer mockEntraServer;
    
    @Autowired
    private TestUserManager testUserManager;
    
    @Value("${test.client.id}")
    private String clientId;
    
    @Value("${test.client.secret}")
    private String clientSecret;

    private TestUser testUser;
    private TestUser adminUser;

    @BeforeAll
    void setUp() {
        // Initialize mock Entra ID server
        mockEntraServer.start();
        
        // Create test users
        testUser = testUserManager.createTestUser(UserRole.USER);
        adminUser = testUserManager.createTestUser(UserRole.ADMIN);
    }

    @Test
    void testAuthenticationFlow() {
        // Test complete authentication flow
        AuthenticationRequest request = AuthenticationRequest.builder()
            .username(testUser.getUsername())
            .clientId(clientId)
            .clientSecret(clientSecret)
            .scopes(Arrays.asList("user.read", "profile"))
            .build();

        AuthenticationResult result = authenticationService
            .authenticate(request);

        assertThat(result.isSuccessful()).isTrue();
        assertThat(result.getTokens()).isNotNull();
        assertThat(result.getTokens().getAccessToken()).isNotEmpty();
        
        // Validate token claims
        TokenValidationResult validationResult = tokenService
            .validateToken(result.getTokens().getAccessToken());
            
        assertThat(validationResult.isValid()).isTrue();
        assertThat(validationResult.getClaims())
            .containsKey("preferred_username");
        assertThat(validationResult.getClaims().get("roles"))
            .contains("USER");
    }

    @Test
    void testRoleBasedAuthorization() {
        // Test authorization with different roles
        AuthenticationResult userAuth = authenticateUser(testUser);
        AuthenticationResult adminAuth = authenticateUser(adminUser);

        // Test user access
        assertThat(authorizationService.hasAccess(
            userAuth.getPrincipal(), 
            "read_resource"))
            .isTrue();
        assertThat(authorizationService.hasAccess(
            userAuth.getPrincipal(), 
            "admin_action"))
            .isFalse();

        // Test admin access
        assertThat(authorizationService.hasAccess(
            adminAuth.getPrincipal(), 
            "admin_action"))
            .isTrue();
    }

    @Test
    void testTokenRefresh() {
        // Initial authentication
        AuthenticationResult auth = authenticateUser(testUser);
        
        // Wait for token to approach expiration
        Thread.sleep(Duration.ofMinutes(55).toMillis());
        
        // Attempt token refresh
        TokenRefreshResult refreshResult = tokenService.refreshToken(
            auth.getTokens().getRefreshToken());
            
        assertThat(refreshResult.isSuccessful()).isTrue();
        assertThat(refreshResult.getNewTokens().getAccessToken())
            .isNotEqualTo(auth.getTokens().getAccessToken());
    }

    @Test
    void testConcurrentSessions() {
        // Test handling of multiple concurrent sessions
        ExecutorService executor = Executors.newFixedThreadPool(5);
        CountDownLatch latch = new CountDownLatch(5);
        
        List<Future<AuthenticationResult>> futures = new ArrayList<>();
        
        for (int i = 0; i < 5; i++) {
            futures.add(executor.submit(() -> {
                try {
                    return authenticateUser(testUser);
                } finally {
                    latch.countDown();
                }
            }));
        }

        latch.await(30, TimeUnit.SECONDS);
        
        // Verify session management
        List<AuthenticationResult> results = futures.stream()
            .map(Future::get)
            .collect(Collectors.toList());
            
        assertThat(sessionManager.getActiveSessions(testUser.getId()))
            .hasSizeLessThanOrEqualTo(
                maxConcurrentSessions);
    }

    @Test
    void testSecurityEventLogging() {
        // Test security event logging during authentication
        AuthenticationRequest request = AuthenticationRequest.builder()
            .username("invalid_user")
            .clientId(clientId)
            .clientSecret(clientSecret)
            .build();

        try {
            authenticationService.authenticate(request);
            fail("Should throw AuthenticationException");
        } catch (AuthenticationException e) {
            // Expected exception
        }

        // Verify security event was logged
        List<SecurityEvent> events = securityEventRepository
            .findByUserAndType(
                "invalid_user", 
                SecurityEventType.FAILED_LOGIN);
                
        assertThat(events).hasSize(1);
        assertThat(events.get(0).getDetails())
            .containsKey("failure_reason");
    }

    @Test
    void testComplianceAuditing() {
        // Test compliance audit trail
        AuthenticationResult auth = authenticateUser(adminUser);
        
        // Perform sensitive action
        resourceService.deleteResource(
            "sensitive_resource", 
            auth.getPrincipal());

        // Verify audit trail
        List<AuditRecord> auditTrail = auditRepository
            .findByUserAndAction(
                adminUser.getId(), 
                "DELETE_RESOURCE");
                
        assertThat(auditTrail).hasSize(1);
        assertThat(auditTrail.get(0).getResourceId())
            .isEqualTo("sensitive_resource");
        assertThat(auditTrail.get(0).getActionResult())
            .isEqualTo(ActionResult.SUCCESS);
    }

    private SecurityEventListener setupSecurityEventListener() {
        return new SecurityEventListener() {
            private final List<SecurityEvent> events = 
                new CopyOnWriteArrayList<>();

            @Override
            public void onSecurityEvent(SecurityEvent event) {
                events.add(event);
            }

            public List<SecurityEvent> getEvents() {
                return new ArrayList<>(events);
            }
        };
    }
}
```

### Security Validation Tests

```java
@SpringBootTest
public class SecurityValidationTests {
    
    @Autowired
    private TokenService tokenService;
    
    @Autowired
    private SecurityConfigurationValidator configValidator;
    
    @Test
    void testTokenSecurity() {
        // Test token encryption
        String sensitiveData = "sensitive_information";
        String encryptedToken = tokenService
            .generateEncryptedToken(sensitiveData);
            
        assertThat(encryptedToken).isNotEqualTo(sensitiveData);
        
        // Test token decryption
        String decryptedData = tokenService
            .decryptToken(encryptedToken);
            
        assertThat(decryptedData).isEqualTo(sensitiveData);
    }

    @Test
    void testSecurityHeaders() {
        MockMvc mockMvc = MockMvcBuilders
            .webAppContextSetup(webApplicationContext)
            .build();

        mockMvc.perform(get("/api/secure"))
            .andExpect(header().string(
                "X-Content-Type-Options", "nosniff"))
            .andExpect(header().string(
                "X-Frame-Options", "DENY"))
            .andExpect(header().string(
                "X-XSS-Protection", "1; mode=block"))
            .andExpect(header().exists(
                "Content-Security-Policy"));
    }

    @Test
    void testSecurityConfiguration() {
        SecurityConfigurationValidationResult result = 
            configValidator.validateConfiguration();
            
        assertThat(result.isValid()).isTrue();
        assertThat(result.getFindings()).isEmpty();
        
        // Verify specific security settings
        assertThat(result.getConfig().getTokenExpiration())
            .isLessThanOrEqualTo(Duration.ofHours(1));
        assertThat(result.getConfig().getPasswordPolicy()
            .getMinimumLength())
            .isGreaterThanOrEqualTo(12);
    }
}
```

## Performance Testing and Load Testing

Performance testing is crucial for ensuring your Entra ID integration can handle production loads while maintaining security and responsiveness. This section covers implementing comprehensive performance tests and load testing scenarios.

### Performance Testing Framework

#### Java Implementation
```java
@SpringBootTest
@TestPropertySource(properties = {
    "spring.main.web-application-type=servlet",
    "performance.test.users=1000",
    "performance.test.concurrent-users=100"
})
public class EntraIdPerformanceTest {

    @Autowired
    private AuthenticationService authenticationService;
    
    @Autowired
    private TokenService tokenService;
    
    @Autowired
    private TestUserGenerator userGenerator;
    
    @Autowired
    private MetricsCollector metricsCollector;

    @Value("${performance.test.users}")
    private int totalUsers;

    @Value("${performance.test.concurrent-users}")
    private int concurrentUsers;

    private ExecutorService executorService;
    private List<TestUser> testUsers;

    @BeforeAll
    void setUp() {
        executorService = Executors.newFixedThreadPool(concurrentUsers);
        testUsers = userGenerator.generateTestUsers(totalUsers);
    }

    @Test
    void testAuthenticationPerformance() throws InterruptedException {
        PerformanceTestResult result = runLoadTest(
            "Authentication Performance",
            () -> {
                TestUser user = getRandomTestUser();
                return measureOperation(
                    "authentication",
                    () -> authenticateUser(user)
                );
            }
        );

        assertPerformanceMetrics(result, 
            PerformanceThreshold.builder()
                .averageResponseTime(Duration.ofMillis(500))
                .maxResponseTime(Duration.ofSeconds(2))
                .errorRate(0.01) // 1% error rate threshold
                .build()
        );
    }

    @Test
    void testTokenValidationPerformance() throws InterruptedException {
        // Pre-generate tokens for testing
        List<String> tokens = generateTestTokens(1000);

        PerformanceTestResult result = runLoadTest(
            "Token Validation Performance",
            () -> {
                String token = getRandomToken(tokens);
                return measureOperation(
                    "token_validation",
                    () -> tokenService.validateToken(token)
                );
            }
        );

        assertPerformanceMetrics(result,
            PerformanceThreshold.builder()
                .averageResponseTime(Duration.ofMillis(50))
                .maxResponseTime(Duration.ofMillis(200))
                .errorRate(0.001) // 0.1% error rate threshold
                .build()
        );
    }

    @Test
    void testConcurrentAuthenticationLoad() throws InterruptedException {
        int testDurationSeconds = 60;
        AtomicInteger successCount = new AtomicInteger(0);
        AtomicInteger failureCount = new AtomicInteger(0);
        
        // Create metrics collector
        MetricsCollector metrics = new MetricsCollector(
            "concurrent_auth_test");

        // Start load test
        CountDownLatch completionLatch = new CountDownLatch(concurrentUsers);
        long startTime = System.currentTimeMillis();

        for (int i = 0; i < concurrentUsers; i++) {
            executorService.submit(() -> {
                try {
                    while ((System.currentTimeMillis() - startTime) < 
                            (testDurationSeconds * 1000)) {
                        try {
                            TestUser user = getRandomTestUser();
                            
                            metrics.recordOperation("authentication", () -> {
                                AuthenticationResult result = 
                                    authenticateUser(user);
                                return result.isSuccessful();
                            });

                            successCount.incrementAndGet();
                            
                            // Simulate user think time
                            Thread.sleep(
                                ThreadLocalRandom.current()
                                    .nextInt(100, 1000)
                            );
                        } catch (Exception e) {
                            failureCount.incrementAndGet();
                            log.error("Authentication failed", e);
                        }
                    }
                } finally {
                    completionLatch.countDown();
                }
            });
        }

        completionLatch.await();

        // Analyze results
        PerformanceReport report = PerformanceReport.builder()
            .testName("Concurrent Authentication Load Test")
            .duration(Duration.ofSeconds(testDurationSeconds))
            .concurrentUsers(concurrentUsers)
            .totalRequests(successCount.get() + failureCount.get())
            .successCount(successCount.get())
            .failureCount(failureCount.get())
            .metrics(metrics.getMetrics())
            .build();

        assertLoadTestResults(report);
    }

    @Test
    void testTokenRefreshUnderLoad() throws InterruptedException {
        // Pre-authenticate users and get refresh tokens
        List<TokenPair> tokenPairs = authenticateUsers(testUsers);

        PerformanceTestResult result = runLoadTest(
            "Token Refresh Performance",
            () -> {
                TokenPair tokenPair = getRandomTokenPair(tokenPairs);
                return measureOperation(
                    "token_refresh",
                    () -> tokenService.refreshToken(
                        tokenPair.getRefreshToken())
                );
            }
        );

        assertPerformanceMetrics(result,
            PerformanceThreshold.builder()
                .averageResponseTime(Duration.ofMillis(200))
                .maxResponseTime(Duration.ofMillis(800))
                .errorRate(0.005) // 0.5% error rate threshold
                .build()
        );
    }

    private PerformanceTestResult runLoadTest(
            String testName, 
            Supplier<OperationResult> operation) 
            throws InterruptedException {
            
        MetricsCollector metrics = new MetricsCollector(testName);
        CountDownLatch completionLatch = new CountDownLatch(concurrentUsers);
        AtomicBoolean testRunning = new AtomicBoolean(true);

        // Start load test threads
        for (int i = 0; i < concurrentUsers; i++) {
            executorService.submit(() -> {
                try {
                    while (testRunning.get()) {
                        metrics.recordOperation(operation.get());
                        // Add random delay between operations
                        Thread.sleep(
                            ThreadLocalRandom.current()
                                .nextInt(50, 200)
                        );
                    }
                } catch (Exception e) {
                    log.error("Test execution error", e);
                } finally {
                    completionLatch.countDown();
                }
            });
        }

        // Run test for specified duration
        Thread.sleep(Duration.ofMinutes(5).toMillis());
        testRunning.set(false);
        completionLatch.await();

        return PerformanceTestResult.builder()
            .testName(testName)
            .metrics(metrics.getMetrics())
            .build();
    }

    private void assertPerformanceMetrics(
            PerformanceTestResult result,
            PerformanceThreshold threshold) {
            
        PerformanceMetrics metrics = result.getMetrics();
        
        assertThat(metrics.getAverageResponseTime())
            .isLessThanOrEqualTo(threshold.getAverageResponseTime());
        assertThat(metrics.getMaxResponseTime())
            .isLessThanOrEqualTo(threshold.getMaxResponseTime());
        assertThat(metrics.getErrorRate())
            .isLessThanOrEqualTo(threshold.getErrorRate());

        // Log detailed metrics
        log.info("Performance Test Results - {}", result.getTestName());
        log.info("Average Response Time: {} ms", 
            metrics.getAverageResponseTime().toMillis());
        log.info("Max Response Time: {} ms", 
            metrics.getMaxResponseTime().toMillis());
        log.info("Error Rate: {}%", 
            metrics.getErrorRate() * 100);
        log.info("Total Requests: {}", 
            metrics.getTotalRequests());
        log.info("Requests/Second: {}", 
            metrics.getRequestsPerSecond());
    }
}
```













