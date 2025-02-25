using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TgmBot.ConnectionProperties
{
    internal class TgmKey
    {
        public static string Key { get; set; }
        public static string Bot()
        {
            StreamReader f = new("Key.txt");
            if (!f.EndOfStream)
#pragma warning disable CS8601 // Возможно, назначение-ссылка, допускающее значение NULL.
                Key = f.ReadLine();
#pragma warning restore CS8601 // Возможно, назначение-ссылка, допускающее значение NULL.
            f.Close();
            return !string.IsNullOrEmpty(Key) ? Key : "Нет ключа";
        }
    }
}
