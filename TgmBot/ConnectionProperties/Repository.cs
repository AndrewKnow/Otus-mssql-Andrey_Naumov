using System;
using System.Data.SqlClient;
using System.Reflection;


namespace TgmBot.ConnectionProperties
{
    public class Repository
    {
        private static readonly string _connectionString = "Server=Dynamo\\OTUSSQL; Database=WarehouseForAutoTourism; Integrated Security=True;";

        public async Task InsertPruduct(string txt)
        {

            string[] parts = txt.Split(',');

            string param1 = parts[0].Trim();         
            string param2 = parts[1].Trim();         
            string param3 = parts[2].Trim();         
            string param4 = parts[3].Trim();


            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                connection.Open();

                var sqlQ = "INSERT INTO Products (ProductName, CategoryId, Price, Description) VALUES " +
                           "(@ProductName, @CategoryId, @Price, @Description)";

                using (SqlCommand command = new SqlCommand(sqlQ, connection))
                {
                    command.Parameters.AddWithValue("@ProductName", param1);
                    command.Parameters.AddWithValue("@CategoryId", param2);
                    command.Parameters.AddWithValue("@Price", param3);
                    command.Parameters.AddWithValue("@Description", param4);

                    command.ExecuteNonQuery();
                }   
            }

        }


        public async Task InsertAccessories(string txt)
        {
            string[] parts = txt.Split(',');

            string param1 = parts[0].Trim();
            string param2 = parts[1].Trim();
            string param3 = parts[2].Trim();
            string param4 = parts[3].Trim();
            string param5 = parts[4].Trim();

            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                connection.Open();

                var sqlQ = "INSERT INTO Accessories (ProductId, AccessoryName, CategoryId, Price, Description) VALUES " +
                           "(@ProductId, @AccessoriesName, @CategoryId, @Price, @Description)";

                using (SqlCommand command = new SqlCommand(sqlQ, connection))
                {
                    command.Parameters.AddWithValue("@ProductId", param1);
                    command.Parameters.AddWithValue("@AccessoriesName", param2);
                    command.Parameters.AddWithValue("@CategoryId", param3);
                    command.Parameters.AddWithValue("@Price", param4);
                    command.Parameters.AddWithValue("@Description", param5);

                    command.ExecuteNonQuery();
                }
            }
        }

    }
}
