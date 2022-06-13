using System;
using System.Collections.Generic;
using System.Text;

namespace ContosoCustomerService.Model
{
    public class Order
    {
        public string ProductName { get; set; }
        public string Description { get; set; }
        public int Quantity { get; set; }
        public double Cost { get; set; }
    }
}
