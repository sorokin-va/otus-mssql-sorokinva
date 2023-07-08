/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "07 - Динамический SQL".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

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



--1. Требуется написать запрос, который в результате своего выполнения 
--формирует сводку по количеству покупок в разрезе клиентов и месяцев.
--В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

--Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
--Имя клиента нужно поменять так чтобы осталось только уточнение.
--Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
--Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

--Пример, как должны выглядеть результаты:
---------------+--------------------+--------------------+-------------+--------------+------------
--InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
---------------+--------------------+--------------------+-------------+--------------+------------
--01.01.2013   |      3             |        1           |      4      |      2        |     2
--01.02.2013   |      7             |        3           |      4      |      2        |     1
---------------+--------------------+--------------------+-------------+--------------+------------

Я собрал этот завпрос, НО не могу преобразовать дату в нужный формат, убил у же 4 часа, набросал несколько вариантов и всё не то, на уровне позапроса всё работает, но полностью весь скрипт выдает ошибки

-- Вариант первый... очевидный
declare @dml as nvarchar(max)
declare @colunmname as nvarchar(max)

select @colunmname = isnull(@colunmname + ',','') + t1.CustomerName
from
(select distinct
CustomerName
from Sales.Invoices as SI
	join (select
			CustomerID
			,CustomerName = '[' + CustomerName + ']'
			from Sales.Customers) T1 on T1.CustomerID = SI.CustomerID
group by T1.CustomerName, left(SI.InvoiceDate,7)) t1


set @dml =
N'select YearMonth, ' +@colunmname + ' from (
				select 
				 T1.CustomerName
				,YearMonth = replace(left(SI.InvoiceDate,7) + '-01','-','')
				,count (*) as KolProd
				from Sales.Invoices as SI
					join (  select
							 customerID
							,CustomerName
							from Sales.Customers) T1 on T1.CustomerID = SI.CustomerID
				group by T1.CustomerName, left(SI.InvoiceDate,7)    ) as t

PIVOT (sum(KolProd) for CustomerName IN (' + @colunmname + ')) as PivotTable'

exec sp_executesql @dml



-- Вариант второй... тут вроде правильный формат даты, в подзапросе нарушена сортировка и тоже ошибка
declare @dml as nvarchar(max)
declare @colunmname as nvarchar(max)

select @colunmname = isnull(@colunmname + ',','') + t1.CustomerName
from
(select distinct
CustomerName
from Sales.Invoices as SI
	join (select
			CustomerID
			,CustomerName = '[' + CustomerName + ']'
			from Sales.Customers) T1 on T1.CustomerID = SI.CustomerID
group by T1.CustomerName, left(SI.InvoiceDate,7)) t1


set @dml =
N'select YearMonth, ' +@colunmname + ' from (
				select 
				 T1.CustomerName
				,YearMonth = convert (nvarchar, DATEADD(m, DATEDIFF(m, 0, SI.InvoiceDate), 0), 104)
				,count (*) as KolProd
				from Sales.Invoices as SI
					join (  select
							 customerID
							,CustomerName
							from Sales.Customers) T1 on T1.CustomerID = SI.CustomerID
				group by T1.CustomerName, DATEADD(m, DATEDIFF(m, 0, SI.InvoiceDate), 0) ) as t

PIVOT (sum(KolProd) for CustomerName IN (' + @colunmname + ')) as PivotTable'

exec sp_executesql @dml


-- Вариант третий...извращённый. Тут я вообще не понимаю что за фигня, опять же на уровне позапроса всё красиво...
declare @dml as varchar(max)
declare @colunmname as varchar(max)

select @colunmname = isnull(@colunmname + ',','') + t1.CustomerName
from
(select distinct
CustomerName
from Sales.Invoices as SI
	join (select
			CustomerID
			,CustomerName = '[' + CustomerName + ']'
			from Sales.Customers) T1 on T1.CustomerID = SI.CustomerID
group by T1.CustomerName, left(SI.InvoiceDate,7)) t1


set @dml =
N'select YearMonth, ' +@colunmname + ' from (
				select 
				 T1.CustomerName
				,convert (varchar(14), (convert (datetime2, left(SI.InvoiceDate,7) + cast('-' as varchar(1)) + cast(0 as varchar(1)) + cast(1 as varchar(1)))), 104)  as YearMonth
				,count (*) as KolProd
				from Sales.Invoices as SI
					join (  select
							 customerID
							,CustomerName
							from Sales.Customers) T1 on T1.CustomerID = SI.CustomerID
				group by T1.CustomerName, left(SI.InvoiceDate,7) ) as t

PIVOT (sum(KolProd) for CustomerName IN (' + @colunmname + ')) as PivotTable'

exec sp_executesql @dml


-- тут я бы плюнул и договорился с бизнесом, что такой вариант им больше подойдет))
declare @dml as nvarchar(max)
declare @colunmname as nvarchar(max)

select @colunmname = isnull(@colunmname + ',','') + t1.CustomerName
from
(select distinct
CustomerName
from Sales.Invoices as SI
	join (select
			CustomerID
			,CustomerName = '[' + CustomerName + ']'
			from Sales.Customers) T1 on T1.CustomerID = SI.CustomerID
group by T1.CustomerName, left(SI.InvoiceDate,7)) t1


set @dml =
N'select YearMonth, ' +@colunmname + ' from (
				select 
				 T1.CustomerName
				,YearMonth = left(SI.InvoiceDate,7)
				,count (*) as KolProd
				from Sales.Invoices as SI
					join (  select
							 customerID
							,CustomerName
							from Sales.Customers) T1 on T1.CustomerID = SI.CustomerID
				group by T1.CustomerName, left(SI.InvoiceDate,7)    ) as t

PIVOT (sum(KolProd) for CustomerName IN (' + @colunmname + ')) as PivotTable'

exec sp_executesql @dml