using Azure.Identity;
using Azure.Security.KeyVault.Secrets;
using Microsoft.AspNetCore.Components;
using Microsoft.IdentityModel.Tokens;
using susi_generator.Models;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Cryptography.X509Certificates;

namespace susi_generator.Pages
{
    public class InviteBase : ComponentBase
    {
        [Inject]
        protected IConfiguration configuration { get; set; }
        private static Lazy<X509SigningCredentials> SigningCredentials;
        protected string SigningCertThumbprint = string.Empty;

        public static SignUpLinkModel SignUp { get; set; }
        public string output = "";

        protected override void OnInitialized()
        {
            string iss = configuration.GetSection("JWTSettings")["Issuer"];
            string aud = configuration.GetSection("JWTSettings")["Audience"];
            string sub = configuration.GetSection("SuSiSettings")["EmailAddress"];

            SigningCertThumbprint = configuration.GetSection("SuSiSettings")["SigningCertThumbprint"];

            SignUp = new SignUpLinkModel
            {
                audience = aud,
                email = configuration.GetSection("SuSiSettings")["EmailAddress"],
                displayName = "John Doe",
                givenName = "John",
                surname = "Doe",
            };

            //If we run on Windows the certificate needs to be in cert store
            if (Environment.OSVersion.Platform == PlatformID.Win32NT)
            {
                SigningCredentials = new Lazy<X509SigningCredentials>(() =>
                {
                    X509Store certStore = new(StoreName.My, StoreLocation.CurrentUser);
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
                    if (configuration.GetSection("JWTSettings")["HostEnvironment"] == "ACA")
                    {
                        var vaultName = configuration.GetSection("AzureSettings")["KeyVaultName"];
                        var certificateName = configuration.GetSection("AzureSettings")["CertificateName"];

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
        }

        protected void HandleValidSubmit()
        {

        }

        protected async Task GenerateInviteLinkAsync()
        {
            string email = SignUp.email;
            string token = BuildIdToken(email);
            string link = BuildUrl(token);
            output = link;
        }
        private string BuildIdToken(string Email)
        {
            string B2CClientId = configuration.GetSection("SuSiSettings")["B2CClientId"];
            double.TryParse(configuration.GetSection("SuSiSettings")["LinkExpiresAfterMinutes"], out double LinkExpiresAfterMinutes);

            string issuer = configuration.GetSection("SuSiSettings")["issuer"];
            string audience = configuration.GetSection("SuSiSettings")["audience"];

            // All parameters sent to Azure AD B2C needs to be sent as claims
            IList<System.Security.Claims.Claim> claims = new List<System.Security.Claims.Claim>
            {
                new System.Security.Claims.Claim("aud", audience, System.Security.Claims.ClaimValueTypes.String, issuer),
                new System.Security.Claims.Claim("email", Email, System.Security.Claims.ClaimValueTypes.String, issuer),
                new System.Security.Claims.Claim("displayName", SignUp.displayName, System.Security.Claims.ClaimValueTypes.String, issuer),
                new System.Security.Claims.Claim("givenName", SignUp.givenName, System.Security.Claims.ClaimValueTypes.String, issuer),
                new System.Security.Claims.Claim("surname", SignUp.surname, System.Security.Claims.ClaimValueTypes.String, issuer),
                new System.Security.Claims.Claim("family_name", SignUp.surname, System.Security.Claims.ClaimValueTypes.String, issuer)
            };

            // Create the token
            JwtSecurityToken token = new(
                    issuer,
                    B2CClientId,
                    claims,
                    DateTime.Now,
                    DateTime.Now.AddMinutes(LinkExpiresAfterMinutes),
                    SigningCredentials.Value);

            // Get the representation of the signed token
            JwtSecurityTokenHandler jwtHandler = new();

            return jwtHandler.WriteToken(token);
        }

        private string BuildUrl(string token)
        {
            string B2CSignUpUrl    = configuration.GetSection("SuSiSettings")["B2CSignUpUrlBase"];
            string B2CSignUpPolicy = configuration.GetSection("SuSiSettings")["B2CSignUpPolicy"];

            return $"{B2CSignUpUrl}/MicrosoftIdentity/Account/SignIn?tokenHint={token}&policy={B2CSignUpPolicy}";
        }
    }
}
