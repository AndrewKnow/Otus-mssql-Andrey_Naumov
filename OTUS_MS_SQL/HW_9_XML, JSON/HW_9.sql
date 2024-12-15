/*
1. В личном кабинете есть файл StockItems.xml.
Это данные из таблицы Warehouse.StockItems.
Преобразовать эти данные в плоскую таблицу с полями, аналогичными Warehouse.StockItems.
Поля: StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice 

Загрузить эти данные в таблицу Warehouse.StockItems: 
существующие записи в таблице обновить, отсутствующие добавить (сопоставлять записи по полю StockItemName). 

Сделать два варианта: с помощью OPENXML и через XQuery.
*/

--Этот параметр используется для работы с CLOB (Character Large Object), то есть большими текстовыми данными. 
--Когда вы используете SINGLE_CLOB, запрос будет оптимизирован таким образом, чтобы весь CLOB был возвращен за одну операцию чтения. Это полезно, когда вам нужно получить все содержимое большого текста целиком.

--Параметр SINGLE_BLOB применяется к BLOB (Binary Large Object), то есть большим двоичным данным. 
--Он работает аналогично SINGLE_CLOB, но применительно к бинарным объектам. Этот параметр также позволяет вернуть весь BLOB за одно чтение.

--OPENXML
Declare @openXML xml;

		-- загрузка в переменную
		Set @openXML = (Select * From openrowset(bulk 'C:\StockItems-188-1fb5df.xml', single_clob) x);
		
		-- подготовка XML-документа к разборке
		Declare @handle int; -- уникальный идентификатор файла
		Exec sp_xml_preparedocument @handle output, @openXML;
		
		-- преобразование
		Select * From OPENXML(@handle, '/StockItems/Item')
		With (
			[StockItemName]		     nvarchar(100)		'@Name',
			[SupplierID]			 int				'SupplierID', 
		    [UnitPackageID]		     int				'Package/UnitPackageID',
		    [OuterPackageID]		 int				'Package/OuterPackageID',
		    [QuantityPerOuter]	     int				'Package/QuantityPerOuter',
		    [TypicalWeightPerUnit]   decimal(18, 3)     'Package/TypicalWeightPerUnit',
			[LeadTimeDays]		     int                'LeadTimeDays',
			[IsChillerStock]		 bit                'IsChillerStock',
			[TaxRate]				 decimal(18, 3)     'TaxRate',
			[UnitPrice]              decimal(18, 2)     'UnitPrice') 

--XQuery
Declare @xQuery xml
		Set @xQuery = (Select * From openrowset(bulk 'C:\StockItems-188-1fb5df.xml', single_clob) x)
		
		Select x.StockItems.value ('(@Name)[1]',                        'varchar(100)' ) [StockItemName]
			 , x.StockItems.value ('(SupplierID)[1]',                   'int'          ) [SupplierID]
			 , x.StockItems.value ('(Package/UnitPackageID)[1]',        'int'          ) [UnitPackageID]
			 , x.StockItems.value ('(Package/OuterPackageID)[1]',       'int'          ) [OuterPackageID]
			 , x.StockItems.value ('(Package/QuantityPerOuter)[1]',     'int'          ) [QuantityPerOuter]
			 , x.StockItems.value ('(Package/TypicalWeightPerUnit)[1]', 'decimal(18,3)') [TypicalWeightPerUnit]
			 , x.StockItems.value ('(LeadTimeDays)[1]',                 'int'          ) [LeadTimeDays]
			 , x.StockItems.value ('(IsChillerStock)[1]',               'bit'          ) [IsChillerStock]
			 , x.StockItems.value ('(TaxRate)[1]',                      'decimal(18,3)') [TaxRate]
			 , x.StockItems.value ('(UnitPrice)[1]',                    'decimal(18,2)') [UnitPrice]
		From @xQuery.nodes('/StockItems/Item') x(StockItems) 

-- временная таблица
Drop table if EXISTS #StockItems_copy;

Create table #StockItems_copy                                                         
		([StockItemName] [nvarchar](100) NOT NULL,
		 [SupplierID] [int] NOT NULL,
		 [UnitPackageID] [int] NOT NULL,
		 [OuterPackageID] [int] NOT NULL,
		 [QuantityPerOuter] [int] NOT NULL,
		 [TypicalWeightPerUnit] [decimal](18, 3) NOT NULL,
		 [LeadTimeDays] [int] NOT NULL,
		 [IsChillerStock] [bit] NOT NULL,
		 [TaxRate] [decimal](18, 3) NOT NULL,
		 [UnitPrice] [decimal](18, 2) NOT NULL)

-- копирование OPENXML
Insert Into #StockItems_copy
		Select * From OPENXML(@handle, '/StockItems/Item')
		With (
			[StockItemName]		     nvarchar(100)		'@Name',
			[SupplierID]			 int				'SupplierID', 
		    [UnitPackageID]		     int				'Package/UnitPackageID',
		    [OuterPackageID]		 int				'Package/OuterPackageID',
		    [QuantityPerOuter]	     int				'Package/QuantityPerOuter',
		    [TypicalWeightPerUnit]   decimal(18, 3)     'Package/TypicalWeightPerUnit',
			[LeadTimeDays]		     int                'LeadTimeDays',
			[IsChillerStock]		 bit                'IsChillerStock',
			[TaxRate]				 decimal(18, 3)     'TaxRate',
			[UnitPrice]              decimal(18, 2)     'UnitPrice') 

-- копирование XQuery
Insert Into #StockItems_copy
		Select x.StockItems.value ('(@Name)[1]',                        'varchar(100)' ) [StockItemName]
			 , x.StockItems.value ('(SupplierID)[1]',                   'int'          ) [SupplierID]
			 , x.StockItems.value ('(Package/UnitPackageID)[1]',        'int'          ) [UnitPackageID]
			 , x.StockItems.value ('(Package/OuterPackageID)[1]',       'int'          ) [OuterPackageID]
			 , x.StockItems.value ('(Package/QuantityPerOuter)[1]',     'int'          ) [QuantityPerOuter]
			 , x.StockItems.value ('(Package/TypicalWeightPerUnit)[1]', 'decimal(18,3)') [TypicalWeightPerUnit]
			 , x.StockItems.value ('(LeadTimeDays)[1]',                 'int'          ) [LeadTimeDays]
			 , x.StockItems.value ('(IsChillerStock)[1]',               'bit'          ) [IsChillerStock]
			 , x.StockItems.value ('(TaxRate)[1]',                      'decimal(18,3)') [TaxRate]
			 , x.StockItems.value ('(UnitPrice)[1]',                    'decimal(18,2)') [UnitPrice]
		From @xQuery.nodes('/StockItems/Item') x(StockItems) 


Exec sp_xml_removedocument @handle;


Drop table if EXISTS Warehouse.StockItems_copy;
Select * Into Warehouse.StockItems_copy From Warehouse.StockItems;
-- Select * From Warehouse.StockItems
-- Select * From Warehouse.StockItems_copy
-- Select * From #StockItems_copy


--Для проверки
----Select TaxRate From Warehouse.StockItems_copy  Where StockItemName = 'Dinosaur battery-powered slippers (Green) L'
----Select TaxRate From #StockItems_copy  Where StockItemName = 'Dinosaur battery-powered slippers (Green) L'

--Решение ошибки "Не удалось разрешить конфликт параметров сортировки между "Latin1_General_100_CI_AS" и "Cyrillic_General_CI_AS" в операции equal to." ...StockItemName COLLATE Latin1_General_100_CI_AS
Merge #StockItems_copy as target 
Using Warehouse.StockItems_copy as source
On source.StockItemName COLLATE Latin1_General_100_CI_AS = target.StockItemName COLLATE Latin1_General_100_CI_AS
When MATCHED Then
    Update SET 
	 target.SupplierID = source.SupplierID,
	 target.UnitPackageID = source.UnitPackageID,
	 target.OuterPackageID = source.OuterPackageID, 
	 target.QuantityPerOuter = source.QuantityPerOuter,
	 target.TypicalWeightPerUnit = source.TypicalWeightPerUnit,
	 target.LeadTimeDays = source.LeadTimeDays,
	 target.IsChillerStock = source.IsChillerStock,
	 target.TaxRate = source.TaxRate,
	 target.UnitPrice = source.UnitPrice
When NOT MATCHED by target Then
	Insert 
	(StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, 
	TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice)
	values 
	(source.StockItemName, source.SupplierID, source.UnitPackageID, source.OuterPackageID, source.QuantityPerOuter, 
	source.TypicalWeightPerUnit, source.LeadTimeDays, source.IsChillerStock, source.TaxRate, source.UnitPrice );

/*
2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
*/

Declare @xml xml;

Set @xml = (
    Select 
        StockItemName '@Name',
        SupplierID 'SupplierID',
		(Select 
		        UnitPackageID 'UnitPackageID',
		        OuterPackageID 'OuterPackageID',
		        QuantityPerOuter 'QuantityPerOuter',
		        TypicalWeightPerUnit 'TypicalWeightPerUnit'
		    For XML path(''), type
		) 'Package',
		LeadTimeDays 'LeadTimeDays',
		IsChillerStock 'IsChillerStock',
		TaxRate 'TaxRate',
		UnitPrice 'UnitPrice'
    From Warehouse.StockItems
    For XML path('StockItem'), root('StockItems')
);
Select @xml

