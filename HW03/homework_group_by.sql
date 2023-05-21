/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

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
1. Посчитать среднюю цену товара, общую сумму продажи по месяцам.
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select
	 datepart(YEAR, FinalizationDate)                 as 'Год продажи'
	,datepart(MONTH, FinalizationDate)                as 'Месяц продажи'
	,cast(avg (TransactionAmount) as decimal (10,2))  as 'Средняя цена за месяц по всем товарам'
	,sum (TransactionAmount)                          as 'Общая сумма продаж за месяц'
from Sales.CustomerTransactions
where IsFinalized = 1                   -- под продажами я понимаю завершённые сделки, т.е. с флагом IsFinalized = 1, поэтому добавил это условие.
	and InvoiceID is not null           -- объясните почему без этого условия агрегаты не работают?
group by
	 datepart(YEAR, FinalizationDate)
	,datepart(MONTH, FinalizationDate)
order by 1,2

/*
2. Отобразить все месяцы, где общая сумма продаж превысила 4 600 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select
	 datepart(YEAR, FinalizationDate)       as 'Год продажи'
	,datepart(MONTH, FinalizationDate)      as 'Месяц продажи'
	,sum (TransactionAmount)                as 'Общая сумма продаж за месяц'
From Sales.CustomerTransactions
where IsFinalized = 1                   -- под продажами я понимаю завершённые сделки, т.е. с флагом IsFinalized = 1, поэтому добавил это условие.
	and InvoiceID is not null           -- объясните почему без этого условия агрегаты не работают?
group by
	 datepart(YEAR, FinalizationDate)
	,datepart(MONTH, FinalizationDate)
having sum (TransactionAmount) > 4600000
order by 1,2

/*
3. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select
	 datepart(YEAR, SCT.FinalizationDate)   as 'Год продажи'
	,datepart(MONTH, SCT.FinalizationDate)  as 'Месяц продажи'
	,WSI.StockItemName                      as 'Наименование товара'
	,sum (SCT.TransactionAmount)            as 'Сумма продаж'
	,min (SCT.FinalizationDate)             as 'Дата первой продажи'
	,count (SIL.StockItemID)                as 'Количество проданного'
from Sales.InvoiceLines as SIL
	join Sales.CustomerTransactions as SCT on SIL.InvoiceID = SCT.InvoiceID
	join Warehouse.StockItems as WSI on SIL.StockItemID = WSI.StockItemID
where SCT.IsFinalized = 1               -- под продажами я понимаю завершённые сделки, т.е. с флагом IsFinalized = 1, поэтому добавил это условие. (оно же отсекает в результатах NULL'ы по году и месяцу)
group by 
	 datepart(YEAR, SCT.FinalizationDate)
	,datepart(MONTH, SCT.FinalizationDate)
	,WSI.StockItemName
having count (SIL.StockItemID) < 50
order by 1,2,3

-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 2-3 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/

-- опционально 2 задание
select
	 datepart(YEAR, FinalizationDate)                        as 'Год продажи'
	,datepart(MONTH, FinalizationDate)                       as 'Месяц продажи'
	,case
		when sum(TransactionAmount) > 4600000 then sum(TransactionAmount)
		else 0
		end                                                  as 'Общая сумма продаж за месяц'
From Sales.CustomerTransactions
where IsFinalized = 1                   -- под продажами я понимаю завершённые сделки, т.е. с флагом IsFinalized = 1, поэтому добавил это условие.
	and InvoiceID is not null           -- объясните почему без этого условия агрегаты не работают?
group by
	 datepart(YEAR, FinalizationDate)
	,datepart(MONTH, FinalizationDate)
--having sum (TransactionAmount) > 4600000
order by 1,2

-- опционально 3 задание   177 товар в 04-2016 количество продаж 52 обработать, и заменить ID товара на наименование
select
	 BASE.[Год продажи]
	,BASE.[Месяц продажи]
	,BASE.[Наименование товара]
	,isnull(DETAIL.[Сумма продаж],0)  as 'Сумма продаж'
	,isnull(DETAIL.[Дата первой продажи],' ') as 'Дата первой продажи'
	,isnull(DETAIL.[Количество проданного],0) as 'Количество проданного' 
from (select distinct
			 datepart(YEAR, E.FinalizationDate)   as 'Год продажи'
			,datepart(MONTH, E.FinalizationDate)  as 'Месяц продажи'
			,X.StockItemID                        as 'ID товара'
			,X.StockItemName                      as 'Наименование товара'
			from Sales.CustomerTransactions as E
				cross apply (select StockItemID, StockItemName from Warehouse.StockItems) X
			where E.FinalizationDate is not null) BASE
left join (select
				 datepart(YEAR, SCT.FinalizationDate)   as 'Год продажи'
				,datepart(MONTH, SCT.FinalizationDate)  as 'Месяц продажи'
				,WSI.StockItemID                        as 'ID товара'
				,WSI.StockItemName                      as 'Наименование товара'
				,sum (SCT.TransactionAmount)            as 'Сумма продаж'
				,min (SCT.FinalizationDate)             as 'Дата первой продажи'
				,case when count (SIL.StockItemID) < 50 then count (SIL.StockItemID)
				else 999999999 end as 'Количество проданного'
			from Sales.InvoiceLines as SIL
				join Sales.CustomerTransactions as SCT on SIL.InvoiceID = SCT.InvoiceID
				join Warehouse.StockItems as WSI on SIL.StockItemID = WSI.StockItemID
			where SCT.IsFinalized = 1               -- под продажами я понимаю завершённые сделки, т.е. с флагом IsFinalized = 1, поэтому добавил это условие. (оно же отсекает в результатах NULL'ы по году и месяцу)
			group by 
				 datepart(YEAR, SCT.FinalizationDate)
				,datepart(MONTH, SCT.FinalizationDate)
				,WSI.StockItemID
				,WSI.StockItemName
			) DETAIL on BASE.[Месяц продажи] = DETAIL.[Месяц продажи] and BASE.[Год продажи] = DETAIL.[Год продажи] and BASE.[ID товара] = DETAIL.[ID товара]
where DETAIL.[Количество проданного] is null or DETAIL.[Количество проданного] <> 999999999
order by 1,2,3