using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Azure.WebJobs.Extensions.OpenApi.Core.Attributes;
using Microsoft.Extensions.Logging;
using Microsoft.OpenApi.Models;
using OpenQA.Selenium.Edge;
using OpenQA.Selenium.Remote;
using System;
using System.Net;
using System.Threading.Tasks;

namespace AzureFunctionSeleniumInfraTest.Functions
{
    public class TestSeleniumOnEdge
    {
        private readonly ILogger<TestSeleniumOnEdge> _logger;

        public TestSeleniumOnEdge(ILogger<TestSeleniumOnEdge> log)
        {
            _logger = log;
        }

        [FunctionName("TestSeleniumOnEdge")]
        [OpenApiOperation(operationId: "Run")]
        [OpenApiResponseWithBody(statusCode: HttpStatusCode.OK, contentType: "text/plain", bodyType: typeof(string), Description = "The OK response")]
        public async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", "post", Route = null)] HttpRequest req)
        {
            _logger.LogInformation("C# HTTP trigger function processed a request.");

            string pageTitle = "Unknown"; // Default page title if operation fails
            RemoteWebDriver driver = null;

            try
            {
                // Get the Selenium Grid URL from the environment
                var seleniumGridUrl = Environment.GetEnvironmentVariable("SELENIUM_GRID_URL");
                if (string.IsNullOrEmpty(seleniumGridUrl))
                {
                    _logger.LogError("SELENIUM_GRID_URL environment variable is not set.");
                    return new BadRequestObjectResult("SELENIUM_GRID_URL is not configured.");
                }

                // Initialize EdgeOptions for RemoteWebDriver
                EdgeOptions options = new EdgeOptions();
                options.AddArgument("headless");  // Run in headless mode
                options.AddArgument("disable-gpu");

                // Instantiate the RemoteWebDriver using the Selenium Grid URL
                driver = new RemoteWebDriver(new Uri(seleniumGridUrl), options.ToCapabilities(), TimeSpan.FromSeconds(180));

                // Navigate to microsoft.com
                driver.Navigate().GoToUrl("https://www.microsoft.com");

                // Retrieve the page title
                pageTitle = driver.Title;
                _logger.LogInformation($"Page title: {pageTitle}");
            }
            catch (Exception ex)
            {
                _logger.LogError($"An error occurred while fetching the page title: {ex.Message}");
                return new StatusCodeResult(StatusCodes.Status500InternalServerError);
            }
            finally
            {
                driver?.Quit();
            }

            // Return the page title as a response
            return new OkObjectResult($"Page Title: {pageTitle}");
        }
    }
}

