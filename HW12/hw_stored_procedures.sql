/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "12 - Хранимые процедуры, функции, триггеры, курсоры".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

USE WideWorldImporters

/*
Во всех заданиях написать хранимую процедуру / функцию и продемонстрировать ее использование.
*/

/*
1) Написать функцию возвращающую Клиента с наибольшей суммой покупки.
*/

IF OBJECT_ID ( 'dbo.ufn_Customer') IS NOT NULL   
drop function [dbo].[ufn_Customer]
go
CREATE FUNCTION [dbo].[ufn_Customer] (@customerid int)  
RETURNS TABLE  
AS  
RETURN   
(  
    SELECT top 1 CustomerID, TransactionAmount  
    FROM Sales.CustomerTransactions 
	ORDER BY TransactionAmount desc
     
);  
GO

select * from [dbo].[ufn_Customer](0)

/*
2) Написать хранимую процедуру с входящим параметром СustomerID, выводящую сумму покупки по этому клиенту.
Использовать таблицы :
Sales.Customers
Sales.Invoices
Sales.InvoiceLines
*/

IF OBJECT_ID ( 'dbo.GetSumm') IS NOT NULL   
    DROP PROCEDURE dbo.GetSumm; 
GO
CREATE PROCEDURE dbo.GetSumm      
    @CustomerID int   
AS   

    SET NOCOUNT ON;  
	Select  sum(summ) as [Общая сумма покупок клиентов за все времена] from 
									(select InvoiceID, sum(Quantity*UnitPrice) summ from Sales.InvoiceLines 
									group by InvoiceID ) t1
	join Sales.Invoices SI on SI.InvoiceID = t1.InvoiceID
	join Sales.Customers SC on SC.CustomerID = SI.CustomerID  -- не совсем понял зачем в задании указана эта таблица, но укажу, типа это проверка на наличие в справочнике такого CustomerID
	group by SC.CustomerID
	having SC.CustomerID = @CustomerID;
GO 

EXEC dbo.GetSumm 834;


/*
3) Создать одинаковую функцию и хранимую процедуру, посмотреть в чем разница в производительности и почему.
*/
IF OBJECT_ID ( 'dbo.fGetSumm') IS NOT NULL  
drop function dbo.fGetSumm
go
CREATE FUNCTION dbo.fGetSumm (@CustomerID int)
RETURNS TABLE  
AS  
RETURN   
(  
	Select  sum(summ) as [Общая сумма покупок клиентов за все времена] from 
									(select InvoiceID, sum(Quantity*UnitPrice) summ from Sales.InvoiceLines 
									group by InvoiceID ) t1
	join Sales.Invoices SI on SI.InvoiceID = t1.InvoiceID
	join Sales.Customers SC on SC.CustomerID = SI.CustomerID  -- не совсем понял зачем в задании указана эта таблица, но укажу, типа это проверка на наличие в справочнике такого CustomerID
	group by SC.CustomerID
	having SC.CustomerID = @CustomerID
     
);  
GO

EXEC dbo.GetSumm 834;
select * from dbo.fGetSumm(834)

-- нет никакой разницы между функцией и процедурой, т.к. исполняемый код одинаков!

/*
4) Создайте табличную функцию покажите как ее можно вызвать для каждой строки result set'а без использования цикла. 
*/
select  CustomerID, CustomerName, (select * from fGetSumm(customerID)) as [Общая сумма покупок клиентов за все времена]
from Sales.Customers
where CustomerID in (2,834)


/*
5) Опционально. Во всех процедурах укажите какой уровень изоляции транзакций вы бы использовали и почему. 
*/
