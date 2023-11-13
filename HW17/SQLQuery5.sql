-- исходник
Select
	ord.CustomerID,
	det.StockItemID,
	SUM(det.UnitPrice),
	SUM(det.Quantity),
	COUNT(ord.OrderID)
FROM Sales.Orders AS ord
	JOIN Sales.OrderLines det						ON det.OrderID = ord.OrderID
	JOIN Sales.Invoices Inv							ON Inv.OrderID = ord.OrderID
	JOIN Sales.CustomerTransactions Trans			ON Trans.InvoiceID = Inv.InvoiceID
	JOIN Warehouse.StockItemTransactions ItemTrans	ON ItemTrans.StockItemID = det.StockItemID
WHERE Inv.BillToCustomerID != ord.CustomerID
	AND (Select SupplierId
		FROM Warehouse.StockItems AS It
		Where It.StockItemID = det.StockItemID) = 12	

	AND (SELECT SUM(Total.UnitPrice*Total.Quantity)
		FROM Sales.OrderLines AS Total
		JOIN Sales.Orders AS ordTotal ON ordTotal.OrderID = Total.OrderID
		WHERE ordTotal.CustomerID = Inv.CustomerID) > 250000
		
	AND DATEDIFF(dd, Inv.InvoiceDate, ord.OrderDate) = 0

GROUP BY ord.CustomerID, det.StockItemID
ORDER BY ord.CustomerID, det.StockItemID


-- исходник

Select
	ord.CustomerID,
	det.StockItemID,
	SUM(det.UnitPrice),
	SUM(det.Quantity),
	COUNT(ord.OrderID)
FROM Sales.OrderLines AS det
	join Warehouse.StockItems ws					ON ws.StockItemID = det.StockItemID and ws.SupplierID = 12
	JOIN Sales.Orders ord							ON det.OrderID = ord.OrderID
	JOIN Sales.Invoices Inv							ON Inv.OrderID = ord.OrderID and Inv.BillToCustomerID != ord.CustomerID and Inv.InvoiceDate = ord.OrderDate
	JOIN Warehouse.StockItemTransactions ItemTrans	ON ItemTrans.StockItemID = det.StockItemID
	JOIN Sales.CustomerTransactions Trans			ON Trans.InvoiceID = Inv.InvoiceID
WHERE	(SELECT SUM(Total.UnitPrice*Total.Quantity)
		FROM Sales.OrderLines AS Total
		JOIN Sales.Orders AS ordTotal ON ordTotal.OrderID = Total.OrderID
		WHERE ordTotal.CustomerID = Inv.CustomerID) > 250000
	
GROUP BY ord.CustomerID, det.StockItemID
ORDER BY ord.CustomerID, det.StockItemID
--option (force order)