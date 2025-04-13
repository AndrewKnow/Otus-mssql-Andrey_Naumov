using System.Data.SqlClient;
using System.Text;

//ADO.NET

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

                    await command.ExecuteNonQueryAsync();
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

                    await command.ExecuteNonQueryAsync();
                }
            }
        }

        public async Task<string> SelectTop20Cars()
        {
            StringBuilder sb = new StringBuilder();

            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                connection.Open();
                using (SqlCommand command = new SqlCommand("SELECT * FROM CARS ORDER BY CarModelId ASC;", connection))
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
                                sb.AppendLine("\n------------------");
                            }

                            //// Вывод заголовков столбцов
                            //sb.AppendLine(string.Format("{0,10} | {1,-10}", "Model", "Brand"));
                            //sb.AppendLine(new string('-', 35)); // Разделитель

                            //while (reader.Read())
                            //{
                            //    // Length

                            //    int a = reader.GetString(0).Length;
                            //    int b = reader.GetString(1).Length;
                            //    char symbol = '\t';

                            //    string repeated = new string(symbol, 25 - a);


                            //    //Telegram не поддерживает выравнивание текста с использованием пробелов
                            //    sb.Append(reader.GetString(1) + "   (" + reader.GetString(0) + ")\n");
                            //    //sb.AppendLine(string.Format("{0,-15} | {1,-15}", reader.GetString(1), reader.GetString(0)));

                            //}
                        }
                    }
                }
            }

            return sb.ToString();
        }


        public async Task<string> SelectCategory()
        {
            StringBuilder sb = new StringBuilder();
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                connection.Open();
                // Изменено: добавляем "*" в запрос для получения всех столбцов
                using (SqlCommand command = new SqlCommand("SELECT * FROM Categories", connection))
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
                                sb.AppendLine("\n------------------");
                            }
                        }
                    }
                }
            }
            return sb.ToString();
        }

        public async Task<string> SelectTop5(string tbl)
        {
            StringBuilder sb = new StringBuilder();
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                connection.Open();
                // Изменено: добавляем "*" в запрос для получения всех столбцов
                using (SqlCommand command = new SqlCommand(tbl == "Accessories" ? $"SELECT * FROM {tbl} Order By {tbl.Substring(0, tbl.Length - 0)}Id asc;" : $"SELECT * FROM {tbl} Order By {tbl.Substring(0, tbl.Length - 1)}Id asc;", connection))
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
                                sb.AppendLine("\n------------------");
                            }
                        }
                    }
                }
            }
            return sb.ToString();
        }


        public async Task<string> Reports(string tbl)
        {
            StringBuilder sb = new StringBuilder();
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                connection.Open();
                var sqlQ = "";
                if (tbl == "ReportProducts")
                {
                    sqlQ = $"SELECT ROW_NUMBER() OVER (ORDER BY p.ProductName) AS [№], p.ProductId ID, p.ProductName Название, t.TotalQuantity Количество FROM {tbl} t JOIN Products p ON p.ProductId = t.ProductId ORDER BY p.ProductName;";
                }
                else if (tbl == "ReportAccessories")
                {
                    sqlQ = $"SELECT ROW_NUMBER() OVER (ORDER BY p.AccessoryName) AS [№], p.AccessoriesId ID, p.AccessoryName Название, t.TotalQuantity Количество FROM {tbl} t JOIN Accessories p ON p.AccessoriesId = t.AccessoriesId ORDER BY p.AccessoryName;";
                }


                using (SqlCommand command = new SqlCommand(sqlQ, connection))
                {
                    using (SqlDataReader reader = await command.ExecuteReaderAsync())
                    {
                        
                        while (await reader.ReadAsync())
                        {
                            // Для каждого столбца в строке
                            for (int i = 0; i < reader.FieldCount; i++)
                            {
                                string columnName = reader.GetName(i); // Имя столбца
                                var columnValue = reader.IsDBNull(i) ? "NULL" : reader.GetValue(i).ToString(); // Значение столбца

                                sb.AppendLine($"{columnName} - {columnValue}"); // Формируем строку "заголовок - значение"
                            }
                            sb.AppendLine("\n------------------");
                        }
                    }
                }
            }
            return sb.ToString();
        }

        public async Task UpdateQuantity(string tbl, string txt)
        {
            try
            {
                string QuantitySource = null;
                string QuantityID = null;

                var quantityMap = new Dictionary<string, string>
                {
                    { "AccessoriesStockQuantity", "TgmBot_Accessories" },
                    { "ProductsStockQuantity", "TgmBot_Products" }
                };

                if (!quantityMap.ContainsKey(tbl))
                    return;

                QuantitySource = quantityMap[tbl];
                QuantityID = QuantitySource == "TgmBot_Accessories" ? "[AccessoriesId]" : "[ProductId]";

                string[] parts = txt.Split(',');

                string param1 = parts[0].Trim();
                string param2 = parts[1].Trim();
                string param3 = QuantitySource;

                using (SqlConnection connection = new SqlConnection(_connectionString))
                {
                    await connection.OpenAsync();

                    var sqlQ = $"SELECT count(*) FROM {tbl} WHERE {QuantityID} = @setQuantityId;";
                    bool exists = false;

                    using (SqlCommand command = new SqlCommand(sqlQ, connection))
                    {
                        command.Parameters.AddWithValue("@setQuantityId", param1);
                        using (SqlDataReader reader = await command.ExecuteReaderAsync())
                        {
                            //exists = reader.HasRows;
                            var i = 0;
                            while (await reader.ReadAsync())
                            {
                                i = int.Parse(reader[0].ToString());
                            }
                            if (i > 0)
                            {
                                exists = true;
                            }
                        }
                    }

                    if (exists)
                    {
                        sqlQ = $"UPDATE {tbl} SET [Quantity] = [Quantity] + (@setQuantity) WHERE {QuantityID} = @setQuantityId;";

                        //sqlQ = $"UPDATE {tbl} SET[Quantity] = [Quantity] + (@setQuantity)  WHERE [ProductId] = @setQuantityId;";

                        using (SqlCommand commandUPDATE = new SqlCommand(sqlQ, connection))
                        {
                            commandUPDATE.Parameters.AddWithValue("@setQuantity", param2);
                            commandUPDATE.Parameters.AddWithValue("@setQuantityId", param1);
                            await commandUPDATE.ExecuteNonQueryAsync();
                        }
                    }
                    else
                    {
                        sqlQ = $"INSERT INTO {tbl} ([Quantity], {QuantityID}, [QuantitySource]) VALUES (@setQuantity, @setQuantityId, @QuantitySource);";
                        using (SqlCommand commandInsert = new SqlCommand(sqlQ, connection))
                        {
                            commandInsert.Parameters.AddWithValue("@setQuantity", param2);
                            commandInsert.Parameters.AddWithValue("@setQuantityId", param1);
                            commandInsert.Parameters.AddWithValue("@QuantitySource", param3);
                            await commandInsert.ExecuteNonQueryAsync();
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Ошибка при обновлении: {ex.Message}");
                // Можно пробросить или логировать
            }
        }
    }
}
