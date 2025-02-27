using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using System.Text.RegularExpressions;
using TgmBot.ConnectionProperties;

namespace TgmBot.Data
{
    public class DataValidation
    {

        public static async Task<bool> GetValidationProduct(string txt)
        {
            bool check = false;
            // Шаблон регулярного выражения
            string pattern = @"^[\w\s]+,\s*\d+\s*,\s*\d+(?:\.\d+)?\s*,[\w\s]+$";

            // Создаем объект Regex и проверяем совпадение
            Match match = Regex.Match(txt, pattern);

            // Возвращаем результат проверки
            check = match.Success;

            if (check)
            {
                Repository repository = new Repository();
                await repository.InsertPruduct(txt);
            }

            return check;
        }

        public static async Task<bool> GetValidationAccessories(string txt)
        {
            bool check = false;
            // Шаблон регулярного выражения
            string pattern = @"^\d+(?:\.\d+)?\,\s*[\w\s]+\,\s*\d+\s*,\s*\d+(?:\.\d+)?\s*,\s*[\w\s]+$";

            // Создаем объект Regex и проверяем совпадение
            Match match = Regex.Match(txt, pattern);

            // Возвращаем результат проверки
            check = match.Success;

            if (check)
            {
                Repository repository = new Repository();
                await repository.InsertAccessories(txt);
            }

            return check;
        }

        public static async Task<bool> GetValidationQuantity(string txt, string tbl)
        {
            bool check = false;
            string pattern = @"^\d+\s*,\s*\d+(\.\d+)?$";

            Match match = Regex.Match(txt, pattern);

            // Возвращаем результат проверки
            check = match.Success;

            if (check)
            {
                Repository repository = new Repository();
                await repository.UpdateQuantity(txt, tbl);
            }
            return check;
        }
    }
}
