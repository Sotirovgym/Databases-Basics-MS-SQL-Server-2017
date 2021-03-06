Use SoftUni -- DO NOT submit in judge The Use SoftUni statement or you will get compile time error.
--01. Employee Address
SELECT TOP 5 EmployeeID, JobTitle, e.AddressID, Addresses.AddressText FROM Employees as e
JOIN Addresses ON e.AddressID = Addresses.AddressID
ORDER BY e.AddressID

--02. Addresses with Towns
SELECT TOP 50 FirstName, LastName, t.Name, a.AddressText FROM Employees as e
JOIN  Addresses AS a ON e.AddressID = a.AddressID 
JOIN Towns as t ON a.TownID = t.TownID
ORDER BY e.FirstName, e.LastName

--03. Sales Employee
SELECT EmployeeID, FirstName, LastName, d.Name FROM Employees as e
JOIN Departments as d ON e.DepartmentID = d.DepartmentID
WHERE d.Name = 'Sales'
ORDER BY EmployeeID

--04.Employee Departments
SELECT TOP 5 e.EmployeeID, e.FirstName, e.Salary, d.Name AS DepartmentName FROM Employees AS e
JOIN Departments AS d ON e.DepartmentID = d.DepartmentID
WHERE e.Salary > 15000
ORDER BY d.DepartmentID

--05. Employees Without Projects
SELECT TOP 3 e.EmployeeID, e.FirstName FROM Employees AS e
LEFT JOIN EmployeesProjects AS p ON p.EmployeeID = e.EmployeeID
WHERE p.EmployeeID IS NULL
ORDER BY p.EmployeeID

--06. Employees Hired After
SELECT FirstName, LastName, HireDate, d.Name AS DeptName FROM Employees as e 
JOIN Departments AS d ON e.DepartmentID = d.DepartmentID
WHERE (d.Name = 'Finance' OR d.Name = 'Sales') AND e.HireDate > '1999-01-01'
ORDER BY e.HireDate

--07. Employees with Project
SELECT TOP 5 e.EmployeeID, FirstName, p.Name AS ProjectName FROM Employees AS e
JOIN EmployeesProjects AS ep ON ep.EmployeeID = e.EmployeeID
JOIN Projects AS p ON p.ProjectID = ep.ProjectID
WHERE p.StartDate > '2002-08-13' AND p.EndDate IS NULL
ORDER BY e.EmployeeID

--08. Employee 24
SELECT e.EmployeeID, FirstName, 
IIF(p.StartDate > '2005-01-01', NULL, p.Name) AS ProjectName
FROM Employees AS e
JOIN EmployeesProjects AS ep ON ep.EmployeeID = e.EmployeeID
JOIN Projects AS p ON p.ProjectID = ep.ProjectID
WHERE e.EmployeeID = 24

--09. Employee Manager
SELECT e.EmployeeID, e.FirstName, e.ManagerID, ep.FirstName FROM Employees AS e
JOIN Employees AS ep ON ep.EmployeeID = e.ManagerID
WHERE e.ManagerID IN (3,7)
ORDER BY e.EmployeeID

--10. Employee Summary
SELECT TOP 50 e.EmployeeID, e.FirstName + ' ' + e.LastName AS EmployeeName, 
ep.FirstName + ' ' + ep.LastName AS ManagerName, 
d.Name FROM Employees AS e
JOIN Employees as ep ON ep.EmployeeID = e.ManagerID
JOIN Departments AS d ON d.DepartmentID = e.DepartmentID
ORDER BY e.EmployeeID

--11. Min Average Salary
SELECT TOP 1 AVG(Salary) AS MinAverageSalary
FROM Employees
GROUP BY DepartmentID
ORDER BY MinAverageSalary

--12. Highest Peaks in Bulgaria
Use Geography -- DO NOT submit in judge The Use Geography statement or you will get compile time error.

SELECT mc.CountryCode, m.MountainRange, p.PeakName, p.Elevation FROM MountainsCountries AS mc
JOIN Mountains AS m ON m.Id = mc.MountainId
JOIN Peaks AS p ON P.MountainId = mc.MountainId
WHERE mc.CountryCode = 'BG' AND p.Elevation > 2835
ORDER BY p.Elevation DESC

--13. Count Mountain Ranges
SELECT CountryCode, COUNT(MountainId) AS MountainRanges FROM MountainsCountries
WHERE CountryCode IN ('US', 'RU', 'BG')
GROUP BY CountryCode

--14. Countries with Rivers
SELECT TOP 5 c.CountryName, r.RiverName
FROM Countries AS c
JOIN Continents AS cont ON cont.ContinentCode = c.ContinentCode
LEFT JOIN CountriesRivers AS cr ON cr.CountryCode = c.CountryCode
LEFT JOIN Rivers AS r ON r.Id = cr.RiverId
WHERE cont.ContinentName = 'Africa'
ORDER BY c.CountryName

--15. Continets and Most Used Currencies
 SELECT cur.ContinentCode, cur.CurrencyCode, cur.CurrencyUsage
   FROM 
(SELECT ContinentCode, CurrencyCode, COUNT(*) AS CurrencyUsage,
  DENSE_RANK() OVER (PARTITION BY ContinentCode ORDER BY COUNT(*) DESC) AS [Rank]
   FROM Countries
  GROUP BY CurrencyCode, ContinentCode
 HAVING COUNT(*) > 1) AS cur
  WHERE cur.Rank = 1

--16. Countries without any Mountains
SELECT
  COUNT(c.CountryCode) AS CountryCode
FROM Countries AS c
LEFT JOIN MountainsCountries AS m ON c.CountryCode = m.CountryCode
WHERE m.MountainId IS NULL

--17. Highest Peak and Longest River by Country
SELECT TOP 5 c.CountryName,
  MAX(p.Elevation) AS HighestPeakElevation,
  MAX(r.Length) AS LongestRiverLength
FROM Countries AS c
  LEFT JOIN MountainsCountries AS mc ON c.CountryCode = mc.CountryCode
  LEFT JOIN Peaks AS p ON p.MountainId = mc.MountainId
  LEFT JOIN CountriesRivers AS cr ON c.CountryCode = cr.CountryCode
  LEFT JOIN Rivers AS r ON r.Id = cr.RiverId
GROUP BY c.CountryName
ORDER BY HighestPeakElevation DESC, LongestRiverLength DESC, c.CountryName

--18. Highest Peak Name and Elevation by Country
SELECT TOP 5 c.CountryName AS [Country],
       CASE WHEN p.PeakName IS NULL THEN '(no highest peak)' ELSE p.PeakName END AS [HighestPeakName],
	   CASE WHEN p.Elevation IS NULL THEN 0 ELSE MAX(p.Elevation) END AS [HighestPeakElevation],
	   CASE WHEN m.MountainRange IS NULL THEN '(no mountain)' ELSE m.MountainRange END AS [Mountain]
  FROM Countries AS c
  LEFT OUTER JOIN MountainsCountries AS mc ON mc.CountryCode = c.CountryCode
  LEFT OUTER JOIN Mountains AS m ON m.Id = mc.MountainId
  LEFT OUTER JOIN Peaks AS p ON p.MountainId = m.Id
  GROUP BY c.CountryName, p.PeakName, p.Elevation, m.MountainRange
  ORDER BY c.CountryName, p.PeakName