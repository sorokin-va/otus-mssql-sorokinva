USE WideWorldImporters
go

-- ������ ��� ��������������� ��������� �������� Warehouse.ColdRoomTemperatures_Archive, �.�. ��� ����� ������� ���������� ������� (������� ����� �� �� ��� ��� �������� �������))) 
select count(*) from Warehouse.ColdRoomTemperatures_Archive
-- ���� ��� ��������������� ������� ColdroomSensornumber, ��������, ������ ��� ������ �� 4-�� �������� ����� � ������ ���������� � ������ ��������� ��� ������ ���� �������������.
select distinct ColdroomSensornumber from Warehouse.ColdRoomTemperatures_Archive


--�������� �������� ������
ALTER DATABASE [WideWorldImporters] ADD FILEGROUP [SensorNumber]
GO

--��������� ���� �� 

-- ��������!!!!     ����������� �������� ���� � ������������ �����!

ALTER DATABASE [WideWorldImporters] ADD FILE 
( NAME = N'SNumber', FILENAME = N'C:\storage\otus-mssql-sorokinva\HW18\SNumber.ndf' , 
SIZE = 109715KB , FILEGROWTH = 6553KB ) TO FILEGROUP [SensorNumber]
GO


--��� ��� ���� � ���� �� �������� � ����� � ����� ������� ���������������� � ������� ��������� � ���� �� ����������� ��������� ������� � �����, ������� �� ����������� � ������ ����� ����� � �������
--������� ������� ����������������� �� ������� �������� (1,2,3,4)
CREATE PARTITION FUNCTION [fnSensorNumber](int) AS RANGE RIGHT FOR VALUES
(1,2,3,4);																																																									
GO


-- ��������������, ��������� ��������� ���� �������
CREATE PARTITION SCHEME [schmSensorNumber] AS PARTITION [fnSensorNumber] 
ALL TO ([SensorNumber])
GO

--������� ������ � �������
SELECT * INTO Warehouse.ColdRoomTemperatures_Section
FROM Warehouse.ColdRoomTemperatures_Archive;

--�������� 1
--SELECT top 100 * from Warehouse.ColdRoomTemperatures_Section

--��������� ������ ��������� � ��� ��� �� �� ����� � ���� ��������� fnSensorNumber � schmSensorNumber, ������� �� ����� � ���: fnSensorNumber_new � schmSensorNumber_new, ��������������

--�������� 2
--��� ������� ���� � ������ ����������������
select distinct t.name
from sys.partitions p
inner join sys.tables t
	on p.object_id = t.object_id
where p.partition_number <> 1
and t.name = 'ColdRoomTemperatures_Section'

--�������� 3
--������� ��� ��������� �� ���������� ����� ������
SELECT  $PARTITION.fnSensorNumber_new(ColdRoomSensorNumber) AS Partition
		, COUNT(*) AS [COUNT]
		, MIN(ColdRoomSensorNumber)
		,MAX(ColdRoomSensorNumber) 
FROM Warehouse.ColdRoomTemperatures_Section
GROUP BY $PARTITION.fnSensorNumber_new(ColdRoomSensorNumber) 
ORDER BY Partition ;  


--������ ������� � ������� �������������� ����� � �������:
drop partition scheme schmSensorNumber
--���������
select * from sys.partition_schemes;

drop partition function fnSensorNumber
--���������
select * from sys.partition_functions;

