using System;
using System.Data;
using System.Data.SqlClient;

namespace ConsoleApp
{
    class Program
    {
        static void Main(string[] args)
        {
            // Запрашиваем у пользователя значения для фильтрации
            Console.Write("Введите бренд автомобиля (например, 'LADA'): ");
            var brand = Console.ReadLine();

            Console.Write("Введите модель автомобиля (например, 'GRANTA'): ");
            var model = Console.ReadLine();

            Console.Write("Введите часть названия продукта для поиска (например, 'тент'): ");
            var productName = Console.ReadLine();

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
                    command.Parameters.AddWithValue("@Brand", brand);
                    command.Parameters.AddWithValue("@Model", model);
                    command.Parameters.AddWithValue("@ProductName", "%" + productName + "%"); // Добавляем символы '%' для LIKE

                    using (SqlDataReader reader = command.ExecuteReader())
                    {
                        if (reader.HasRows)
                        {
                            Console.WriteLine("Результаты запроса:");
       
                            Console.WriteLine("ProductId | ProductName | Price | ProductDescription | AccessoriesId | AccessoryName | AccessoryPrice | AccessoryDescription");

                            while (reader.Read())
                            {
          
                                Console.WriteLine($"{reader.GetInt32(0)} | {reader.GetString(1)} | {reader.GetDecimal(2)} | {reader.GetString(3)} | " +
                                    $"{(reader.IsDBNull(4) ? "NULL" : reader.GetInt32(4).ToString())} | " +
                                    $"{(reader.IsDBNull(5) ? "NULL" : reader.GetString(5))} | " +
                                    $"{(reader.IsDBNull(6) ? "NULL" : reader.GetDecimal(6).ToString())} | " +
                                    $"{(reader.IsDBNull(7) ? "NULL" : reader.GetString(7))}");
                            }
                        }
                        else
                        {
                            Console.WriteLine("Нет данных для указанного запроса.");
                        }
                    }
                }
            }

            Console.WriteLine("\nНажмите любую клавишу для выхода...");
            Console.ReadKey();
        }
    }
}
