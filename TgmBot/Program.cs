
using TgmBot.ConnectionProperties;

namespace TgmBot
{
    internal class Program
    {
        static void Main(string[] args)
        {
            string Key = Password.Bot();
            var bot = new TelegramBotClient(Key);
        }
    }
}
