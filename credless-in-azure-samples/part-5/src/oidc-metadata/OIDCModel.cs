using System.Text.Json.Serialization;

namespace oidc_metadata
{
    public class OIDCModel
    {
        [JsonPropertyName("issuer")]
        public string? Issuer { get; set; }

        [JsonPropertyName("jwks_uri")]
        public string? JwksUri { get; set; }

        [JsonPropertyName("id_token_signing_alg_values_supported")]
        public ICollection<string>? IdTokenSigningAlgValuesSupported { get; set; }
    }
}
