/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

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

; with CTE as (
				select 
				 T1.CustomerNameShort
				,left(SI.InvoiceDate,7) as YearMonth
				,count (*) as KolProd
				from Sales.Invoices as SI
					join (  select
							 customerID
							,substring(CustomerName,16,(len(substring(CustomerName,16,100))-1)) as CustomerNameShort
							from Sales.Customers as SC
							where CustomerID between 2 and 6) T1 on T1.CustomerID = SI.CustomerID
				group by T1.CustomerNameShort, left(SI.InvoiceDate,7))
				
select YearMonth, [Sylvanite, MT], [Peeples Valley, AZ], [Medicine Lodge, KS], [Gasport, NY], [Jessie, ND] from CTE
PIVOT (sum(KolProd) for CustomerNameShort IN ([Sylvanite, MT], [Peeples Valley, AZ], [Medicine Lodge, KS], [Gasport, NY], [Jessie, ND])) as PivotTable


/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/

select
 unpvt.CustomerName
,unpvt.DeliveryAddressList
from (	select CustomerName, DeliveryAddressLine1, DeliveryAddressLine2
		from Sales.Customers
		where CustomerName like '%Tailspin Toys%') as T1
UNPIVOT (DeliveryAddressList For id IN ([DeliveryAddressLine1], [DeliveryAddressLine2])) as unpvt

/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.
Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/

select
 unpvt.CountryID
,unpvt.CountryName
,unpvt.Code
from (	select CountryID, CountryName, cast(IsoAlpha3Code as char) IsoAlpha3Code, cast(IsoNumericCode as char) IsoNumericCode
		from Application.Countries) as T1
UNPIVOT (Code FOR id in ([IsoAlpha3Code], [IsoNumericCode])) as unpvt


/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

select
 SC.CustomerID
,SC.CustomerName
,CA.StockItemID
,CA.UnitPrice
,CA.[самая актуальная дата покупки]
from Sales.Customers as SC
cross apply (select distinct top 2
				 SO.CustomerID
				,SOL.UnitPrice
				,SOL.StockItemID
				,max(SO.OrderDate) OVER (PARTITION BY SO.CustomerID, SOL.UnitPrice, SOL.StockItemID order by SOL.UnitPrice desc) as 'самая актуальная дата покупки'
				from Sales.OrderLines as SOL
					join Sales.Orders as SO on SO.OrderID = SOL.OrderID
				where SC.CustomerID = SO.CustomerID
				order by 1 asc, 2 desc) CA;