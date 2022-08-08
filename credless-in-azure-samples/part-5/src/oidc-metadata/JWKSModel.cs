using Microsoft.IdentityModel.Tokens;
using Newtonsoft.Json;
using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;
using System.Text.Json.Serialization;

namespace oidc_metadata
{
    public class JWKSModel
    {
        [JsonPropertyName("keys")]
        public ICollection<JwksKeyModel> Keys { get; set; }
    }

    public class JwksKeyModel
    {
        [JsonPropertyName("kid")]
        public string Kid { get; set; }

        [JsonPropertyName("nbf")]
        public long Nbf { get; set; }

        [JsonPropertyName("use")]
        public string Use { get; set; }

        [JsonPropertyName("kty")]
        public string Kty { get; set; }

        [JsonPropertyName("alg")]
        public string Alg { get; set; }

        [JsonPropertyName("x5c")]

        public ICollection<string> X5C { get; set; }

        [JsonPropertyName("x5t")]
        public string X5T { get; set; }

        [JsonPropertyName("n")]
        public string N { get; set; }

        [JsonPropertyName("e")]
        public string E { get; set; }

        public static JwksKeyModel FromSigningCredentials(X509SigningCredentials signingCredentials)
        {
            if (signingCredentials == null)
                return null;

            X509Certificate2 certificate = signingCredentials.Certificate;

            // JWK cert data must be base64 (not base64url) encoded
            string certData = Convert.ToBase64String(certificate.Export(X509ContentType.Cert));

            // JWK thumbprints must be base64url encoded (no padding or special chars)
            string thumbprint = Base64UrlEncoder.Encode(certificate.GetCertHash());

            // JWK must have the modulus and exponent explicitly defined
            var rsa = certificate.GetRSAPublicKey(); ;

            if (rsa == null)
            {
                throw new Exception("Certificate is not an RSA certificate.");
            }

            RSAParameters keyParams = rsa.ExportParameters(false);
            string keyModulus = Base64UrlEncoder.Encode(keyParams.Modulus);
            string keyExponent = Base64UrlEncoder.Encode(keyParams.Exponent);

            return new JwksKeyModel
            {
                //In line with AAD convention kid == x5t == thumbprint:
                Kid = thumbprint,
                //To use "kid" as kid:
                //Kid = signingCredentials.Kid,
                Kty = "RSA",
                Nbf = new DateTimeOffset(certificate.NotBefore).ToUnixTimeSeconds(),
                Use = "sig",
                Alg = signingCredentials.Algorithm,
                X5C = new[] { certData },
                X5T = thumbprint,
                N = keyModulus,
                E = keyExponent
            };
        }
    }
}
