using System;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;
using System.Data.SqlClient;


namespace CLR
{
    public class WarehouseForAutoTourism
    {

        [SqlProcedure]
        public static void GetStockQuantities(DateTime startDate, DateTime endDate)
        {
            using (SqlConnection connection = new  SqlConnection("Server=Dynamo\\OTUSSQL; Database=WarehouseForAutoTourism; Integrated Security=True;"))
            {
                connection.Open();

                // Шаг 1: Получение списка уникальных дат
                string columnsDateListQuery = @"
                SELECT DISTINCT CONVERT(VARCHAR(10), LastUpdated, 120) AS LastUpdated 
                FROM ProductsStockQuantity
                WHERE CONVERT(DATE, LastUpdated) BETWEEN @startDate AND @endDate
                ORDER BY LastUpdated;";

                SqlCommand cmd = new SqlCommand(columnsDateListQuery, connection);
                cmd.Parameters.AddWithValue("@startDate", startDate);
                cmd.Parameters.AddWithValue("@endDate", endDate);

                SqlDataReader reader = cmd.ExecuteReader();
                StringBuilder columnsDateList = new StringBuilder();

                while (reader.Read())
                {
                    if (columnsDateList.Length > 0)
                        columnsDateList.Append(", ");
                    columnsDateList.Append(QUOTENAME(reader["LastUpdated"].ToString()));
                }
                reader.Close();

                if (columnsDateList.Length == 0)
                {
                    // Отправка сообщения в Pipe в случае, если нет данных
                    SqlContext.Pipe.Send("Нет данных для указанного диапазона.");
                    return;
                }

                // Шаг 2: Формирование динамического SQL-запроса
                string sql = @"
                SELECT ProductName, QuantitySource, " + columnsDateList.ToString() + @"
                FROM 
                (
                    SELECT 
                        P.ProductName,
                        PSQ.QuantitySource,
                        CONVERT(VARCHAR(10), PSQ.LastUpdated, 120) AS StockDate,
                        PSQ.Quantity
                    FROM ProductsStockQuantity PSQ
                    JOIN Products P ON PSQ.ProductId = P.ProductId
                    WHERE PSQ.LastUpdated BETWEEN @startDate AND @endDate
                ) AS SourceTable
                PIVOT 
                (
                    SUM(Quantity)
                    FOR StockDate IN (" + columnsDateList.ToString() + @")
                ) AS PivotTable
                ORDER BY ProductName, QuantitySource;";

                // Шаг 3: Выполнение динамического SQL и возврат данных через SqlDataReader
                cmd = new SqlCommand(sql, connection);
                cmd.Parameters.AddWithValue("@startDate", startDate);
                cmd.Parameters.AddWithValue("@endDate", endDate);

                SqlDataReader finalReader = cmd.ExecuteReader();

                // Теперь возвращаем результаты как обычный результат в виде таблицы

                //SqlContext.Pipe.Send($" результат имеет строки {finalReader.HasRows.ToString()}");

                while (finalReader.Read())
                {
                    //SqlContext.Pipe.Send("Читаю finalReader");
                    // Выводим данные через SqlContext.Pipe.Send
                    string resultRow = "";
                    for (int i = 0; i < finalReader.FieldCount; i++)
                    {
                        resultRow += finalReader.GetValue(i).ToString() + "\t";
                    }
                    SqlContext.Pipe.Send(resultRow);
                }

                
            }
        }

        private static string QUOTENAME(string value)
        {
            return "[" + value.Replace("]", "]]") + "]";
        }
    }

}

