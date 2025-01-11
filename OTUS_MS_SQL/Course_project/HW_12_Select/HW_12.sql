
--Описание/Пошаговая инструкция выполнения домашнего задания:
--Думаем какие запросы у вас будут в базе и добавляем для них индексы. Проверяем, что они используются в запросе.


-- поиск категории
CREATE NONCLUSTERED INDEX IX_Categories_Name ON Categories (CategoryName); 

-- поиск авто
CREATE NONCLUSTERED INDEX IX_Cars_Brand_Model ON Cars (Brand, Model);

-- поиск товаров
CREATE NONCLUSTERED INDEX IX_Products_CategoryId ON Products (CategoryId) INCLUDE (ProductName, Description); 

-- поиск товара совместимого с авто
CREATE NONCLUSTERED INDEX IX_CarCompatibility_CarModelId ON CarCompatibility (CarModelId);

-- поиск аксесуаров
CREATE NONCLUSTERED INDEX IX_Accessories_ProductId ON Accessories (ProductId) INCLUDE (AccessoryName, Description);

-- остатки по товару
CREATE NONCLUSTERED INDEX IX_ProductsStock_ProductId ON ProductsStockQuantity (ProductId);

-- остатки аксессуаров
CREATE NONCLUSTERED INDEX IX_AccessoriesStock_AccessoriesId ON AccessoriesStockQuantity (AccessoriesId);


---------------------------------------------------------------
-- Вероятные запросы к БД (преверка использованием индексов):--
---------------------------------------------------------------


-- поиск всех аксессуаров дла товара, отобранного по авто
Select A.AccessoriesId, A.AccessoryName, A.Price, A.Description
From Accessories A
Join Products P on A.ProductId = P.ProductId
Join CarCompatibility CC on P.ProductId = CC.ProductId
Join Cars C on CC.CarModelId = C.CarModelId
Where P.ProductId = 1 and C.CarModelId = 1; 

-- поиск товаров по авто и наименованию
Select P.ProductId, P.ProductName, P.Price, P.Description
From Products P
Join CarCompatibility CC on P.ProductId = CC.ProductId
Join Cars C on CC.CarModelId = C.CarModelId
Where P.ProductName like '%тент%' and C.Brand = 'лада'  and C.Model = 'гранта';

-- + аксессуары
Select 
    P.ProductId, 
    P.ProductName, 
    P.Price, 
    P.Description ProductDescription,
    A.AccessoriesId, 
    A.AccessoryName, 
    A.Price , 
    A.Description AccessoryDescription
From Products P
Join CarCompatibility CC on P.ProductId = CC.ProductId
Join Cars C on CC.CarModelId = C.CarModelId
Left join Accessories A on P.ProductId = A.ProductId  
Where P.ProductName LIKE '%тент%' and C.Brand = 'лада' and C.Model = 'гранта'; 


-- поиск аксессуаров для товара, в наименовании которого есть "тент" для авто
Select 
    P.ProductId, 
    P.ProductName, 
    P.Price ProductPrice, 
    P.Description ProductDescription,
    A.AccessoriesId, 
    A.AccessoryName, 
    A.Price AccessoryPrice, 
    A.Description AccessoryDescription
From Products P
Cross apply (
    Select 
        A.AccessoriesId, 
        A.AccessoryName, 
        A.Price, 
        A.Description
    From Accessories A
    Where A.ProductId = P.ProductId  
) A
Join CarCompatibility CC ON P.ProductId = CC.ProductId 
Join Cars C ON CC.CarModelId = C.CarModelId 
Where P.ProductName like '%тент%' 
and C.Brand = 'лада'  and C.Model = 'гранта'; 


-- поиск количества остатков товаров на определенные даты

Declare @ColumnsDateList nvarchar(max), @sql nvarchar(max);

-- Уникальные даты для столбцов
Select @ColumnsDateList = STRING_AGG(QUOTENAME(convert(varchar(10), LastUpdated, 120)), ', ')
From (Select distinct convert(varchar(10), LastUpdated, 120) AS LastUpdated
      From ProductsStockQuantity) AS DateList;

Set @SQL = '
Select ProductName, QuantitySource, ' + @ColumnsDateList + '
From 
(
    Select 
        P.ProductName,
        PSQ.QuantitySource,
        convert(varchar(10), PSQ.LastUpdated, 120) AS StockDate,  -- конвертируем дату для использования в pivot
        PSQ.Quantity
    From ProductsStockQuantity PSQ
    Join Products P ON PSQ.ProductId = P.ProductId
) AS SourceTable
pivot 
(
    sum(Quantity)  -- подсчета остатков на определенную дату @ColumnsDateList
    For StockDate in (' + @ColumnsDateList + ')  
) AS PivotTable
Order by ProductName, QuantitySource;
';

exec sp_executesql @SQL;


