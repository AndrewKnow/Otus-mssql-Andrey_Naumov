
using Telegram.Bot;
using Telegram.Bot.Extensions;
using Telegram.Bot.Polling;
using Telegram.Bot.Types;
using Telegram.Bot.Types.Enums;
using Telegram.Bot.Types.ReplyMarkups;

using TgmBot.ConnectionProperties;

namespace TgmBot
{
    internal class Program
    {
        static void Main(string[] args)
        {
            string Key = TgmKey.Bot();
            var bot = new TelegramBotClient(Key);

            Console.WriteLine("Включён бот " + bot.GetMyName().Result.Name);

            using var cts = new CancellationTokenSource();
            var cancellationToken = cts.Token;
            var receiverOptions = new ReceiverOptions
            {
                AllowedUpdates = { },
            };

            bot.StartReceiving(updateHandler: HandleUpdateAsync,
                   errorHandler: HandleErrorAsync,
                   receiverOptions: new ReceiverOptions()
                   {
                       AllowedUpdates = Array.Empty<UpdateType>()
                   },
                   cancellationToken: cts.Token);

            Console.ReadKey();
            cts.Cancel();
        }
        public static Task HandleErrorAsync(ITelegramBotClient botClient, Exception exception,
            CancellationToken cancellationToken)
        {
            var ErrorMessage = exception.ToString();

            Console.WriteLine(ErrorMessage);
            return Task.CompletedTask;
        }
        public static async Task HandleUpdateAsync(ITelegramBotClient botClient, Update update, CancellationToken cancellationToken)
        {
            try
            {
                Message message = update.Message;
           
                if (update.Type == UpdateType.Message)
                {
                    var userId = message.From.Id;
                    var name = message.From.FirstName;

                    Console.WriteLine($"Сообщение: {message.Text}\n Id: {userId}\n Имя: {name}");
                }
            }
            catch
            {

            }
        }
    }
}
