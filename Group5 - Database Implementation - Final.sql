CREATE DATABASE Group_5_Project;
GO
USE Group_5_Project;

CREATE TABLE Customers
	(
	CustomerID INT NOT NULL PRIMARY KEY,
	CustomerFirstName VARCHAR(20) NOT NULL,
	CustomerLastName VARCHAR(20) NOT NULL,
	CustomerStreetAddress VARCHAR(500),
	CustomerCity VARCHAR(20),
	CustomerState VARCHAR(2),
	CustomerZipCode VARCHAR(5),
	CustomerEmail VARCHAR(50) NOT NULL,
	CustomerPhoneNo VARCHAR(10) NOT NULL
	);

CREATE MASTER KEY
ENCRYPTION BY PASSWORD = 'group5P@ssword';

CREATE TABLE Accounts
	(
	AccountID INT NOT NULL PRIMARY KEY,
	CustomerID INT NOT NULL REFERENCES Customers(CustomerID),
	UserName VARCHAR(20) NOT NULL,
	Password VARBINARY(250) NOT NULL
	);

CREATE CERTIFICATE Group5TestCertificate
WITH SUBJECT = 'Protect Customers data'
GO

CREATE SYMMETRIC KEY TestSymmetricKey 
WITH ALGORITHM = AES_256 
ENCRYPTION BY CERTIFICATE Group5TestCertificate
GO 

OPEN SYMMETRIC KEY TestSymmetricKey
DECRYPTION BY CERTIFICATE Group5TestCertificate
INSERT INTO Accounts VALUES
('133090','65667','12huituziasd' , EncryptByKey(KEY_GUID(N'testingSymmetricKey2'), convert(varbinary, '65com1244'))),
('133999','12567','asd1234dfs' , EncryptByKey(KEY_GUID(N'testingSymmetricKey2'), 'Liu12768*')),
('234667','34536','1826385gksl' , EncryptByKey(KEY_GUID(N'testingSymmetricKey2'), '!2345%67')),
('238990','12662','091awwwds' , EncryptByKey(KEY_GUID(N'testingSymmetricKey2'), '09578%Hus')),
('245899','27362','adwords129' , EncryptByKey(KEY_GUID(N'testingSymmetricKey2'), '123@asffew')),
('133999','12567','asd1234dfs' , EncryptByKey(KEY_GUID(N'testingSymmetricKey2'), 'Liu12768*')),
('234667','34536','1826385gksl' , EncryptByKey(KEY_GUID(N'testingSymmetricKey2'), '!2345%67')),
('238990','12662','091awwwds' , EncryptByKey(KEY_GUID(N'testingSymmetricKey2'), '09578%Hus')),
('245899','27362','adwords129' , EncryptByKey(KEY_GUID(N'testingSymmetricKey2'), '123@asffew'));

SELECT * FROM Accounts;
	
CREATE TABLE PaymentMethods
	(
	PaymentMethodID INT NOT NULL PRIMARY KEY,
	AccountID INT NOT NULL REFERENCES Accounts(AccountID),
	CardType VARCHAR(10) NOT NULL,
	CardNumber VARCHAR(16) NOT NULL,
	FirstNameOnCard VARCHAR(20) NOT NULL,
	LastNameOnCard VARCHAR(20) NOT NULL,
	CardExpirationDate DATE NOT NULL,
	CVV VARCHAR(4) NOT NULL,
	BillingStreetAddress VARCHAR(50) NOT NULL,
	BillingCity VARCHAR(20) NOT NULL,
	BillingState VARCHAR(2) NOT NULL,
	BillingZipCode VARCHAR(5) NOT NULL,
	BillingPhoneNo VARCHAR(10) NOT NULL
	);

CREATE FUNCTION CheckCardValid (@ExpirationDate DATE)
RETURNS SMALLINT
AS
BEGIN
	DECLARE @IfValid SMALLINT = 0;
	IF YEAR(@ExpirationDate) > YEAR(GETDATE()) 
		SET @IfValid = 1;
	IF YEAR(@ExpirationDate) = YEAR(GETDATE()) AND MONTH(@ExpirationDate) > MONTH(GETDATE())
		SET @IfValid = 1;
	RETURN @IfValid;
END;

ALTER TABLE PaymentMethods ADD CONSTRAINT BanExpiredCard CHECK (dbo.CheckCardValid(CardExpirationDate) = 1);
	
CREATE TABLE ProductionCompanies
	(
	ProductionCompanyID INT NOT NULL PRIMARY KEY,
	CompanyName VARCHAR(50) NOT NULL,
	CompanyDescription VARCHAR(500)
	);
	
CREATE TABLE Countries
	(
	CountryID INT NOT NULL PRIMARY KEY,
	CountryName VARCHAR(20) NOT NULL,
	Continent VARCHAR(13) NOT NULL,
	CountryDescription VARCHAR(500)
	);

CREATE TABLE Directors
	(
	DirectorID INT NOT NULL PRIMARY KEY,
	DirectorFirstName VARCHAR(20) NOT NULL,
	DirectorLastName VARCHAR(20) NOT NULL,
	DirectorGender VARCHAR(6) NOT NULL,
	DirectorBirthday DATE NOT NULL,
	CountryID INT NOT NULL REFERENCES Countries(CountryID),
	DirectorDescription VARCHAR(500)
	);

CREATE TABLE Movies
	(
	MovieID INT NOT NULL PRIMARY KEY,
	MovieName VARCHAR(100) NOT NULL,
	Price MONEY NOT NULL,
	DirectorID INT NOT NULL REFERENCES Directors(DirectorID),
	CountryID INT NOT NULL REFERENCES Countries(CountryID),
	ProductionCompanyID INT NOT NULL REFERENCES ProductionCompanies(ProductionCompanyID),
	MovieLanguage VARCHAR(20) NOT NULL,
	ReleaseYear VARCHAR(4) NOT NULL,
	Duration VARCHAR(5) NOT NULL,
	Rating VARCHAR(5) NOT NULL,
	MovieDescription VARCHAR(500),
	OrderTimes INT NOT NULL
	);

CREATE TABLE Actors
	(
	ActorID INT NOT NULL PRIMARY KEY,
	ActorFirstName VARCHAR(20) NOT NULL,
	ActorLastName VARCHAR(20) NOT NULL,
	ActorGender VARCHAR(6) NOT NULL,
	ActorBirthday DATE NOT NULL,
	CountryID INT NOT NULL REFERENCES Countries(CountryID),
	ActorDescription VARCHAR(500)
	);
	
CREATE TABLE Genres
	(
	GenreID INT NOT NULL PRIMARY KEY,
	GenreName VARCHAR(50) NOT NULL,
	GenreDescription VARCHAR(500)
	);

CREATE TABLE MovieActorDetails
	(
	MovieID INT NOT NULL REFERENCES Movies(MovieID),
	ActorID INT NOT NULL REFERENCES Actors(ActorID),
	CONSTRAINT PKMovieActorDetails PRIMARY KEY CLUSTERED
		(MovieID, ActorID)
	);
	
CREATE TABLE MovieGenreDetails
	(
	MovieID INT NOT NULL REFERENCES Movies(MovieID),
	GenreID INT NOT NULL REFERENCES Genres(GenreID),
	CONSTRAINT PKMovieGenreDetails PRIMARY KEY CLUSTERED
		(MovieID, GenreID)
	);
	
CREATE TABLE MovieOrders
	(
	OrderID INT NOT NULL PRIMARY KEY,
	AccountID INT NOT NULL REFERENCES Accounts(AccountID),
	MovieID INT NOT NULL REFERENCES Movies(MovieID),
	OrderDate DATE NOT NULL,
	StartDate DATE NOT NULL
	);

CREATE FUNCTION CalExpDate(@StartDate DATE)
RETURNS DATE
AS
BEGIN
	DECLARE @EndDate DATE = DATEADD(dd, 30, @StartDate);
	RETURN @EndDate;
END;

ALTER TABLE ADD COLUMN ExpirationDate AS dbo.CalExpDate(StartDate);

CREATE FUNCTION CheckStartDate(@StartDate DATE, @OrderDate DATE)
RETURNS SMALLINT
AS
BEGIN
	DECLARE @IfValid SMALLINT = 1;
	IF @StartDate < @OrderDate 
		SET @IfValid = 0;
	RETURN @IfValid;
END;

ALTER TABLE MovieOrders ADD CONSTRAINT BanInvalidDate CHECK (dbo.CheckStartDate(StartDate, OrderDate) = 1);

CREATE TABLE Payments
	(
	PaymentID INT NOT NULL PRIMARY KEY,
	PaymentMethodID INT NOT NULL REFERENCES PaymentMethods(PaymentMethodID),
	OrderID INT NOT NULL REFERENCES MovieOrders(OrderID),
	PaymentDate DATE NOT NULL
	);

CREATE FUNCTION CalPaymentAmount(@OrderID INT)
RETURNS MONEY
AS
BEGIN
	DECLARE @Amount MONEY = (
	SELECT m.Price
	FROM Movies m
	INNER JOIN MovieOrders mo
	ON m.MovieID = mo.MovieID
	WHERE mo.OrderID = @OrderID
	);
	RETURN @Amount;
END;

ALTER TABLE Payments ADD COLUMN PaymentAmount AS dbo.CalPaymentAmount(OrderID);

CREATE VIEW ViewCustomerOrders
AS
	SELECT c.CustomerID, c.CustomerFirstName, c.CustomerLastName, COUNT(mo.OrderID) AS OrderAmount,
	STUFF(
 	(SELECT ', ' + m.MovieName 
 	FROM Movies m
 	INNER JOIN MovieOrders mos
 	ON mos.MovieID = m.MovieID 
 	INNER JOIN Accounts acs
 	ON acs.AccountID = mos.AccountID
 	WHERE acs.CustomerID = c.CustomerID 
 	FOR XML PATH('')
 	), 1, 2, '') OrderedMovies
	FROM Customers c
	INNER JOIN Accounts a
	ON a.CustomerID = c.CustomerID
	INNER JOIN MovieOrders mo
	ON mo.AccountID = a.AccountID 
	GROUP BY c.CustomerID, c.CustomerFirstName, c.CustomerLastName;

SELECT * FROM ViewCustomerOrders;

CREATE VIEW ViewMovieMonthIncomes
AS
	SELECT YEAR(mo.OrderDate) AS OrderYear, MONTH(mo.OrderDate) AS OrderMonth, m.MovieName, (temp.Amount * m.Price) AS SalesAmount
	FROM MovieOrders mo
	INNER JOIN Movies m
	ON mo.MovieID = m.MovieID
	INNER JOIN 
	(
	SELECT YEAR(mos.OrderDate) AS OrderYear, MONTH(mos.OrderDate) AS OrderMonth, ms.MovieName, COUNT(mos.OrderID) AS Amount
	FROM MovieOrders mos
	INNER JOIN Movies ms
	ON mos.MovieID = ms.MovieID
	GROUP BY YEAR(mos.OrderDate), MONTH(mos.OrderDate), ms.MovieName
	) AS temp
	ON temp.OrderYear = YEAR(mo.OrderDate) AND temp.OrderMonth = MONTH(mo.OrderDate) AND temp.MovieName = m.MovieName;

SELECT * FROM ViewMovieMonthIncomes;

USE AdventureWorks2008R2;
DROP DATABASE Group_5_Project;
