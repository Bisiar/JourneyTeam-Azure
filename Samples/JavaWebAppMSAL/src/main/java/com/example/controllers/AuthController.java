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