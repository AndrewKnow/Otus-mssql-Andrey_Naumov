using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TgmBot.Data
{
    public class Accessories
    {
        public static bool InsertAccessories  { get; set; }
        public int ProductId { get; set; }
        public string AccessoryName { get; set; }
        public int CategoryId { get; set; }
        public decimal Price { get; set; }
        public string Description { get; set; }
    }
}
