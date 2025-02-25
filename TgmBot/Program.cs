
using Telegram.Bot;
using Telegram.Bot.Extensions;
using Telegram.Bot.Polling;
using Telegram.Bot.Types;
using Telegram.Bot.Types.Enums;
using Telegram.Bot.Types.ReplyMarkups;

using TgmBot.ConnectionProperties;
using TgmBot.Data;

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

                if (update.Message != null)
                {
                    Message message = update.Message;

                    if (Product.InsertProduct)
                    {



              
                        Task<bool> checkData = DataValidation.GetValidationProduct(message.Text);
                        bool result = await checkData; // Асинхронное ожидание

                        if (result)
                        {
                            await botClient.SendMessage(chatId: message.Chat.Id, text: "🤖 Завёл продукт");
                        }
                        else
                        {
                            await botClient.SendMessage(chatId: message.Chat.Id, text: "🤖 Несоответствие шаблону для ввода");
                        }
                        Product.InsertProduct = false;
                    }

                    if (Accessories.InsertAccessories)
                    {

                        Task<bool> checkData = DataValidation.GetValidationAccessories(message.Text);
                        bool result = await checkData; // Асинхронное ожидание

                        if (result)
                        {
                            await botClient.SendMessage(chatId: message.Chat.Id, text: "🤖 Завёл аксессуар");
                        }
                        else
                        {
                            await botClient.SendMessage(chatId: message.Chat.Id, text: "🤖 Несоответствие шаблону для ввода");
                        }
                        Accessories.InsertAccessories = false;
                    }

                    if (update.Type == UpdateType.Message)
                    {
                        var userId = message.From.Id;
                        var name = message.From.FirstName;

                        Console.WriteLine($"Сообщение: {message.Text}"); // \n Id: {userId}\n Имя: {name}");
                        switch (message.Text)
                        {
                            case "/menu":
                                await RemoveReplyKeboard(botClient, message);
                                await SendReplyKeboard(botClient, message, 1);
                            break;

                            case "Создать запись в товарах":

                                await botClient.SendMessage(chatId: message.Chat.Id, text: "🤖 Введите через запятую [ProductName], [CategoryId], [Price], [Description]");
                                Product.InsertProduct = true;

                            break;

                            case "Создать запись в аксессуарах":

                                await botClient.SendMessage(chatId: message.Chat.Id, text: "🤖 Введите через запятую [ProductId], [AccessoryNameName], [CategoryId], [Price], [Description]");
                                Accessories.InsertAccessories = true;

                            break;
                        }
                    }

                    // Обработка кнопок
                    if (update.Type == UpdateType.CallbackQuery)
                    {
                        Console.WriteLine($"Обработка кнопки"); // InlineKeyboardButton не создавал
                    }
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
                            "Вывести TOP 10 аксессуаров",
                            "Вывести TOP 10 авто"
                        ],
                        [
                            "Внести количество товара по Id",
                            "Внести количество аксессуаров по Id"
                        ]
                    })
                    {
                        ResizeKeyboard = true, // Автоматически адаптировать размер клавиатуры
                        // OneTimeKeyboard = true // Скрыть клавиатуру после первого использования
                    };

                    replyKeyboardMarkup = replyKeyboard;

                break;               
            }

            return await botClient.SendMessage(chatId: message.Chat.Id, text: "🤖 Выберите комманду", replyMarkup: replyKeyboardMarkup);
        }

    }
}
