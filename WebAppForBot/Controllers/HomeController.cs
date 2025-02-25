using Microsoft.AspNetCore.Mvc;
using System.Diagnostics;
using WebAppForBot.Models;

namespace WebAppForBot.Controllers
{
    public class HomeController : Controller
    {
        private readonly ILogger<HomeController> _logger;

        public HomeController(ILogger<HomeController> logger)
        {
            _logger = logger;
        }

        public IActionResult Index()
        {
            return View();
        }

        public IActionResult Privacy()
        {
            return View();
        }

        [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
        public IActionResult Error()
        {
            return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
        }

        public IActionResult Form()
        {
            return View();
        }


        [HttpPost]
        public IActionResult Submit(FormModel model)
        {
            if (ModelState.IsValid)
            {
                // —охран€йте данные в базу данных или выполн€йте другие действи€
                return RedirectToAction(nameof(Submitted));
            }
            else
            {
                return RedirectToAction(nameof(Submitted));
            }
            //return View(model);
        }

        public IActionResult Submitted()
        {
            return Content("—пасибо за отправленные данные!");
        }

    }
}
