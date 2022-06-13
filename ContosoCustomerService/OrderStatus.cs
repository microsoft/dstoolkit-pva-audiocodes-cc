using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

namespace ContosoCustomerService
{
    public static class OrderStatus
    {
        [FunctionName("OrderSummary")]
        public static async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "orderstatus/{orderId}")] HttpRequest req,
            string orderId,
            ILogger log)
        {
            return new ContentResult() { Content = "1 pair of ladies classic gloves on March 6th 2022 and delivery is currently delayed. The new delivery date is March 21st 2022", ContentType = "text/plain; charset=utf-8", StatusCode = StatusCodes.Status200OK };
        }
    }
}