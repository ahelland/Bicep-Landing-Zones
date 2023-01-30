using Microsoft.AspNetCore.Mvc;
using Microsoft.Graph;

namespace workload_identity_backend_dotnet7.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class GraphController : ControllerBase
    {
        [HttpGet]
        public ActionResult<IEnumerable<string>> Get()
        {
            GraphServiceClient GraphClient = new GraphServiceClient(new MyClientAssertionCredential());
            var graphOrg = GraphClient.Organization.Request().GetAsync().Result;
            var orgName = graphOrg[0].DisplayName;
            return new string[] { orgName };
        }
    }
}
