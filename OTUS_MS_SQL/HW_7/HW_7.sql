USE WideWorldImporters

/*

Это задание из занятия "Операторы CROSS APPLY, PIVOT, UNPIVOT."
Нужно для него написать динамический PIVOT, отображающий результаты по всем клиентам.
Имя клиента указывать полностью из поля CustomerName.

Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+----------------+----------------------
InvoiceMonth | Aakriti Byrraju    | Abel Spirlea       | Abel Tatarescu | ... (другие клиенты)
-------------+--------------------+--------------------+----------------+----------------------
01.01.2013   |      3             |        1           |      4         | ...
01.02.2013   |      7             |        3           |      4         | ...
-------------+--------------------+--------------------+----------------+----------------------
*/

use WideWorldImporters

Declare @cNames nvarchar(max), @sql nvarchar(max);

-- уникальные значения CustomerName
Select @cNames =isnull(@cNames+ ',','') + QUOTENAME(names)
From (Select distinct c.CustomerName names
      From Sales.Customers c) as names;

--Select @cNames as cNames

-- динамический SQL с PIVOT
Set @sql = N'
;With cteCustomerInvoices as
(Select 
	count(a.InvoiceID) count, 
	c.CustomerName, 
	convert(varchar(10), dateadd(month, datediff(MONTH, 0, a.InvoiceDate), 0), 104) xdate
From Sales.Invoices a Join Sales.Customers c ON a.CustomerID = c.CustomerID
Group by c.CustomerName, convert(varchar(10), dateadd(month, datediff(MONTH, 0, a.InvoiceDate), 0), 104))

Select *
From cteCustomerInvoices
Pivot
(
    sum(count)
    For CustomerName in (' + @cNames + ')
) pivotTbl
Order by  convert(date, xdate, 104) ';

-- выполняем динамический SQL
Exec sp_executesql @sql;


