/* Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), и не сделали ни одной продажи 04 июля 2015 года.
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

/*Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. Вывести: ИД товара, наименование товара, цена.*/
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


/*Выберите информацию по клиентам, которые перевели компании пять максимальных платежей из Sales.CustomerTransactions.
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

/*Выберите города (ид и название), в которые были доставлены товары, входящие в тройку самых дорогих товаров,
а также имя сотрудника, который осуществлял упаковку заказов (PackedByPersonID)*/
-- 4.1 Через подзапрос
select top 3 UnitPrice from Warehouse.StockItems
order by UnitPrice desc



select * from Sales.CustomerTransactions


select * from Sales.Invoices 
select * from Sales.CustomerTransactions
select * from Sales.OrderLines
select * from Warehouse.StockItems
select * from Warehouse.StockItemTransactions
