USE WideWorldImporters

/*
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/


;With cteCustomerInvoices as
(Select 
	count(a.InvoiceID) [Кол-во], 
	substring(с.CustomerName, charindex('(', с.CustomerName) + 1, charindex(')', с.CustomerName) - charindex('(', с.CustomerName) - 1) [Название], 
	convert(VARCHAR(10), a.InvoiceDate, 104) [Дата]
From Sales.Invoices a Join Sales.Customers с ON a.CustomerID = с.CustomerID
Where a.CustomerID between 2 and 6
Group by 
	substring(с.CustomerName, charindex('(', с.CustomerName) + 1, charindex(')', с.CustomerName) - charindex('(', с.CustomerName) - 1), 
	convert(VARCHAR(10), a.InvoiceDate, 104))

Select *
From cteCustomerInvoices
Pivot
(
    sum([Кол-во])
    for [Название] IN ([Sylvanite, MT],	[Peeples Valley, AZ], [Medicine Lodge, KS],	[Gasport, NY], [Jessie, ND])
) pivotTbl
Order by Convert(DATE,[Дата])


--Для проверки
/*
Select a.CustomerID, count(a.InvoiceID) [Кол-во]
From Sales.Invoices a  Join Sales.Customers с ON a.CustomerID = с.CustomerID
Where a.CustomerID between 2 and 6
group by a.CustomerID

;With cteCustomerInvoices as
(Select 
	count(a.InvoiceID) [Кол-во], 
	substring(с.CustomerName, charindex('(', с.CustomerName) + 1, charindex(')', с.CustomerName) - charindex('(', с.CustomerName) - 1) [Название]
From Sales.Invoices a Join Sales.Customers с ON a.CustomerID = с.CustomerID
Where a.CustomerID between 2 and 6
Group by 
	substring(с.CustomerName, charindex('(', с.CustomerName) + 1, charindex(')', с.CustomerName) - charindex('(', с.CustomerName) - 1), 
	convert(VARCHAR(10), a.InvoiceDate, 104))

Select *
From cteCustomerInvoices
Pivot
(
	sum([Кол-во])
	for [Название] IN ([Sylvanite, MT],	[Peeples Valley, AZ], [Medicine Lodge, KS],	[Gasport, NY], [Jessie, ND])
) pivotTbl
*/