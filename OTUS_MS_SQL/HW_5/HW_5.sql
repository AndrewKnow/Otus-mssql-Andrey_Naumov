﻿
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

;With DataCTE as
(Select a.InvoiceID, с.CustomerName, a.InvoiceDate, sum(b.ExtendedPrice) [сумма продажи]
	From Sales.Invoices a 
	Join Sales.InvoiceLines b ON a.InvoiceID = b.InvoiceID
	Join Sales.Customers с ON a.CustomerID = с.CustomerID
	Where a.InvoiceDate >= '2015-01-01'  
	Group by a.InvoiceID, с.CustomerName, a.InvoiceDate)

Select 
DataCTE.InvoiceID [id продажи],
DataCTE.CustomerName [название клиента],
DataCTE.InvoiceDate [дата продажи],  
DataCTE.[сумма продажи],
(Select sum([сумма продажи]) FROM DataCTE cte2 WHERE month(DataCTE.InvoiceDate) = month(cte2.InvoiceDate) and year(DataCTE.InvoiceDate) = year(cte2.InvoiceDate)) [сумма нарастающим итогом]  
From DataCTE
Order by DataCTE.InvoiceDate;

/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/

;With DataCTE as
(Select a.InvoiceID, с.CustomerName, a.InvoiceDate, sum(b.ExtendedPrice) [сумма продажи]
	From Sales.Invoices a 
	Join Sales.InvoiceLines b ON a.InvoiceID = b.InvoiceID
	Join Sales.Customers с ON a.CustomerID = с.CustomerID
	Where a.InvoiceDate >= '2015-01-01'  
	Group by a.InvoiceID, с.CustomerName, a.InvoiceDate)
Select 
DataCTE.InvoiceID [id продажи],
DataCTE.CustomerName [название клиента],
DataCTE.InvoiceDate [дата продажи],  
DataCTE.[сумма продажи],
sum(DataCTE.[сумма продажи]) over (Order by year(DataCTE.InvoiceDate), month(DataCTE.InvoiceDate)) [сумма нарастающим итогом] 
From DataCTE
Order by DataCTE.InvoiceDate;

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