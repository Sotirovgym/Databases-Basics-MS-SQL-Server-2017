--1. Employees with Salary Above 35000
CREATE PROCEDURE usp_GetEmployeesSalaryAbove35000
AS
BEGIN
	SELECT FirstName, LastName 
	  FROM Employees
	 WHERE Salary > 35000
END

--2. Employees with Salary Above Number
CREATE PROCEDURE usp_GetEmployeesSalaryAboveNumber @Number DECIMAL(18,4)
AS
BEGIN
	SELECT FirstName, LastName FROM Employees
	WHERE Salary >= @Number
END

--3. Town Names Starting With
CREATE PROC usp_GetTownsStartingWith @Parameter NVARCHAR(50)
AS
BEGIN
	SELECT Name AS Town
	  FROM Towns
	 WHERE LEFT(Name, LEN(@Parameter)) = @Parameter
END

--4. Employees from Town
CREATE PROC usp_GetEmployeesFromTown @TownName NVARCHAR(50)
AS
BEGIN
	SELECT FirstName, LastName 
	  FROM Employees AS e
	 INNER JOIN Addresses AS a ON a.AddressID = e.AddressID
	 INNER JOIN Towns AS t ON t.TownID = a.TownID
	 WHERE t.Name LIKE @TownName
END

--5. Salary Level Function
CREATE FUNCTION ufn_GetSalaryLevel(@Salary DECIMAL(18,4))
RETURNS VARCHAR(10)
AS
BEGIN
	DECLARE @SalaryLevel VARCHAR(10) =
	CASE
	WHEN @Salary < 30000 THEN 'Low'
	WHEN @Salary BETWEEN 30000 AND 50000 THEN 'Average'
	WHEN @Salary > 50000 THEN 'High'
    END

	RETURN @SalaryLevel
END

--6. Employees by Salary Level
CREATE PROC usp_EmployeesBySalaryLevel @LevelOfSalary VARCHAR(10)
AS
BEGIN
	SELECT lvl.FirstName, lvl.LastName FROM
	(SELECT FirstName,
	       LastName,
		   dbo.ufn_GetSalaryLevel(Salary) AS SalaryLevel 
	  FROM Employees
	  WHERE dbo.ufn_GetSalaryLevel(Salary) = @LevelOfSalary) AS lvl
END

--7. Define Function
CREATE FUNCTION ufn_IsWordComprised(@SetOfLetters VARCHAR(MAX), @Word VARCHAR(MAX))
RETURNS BIT
AS
BEGIN
	DECLARE @Length INT = LEN(@Word);
	DECLARE @LetterIndex INT = 1;
	DECLARE @IsComprised BIT = 0;
	DECLARE @CurrentChar CHAR;
	WHILE (@Length > 0)
	BEGIN
		SET @CurrentChar = SUBSTRING(@Word, @LetterIndex, 1)
		IF (CHARINDEX(@CurrentChar, @SetOfLetters) = 0)
		BEGIN
			SET @IsComprised = 0;
			RETURN @IsComprised
		END
		SET @Length -= 1;
		SET @LetterIndex += 1;
	END

	RETURN @IsComprised + 1	
END

--8. Delete Employees and Departments
CREATE PROC usp_DeleteEmployeesFromDepartment (@departmentId INT)
AS
BEGIN
	ALTER TABLE Departments
	ALTER COLUMN ManagerID INT NULL

	DELETE FROM EmployeesProjects
	 WHERE EmployeeID IN (SELECT EmployeeID
	                        FROM Employees
						   WHERE DepartmentID = @departmentId) 

	UPDATE Employees
	SET ManagerID = NULL
	WHERE ManagerID IN (SELECT EmployeeID
	                      FROM Employees
						 WHERE DepartmentID = @departmentId)

    UPDATE Departments
	SET ManagerID = NULL
	WHERE ManagerID IN (SELECT EmployeeID
	                          FROM Employees
						     WHERE DepartmentID = @departmentId)

	DELETE FROM Employees
	WHERE EmployeeID IN (SELECT EmployeeID
	                       FROM Employees
						  WHERE DepartmentID = @departmentId)
   
   DELETE FROM Departments
   WHERE DepartmentID = @departmentId

	SELECT COUNT(*) AS NumberOfEmployees FROM Employees AS e
	 INNER JOIN Departments AS d ON d.DepartmentID = e.DepartmentID
	 WHERE e.DepartmentID = @departmentId
END

--9. Find Full Name
CREATE PROC usp_GetHoldersFullName
AS
BEGIN
	SELECT FirstName + ' ' + LastName AS [Full Name]
	  FROM AccountHolders
END

--10. People with Balance Higher Than
CREATE PROC usp_GetHoldersWithBalanceHigherThan (@number MONEY)
AS
BEGIN
	SELECT FirstName, LastName FROM
	   (SELECT FirstName, LastName, SUM(acc.Balance) AS TotalSum
		  FROM AccountHolders AS ah
		 INNER JOIN Accounts AS acc ON acc.AccountHolderId = ah.Id
		 GROUP BY ah.FirstName, ah.LastName) AS PeopleWIthMoreMoneyThanNumber
	WHERE TotalSum > @number
END

--11. Future Value Function
CREATE FUNCTION ufn_CalculateFutureValue (@sum MONEY, @yearlyInterestRate DECIMAL(18,4), @numberOfYears INT)
RETURNS DECIMAL(18,4)
AS
BEGIN
	DECLARE @FinalSum DECIMAL(18,4);
	WHILE(@numberOfYears > 0)
	BEGIN
		SET @FinalSum = (@sum * @yearlyInterestRate) + @sum;
		SET @sum = @FinalSum;
		SET @numberOfYears -= 1;
	END
	RETURN @FinalSum
END

--12. Calculating Interest
CREATE PROC usp_CalculateFutureValueForAccount (@accountId INT, @interestRate DECIMAL(18,4))
AS
BEGIN
	SELECT ah.Id AS [Account Id],
	       ah.FirstName,
		   ah.LastName,
		   acc.Balance AS CurrentBalance,
		   dbo.ufn_CalculateFutureValue(acc.Balance, @interestRate, 5) AS [Balance in 5 years]
      FROM AccountHolders AS ah
	 INNER JOIN Accounts AS acc ON acc.AccountHolderId = ah.Id
	 WHERE acc.Id = @accountId
END

--13. *Cash in User Games Odd Rows
CREATE FUNCTION ufn_CashInUsersGames (@gameName NVARCHAR(100))
RETURNS TABLE
AS
RETURN (
    WITH CTE_CashInRows (Cash, RowNumber) AS (
    SELECT ug.Cash, ROW_NUMBER() OVER (ORDER BY ug.Cash DESC)
    FROM UsersGames AS ug
    JOIN Games AS g ON ug.GameId = g.Id
    WHERE g.Name = @gameName
  )
  SELECT SUM(Cash) AS SumCash
  FROM CTE_CashInRows
  WHERE RowNumber % 2 = 1)