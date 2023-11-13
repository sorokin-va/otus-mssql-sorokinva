USE WideWorldImporters
go

-- Выбрал для секционирования идеальную табличку Warehouse.ColdRoomTemperatures_Archive, т.к. тут самое большое количество записей (закроем глаза на то что это архивная таблица))) 
select count(*) from Warehouse.ColdRoomTemperatures_Archive
-- Поле для секционирования выбираю ColdroomSensornumber, например, потому как каждый из 4-ёх сенсоров стоит в разных помещениях и данные интересны для разных груп пользователей.
select distinct ColdroomSensornumber from Warehouse.ColdRoomTemperatures_Archive


--создадим файловую группу
ALTER DATABASE [WideWorldImporters] ADD FILEGROUP [SensorNumber]
GO

--добавляем файл БД 

-- ВНИМАНИЕ!!!!     Обязательно изменить путь к создаваемому файлу!

ALTER DATABASE [WideWorldImporters] ADD FILE 
( NAME = N'SNumber', FILENAME = N'C:\storage\otus-mssql-sorokinva\HW18\SNumber.ndf' , 
SIZE = 109715KB , FILEGROWTH = 6553KB ) TO FILEGROUP [SensorNumber]
GO


--Вот эти шаги у меня не взлетели и когда я делал таблицу секционированной в мастере настройки у меня не подтянулись созданные функция и схема, поэтому их закомментил и создал новые прямо в мастере
--создаем функцию партиционирования по номерам сенсоров (1,2,3,4)
CREATE PARTITION FUNCTION [fnSensorNumber](int) AS RANGE RIGHT FOR VALUES
(1,2,3,4);																																																									
GO


-- партиционируем, используя созданную нами функцию
CREATE PARTITION SCHEME [schmSensorNumber] AS PARTITION [fnSensorNumber] 
ALL TO ([SensorNumber])
GO

--закинул данные в таблицу
SELECT * INTO Warehouse.ColdRoomTemperatures_Section
FROM Warehouse.ColdRoomTemperatures_Archive;

--проверил 1
--SELECT top 100 * from Warehouse.ColdRoomTemperatures_Section

--Запускаем Мастер настройки и так как он не видит в упор созданные fnSensorNumber и schmSensorNumber, создаем их прямо в нем: fnSensorNumber_new и schmSensorNumber_new, соответственно

--проверил 2
--что таблица есть в списке секционированных
select distinct t.name
from sys.partitions p
inner join sys.tables t
	on p.object_id = t.object_id
where p.partition_number <> 1
and t.name = 'ColdRoomTemperatures_Section'

--проверил 3
--смотрим как конкретно по диапазонам легли данные
SELECT  $PARTITION.fnSensorNumber_new(ColdRoomSensorNumber) AS Partition
		, COUNT(*) AS [COUNT]
		, MIN(ColdRoomSensorNumber)
		,MAX(ColdRoomSensorNumber) 
FROM Warehouse.ColdRoomTemperatures_Section
GROUP BY $PARTITION.fnSensorNumber_new(ColdRoomSensorNumber) 
ORDER BY Partition ;  


--Наводи красоту и удаляем неиспользуемые схему и функцию:
drop partition scheme schmSensorNumber
--Проверяем
select * from sys.partition_schemes;

drop partition function fnSensorNumber
--Проверяем
select * from sys.partition_functions;

