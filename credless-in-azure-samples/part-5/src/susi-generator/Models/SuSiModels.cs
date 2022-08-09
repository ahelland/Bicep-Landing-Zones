namespace susi_generator.Models
{
    public class SignInLinkModel
    {        
        public string audience { get; set; }
        public string email { get; set; }        
    }

    public class SignUpLinkModel
    {
        public string audience { get; set; }
        public string email { get; set; }     
        public string displayName { get; set; }
        public string givenName { get; set; }
        public string surname { get; set; }
    }
}
