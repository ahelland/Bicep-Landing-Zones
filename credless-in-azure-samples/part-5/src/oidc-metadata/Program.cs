using Azure.Identity;
using Azure.Security.KeyVault.Secrets;
using Microsoft.AspNetCore.DataProtection.KeyManagement;
using Microsoft.IdentityModel.Tokens;
using oidc_metadata;
using System.Security.Cryptography.X509Certificates;

var builder = WebApplication.CreateBuilder(args);

var app = builder.Build();

//Make sure scheme is https
app.Use((context, next) =>
{
    context.Request.Scheme = "https";
    return next();
});

app.UseHttpsRedirection();

app.MapGet("/.well-known/openid-configuration", (HttpContext httpContext) =>
{
    var metadata = new OIDCModel
    {
        Issuer = builder.Configuration.GetSection("JWTSettings")["Issuer"],
        JwksUri = $"{httpContext.Request.Scheme}://{httpContext.Request.Host}/.well-known/keys",
        IdTokenSigningAlgValuesSupported = new[] { builder.Configuration.GetSection("JWTSettings")["SigningCertAlgorithm"], }
    };

    return metadata;
})
.WithName("openid-configuration");

app.MapGet(".well-known/openid-configuration-b2c", (HttpContext httpContext) =>
{
    var instance = builder.Configuration.GetSection("AzureAD")["Instance"];
    var domain = builder.Configuration.GetSection("AzureAD")["Domain"];

    var metadata = new B2CModel
    {
        Issuer = builder.Configuration.GetSection("JWTSettings")["Issuer"],
        AuthorizationEndpoint = $"{instance}/{domain}/oauth2/v2.0/authorize?p=b2c_1a_signin_link_github",
        TokenEndpoint = $"{instance}/{domain}/oauth2/v2.0/token?p=b2c_1a_signin_link_github",
        EndSessionEndpoint = $"{instance}/{domain}/oauth2/v2.0/logout?p=b2c_1a_signin_link_github",
        ResponseModesSupported = new[] { "query", "fragment", "form_post" },
        ResponseTypesSupported = new[] { "code", "code id_token", "code token", "code id_token token", "id_token", "id_token token", "token", "token id_token" },
        ScopesSupported = new[] { "openid" },
        SubjectTypesSupported = new[] { "pairwise" },
        JwksUri = $"{httpContext.Request.Scheme}://{httpContext.Request.Host}/.well-known/keys",
        TokenEndpointAuthModesSupported = new[] { "client_secret_post", "client_secret_basic" },
        IdTokenSigningAlgValuesSupported = new[] { builder.Configuration.GetSection("JWTSettings")["SigningCertAlgorithm"], },
        ClaimsSupported = new[] { "name", "given_name", "family_name", "email", "sub", "idp", "Role", "iss", "iat", "exp", "aud", "acr", "nonce", "auth_time" }
    };

    return metadata;
})
.WithName("openid-configuration-b2c");

app.MapGet("/.well-known/keys", (HttpContext httpContext) =>
{
    var SigningCertThumbprint = builder.Configuration.GetSection("JWTSettings")["SigningCertThumbprint"];
    Lazy<X509SigningCredentials>? SigningCredentials = null;

    //If we run on Windows the certificate needs to be in cert store
    if (Environment.OSVersion.Platform == PlatformID.Win32NT)
    {
        SigningCredentials = new Lazy<X509SigningCredentials>(() =>
        {
            X509Store certStore = new X509Store(StoreName.My, StoreLocation.CurrentUser);
            certStore.Open(OpenFlags.ReadOnly);
            X509Certificate2Collection certCollection = certStore.Certificates.Find(
                                        X509FindType.FindByThumbprint,
                                        SigningCertThumbprint,
                                        false);
            // Get the first cert with the thumbprint
            if (certCollection.Count > 0)
            {
                return new X509SigningCredentials(certCollection[0]);
            }

            return null;
        });
    }
    //If Linux
    if (Environment.OSVersion.Platform == PlatformID.Unix)
    {
        {
            byte[]? bytes = null;

            //Check if we're running in Azure Container Apps and if so enable Key Vault integration
            if (builder.Configuration.GetSection("JWTSettings")["HostEnvironment"] == "ACA")
            {
                var vaultName = builder.Configuration.GetSection("AzureSettings")["KeyVaultName"];
                var certificateName = builder.Configuration.GetSection("AzureSettings")["CertificateName"];

                var client = new SecretClient(new Uri($"https://{vaultName}.vault.azure.net/"), new ManagedIdentityCredential());
                var certy = client.GetSecret(certificateName);
                var rawCert = certy.Value;
                bytes = Convert.FromBase64String(rawCert.Value);
            }
            //Fallback to file system if local Linux
            else
            {
                bytes = System.IO.File.ReadAllBytes($"/var/ssl/private/{SigningCertThumbprint}.p12");
            }

            var cert = new X509Certificate2(bytes);

            SigningCredentials = new Lazy<X509SigningCredentials>(() =>
            {
                if (cert != null)
                {
                    return new X509SigningCredentials(cert);
                }

                return new X509SigningCredentials(null);
            });
        }
    }

    if (SigningCredentials == null)
        return null;

    JwksKeyModel key = JwksKeyModel.FromSigningCredentials(SigningCredentials.Value);
    var keys = new JWKSModel { Keys = new[] { key } };

    return keys;
})
.WithName("keys");

app.Run();