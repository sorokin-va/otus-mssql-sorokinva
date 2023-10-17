drop database if exists SVA

--создание БД
create database SVA;
GO

--создание схемы для справочников
use SVA;
GO

create schema dic;
GO



-- справочник типов лимитов
drop table if exists dic.limit
create table dic.limit(
	Limit_type 	int not null,
	Limit_name	varchar(50),
	NDays		int not null,
	Date_from	date not null,
	Date_to		date not null)

--select * from dic.limit

ALTER TABLE dic.limit
ADD CONSTRAINT chk_ndays CHECK (ndays > 0)

ALTER TABLE dic.limit
ADD PRIMARY KEY (limit_type, date_to)

ALTER TABLE dic.limit
ADD DEFAULT '9999-12-31' FOR Date_to

insert into dic.limit values
(1, 'Основной отпуск', 28, '2020-01-01', '9999-12-31'),
(2, 'Основной отпуск (инвалид)', 30, '2020-01-01', '9999-12-31'),
(3, 'Основной отпуск (до 18 лет)', 31, '2020-01-01', '9999-12-31'),
(11, 'Дополнительный отпуск (ненорм 3)', 3, '2020-01-01', '9999-12-31'),
(12, 'Дополнительный отпуск (ненорм 4)', 4, '2020-01-01', '9999-12-31'),
(13, 'Дополнительный отпуск (ненорм 5)', 5, '2020-01-01', '9999-12-31')



--справочник типов отсутствий 
drop table if exists dic.vacation
create table dic.vacation(
	Vacation_type 	int not null,
	Vacation_name	varchar(50),
	Date_from	date not null default '2020-01-01',
	Date_to		date not null default '9999-12-31')

--select * from dic.VACATION

ALTER TABLE dic.VACATION
ADD CONSTRAINT chk_date CHECK (Date_from <= Date_to)
ALTER TABLE dic.VACATION
ADD PRIMARY KEY (Vacation_type, date_to)
-- Создаем индекс, так как в отчет планируется подтягивать название отсутствия, отобрав его по типу и датам.
-- При этом создаются новые отсутствия или меняются их названия давольно редко, поэтому создание индекса обосновано и не требует больших затрат на администрирование
CREATE NONCLUSTERED INDEX tn_ct_index_noclst_include
    ON SVA.dic.vacation (Vacation_type, Date_from, Date_to) include (Vacation_name);

insert into dic.VACATION (Vacation_type, Vacation_name) values
(100, 'Ежегодный основной отпуск'),
(200, 'Ежегодный дополнительный отпуск')

GO


-- создание функций для использования в constraint'ах
CREATE FUNCTION get_limit_type(@limit_type int)
RETURNS VARCHAR(50)
AS
BEGIN
RETURN (SELECT limit_type FROM dic.limit WHERE limit_type=@limit_type)
END;
go
CREATE FUNCTION get_vac_type(@vac_type int)
RETURNS VARCHAR(50)
AS
BEGIN
RETURN (SELECT vacation_type FROM dic.vacation WHERE vacation_type=@vac_type)
END;
go
CREATE FUNCTION get_TN(@TN int)
RETURNS VARCHAR(50)
AS
BEGIN
RETURN (SELECT TN FROM dbo.personal WHERE TN=@TN)
END;
go

--настроечная таблица соответствия типа лимита и типа отпуска, который может использовать данный тип лимита
drop table if exists DIC.VAC_LIM
create table dic.vac_lim(
	Limit_type		int not null CONSTRAINT limit_type check (dbo.get_limit_type(limit_type) is not null),
	Vacation_type 	int not null CONSTRAINT vacation_type check (dbo.get_vac_type(vacation_type) is not null),
	Date_from		date not null default '2020-01-01',
	Date_to			date not null default '9999-12-31',
	Primary key (Limit_type, Vacation_type, Date_to))

insert into dic.VAC_LIM (Limit_type, Vacation_type) values
(1, 100),
(2, 100),
(3, 100),
(11, 200),
(12, 200),
(13, 200)

--select * from dic.VAC_LIM


--справочник условий для трудового договора 
drop table if exists DIC.CONDITIONS
create table dic.conditions (
	Condition_type	int not null primary key,
	Condition_name 	varchar(100) not null,
	Main_limit_type	int not null CONSTRAINT Main_limit_type check (dbo.get_limit_type(Main_limit_type) is not null and len (Main_limit_type) = 1),
	Add_limit_type	int CONSTRAINT Add_limit_type check (len(Add_limit_type)=2)
)

insert into dic.CONDITIONS (Condition_type, Condition_name, Main_limit_type, Add_limit_type) values
(1, 'Отпуск 28', 1, null),
(2, 'Отпуск 30', 2, null),
(3, 'Отпуск 31', 3, null),
(4, 'Отпуск 28+3', 1, 11),
(5, 'Отпуск 28+4', 1, 12),
(6, 'Отпуск 28+5', 1, 13),
(7, 'Отпуск 30+3', 2, 11),
(8, 'Отпуск 30+4', 2, 12),
(9, 'Отпуск 30+5', 2, 13),
(10, 'Отпуск 31+3', 3, 11),
(11, 'Отпуск 31+4', 3, 12),
(12, 'Отпуск 31+5', 3, 13)

-- select * from dic.CONDITIONS



-- для основных таблиц  с данными отдельную схему не создаю, использую dbo по умолчанию
-- основная таблица с персональными данными о сотруднике
drop table if exists dbo.personal
create table dbo.personal (
	TN				int not null identity(1, 1),
	Surname		 	varchar(100) not null,
	FisrtName		varchar(100) not null,
	MiddleName		varchar(100),
	Gender			varchar(1) not null constraint gender check (gender in ('м','ж')),
	Date_of_birth	date not null,
	Date_from		date not null default '2020-01-01',
	Date_to			date not null default '9999-12-31',
	Primary key (TN, Date_to))

ALTER TABLE dbo.personal
ADD CONSTRAINT chk_date_p CHECK (Date_from <= Date_to)
-- Создаем индекс, так как в отчет планируется подтягивать ФИО, отобрав его по ТН и датам.
-- При этом есть сомнение в том, что будет использоваться индекс, т.к. TN имеет упорядоченные значения, но на практике люди меняют фамилии, либо мигрируются работники из других систем со своими диапазонами для ТН и сортировка нарушается.
CREATE NONCLUSTERED INDEX pers_index_noclst_include
    ON SVA.dbo.personal (TN, Date_from, Date_to) include (Surname, FisrtName, MiddleName); 
-- Создаем индекс, так как в планируется формировать список именников, отобрав их по датам рождения.
-- Список формируется ежедневно, и при большом штате сотрудников использование индекса актуально.
CREATE NONCLUSTERED INDEX birthday_index_noclst_include
    ON SVA.dbo.personal (Date_of_birth) include (Surname, FisrtName, MiddleName); 

insert into dbo.personal (Surname, FisrtName, MiddleName, Gender, Date_of_birth) values 
('Иванов1', 'Иван1', 'Иванович1', 'м', '1980-03-13'),
('Иванов2', 'Иван2', 'Иванович2', 'м', '1980-03-14'),
('Иванов3', 'Иван3', 'Иванович3', 'м', '1980-03-15'),
('Иванов4', 'Иван4', 'Иванович4', 'м', '1980-03-16'),
('Иванов5', 'Иван5', 'Иванович5', 'м', '1980-03-17'),
('Иванов6', 'Иван6', 'Иванович6', 'м', '1980-03-18'),
('Иванов7', 'Иван7', 'Иванович7', 'м', '1980-03-19'),
('Иванов8', 'Иван8', 'Иванович8', 'м', '1980-03-20'),
('Иванов9', 'Иван9', 'Иванович9', 'м', '1980-03-21'),
('Иванов10', 'Иван10', 'Иванович10', 'м', '1980-03-22'),
('Петрова1', 'Мария1', 'Петровна1', 'ж', '1985-01-09'),
('Петрова2', 'Мария2', 'Петровна2', 'ж', '1985-01-10'),
('Петрова3', 'Мария3', 'Петровна3', 'ж', '1985-01-11'),
('Петрова4', 'Мария4', 'Петровна4', 'ж', '1985-01-12'),
('Петрова5', 'Мария5', 'Петровна5', 'ж', '1985-01-13'),
('Петрова6', 'Мария6', 'Петровна6', 'ж', '1985-01-14'),
('Петрова7', 'Мария7', 'Петровна7', 'ж', '1985-01-15'),
('Петрова8', 'Мария8', 'Петровна8', 'ж', '1985-01-16'),
('Петрова9', 'Мария9', 'Петровна9', 'ж', '1985-01-17'),
('Петрова10', 'Мария10', 'Петровна10', 'ж', '1985-01-18')


--таблица с трудовыми договорами сотрудников
drop table if exists dbo.agreement
create table dbo.agreement (
	TN				int not null,
	Date_from		date not null default '2020-01-01',
	Date_to			date not null default '9999-12-31',
	Salary		 	decimal (19,2) not null,
	Condition_type	int not null,
	Primary key (TN, Date_to)	)

ALTER TABLE dbo.agreement
ADD foreign key (condition_type) references dic.CONDITIONS(condition_type)
ALTER TABLE dbo.agreement
ADD CONSTRAINT chk_date CHECK (Date_from <= Date_to)
CREATE NONCLUSTERED INDEX tn_ct_index_noclst
    ON SVA.dbo.agreement (TN, Condition_type);  
GO

insert into dbo.agreement (TN, Salary, Condition_type) values 
(1, 50000, 1),
(2, 55000, 1),
(3, 55000, 3),
(4, 55000, 1),
(5, 55000, 7),
(6, 55000, 1),
(7, 65000, 8),
(8, 55000, 1),
(9, 55000, 1),
(10, 43600, 1),
(11, 59000, 1),
(12, 155000, 9),
(13, 55000, 1),
(14, 55000, 1),
(15, 55000, 5),
(16, 55000, 1),
(17, 55000, 12),
(18, 55000, 1),
(19, 55500, 1),
(20, 100000, 1)


--таблица с отсутствиями сотрудников
drop table if exists dbo.vacation
create table dbo.vacation (
	TN				int not null,
	Vacation_type	int not null,-- foreign key (vacation_type) references dic.vacation(Vacation_type),
	Date_from		date not null,
	Date_to			date not null,
	Ndays			as (datediff(DD, Date_from, Date_to)+1) persisted,
	Primary key (TN, Date_to)	)

ALTER TABLE dbo.vacation
ADD CONSTRAINT chk_date_vac CHECK (dbo.get_vac_type(vacation_type) is not null)

insert into dbo.vacation (tn, Vacation_type, Date_from, Date_to) values 
(1, 100, '2023-03-01', '2023-03-14' ),
(1, 100, '2023-04-01', '2023-04-14' ),
(1, 200, '2023-04-15', '2023-04-18' ),
(2, 100, '2023-03-01', '2023-03-21' ),
(3, 100, '2023-03-01', '2023-03-14' )


--таблица с составом бригад
drop table  if exists dbo.workgroup
create table dbo.workgroup(
	Id_group 	int not null,
	Group_name	varchar(50),
	TN		int not null,
	Date_from	date not null,
	Date_to		date not null)

ALTER TABLE dbo.workgroup
ADD CONSTRAINT chk_TN CHECK (dbo.get_TN(TN) is not null)

ALTER TABLE dbo.workgroup
ADD PRIMARY KEY (Id_group, TN, date_to)

ALTER TABLE dbo.workgroup
ADD DEFAULT '9999-12-31' FOR Date_to

ALTER TABLE dbo.workgroup
ADD DEFAULT '2020-01-01' FOR Date_from

CREATE NONCLUSTERED INDEX tn_index_noclst
    ON SVA.dbo.workgroup (TN)
	
insert into dbo.workgroup (Id_group, Group_name, TN)values
(1, 'Бригада №1', 1),
(1, 'Бригада №1', 4),
(1, 'Бригада №1', 7),
(2, 'Бригада №2', 2),
(2, 'Бригада №2', 5),
(2, 'Бригада №2', 8),
(3, 'Бригада №3', 3),
(3, 'Бригада №3', 6),
(3, 'Бригада №3', 9),
(4, 'Бригада №4', 10),
(4, 'Бригада №4', 13),
(4, 'Бригада №4', 16),
(5, 'Бригада №5', 11),
(5, 'Бригада №5', 14),
(5, 'Бригада №5', 17),
(6, 'Бригада №6', 12),
(6, 'Бригада №6', 15),
(6, 'Бригада №6', 18),
(7, 'Бригада №7', 19),
(7, 'Бригада №7', 20)




