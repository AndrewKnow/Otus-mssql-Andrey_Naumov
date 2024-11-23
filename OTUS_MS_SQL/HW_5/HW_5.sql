
USE WideWorldImporters
/*
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/

set statistics time ON;
set statistics io ON;

;With cteExtendedPrice as
(Select a.InvoiceID, с.CustomerName, a.InvoiceDate, sum(b.ExtendedPrice) [сумма продажи]
From Sales.Invoices a 
Join Sales.InvoiceLines b ON a.InvoiceID = b.InvoiceID
Join Sales.Customers с ON a.CustomerID = с.CustomerID
Where a.InvoiceDate >= '2015-01-01'  
Group by a.InvoiceID, с.CustomerName, a.InvoiceDate)

Select 
cteExtendedPrice.InvoiceID [id продажи],
cteExtendedPrice.CustomerName [название клиента],
cteExtendedPrice.InvoiceDate [дата продажи],  
cteExtendedPrice.[сумма продажи],
(Select sum([сумма продажи]) FROM cteExtendedPrice cte2 
Where month(cteExtendedPrice.InvoiceDate) = month(cte2.InvoiceDate) and year(cteExtendedPrice.InvoiceDate) = year(cte2.InvoiceDate)) [сумма нарастающим итогом]  
From cteExtendedPrice
Order by cteExtendedPrice.InvoiceDate;

/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/

;With cteExtendedPrice as
(Select a.InvoiceID, с.CustomerName, a.InvoiceDate, sum(b.ExtendedPrice) [сумма продажи]
From Sales.Invoices a 
Join Sales.InvoiceLines b ON a.InvoiceID = b.InvoiceID
Join Sales.Customers с ON a.CustomerID = с.CustomerID
Where a.InvoiceDate >= '2015-01-01'  
Group by a.InvoiceID, с.CustomerName, a.InvoiceDate)
Select 
cteExtendedPrice.InvoiceID [id продажи],
cteExtendedPrice.CustomerName [название клиента],
cteExtendedPrice.InvoiceDate [дата продажи],  
cteExtendedPrice.[сумма продажи],
sum(cteExtendedPrice.[сумма продажи]) over (Order by year(cteExtendedPrice.InvoiceDate), month(cteExtendedPrice.InvoiceDate)) [сумма нарастающим итогом] 
From cteExtendedPrice
Order by cteExtendedPrice.InvoiceDate;

set statistics time OFF;
set statistics io OFF;

-- Без оконной функции
--> Время ЦП = 50156 мс, затраченное время = 85910 мс.

-- С оконной функции
--> Время ЦП = 94 мс, затраченное время = 281 мс.

/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/
;With cteQuantity as (
Select year(b.InvoiceDate) год, month(b.InvoiceDate) месяц, a.Description, sum(a.Quantity) количество,
row_number() over (partition by year(b.InvoiceDate), month(b.InvoiceDate) Order by sum(a.Quantity) desc) as популярность
From Sales.InvoiceLines a Inner join Sales.Invoices b ON a.InvoiceID = b.InvoiceID
Where b.InvoiceDate >= '2016-01-01' 
Group by year(b.InvoiceDate), month(b.InvoiceDate), a.Description)

Select * From cteQuantity a
Where a.популярность <= 2
Order by a.год, a.месяц

/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/

Select 
StockItemID,
StockItemName, 
row_number() over (partition by left(StockItemName, 1) Order by StockItemName) [Нумерация по первой букве],
count(*) over () [Общее кол-во],
count(*) over (partition by left(StockItemName, 1)) [Общее кол-во товаров в зависимости],
lead(StockItemID) over (Order by StockItemName) [Cледующий id],
lag(StockItemID) over (Order by StockItemName) [предыдущий id],
lag(StockItemName, 2, 'No items') over (Order by StockItemName) [Названия товара 2 строки назад],
ntile(30) over (Order by TypicalWeightPerUnit) [Группа товаров по полю вес]
From [Warehouse].[StockItems];

/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/

;With cteSales as (
Select 
a.SalespersonPersonID,
b.FullName,
c.CustomerID,
c.CustomerName,
a.InvoiceDate,
sum(d.ExtendedPrice) [сумма сделки],
row_number() over (partition by a.SalespersonPersonID Order by a.InvoiceDate desc) [нумерация сделок]
From Sales.Invoices a
Join Application.People b on b.PersonID = a.SalespersonPersonID
Join Sales.Customers c on c.CustomerID = a.CustomerID 
Join Sales.InvoiceLines d on d.InvoiceID = a.InvoiceID 
Group by a.SalespersonPersonID, b.FullName, c.CustomerID, c.CustomerName, a.InvoiceDate)

Select 
cteSales.*
From cteSales 
Where [нумерация сделок] = 1 
Order by cteSales.SalespersonPersonID;

/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

;With cteCustomers as (
Select distinct
b.CustomerID,
b.CustomerName,
c.StockItemID,
c.UnitPrice,
--a.InvoiceDate,
max(a.InvoiceDate) OVER (partition by b.CustomerID, c.StockItemID) AS [дата],
dense_rank() over (partition by b.CustomerID Order by c.UnitPrice desc) [нумерация товаров]
From Sales.Invoices a
Join Sales.Customers b on b.CustomerID = a.CustomerID 
Join Sales.InvoiceLines c on c.InvoiceID = a.InvoiceID )

Select * From cteCustomers
Where cteCustomers.[нумерация товаров] <= 2 
Order by cteCustomers.CustomerID, cteCustomers.[нумерация товаров]

