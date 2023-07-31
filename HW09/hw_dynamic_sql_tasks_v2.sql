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

--Я собрал этот запрос, НО не могу преобразовать дату в нужный формат, убил у же 4 часа, набросал несколько вариантов и всё не то, на уровне позапроса всё работает, но полностью весь скрипт выдает ошибки

-- Учел замечания... но не нравится, что нет сортировки по дате.
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
				,YearMonth = format(datefromparts(year(SI.InvoiceDate),month(SI.InvoiceDate),1), ''dd.MM.yyyy'')
				,SI.InvoiceID as KolProd
				from Sales.Invoices as SI
					join (  select
							 customerID
							,CustomerName
							from Sales.Customers) T1 on T1.CustomerID = SI.CustomerID
				group by datefromparts(year(SI.InvoiceDate),month(SI.InvoiceDate),1), SI.InvoiceID, T1.CustomerName) as t

PIVOT (count(KolProd) for CustomerName IN (' + @colunmname + ')) as PivotTable'

exec sp_executesql @dml


