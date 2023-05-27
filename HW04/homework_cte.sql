/* �������� ����������� (Application.People), ������� �������� ������������ (IsSalesPerson), � �� ������� �� ����� ������� 04 ���� 2015 ����.
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

/*�������� ������ � ����������� ����� (�����������). �������� ��� �������� ����������. �������: �� ������, ������������ ������, ����.*/
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


/*�������� ���������� �� ��������, ������� �������� �������� ���� ������������ �������� �� Sales.CustomerTransactions.
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

/*�������� ������ (�� � ��������), � ������� ���� ���������� ������, �������� � ������ ����� ������� �������,
� ����� ��� ����������, ������� ����������� �������� ������� (PackedByPersonID)*/
-- 4.1 ����� ���������
select top 3 UnitPrice from Warehouse.StockItems
order by UnitPrice desc



select * from Sales.CustomerTransactions


select * from Sales.Invoices 
select * from Sales.CustomerTransactions
select * from Sales.OrderLines
select * from Warehouse.StockItems
select * from Warehouse.StockItemTransactions
