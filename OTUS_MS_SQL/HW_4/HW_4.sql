USE WideWorldImporters

--Для всех заданий, где возможно, сделайте два варианта запросов:
--через вложенный запрос
--через WITH (для производных таблиц)

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

Select PersonID, FullName
From Application.People
Where PersonID not in (Select SalespersonPersonID From Sales.Invoices Where InvoiceDate = '2015-07-04') 
and IsSalesperson = 1;

;With cte (SalespersonPersonID) as (Select SalespersonPersonID From Sales.Invoices Where InvoiceDate = '2015-07-04')
Select PersonID, FullName
From Application.People a Left join cte b on a.PersonID = b.SalespersonPersonID
Where a.IsSalesperson = 1 and b.SalespersonPersonID is null;

/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/

Select StockItemID, StockItemName, UnitPrice 
From Warehouse.StockItems
Where UnitPrice = ANY (Select min(UnitPrice) From Warehouse.StockItems);

Select StockItemID, StockItemName, UnitPrice 
From Warehouse.StockItems
Where UnitPrice in (Select min(UnitPrice) From Warehouse.StockItems);

Select StockItemID, StockItemName, UnitPrice 
From Warehouse.StockItems
Where UnitPrice <= ALL (Select UnitPrice From Warehouse.StockItems);

;With cte (UnitPriceCte) as (Select min(UnitPrice) From Warehouse.StockItems)
Select StockItemID, StockItemName, UnitPrice 
From Warehouse.StockItems a Join cte b on a.UnitPrice = b.UnitPriceCte

/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/

--Select Top 5 a.CustomerID ,a.CustomerName, max(b.TransactionAmount)
--From Sales.Customers a
--Left join Sales.CustomerTransactions b on a.CustomerID = b.CustomerID
--Group by a.CustomerID,a.CustomerName
--Order by max(b.TransactionAmount) desc

Select CustomerID ,CustomerName 
From Sales.Customers 
Where CustomerID in 
(Select Top 5 CustomerID From Sales.CustomerTransactions 
Group by CustomerID
Order by max(TransactionAmount) desc)

Select CustomerID ,CustomerName
From Sales.Customers 
Where CustomerID = ANY 
(Select Top 5 CustomerID
From Sales.CustomerTransactions
Group by CustomerID 
Order by max(TransactionAmount) desc) ;

;With cte (CustomerIDcte) as 
(Select Top 5 CustomerID
From Sales.CustomerTransactions Group by CustomerID Order by max(TransactionAmount) desc)
Select CustomerID ,CustomerName
From Sales.Customers a Join cte b on a.CustomerID = b.CustomerIDcte
Group by CustomerID,CustomerName


/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/

Select Top 1 * From Application.Cities
Select Top 1 * From Application.People
Select Top 1 * From Warehouse.StockItems
Select Top 1 * from Sales.Invoices



Select Top 3 StockItemID, StockItemName, SupplierID, UnitPrice From Warehouse.StockItems  Order by UnitPrice desc;

