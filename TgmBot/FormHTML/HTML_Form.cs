using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TgmBot.FormHTML
{
    internal class HTML_Form
    {
        public static void OpenBrowserWithForm()
        {
            Process.Start("chrome.exe", "https://localhost:7219/home/form");
            // Замените [chrome.exe](chrome.exe) на нужный браузер и укажите правильный URL вашего веб-приложения
        }
    }
}
