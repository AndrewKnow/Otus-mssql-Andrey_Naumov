using Microsoft.Extensions.Primitives;
using System;
using System.Data.SqlClient;
using System.Reflection;
using System.Text;
using TgmBot.Data;
using static System.Runtime.InteropServices.JavaScript.JSType;


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

        public async Task<string> SelectTop10Cars()
        {
            StringBuilder sb = new StringBuilder();

            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                connection.Open();
                using (SqlCommand command = new SqlCommand("SELECT TOP 10 Brand, Model FROM CARS ORDER BY CarModelId ASC;", connection))
                {
                    using (SqlDataReader reader = command.ExecuteReader())
                    {
                        if (reader.HasRows)
                        {

                            // Вывод заголовков столбцов
                            sb.AppendLine(string.Format("{0,10} | {1,-10}", "Model", "Brand"));
                            sb.AppendLine(new string('-', 35)); // Разделитель

                            while (reader.Read())
                            {
                                // Length

                                int a = reader.GetString(0).Length;
                                int b = reader.GetString(1).Length;
                                char symbol = '\t';

                                string repeated = new string(symbol, 25 - a);
      

                                //Telegram не поддерживает выравнивание текста с использованием пробелов
                                sb.Append(reader.GetString(1)  + "   (" + reader.GetString(0) + ")\n");
                                //sb.AppendLine(string.Format("{0,-15} | {1,-15}", reader.GetString(1), reader.GetString(0)));

                            }
                        }
                    }
                }
            }

            return sb.ToString();
        }

        public async Task<string> SelectTop1(string tbl)
        {
            StringBuilder sb = new StringBuilder();
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                connection.Open();
                // Изменено: добавляем "*" в запрос для получения всех столбцов
                using (SqlCommand command = new SqlCommand($"SELECT TOP 1 * FROM {tbl};", connection))
                {
                    using (SqlDataReader reader = await command.ExecuteReaderAsync())
                    {
                        if (reader.HasRows)
                        {
                            // Читаем столбцы
                            while (await reader.ReadAsync())
                            {
                                // Для каждого столбца в строке
                                for (int i = 0; i < reader.FieldCount; i++)
                                {
                                    string columnName = reader.GetName(i); // Имя столбца
                                    var columnValue = reader.IsDBNull(i) ? "NULL" : reader.GetValue(i).ToString(); // Значение столбца

                                    sb.AppendLine($"{columnName} - {columnValue}"); // Формируем строку "заголовок - значение"
                                }
                            }
                        }
                    }
                }
            }
            return sb.ToString();
        }

    }
}
