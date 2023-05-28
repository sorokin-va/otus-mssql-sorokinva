/* 1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), и не сделали ни одной продажи 04 июля 2015 года.
Вывести ИД сотрудника и его полное имя. Продажи смотреть в таблице Sales.Invoices.*/
-- 1.1. Через подзапрос

select * from application.people
where IsSalesperson = 1
	and PersonID not in (select SalespersonPersonID from Sales.Invoices 
					where invoiceDate like '2015-07-04');

-- 1.2. Через CTE
; with InvoicesCTE as
(
select SalespersonPersonID
from Sales.Invoices 
where invoiceDate like '2015-07-04'
)
select ap.*
from application.people as AP
left join InvoicesCTE as CTE on AP.PersonID = CTE.SalespersonPersonID
where AP.IsSalesperson = 1
	and CTE.SalespersonPersonID is null;

/* 2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. Вывести: ИД товара, наименование товара, цена.*/
-- 2.1. Через подзапрос в WHERE
select 
 StockItemID
,StockItemName
,UnitPrice
from Warehouse.StockItems
where UnitPrice in (select min(UnitPrice) from Warehouse.StockItems);

select 
 StockItemID
,StockItemName
,UnitPrice
from Warehouse.StockItems
where UnitPrice <= ALL (select UnitPrice from Warehouse.StockItems);

-- 2.1. Через подзапросы в FROM
select 
 StockItemID
,StockItemName
,UnitPrice
from (select (select min(UnitPrice) from Warehouse.StockItems) as MinPrice
			  ,UnitPrice
			  ,StockItemID
			  ,StockItemName
		from Warehouse.StockItems) AS WS
where MinPrice = UnitPrice;

-- 2.2. Через CTE
; with CTE as
(
select min(UnitPrice) as MinPrice from Warehouse.StockItems
)
select 
 StockItemID
,StockItemName
,UnitPrice
from Warehouse.StockItems as WS
join CTE on WS.UnitPrice = CTE.MinPrice;


/* 3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей из Sales.CustomerTransactions.
Представьте несколько способов (в том числе с CTE)*/
-- 3.1. Через подзапрос

select * from Sales.Customers as SC
join (select top 5 transactionamount, customerID from Sales.CustomerTransactions
		order by transactionamount desc) as SCT on SC.CustomerID = SCT.CustomerID;

-- 3.2. Через CTE
; with CTE as
(
select top 5 transactionamount, customerID from Sales.CustomerTransactions
order by transactionamount desc
)
select * from Sales.Customers as SC
join CTE on SC.CustomerID = CTE.CustomerID;


/* 4. Выберите города (ид и название), в которые были доставлены товары, входящие в тройку самых дорогих товаров,
а также имя сотрудника, который осуществлял упаковку заказов (PackedByPersonID)*/
-- 4.1 Через подзапрос

select distinct
 (select DeliveryCityID
  from Sales.Customers
  where CustomerID = WTF.CustomerID)					as 'ид. города'
,(select CityName
  from Application.Cities
  where CityID = (select DeliveryCityID
				  from Sales.Customers
				  where CustomerID = WTF.CustomerID))	as 'название города'
,(select FullName
  from Application.People
  where PersonID=WTF.PackedByPersonID)					as 'имя упаковщика'
from (select CustomerID, PackedByPersonID
	  from Sales.Invoices
	  where OrderID in (select orderID
						from Sales.OrderLines
						where StockItemID in (select StockItemID
											  from (select top 3 UnitPrice, StockItemID
													from Warehouse.StockItems
													order by UnitPrice desc) as WSI) ) ) as WTF;
	
-- 4.2. Через CTE
; with CTE as
(
select top 3 UnitPrice, StockItemID
from Warehouse.StockItems
order by UnitPrice desc
)

select distinct
 AC.CityID   as 'ид. города'
,AC.CityName as 'название города'
,AP.FullName as 'имя упаковщика'
from Sales.Invoices			as SI
	join Sales.Customers	as SC	on SI.CustomerID = SC.CustomerID
	join Application.Cities	as AC	on SC.DeliveryCityID = AC.CityID
	join Application.People	as AP	on SI.PackedByPersonID = AP.PersonID
	join Sales.OrderLines	as SOL	on SI.OrderID = SOL.OrderID
	join CTE						on SOL.StockItemID = CTE.StockItemID;


/* 5. Объясните, что делает и оптимизируйте запрос. Можно двигаться как в сторону улучшения читабельности запроса, так и в сторону упрощения плана\ускорения.
Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON.
Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы).
Напишите ваши рассуждения по поводу оптимизации.*/

-- запрос на вывод номера накладной, даты накладной, полного имени продавца, общей суммы по накладной и общей суммы укомплектованных товаров, где общая сумма по накладной больше 27000.

-- Первоначальный запрос:
set statistics time on;
GO

SELECT
Invoices.InvoiceID,
Invoices.InvoiceDate,
(SELECT People.FullName
FROM Application.People
WHERE People.PersonID = Invoices.SalespersonPersonID
) AS SalesPersonName,
SalesTotals.TotalSumm AS TotalSummByInvoice,
(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
FROM Sales.OrderLines
WHERE OrderLines.OrderId = (SELECT Orders.OrderId
FROM Sales.Orders
WHERE Orders.PickingCompletedWhen IS NOT NULL
AND Orders.OrderId = Invoices.OrderId)
) AS TotalSummForPickedItems
FROM Sales.Invoices
JOIN
(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
FROM Sales.InvoiceLines
GROUP BY InvoiceId
HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC;


-- Оптимизированный запрос.
-- 1. Вынес независимый подзапрос в CTE, где он выглядит достаточно просто и не нагромождает блок "from" основного запроса.
-- 2. В целом основной запрос сделал более читабельным за счет
-- 2.1. Использования алиасов;
-- 2.2. Отсутствия подзапросов;
-- 2.3. Перевода на join, что сразу дает понимание какие таблицы и по каким условия участвуют в запросе.
-- 3. Так же примерно в два раза сократилось время выполнения запроса
; with CTE (InvoiceId, TotalSummByInvoice) as
(
select InvoiceId, sum (Quantity * UnitPrice)
from Sales.InvoiceLines
group by InvoiceId
having sum (Quantity * UnitPrice) > 27000
)

select
 SI.InvoiceID
,SI.InvoiceDate
,AP.FullName								as SalesPersonName
,CTE.TotalSummByInvoice
,SUM (SOL.PickedQuantity * SOL.UnitPrice)	as TotalSummForPickedItems
from Sales.Invoices as SI
	join CTE						on SI.InvoiceID = CTE.InvoiceID
	join Application.People as AP	on SI.SalespersonPersonID = AP.PersonID
	join Sales.OrderLines as SOL	on SI.OrderID = SOL.OrderID
	join Sales.Orders as SO			on SOL.OrderID = SO.OrderID
where SO.PickingCompletedWhen is not null
group by 
 SI.InvoiceID
,SI.InvoiceDate
,AP.FullName
,CTE.TotalSummByInvoice
order by TotalSummByInvoice desc;

go
set statistics time off;