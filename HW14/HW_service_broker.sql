USE WideWorldImporters
go

-- Создадим времянку где будем подсчитывать количество заказов по клиенту
drop table if exists ##test
SELECT distinct CustomerID as Client, 0 as Count_of_Orders
INTO ##test
FROM Sales.Invoices;


USE master
go
ALTER DATABASE WideWorldImporters
SET ENABLE_BROKER  WITH ROLLBACK IMMEDIATE;
go
ALTER DATABASE WideWorldImporters SET TRUSTWORTHY ON;
go
ALTER AUTHORIZATION    
   ON DATABASE::WideWorldImporters TO [sa];
go

--Create Message Types for Request and Reply messages
USE WideWorldImporters
go
-- For Request
CREATE MESSAGE TYPE
[//WWI/SB/RequestMessage]
VALIDATION=WELL_FORMED_XML;
go
-- For Reply
CREATE MESSAGE TYPE
[//WWI/SB/ReplyMessage]
VALIDATION=WELL_FORMED_XML; 
go

CREATE CONTRACT [//WWI/SB/Contract]
      ([//WWI/SB/RequestMessage]
         SENT BY INITIATOR,
       [//WWI/SB/ReplyMessage]
         SENT BY TARGET
      );
GO

CREATE QUEUE TargetQueueWWI;
go
CREATE SERVICE [//WWI/SB/TargetService]
       ON QUEUE TargetQueueWWI
       ([//WWI/SB/Contract]);
GO

CREATE QUEUE InitiatorQueueWWI;
go
CREATE SERVICE [//WWI/SB/InitiatorService]
       ON QUEUE InitiatorQueueWWI
       ([//WWI/SB/Contract]);
GO

-- Создаем процедуру отправки
CREATE PROCEDURE Sales.SendNewInvoice
	@invoiceId INT
AS
BEGIN
	SET NOCOUNT ON;

    --Sending a Request Message to the Target	
	DECLARE @InitDlgHandle UNIQUEIDENTIFIER;
	DECLARE @RequestMessage NVARCHAR(4000);
	
	BEGIN TRAN 

	--Prepare the Message
	SELECT @RequestMessage = (SELECT InvoiceID
							  FROM Sales.Invoices AS Inv
							  WHERE InvoiceID = @invoiceId
							  FOR XML AUTO, root('RequestMessage')); 
	
	--Determine the Initiator Service, Target Service and the Contract 
	BEGIN DIALOG @InitDlgHandle
	FROM SERVICE
	[//WWI/SB/InitiatorService]
	TO SERVICE
	'//WWI/SB/TargetService'
	ON CONTRACT
	[//WWI/SB/Contract]
	WITH ENCRYPTION=OFF; 

	--Send the Message
	SEND ON CONVERSATION @InitDlgHandle 
	MESSAGE TYPE
	[//WWI/SB/RequestMessage]
	(@RequestMessage);
	
	SELECT @RequestMessage AS SentRequestMessage;
	
	COMMIT TRAN 
END
GO

-- Создаем процедуру получения

CREATE PROCEDURE Sales.GetNewInvoice
AS
BEGIN

	DECLARE @TargetDlgHandle UNIQUEIDENTIFIER,
			@Message NVARCHAR(4000),
			@MessageType Sysname,
			@ReplyMessage NVARCHAR(4000),
			@ReplyMessageName Sysname,
			@InvoiceID INT,
			@xml XML; 
	
	BEGIN TRAN; 

	--Receive message from Initiator
	RECEIVE TOP(1)
		@TargetDlgHandle = Conversation_Handle,
		@Message = Message_Body,
		@MessageType = Message_Type_Name
	FROM dbo.TargetQueueWWI; 

	SELECT @Message;

	SET @xml = CAST(@Message AS XML);

	SELECT @InvoiceID = R.Iv.value('@InvoiceID','INT')
	FROM @xml.nodes('/RequestMessage/Inv') as R(Iv);

-- Проверка инвойса и увеличение счетчика для соответствующего клиента
	IF EXISTS (SELECT * FROM Sales.Invoices WHERE InvoiceID = @InvoiceID)
	BEGIN
		UPDATE ##test
		SET Count_of_Orders = Count_of_Orders + 1
		WHERE Client in (SELECT CustomerID FROM Sales.Invoices WHERE InvoiceID = @InvoiceID);
	END;
	
	SELECT @Message AS ReceivedRequestMessage, @MessageType;
	
	-- Confirm and Send a reply
	IF @MessageType=N'//WWI/SB/RequestMessage'
	BEGIN
		SET @ReplyMessage =N'<ReplyMessage> Message received</ReplyMessage>'; 
	
		SEND ON CONVERSATION @TargetDlgHandle
		MESSAGE TYPE
		[//WWI/SB/ReplyMessage]
		(@ReplyMessage);
		END CONVERSATION @TargetDlgHandle;
	END 
	
	SELECT @ReplyMessage AS SentReplyMessage; --?? ??? ?????

	COMMIT TRAN;
END
go

--Создаем процедуру для подтверждения и закрытия диалога
CREATE PROCEDURE Sales.ConfirmInvoice
AS
BEGIN
	--Receiving Reply Message from the Target.	
	DECLARE @InitiatorReplyDlgHandle UNIQUEIDENTIFIER,
			@ReplyReceivedMessage NVARCHAR(1000) 
	
	BEGIN TRAN; 

		RECEIVE TOP(1)
			@InitiatorReplyDlgHandle=Conversation_Handle
			,@ReplyReceivedMessage=Message_Body
		FROM dbo.InitiatorQueueWWI; 
		
		END CONVERSATION @InitiatorReplyDlgHandle; 
		
		SELECT @ReplyReceivedMessage AS ReceivedRepliedMessage; --?? ??? ?????

	COMMIT TRAN; 
END

GO

USE [WideWorldImporters]
GO
/****** Object:  ServiceQueue [InitiatorQueueWWI]    Script Date: 6/5/2019 11:57:47 PM ******/
ALTER QUEUE [dbo].[InitiatorQueueWWI] WITH STATUS = ON , RETENTION = OFF , POISON_MESSAGE_HANDLING (STATUS = OFF) 
	, ACTIVATION (   STATUS = ON ,
        PROCEDURE_NAME = Sales.ConfirmInvoice, MAX_QUEUE_READERS = 1, EXECUTE AS OWNER) ; 

GO
ALTER QUEUE [dbo].[TargetQueueWWI] WITH STATUS = ON , RETENTION = OFF , POISON_MESSAGE_HANDLING (STATUS = OFF)
	, ACTIVATION (  STATUS = ON ,
        PROCEDURE_NAME = Sales.GetNewInvoice, MAX_QUEUE_READERS = 1, EXECUTE AS OWNER) ; 

GO

-- Запуская процедуру и подставляя разные инвойсы, будет расти количество заказов для данного клиента
EXEC Sales.SendNewInvoice
	@invoiceId = 70385;  -- 69136, 67699

Select * from ##test
where Client = 961;