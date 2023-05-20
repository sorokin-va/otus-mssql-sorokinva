/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, JOIN".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД WideWorldImporters можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

select
 StockItemID    as 'ид. товара'
,StockItemName  as 'наименование товара'
from Warehouse.StockItems
where StockItemName like '%urgent%' or StockItemName like 'Animal%'

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

select
 PS.SupplierID     as 'ид. поставщика'
,PS.SupplierName   as 'название поставщика'
from Purchasing.Suppliers as PS
	left join Purchasing.PurchaseOrders as PPO on PS.SupplierID = PPO.SupplierID
where PPO.SupplierID is null

/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.
Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).
Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

select 
 SO.OrderID                                             as 'ид. заказа'
,convert(varchar, SO.OrderDate, 104)                    as 'дата заказа'
,datename(M, SO.OrderDate)                              as 'название месяца'
,datepart(Q, SO.OrderDate)                              as 'номер квартала'
,case
	when datepart(M, SO.OrderDate) in (1,2,3,4) then 1
	when datepart(M, SO.OrderDate) in (5,6,7,8) then 2
	else 3
	end                                                 as 'треть года'
,SC.CustomerName                                        as 'имя заказчика'
from sales.Orders as SO
	join sales.OrderLines SOL on SO.OrderID = SOL.OrderID
	left join sales.Customers SC on SO.CustomerID = SC.CustomerID
where (SOL.UnitPrice > 100 or SOL.Quantity > 20)
	and SOL.PickingCompletedWhen is not null
order by 
	datepart(Q, SO.OrderDate),
	case
		when datepart(M, SO.OrderDate) in (1,2,3,4) then 1
		when datepart(M, SO.OrderDate) in (5,6,7,8) then 2
		else 3
	end,
	convert(varchar, SO.OrderDate, 104)

--Добавьте вариант этого запроса с постраничной выборкой,
--пропустив первую 1000 и отобразив следующие 100 записей.

select 
 SO.OrderID                                             as 'ид. заказа'
,convert(varchar, SO.OrderDate, 104)                    as 'дата заказа'
,datename(M, SO.OrderDate)                              as 'название месяца'
,datepart(Q, SO.OrderDate)                              as 'номер квартала'
,case
	when datepart(M, SO.OrderDate) in (1,2,3,4) then 1
	when datepart(M, SO.OrderDate) in (5,6,7,8) then 2
	else 3
	end                                                 as 'треть года'
,SC.CustomerName                                        as 'имя заказчика'
from sales.Orders as SO
	join sales.OrderLines SOL on SO.OrderID = SOL.OrderID
	left join sales.Customers SC on SO.CustomerID = SC.CustomerID
where (SOL.UnitPrice > 100 or SOL.Quantity > 20)
	and SOL.PickingCompletedWhen is not null
order by 
	datepart(Q, SO.OrderDate),
	case
		when datepart(M, SO.OrderDate) in (1,2,3,4) then 1
		when datepart(M, SO.OrderDate) in (5,6,7,8) then 2
		else 3
	end,
	convert(varchar, SO.OrderDate, 104)
	offset 1000 rows fetch first 100 rows only

/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/
select
 AD.DeliveryMethodName      as 'способ доставки'
,PPO.ExpectedDeliveryDate   as 'дата доставки'
,PS.SupplierName            as 'имя поставщика'
,AP.FullName                as 'имя контактного лица, принимавшего заказ'
from Purchasing.Suppliers as PS
	join Purchasing.PurchaseOrders     as PPO on PS.SupplierID = PPO.SupplierID
	join Application.DeliveryMethods   as AD on PPO.DeliveryMethodID = AD.DeliveryMethodID
	join Application.People            as AP on PPO.ContactPersonID = AP.PersonID
where PPO.ExpectedDeliveryDate like '2013-01%'
	and (AD.DeliveryMethodName like 'Air Freight' or AD.DeliveryMethodName like 'Refrigerated Air Freight')
	and PPO.IsOrderFinalized = 1

/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/
select * from sales.Invoices

/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

select distinct
 WST.CustomerID
,SC.CustomerName
,SC.PhoneNumber 
from Warehouse.StockItemTransactions as WST
	join Warehouse.StockItems as WS on WST.StockItemID = WS.StockItemID
	join sales.Customers as SC on WST.CustomerID = SC.CustomerID
where WS.StockItemName like 'Chocolate frogs 250g'
	and WST.CustomerID is not null