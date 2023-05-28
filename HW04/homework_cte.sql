/* 1. �������� ����������� (Application.People), ������� �������� ������������ (IsSalesPerson), � �� ������� �� ����� ������� 04 ���� 2015 ����.
������� �� ���������� � ��� ������ ���. ������� �������� � ������� Sales.Invoices.*/
-- 1.1. ����� ���������

select * from application.people
where IsSalesperson = 1
	and PersonID not in (select SalespersonPersonID from Sales.Invoices 
					where invoiceDate like '2015-07-04');

-- 1.2. ����� CTE
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

/* 2. �������� ������ � ����������� ����� (�����������). �������� ��� �������� ����������. �������: �� ������, ������������ ������, ����.*/
-- 2.1. ����� ��������� � WHERE
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

-- 2.1. ����� ���������� � FROM
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

-- 2.2. ����� CTE
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


/* 3. �������� ���������� �� ��������, ������� �������� �������� ���� ������������ �������� �� Sales.CustomerTransactions.
����������� ��������� �������� (� ��� ����� � CTE)*/
-- 3.1. ����� ���������

select * from Sales.Customers as SC
join (select top 5 transactionamount, customerID from Sales.CustomerTransactions
		order by transactionamount desc) as SCT on SC.CustomerID = SCT.CustomerID;

-- 3.2. ����� CTE
; with CTE as
(
select top 5 transactionamount, customerID from Sales.CustomerTransactions
order by transactionamount desc
)
select * from Sales.Customers as SC
join CTE on SC.CustomerID = CTE.CustomerID;


/* 4. �������� ������ (�� � ��������), � ������� ���� ���������� ������, �������� � ������ ����� ������� �������,
� ����� ��� ����������, ������� ����������� �������� ������� (PackedByPersonID)*/
-- 4.1 ����� ���������

select distinct
 (select DeliveryCityID
  from Sales.Customers
  where CustomerID = WTF.CustomerID)					as '��. ������'
,(select CityName
  from Application.Cities
  where CityID = (select DeliveryCityID
				  from Sales.Customers
				  where CustomerID = WTF.CustomerID))	as '�������� ������'
,(select FullName
  from Application.People
  where PersonID=WTF.PackedByPersonID)					as '��� ����������'
from (select CustomerID, PackedByPersonID
	  from Sales.Invoices
	  where OrderID in (select orderID
						from Sales.OrderLines
						where StockItemID in (select StockItemID
											  from (select top 3 UnitPrice, StockItemID
													from Warehouse.StockItems
													order by UnitPrice desc) as WSI) ) ) as WTF;
	
-- 4.2. ����� CTE
; with CTE as
(
select top 3 UnitPrice, StockItemID
from Warehouse.StockItems
order by UnitPrice desc
)

select distinct
 AC.CityID   as '��. ������'
,AC.CityName as '�������� ������'
,AP.FullName as '��� ����������'
from Sales.Invoices			as SI
	join Sales.Customers	as SC	on SI.CustomerID = SC.CustomerID
	join Application.Cities	as AC	on SC.DeliveryCityID = AC.CityID
	join Application.People	as AP	on SI.PackedByPersonID = AP.PersonID
	join Sales.OrderLines	as SOL	on SI.OrderID = SOL.OrderID
	join CTE						on SOL.StockItemID = CTE.StockItemID;


/* 5. ���������, ��� ������ � ������������� ������. ����� ��������� ��� � ������� ��������� ������������� �������, ��� � � ������� ��������� �����\���������.
�������� ������������������ �������� ����� ����� SET STATISTICS IO, TIME ON.
���� ������� � ������� ��������, �� ����������� �� (����� � ������� ����� ��������� �����).
�������� ���� ����������� �� ������ �����������.*/

-- ������ �� ����� ������ ���������, ���� ���������, ������� ����� ��������, ����� ����� �� ��������� � ����� ����� ���������������� �������, ��� ����� ����� �� ��������� ������ 27000.

-- �������������� ������:
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


-- ���������������� ������.
-- 1. ����� ����������� ��������� � CTE, ��� �� �������� ���������� ������ � �� ������������ ���� "from" ��������� �������.
-- 2. � ����� �������� ������ ������ ����� ����������� �� ����
-- 2.1. ������������� �������;
-- 2.2. ���������� �����������;
-- 2.3. �������� �� join, ��� ����� ���� ��������� ����� ������� � �� ����� ������� ��������� � �������.
-- 3. ��� �� �������� � ��� ���� ����������� ����� ���������� �������
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