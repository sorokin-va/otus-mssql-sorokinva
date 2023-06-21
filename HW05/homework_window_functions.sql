/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

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
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/

set statistics time, io on

;with CTE as (
select 
left(SI.InvoiceDate,7) as D,
sum(SCT.TransactionAmount) as S
from Sales.Invoices as SI
join Sales.CustomerTransactions as SCT on SCT.InvoiceID = SI.InvoiceID
where SI.InvoiceDate >= '2015-01-01'
group by 
left(SI.InvoiceDate,7))


select
 SI.InvoiceID				as 'id продажи'
,SC.CustomerName			as 'название клиента'
,SI.InvoiceDate				as 'дата продажи'
,SCT.TransactionAmount		as 'сумма продажи'
,FROM_CTE.PROGRESSIVE_TOTAL as 'нарастающий итог по месяцу'
from Sales.Invoices as SI
	join Sales.CustomerTransactions as SCT on SCT.InvoiceID = SI.InvoiceID
	join Sales.Customers as SC on SC.CustomerID = SCT.CustomerID
	join (select T1.*, (select coalesce(sum(T2.S),0)
						from CTE as T2 where T2.D<=T1.D) as PROGRESSIVE_TOTAL
		  from CTE as T1) as FROM_CTE on FROM_CTE.D = left(SI.InvoiceDate,7)
order by [id продажи]


--SQL Server Execution Times:
--   CPU time = 2468 ms,  elapsed time = 3127 ms.

/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/

select
 SI.InvoiceID				as 'id продажи'
,SC.CustomerName			as 'название клиента'
,SI.InvoiceDate				as 'дата продажи'
,SCT.TransactionAmount		as 'сумма продажи'
,sum(SCT.TransactionAmount) over (order by datepart(YEAR, SI.InvoiceDate), datepart(MONTH, SI.InvoiceDate)) as 'нарастающий итог по месяцу'
from Sales.Invoices as SI
	join Sales.CustomerTransactions as SCT on SCT.InvoiceID = SI.InvoiceID
	join Sales.Customers as SC on SC.CustomerID = SCT.CustomerID
where SI.InvoiceDate >= '2015-01-01'
order by [id продажи]	

 --SQL Server Execution Times:
 --  CPU time = 453 ms,  elapsed time = 1099 ms.

-- Вывод: оконная функция рулит)) в 5 раз быстрее чем с СТЕ

/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/

select YEAR_MONTH, StockItemID, TOTAL from (
	select *, ROW_NUMBER() OVER (PARTITION BY YEAR_MONTH ORDER BY TOTAL desc) as ID_ROW from (
		select distinct left(SI.InvoiceDate,7) as YEAR_MONTH, SIL.StockItemID, sum(Quantity) OVER (PARTITION BY month(SI.InvoiceDate), SIL.StockItemID) as TOTAL from Sales.Invoices as SI
			join Sales.InvoiceLines as SIL on SIL.InvoiceID = SI.InvoiceID
		where SI.InvoiceDate like '2016%'
	) t1
) t2
where ID_ROW <= 2
order by YEAR_MONTH, TOTAL

/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/

напишите здесь свое решение

/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/

напишите здесь свое решение

/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

напишите здесь свое решение

Опционально можете для каждого запроса без оконных функций сделать вариант запросов с оконными функциями и сравнить их производительность. 