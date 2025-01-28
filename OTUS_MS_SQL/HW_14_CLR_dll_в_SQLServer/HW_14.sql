
-- Разрешаем выполнение CLR-кода
-- Настройка CLR
exec sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO

exec sp_configure 'clr enabled', 1;
exec sp_configure 'clr strict security', 0;
RECONFIGURE;
GO

ALTER DATABASE WarehouseForAutoTourism SET TRUSTWORTHY ON;

-- Подключение dll
DROP PROCEDURE IF EXISTS GetProductDetailsForCars
DROP ASSEMBLY IF EXISTS ClrWarehouseForAutoTourismAssembly


CREATE ASSEMBLY ClrWarehouseForAutoTourismAssembly
FROM 'C:\Users\naumo\OneDrive\Рабочий стол\SQL devoloper\OTUS_MS_SQL\WarehouseForAutoTourismCLR\bin\Release\WarehouseForAutoTourismCLR.dll'
WITH PERMISSION_SET = UNSAFE;--UNSAFE;
GO

CREATE PROCEDURE GetProductDetailsForCars
	@Brand nvarchar(255),
	@Model nvarchar(255),
	@ProductName nvarchar(255)
	AS EXTERNAL NAME ClrWarehouseForAutoTourismAssembly.[CLR.WarehouseForAutoTourism].GetProductDetailsForCars;
GO


EXEC GetProductDetailsForCars @Brand = 'LADA', @Model = 'GRANTA', @ProductName = 'тент';




