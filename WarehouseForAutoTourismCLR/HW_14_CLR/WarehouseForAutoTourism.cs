using System;
using System.Data;
using System.Data.SqlClient;
using Microsoft.SqlServer.Server;

namespace CLR
{
    public class WarehouseForAutoTourism
    {
        // SQL CLR-процедура
        [SqlProcedure]
        public static void GetProductDetailsForCars(string brand, string model, string productName)
        {
            // Строка подключения
            string connectionString = "Server=Dynamo\\OTUSSQL; Database=WarehouseForAutoTourism; Integrated Security=True;";

            string query = @"
                SELECT 
                    P.ProductId, 
                    P.ProductName, 
                    P.Price, 
                    P.Description AS ProductDescription,
                    A.AccessoriesId, 
                    A.AccessoryName, 
                    A.Price AS AccessoryPrice, 
                    A.Description AS AccessoryDescription
                FROM Products P
                JOIN CarCompatibility CC ON P.ProductId = CC.ProductId
                JOIN Cars C ON CC.CarModelId = C.CarModelId
                LEFT JOIN Accessories A ON P.ProductId = A.ProductId
                WHERE C.Brand = @Brand 
                  AND C.Model = @Model 
                  AND P.ProductName LIKE @ProductName;";


            using (SqlConnection connection = new SqlConnection(connectionString))
            {
                connection.Open();

                using (SqlCommand command = new SqlCommand(query, connection))
                {
                    // Добавление параметров
                    command.Parameters.AddWithValue("@Brand", brand);
                    command.Parameters.AddWithValue("@Model", model);
                    command.Parameters.AddWithValue("@ProductName", "%" + productName + "%"); // Добавляем символы '%' для LIKE

                    using (SqlDataReader reader = command.ExecuteReader())
                    {
                        if (reader.HasRows)
                        {
                            // SQL результат
                            SqlDataRecord record = new SqlDataRecord(
                                new SqlMetaData("ProductId", SqlDbType.Int),
                                new SqlMetaData("ProductName", SqlDbType.NVarChar, 255),
                                new SqlMetaData("Price", SqlDbType.Decimal),
                                new SqlMetaData("ProductDescription", SqlDbType.NVarChar, 255),
                                new SqlMetaData("AccessoriesId", SqlDbType.Int),
                                new SqlMetaData("AccessoryName", SqlDbType.NVarChar, 255),
                                new SqlMetaData("AccessoryPrice", SqlDbType.Decimal),
                                new SqlMetaData("AccessoryDescription", SqlDbType.NVarChar, 255)
                            );

                            // Отправка данных
                            SqlContext.Pipe.SendResultsStart(record);

                            while (reader.Read())
                            {
                                record.SetInt32(0, reader.GetInt32(0)); // ProductId
                                record.SetString(1, reader.GetString(1)); // ProductName
                                record.SetDecimal(2, reader.GetDecimal(2)); // Price
                                record.SetString(3, reader.GetString(3)); // ProductDescription
                                record.SetInt32(4, reader.IsDBNull(4) ? 0 : reader.GetInt32(4)); // AccessoriesId
                                record.SetString(5, reader.IsDBNull(5) ? string.Empty : reader.GetString(5)); // AccessoryName
                                record.SetDecimal(6, reader.IsDBNull(6) ? 0 : reader.GetDecimal(6)); // AccessoryPrice
                                record.SetString(7, reader.IsDBNull(7) ? string.Empty : reader.GetString(7)); // AccessoryDescription

                                SqlContext.Pipe.SendResultsRow(record);
                            }

                            SqlContext.Pipe.SendResultsEnd();
                        }
                        else
                        {
                            SqlContext.Pipe.Send("Нет данных для указанного запроса.");
                        }
                    }
                }
            }
        }
    }
}
