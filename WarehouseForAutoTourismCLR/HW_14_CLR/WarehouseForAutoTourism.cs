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
            var connectionString = "Server=Dynamo\\OTUSSQL; Database=WarehouseForAutoTourism; Integrated Security=True;";

            var query = @"Select
                    P.ProductId, 
                    P.ProductName, 
                    P.Price, 
                    P.Description ProductDescription,
                    A.AccessoriesId, 
                    A.AccessoryName, 
                    A.Price , 
                    A.Description AccessoryDescription
                From Products P
                Join CarCompatibility CC on P.ProductId = CC.ProductId
                Join Cars C on CC.CarModelId = C.CarModelId
                Left join Accessories A on P.ProductId = A.ProductId
                Where C.Brand = @Brand and C.Model = @Model and P.ProductName LIKE @ProductName;";


            using (SqlConnection connection = new SqlConnection(connectionString))
            {
                connection.Open();

                using (SqlCommand command = new SqlCommand(query, connection))
                {
                    // Добавление параметров
                    command.Parameters.AddWithValue("@Brand", brand);
                    command.Parameters.AddWithValue("@Model", model);
                    command.Parameters.AddWithValue("@ProductName", "%" + productName + "%");

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
                            SqlContext.Pipe.Send("Нет данных");
                        }
                    }
                }
            }
        }
    }
}
