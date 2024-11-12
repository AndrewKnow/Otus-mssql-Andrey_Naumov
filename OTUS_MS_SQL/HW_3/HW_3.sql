
USE WideWorldImporters

/*
1. Посчитать среднюю цену товара, общую сумму продажи по месяцам.
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

Select
year(a.InvoiceDate) [Год продажи], 
month(a.InvoiceDate) [Месяц продажи],
avg(b.UnitPrice ) [Средняя цена за месяц по всем товарам],
sum(b.ExtendedPrice) [Общая сумма продаж за месяц]
From Sales.Invoices a 
Inner join Sales.InvoiceLines b on a.InvoiceID = b.InvoiceID
Group by year(a.InvoiceDate), month(a.InvoiceDate)
Order by 1, 2

/*
2. Отобразить все месяцы, где общая сумма продаж превысила 4 600 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

Select 
year(a.InvoiceDate) [Год продажи], 
month(a.InvoiceDate) [Месяц продажи],
sum(b.ExtendedPrice) [Общая сумма продаж за месяц]
From Sales.Invoices a 
Inner join Sales.InvoiceLines b on a.InvoiceID = b.InvoiceID
Group by year(a.InvoiceDate), month(a.InvoiceDate)
Having sum(b.ExtendedPrice) > 4600000
Order by 1, 2

/*
3. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

Select 
year(a.InvoiceDate) [Год продажи], 
month(a.InvoiceDate) [Месяц продажи],
b.Description [Наименование товара],
sum(b.ExtendedPrice) [Cумма продаж],
min(a.InvoiceDate) as [Дата первой продажи],
sum(b.Quantity) as [Количество проданного]
From Sales.Invoices a 
Inner join Sales.InvoiceLines b on a.InvoiceID=b.InvoiceID
Group by year(a.InvoiceDate), month(a.InvoiceDate), b.Description
Having sum(b.Quantity) < 50
Order by 1, 2, 3

