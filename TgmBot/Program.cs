
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
                // Обработка сообщений
                Message message = update.Message;

                if (update.Type == UpdateType.Message)
                {
                    var userId = message.From.Id;
                    var name = message.From.FirstName;

                    Console.WriteLine($"Сообщение: {message.Text}"); // \n Id: {userId}\n Имя: {name}");

                    if (message.Text == "/menu")
                    {
                        await RemoveReplyKeboard(botClient, message);
                        await SendReplyKeboard(botClient, message, 1);
                    }
                }

                // Обработка кнопок
                if (update.Type == UpdateType.CallbackQuery)
                {

                }
            }
            catch
            {

            }
        }

        static async Task<Message> RemoveReplyKeboard(ITelegramBotClient botClient, Message message)
        {
            return await botClient.SendMessage(chatId: message.Chat.Id, text: "🤖 Запускаю меню управления базой данных склада ..."
                         , replyMarkup: new ReplyKeyboardRemove());
        }

        static async Task<Message> SendReplyKeboard(ITelegramBotClient botClient, Message message, int type)
        {
            ReplyKeyboardMarkup? replyKeyboardMarkup = null;
            switch (type)
            {
                case 1:
                    // Создаем клавиатуру с двумя кнопками
                    var replyKeyboard = new ReplyKeyboardMarkup(new[]
                    {
                        new KeyboardButton[] { 
                            "Создать запись в товарах",
                            "Создать запись в аксессуарах"
                        },
                        [
                            "Вывести TOP 10 товаров",
                            "Вывести TOP 10 аксессуаров"
                        ],
                        [
                            "Найти товар по названию",
                            "Найти аксессуар по названию"
                        ],
                        [
                            "Изменить товар",
                            "Изменить аксессуар"
                        ]
                    })
                    {
                        ResizeKeyboard = true, // Автоматически адаптировать размер клавиатуры
                        // OneTimeKeyboard = true // Скрыть клавиатуру после первого использования
                    };


                    replyKeyboardMarkup = replyKeyboard;

                break;
                
            }

            return await botClient.SendMessage(chatId: message.Chat.Id,
                text: "🤖 Выберите комманду", replyMarkup: replyKeyboardMarkup);
        }

    }
}
