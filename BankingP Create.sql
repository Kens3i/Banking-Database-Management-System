--CREATE DATABASE BankingDB;
--USE BankingDB;

-- Creating Customers table
CREATE TABLE Customers (
    CustomerID INT CONSTRAINT PK_Customers_CustomerID PRIMARY KEY IDENTITY(1,1),
    FirstName VARCHAR(50),
    LastName VARCHAR(50),
    DateOfBirth DATE,
    Email VARCHAR(100) CONSTRAINT UQ_Customers_Email UNIQUE,
    PhoneNumber VARCHAR(15),
    Address VARCHAR(255)
);



-- Creating Accounts table
CREATE TABLE Accounts (
    AccountID INT CONSTRAINT PK_Accounts_AccountID PRIMARY KEY IDENTITY(1,1),
    CustomerID INT CONSTRAINT FK_Accounts_CustomerID FOREIGN KEY REFERENCES Customers(CustomerID),
    AccountType VARCHAR(20),
    Balance DECIMAL(18, 2),
    CreatedDate DATE
);



-- Creating Transactions table
CREATE TABLE Transactions (
    TransactionID INT CONSTRAINT PK_Transactions_TransactionID PRIMARY KEY IDENTITY(1,1),
    AccountID INT CONSTRAINT FK_Transactions_AccountID FOREIGN KEY REFERENCES Accounts(AccountID),
    TransactionType VARCHAR(20),
    Amount DECIMAL(18, 2),
    TransactionDate DATE,
    Description VARCHAR(255)
);



-- Creating Loans table
CREATE TABLE Loans (
    LoanID INT CONSTRAINT PK_Loans_LoanID PRIMARY KEY IDENTITY(1,1),
    CustomerID INT CONSTRAINT FK_Loans_CustomerID FOREIGN KEY REFERENCES Customers(CustomerID),
    LoanAmount DECIMAL(18, 2),
    InterestRate DECIMAL(5, 2),
    StartDate DATE,
    EndDate DATE
);


-- Creating Logs table which will store data after Trigger execution(if changes happennes in transaction table)
CREATE TABLE AccountBalanceLogs (
    LogID INT CONSTRAINT PK_AccountBalanceLogs_LogID PRIMARY KEY IDENTITY(1,1),
    AccountID INT,
    OldBalance DECIMAL(18, 2),
    NewBalance DECIMAL(18, 2),
    ChangeDate DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (AccountID) REFERENCES Accounts(AccountID)
);
