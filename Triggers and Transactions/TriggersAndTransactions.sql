--1. Create Table Logs
CREATE TRIGGER tr_ProcessTransaction
ON Accounts
AFTER UPDATE
AS
BEGIN
	INSERT INTO Logs (AccountId, OldSum, NewSum)
	SELECT i.Id, d.Balance, i.Balance FROM inserted AS i
	INNER JOIN deleted AS d ON d.Id = i.Id
END

--2. Create Table Emails
CREATE TRIGGER tr_ProccesEmail
ON Logs
AFTER INSERT
AS
BEGIN
	INSERT INTO NotificationEmails (Recipient, Subject, Body)
	SELECT AccountId,
	       CONCAT('Balance change for account: ', CAST(AccountId AS NVARCHAR(5))),
		   CONCAT('On', CAST(GETDATE() AS NVARCHAR(50)) ,
		          'your balance was changed from', 
				  CAST(OldSum AS NVARCHAR(50)), 'to', 
				  CAST(NewSum AS NVARCHAR(50)))
	  FROM Logs
END

--3. Deposit Money
CREATE PROC usp_DepositMoney (@AccountId INT, @MoneyAmount DECIMAL(15,4))
AS 
BEGIN
	BEGIN TRANSACTION
	IF (@MoneyAmount < 0)
	BEGIN
		RETURN
	END

	UPDATE Accounts
	SET Balance += @MoneyAmount
	WHERE Id = @AccountId

	COMMIT
END

--4. Withdraw Money Procedure
CREATE PROC usp_WithdrawMoney (@AccountId INT, @MoneyAmount DECIMAL(15,4))
AS 
BEGIN
	BEGIN TRANSACTION
	IF (@MoneyAmount < 0)
	BEGIN
		RETURN
	END

	UPDATE Accounts
	SET Balance -= @MoneyAmount
	WHERE Id = @AccountId

	COMMIT
END

--5. Money Transfer
CREATE PROC usp_TransferMoney(@SenderId INT, @ReceiverId INT, @MoneyAmount DECIMAL(15,4))
AS 
BEGIN
	BEGIN TRANSACTION
	IF (@MoneyAmount < 0)
	BEGIN		
		RAISERROR ('Negative amount specified!', 16, 1)
		RETURN
	END	

	UPDATE Accounts
	SET Balance -= @MoneyAmount
	WHERE Id = @SenderId

	UPDATE Accounts
	SET Balance += @MoneyAmount
	WHERE Id = @ReceiverId

	IF (@@ROWCOUNT <> 1)
	BEGIN
		ROLLBACK
		RAISERROR ('Invalid AcccountId', 16, 2)
	END

	DECLARE @FinalAmount DECIMAL(15,4) = (SELECT Balance FROM Accounts WHERE Id = @SenderId)
	IF (@FinalAmount < 0)
	BEGIN
		ROLLBACK
		RAISERROR ('Insuffiecient Funds!', 16, 3)
		RETURN
	END

	COMMIT
END

--6. *Massive Shopping
BEGIN TRANSACTION

DECLARE @ItemSum DECIMAL = (SELECT SUM(i.Price)
					      FROM Items AS i
						 WHERE MinLevel BETWEEN 11 AND 12)

IF(SELECT Cash FROM UsersGames WHERE Id = 110) < @ItemSum
BEGIN
   ROLLBACK
END
ELSE 
BEGIN
	UPDATE UsersGames
	   SET Cash -= @ItemSum
	 WHERE Id = 110

INSERT INTO UserGameItems (UserGameId, ItemId)
	 SELECT 110, Id 
	   FROM Items 
	  WHERE MinLevel BETWEEN 11 AND 12
	 COMMIT
END

BEGIN TRANSACTION

DECLARE @ItemSum2 DECIMAL = (SELECT SUM(i.Price)
						   FROM Items i
						  WHERE MinLevel BETWEEN 19 AND 21)

IF (SELECT Cash FROM UsersGames WHERE Id = 110) < @ItemSum2
BEGIN
	ROLLBACK
END
ELSE 
BEGIN
	UPDATE UsersGames
	   SET Cash = Cash - @ItemSum2
	 WHERE Id = 110

INSERT INTO UserGameItems (UserGameId, ItemId)
     SELECT 110, Id 
	   FROM Items 
	  WHERE MinLevel BETWEEN 19 AND 21
	 COMMIT
END

SELECT i.Name AS [Item Name] 
  FROM UserGameItems ugi
  JOIN Items i ON ugi.ItemId = i.Id
WHERE ugi.UserGameId = 110

--7. Employees with Three Projects
CREATE PROC usp_AssignProject(@EmployeeID INT, @ProjectID INT)
AS 
BEGIN
	DECLARE @EmployeeProjectCount INT = (SELECT COUNT(*) 
										   FROM EmployeesProjects
										  WHERE EmployeeID = @EmployeeID)
	IF (@EmployeeProjectCount >= 3)
	BEGIN
		RAISERROR('The employee has too many projects!', 16, 1)
		ROLLBACK
	END

	INSERT INTO EmployeesProjects (EmployeeID, ProjectID)
	VALUES (@EmployeeID, @ProjectID)

END

--8. Delete Employees
CREATE TRIGGER tr_RecordDeletedEmployees 
ON Employees 
AFTER DELETE
AS
BEGIN
	INSERT INTO Deleted_Employees(FirstName, LastName, MiddleName, JobTitle, DepartmentId, Salary)
	SELECT d.FirstName, d.LastName, d.MiddleName, d.JobTitle, d.DepartmentID, d.Salary 
	  FROM deleted AS d
END