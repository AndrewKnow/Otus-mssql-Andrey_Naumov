
USE WideWorldImporters

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

Select StockItemID, StockItemName From Warehouse.StockItems 
Where StockItemName like '%urgent%' or StockItemName like 'Animal%';

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

Select a.SupplierID, a.SupplierName From Purchasing.Suppliers a
Left join Purchasing.PurchaseOrders b on a.SupplierID = b.SupplierID Where b.SupplierID is null

/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/


Select 
a.OrderID, 
format(a.OrderDate, 'dd.MM.yyyy') [дата заказа], 
datename(month, a.OrderDate) [название месяца], 
datepart(quarter, a.OrderDate) [номер квартала],
Case 
	When month(a.OrderDate) <= 4  Then 1 
	When month(a.OrderDate) >= 9 Then 3
	Else 2 
End [треть года], 
c.CustomerName [имя заказчика] 
From (Sales.Orders a 
Left join Sales.OrderLines b on a.OrderID = b.OrderID) 
Left join Sales.Customers c on a.CustomerID = c.CustomerID
Where (b.UnitPrice >= 100 or b.Quantity >= 20) and b.PickingCompletedWhen is not null 
Order by
	 [номер квартала] 
	,[треть года] 
	,a.OrderDate
OffSet 1000 Rows
Fetch Next 100 rows ONLY


/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

Select c.DeliveryMethodName, b.ExpectedDeliveryDate, a.SupplierName, d.FullName
From Purchasing.Suppliers a
Left join Purchasing.PurchaseOrders b on a.SupplierID = b.SupplierID
Left join Application.DeliveryMethods c on c.DeliveryMethodID = b.DeliveryMethodID
Left join Application.People d on d.PersonID = b.ContactPersonID
Where 
format(b.ExpectedDeliveryDate, 'MM.yyyy') = '01.2013' 
and (c.DeliveryMethodName = 'Air Freight' or c.DeliveryMethodName = 'Refrigerated Air Freight')
and b.IsOrderFinalized  = 1


/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

Select Top 10 a.*, b.CustomerName [клиент], c.FullName [сотрудник]
From Sales.Orders a
Left join Sales.Customers b on a.CustomerID = b.CustomerID
Left join Application.People c on a.SalespersonPersonID = c.PersonID
Order by  a.OrderDate desc, a.OrderID desc


/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

Select distinct d.CustomerID, d.CustomerName, d.PhoneNumber
From Warehouse.StockItems a
Left join Sales.OrderLines b on a.StockItemID = b.StockItemID
Left join Sales.Orders c on b.OrderID = c.OrderID
Left join Sales.Customers d ON d.CustomerID = c.CustomerID
Where a.StockItemName = 'Chocolate frogs 250g'
Order by d.CustomerID
