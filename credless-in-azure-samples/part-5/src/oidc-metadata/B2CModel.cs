using System.Text.Json.Serialization;

namespace oidc_metadata
{
    public class B2CModel
    {
        [JsonPropertyName("issuer")]
        public string? Issuer { get; set; }

        [JsonPropertyName("authorization_endpoint")]
        public string? AuthorizationEndpoint { get; set; }

        [JsonPropertyName("token_endpoint")]
        public string? TokenEndpoint { get; set; }

        [JsonPropertyName("end_session_endpoint")]
        public string? EndSessionEndpoint { get; set; }

        [JsonPropertyName("jwks_uri")]
        public string? JwksUri { get; set; }

        [JsonPropertyName("response_modes_supported")]
        public ICollection<string>? ResponseModesSupported { get; set; }

        [JsonPropertyName("response_types_supported")]
        public ICollection<string>? ResponseTypesSupported { get; set; }

        [JsonPropertyName("scopes_supported")]
        public ICollection<string>? ScopesSupported { get; set; }

        [JsonPropertyName("subject_types_supported")]
        public ICollection<string>? SubjectTypesSupported { get; set; }

        [JsonPropertyName("id_token_signing_alg_values_supported")]
        public ICollection<string>? IdTokenSigningAlgValuesSupported { get; set; }

        [JsonPropertyName("token_endpoint_auth_methods_supported")]
        public ICollection<string>? TokenEndpointAuthModesSupported { get; set; }

        [JsonPropertyName("claims_supported")]
        public ICollection<string>? ClaimsSupported { get; set; }
    }
}
