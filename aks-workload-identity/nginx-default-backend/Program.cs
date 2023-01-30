var builder = WebApplication.CreateBuilder(args);
builder.Services.AddHealthChecks();

var app = builder.Build();

app.MapHealthChecks("/healthz");

app.UseHttpsRedirection();

app.MapGet("/", () => Results.Ok());
app.Run();