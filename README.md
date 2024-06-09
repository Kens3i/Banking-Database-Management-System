#  Banking Database Management System 💳
## Powered by MS SQL Server and T-SQL

![](https://media0.giphy.com/media/v1.Y2lkPTc5MGI3NjExb2sybnZteXBpZHNvNGhhNmd3NWt0ZG5sYjlrZWNwajdsa3F4dXk1aiZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/Mzzes97FZRgbq4JhZW/giphy.webp)

## Table of Contents

1. [Overview](#overview) 
2. [Motivation](#motivation) 
3. [Functionalities Used](#functionalities-used)
4.  [Workflow](#workflow) 
5.  [Execution with Screenshots](#execution-with-screenshots) 

## Overview

This project demonstrates a comprehensive approach to designing and implementing a banking-related database system in MS SQL Server. The system includes:

- Database schema design
- Table creation
- Data insertion
- Function and stored procedure creation
- Indexes and views
- Transaction and trigger implementation
- Security considerations

## Motivation

The primary motivation behind this project is to create a robust and scalable database system for managing banking operations. The system aims to:

- Provide a structured approach to handle customer and account data.
- Ensure data integrity and security.
- Facilitate efficient transaction processing.
- Support financial operations such as deposits, withdrawals, and loan management.
- Offer a foundation for future enhancements and integration with other banking software.


## Functionalities Used

This project leverages various functionalities in MS SQL Server to achieve its objectives, including:

- **Database Creation and Table Design**: Defining tables and their relationships.
- **Data Manipulation**: Inserting, updating, and deleting data.
- **Functions and Stored Procedures**: Encapsulating business logic.
- **Indexes**: Optimizing query performance.
- **Views**: Simplifying data access for reporting.
- **Transactions and Triggers**: Ensuring atomic operations and automatic actions.
- **Security**: Implementing role-based access control.

## Workflow

The project workflow involves several key steps:

### Step 1: Database Schema Design

The first step is to plan the structure of the database. The schema includes tables for Customers, Accounts, Transactions, Loans, and Employees.

#### Customers
**Purpose:** Stores information about the bank's customers.

**Columns:**
- **CustomerID:** Unique identifier for each customer.
- **FirstName, LastName:** Personal details of the customer.
- **DateOfBirth:** For identifying customers and age-based services.
- **Email, PhoneNumber:** Contact details for communication.
- **Address:** Residential address of the customer.

#### Accounts
**Purpose:** Stores information about customer accounts.

**Columns:**
- **AccountID:** Unique identifier for each account.
- **CustomerID:** Links the account to a customer.
- **AccountType:** Specifies the type of account (e.g., Savings, Checking).
- **Balance:** Current balance in the account.
- **CreatedDate:** Date the account was created.

#### Transactions
**Purpose:** Logs all transactions made on the accounts.

**Columns:**
- **TransactionID:** Unique identifier for each transaction.
- **AccountID:** Links the transaction to an account.
- **TransactionType:** Type of transaction (e.g., Deposit, Withdrawal, Transfer).
- **Amount:** Amount of money involved in the transaction.
- **TransactionDate:** Date and time of the transaction.
- **Description:** Additional information about the transaction.

#### Loans
**Purpose:** Stores information about loans taken by customers.

**Columns:**
- **LoanID:** Unique identifier for each loan.
- **CustomerID:** Links the loan to a customer.
- **LoanAmount:** Principal amount of the loan.
- **InterestRate:** Interest rate applied to the loan.
- **StartDate, EndDate:** Duration of the loan.

### Step 2: Creating Tables
We begin by creating the necessary tables with appropriate constraints.
```sql
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

-- Creating Logs table which will store data after Trigger execution (if changes happen in the transaction table)
CREATE TABLE AccountBalanceLogs (
    LogID INT CONSTRAINT PK_AccountBalanceLogs_LogID PRIMARY KEY IDENTITY(1,1),
    AccountID INT,
    OldBalance DECIMAL(18, 2),
    NewBalance DECIMAL(18, 2),
    ChangeDate DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (AccountID) REFERENCES Accounts(AccountID)
);
```
### Step 3: Creating Functions

#### Function to Calculate Loan Interest based on the loan ID and the end date

- **Loan Details Retrieval**: Fetches the loan amount, interest rate, and start date from the `Loans` table using the provided `LoanID`.
- **Date Difference Calculation**: Computes the number of days between the loan start date and the provided end date using the `DATEDIFF` function.
- **Interest Calculation**: Calculates interest using the formula:
  - `Interest = LoanAmount * (InterestRate / 100) * (Days / 365.0)`
- **Return Value**: Returns the calculated interest as a `DECIMAL(18, 2)`, ensuring precision up to two decimal places.
- **Error Handling**: Assumes the `LoanID` exists in the `Loans` table. If not, the function returns `NULL` due to the absence of matching records.

```sql
CREATE FUNCTION CalculateLoanInterest(@LoanID INT, @EndDate DATE)
RETURNS DECIMAL(18, 2)
AS
BEGIN
    -- Declare variables to store loan details and calculated values
    DECLARE @LoanAmount DECIMAL(18, 2); -- Variable to store the loan amount
    DECLARE @InterestRate DECIMAL(5, 2); -- Variable to store the interest rate
    DECLARE @StartDate DATE; -- Variable to store the start date of the loan
    DECLARE @Interest DECIMAL(18, 2); -- Variable to store the calculated interest
    DECLARE @Days INT; -- Variable to store the number of days between the start date and end date

    -- Select loan details from the Loans table based on the provided LoanID
    SELECT
        @LoanAmount = LoanAmount, -- Get the loan amount
        @InterestRate = InterestRate, -- Get the interest rate
        @StartDate = StartDate -- Get the start date of the loan
    FROM Loans
    WHERE LoanID = @LoanID;

    -- Calculate the number of days between the start date and end date
    SET @Days = DATEDIFF(DAY, @StartDate, @EndDate);

    -- Calculate the interest
    -- Formula: Interest = LoanAmount * (InterestRate / 100) * (Days / 365.0)
    SET @Interest = @LoanAmount * (@InterestRate / 100) * (@Days / 365.0);

    -- Return the calculated interest
    RETURN @Interest;
END;
```

### Step 4: Creating Stored Procedures

#### Stored Procedure to Add a New Customer

```sql
CREATE PROCEDURE AddCustomer
    @FirstName VARCHAR(50),
    @LastName VARCHAR(50),
    @DateOfBirth DATE,
    @Email VARCHAR(100),
    @PhoneNumber VARCHAR(15),
    @Address VARCHAR(255)
AS
BEGIN
    INSERT INTO Customers (FirstName, LastName, DateOfBirth, Email, PhoneNumber, Address)
    VALUES (@FirstName, @LastName, @DateOfBirth, @Email, @PhoneNumber, @Address);
END;
```

#### Stored Procedure to Add a Transaction

- **Handles Both Deposits and Withdrawals**: Ensures that both deposit and withdrawal transactions are properly managed.

- **Loan Management**:
  - **Deposits**: Checks for outstanding loans, calculates interest, and repays the loan fully or partially based on the deposit amount.
  - **Withdrawals**: If the withdrawal amount exceeds the current balance, the negative balance is recorded as a loan.

- **Interest Calculation**: Utilizes the `CalculateLoanInterest` function to compute the interest on the loan up to the transaction date.

- **Balance Updates**:
  - **Deposits**: Updates the account balance after repaying any outstanding loan.
  - **Withdrawals**: Adjusts the account balance and creates or updates a loan if the balance becomes negative.

- **Transaction Logging**: Inserts transaction details into the `Transactions` table for record-keeping.

- **Flexible and Comprehensive**: Designed to handle complex scenarios involving deposits, withdrawals, and loans, ensuring accurate and up-to-date financial records.



```sql
CREATE PROCEDURE AddTransaction
    @AccountID INT,
    @TransactionType VARCHAR(20),
    @Amount DECIMAL(18, 2),
    @TransactionDate DATE,
    @Description VARCHAR(255)
AS
BEGIN
    -- Declare variables to store necessary data
    DECLARE @CustomerID INT;
    DECLARE @LoanID INT;
    DECLARE @LoanAmount DECIMAL(18, 2);
    DECLARE @Interest DECIMAL(18, 2);
    DECLARE @TotalDue DECIMAL(18, 2);
    DECLARE @CurrentBalance DECIMAL(18, 2);
    DECLARE @NewLoanAmount DECIMAL(18, 2);

    -- Get the CustomerID from the Accounts table
    SELECT @CustomerID = CustomerID FROM Accounts WHERE AccountID = @AccountID;

    -- Handle deposit transactions
    IF @TransactionType = 'Deposit'
    BEGIN
        -- Check if the customer has an outstanding loan
        IF EXISTS (SELECT 1 FROM Loans WHERE CustomerID = @CustomerID AND LoanAmount > 0)
        BEGIN
            -- Get the loan details
            SELECT @LoanID = LoanID, @LoanAmount = LoanAmount FROM Loans WHERE CustomerID = @CustomerID;

            -- Calculate interest up to the deposit date
            SET @Interest = dbo.CalculateLoanInterest(@LoanID, @TransactionDate);
            SET @TotalDue = @LoanAmount + @Interest;

            -- Check if the deposit amount is enough to fully repay the loan
            IF @Amount >= @TotalDue
            BEGIN
                -- Fully repay the loan including interest
                UPDATE Loans
                SET LoanAmount = 0
                WHERE LoanID = @LoanID;

                -- Update the account balance with the remaining amount after repaying the loan
                UPDATE Accounts
                SET Balance = Balance + (@Amount - @TotalDue)
                WHERE AccountID = @AccountID;
            END
            ELSE
            BEGIN
                -- Partially repay the loan and the interest
                UPDATE Loans
                SET LoanAmount = @TotalDue - @Amount
                WHERE LoanID = @LoanID;

                -- Account balance remains unchanged
            END
        END
        ELSE
        BEGIN
            -- No outstanding loan, just update the account balance
            UPDATE Accounts
            SET Balance = Balance + @Amount
            WHERE AccountID = @AccountID;
        END
    END
    -- Handle withdrawal transactions
    ELSE IF @TransactionType = 'Withdrawal'
    BEGIN
        -- Get the current balance from the Accounts table
        SELECT @CurrentBalance = Balance FROM Accounts WHERE AccountID = @AccountID;

        -- Check if withdrawal exceeds current balance
        IF @CurrentBalance < @Amount
        BEGIN
            -- Calculate the new loan amount
            SET @NewLoanAmount = @Amount - @CurrentBalance;

            -- Check if the customer already has a loan
            IF EXISTS (SELECT 1 FROM Loans WHERE CustomerID = @CustomerID)
            BEGIN
                -- Update existing loan
                UPDATE Loans
                SET LoanAmount = LoanAmount + @NewLoanAmount
                WHERE CustomerID = @CustomerID;
            END
            ELSE
            BEGIN
                -- Create a new loan
                INSERT INTO Loans (CustomerID, LoanAmount, InterestRate, StartDate, EndDate)
                VALUES (@CustomerID, @NewLoanAmount, 5.0, @TransactionDate, DATEADD(YEAR, 1, @TransactionDate));
            END

            -- Update the account balance to zero
            UPDATE Accounts
            SET Balance = 0
            WHERE AccountID = @AccountID;
        END
        ELSE
        BEGIN
            -- Update the account balance
            UPDATE Accounts
            SET Balance = Balance - @Amount
            WHERE AccountID = @AccountID;
        END
    END

    -- Insert the transaction into the Transactions table
    INSERT INTO Transactions (AccountID, TransactionType, Amount, TransactionDate, Description)
    VALUES (@AccountID, @TransactionType, @Amount, @TransactionDate, @Description);
END;
```

### Step 5: Creating Indexes

``` sql
-- Create an index on CustomerID in the Accounts table
CREATE INDEX IDX_CustomerID ON Accounts(CustomerID);

-- Create an index on AccountID in the Transactions table
CREATE INDEX IDX_AccountID ON Transactions(AccountID);
```
**Purpose**: 
Improves the performance of queries that search for specific `CustomerID` in the `Accounts` table and `AccountID` in the `Transactions` table.

**Usage**: 
Speeds up data retrieval, particularly for large tables.

### Step 6: Creating View

```sql
-- View for Customer Account Summary
CREATE VIEW CustomerAccountSummary AS
SELECT 
    c.CustomerID,
    c.FirstName,
    c.LastName,
    a.AccountID,
    a.AccountType,
    a.Balance,
    a.CreatedDate
FROM 
    Customers c
JOIN 
    Accounts a ON c.CustomerID = a.CustomerID;
```

**Purpose**: 
Provides a consolidated view of customer accounts, combining data from the `Customers` and `Accounts` tables.
**Usage**: 
Simplifies reporting and querying for account summaries.

### Step 7: Implementing Transactions via Procedure
Facilitates transferring funds between accounts while managing loan adjustments and transaction logging.
- Handles both deposits and withdrawals.
- Manages loan adjustments if an account balance goes negative.
- Calculates interest using the CalculateLoanInterest function.
- Updates account balances accordingly.
- Logs transactions for both accounts involved in the transfer.
- Includes additional logic to handle loan repayment for a specific account (e.g., Alice).

```sql
-- Procedure to Transfer Funds Between Accounts
CREATE PROCEDURE TransferFunds
	@FromAccountID INT,
	@ToAccountID INT,
	@Amount DECIMAL(18, 2),
	@TransactionDate DATE
AS
BEGIN
	DECLARE @FromBalance DECIMAL(18, 2);
	DECLARE @ToBalance DECIMAL(18, 2);
	DECLARE @CustomerID INT;
	DECLARE @NewLoanAmount DECIMAL(18, 2);

	-- Get the balance of the from account
	SELECT @FromBalance = Balance FROM Accounts WHERE AccountID = @FromAccountID;

	-- Get the balance of the to account
	SELECT @ToBalance = Balance FROM Accounts WHERE AccountID = @ToAccountID;

	-- Check if the from account has sufficient funds
	IF @FromBalance < @Amount
	BEGIN
    	-- Calculate the new loan amount
    	SET @NewLoanAmount = @Amount - @FromBalance;

    	-- Get the CustomerID of the from account
    	SELECT @CustomerID = CustomerID FROM Accounts WHERE AccountID = @FromAccountID;

    	-- Check if the customer already has a loan
    	IF EXISTS (SELECT 1 FROM Loans WHERE CustomerID = @CustomerID)
    	BEGIN
        	-- Update existing loan and set new start date
        	UPDATE Loans
        	SET LoanAmount = LoanAmount + @NewLoanAmount,
            	StartDate = @TransactionDate
        	WHERE CustomerID = @CustomerID;
    	END
    	ELSE
    	BEGIN
        	-- Create a new loan
        	INSERT INTO Loans (CustomerID, LoanAmount, InterestRate, StartDate, EndDate)
        	VALUES (@CustomerID, @NewLoanAmount, 5.0, @TransactionDate, DATEADD(YEAR, 1, @TransactionDate));
    	END

    	-- Update the from account balance to zero
    	UPDATE Accounts
    	SET Balance = 0
    	WHERE AccountID = @FromAccountID;

    	-- Update the to account balance
    	UPDATE Accounts
    	SET Balance = Balance + @Amount
    	WHERE AccountID = @ToAccountID;
	END
	ELSE
	BEGIN
    	-- Update the from account balance
    	UPDATE Accounts
    	SET Balance = Balance - @Amount
    	WHERE AccountID = @FromAccountID;

    	-- Update the to account balance
    	UPDATE Accounts
    	SET Balance = Balance + @Amount
    	WHERE AccountID = @ToAccountID;
	END

	-- Insert transactions for both accounts
	INSERT INTO Transactions (AccountID, TransactionType, Amount, TransactionDate, Description)
	VALUES (@FromAccountID, 'Transfer Out', @Amount, @TransactionDate, 'Transfer to another account');

	INSERT INTO Transactions (AccountID, TransactionType, Amount, TransactionDate, Description)
	VALUES (@ToAccountID, 'Transfer In', @Amount, @TransactionDate, 'Transfer from another account');

	-- Check if the transferred amount to Alice repays the loan
	IF @ToAccountID = 1 -- Assuming Alice's AccountID is 1
	BEGIN
    	DECLARE @AliceCustomerID INT;
    	DECLARE @AliceLoanAmount DECIMAL(18, 2);
    	DECLARE @Interest DECIMAL(18, 2);
    	DECLARE @TotalDue DECIMAL(18, 2);

    	-- Get Alice's CustomerID and current loan details
    	SELECT @AliceCustomerID = CustomerID FROM Accounts WHERE AccountID = @ToAccountID;
    	SELECT @AliceLoanAmount = LoanAmount FROM Loans WHERE CustomerID = @AliceCustomerID;

    	-- Calculate interest up to the transfer date
    	SET @Interest = dbo.CalculateLoanInterest(1, @TransactionDate); -- Assuming Alice's LoanID is 1
    	SET @TotalDue = @AliceLoanAmount + @Interest;

    	IF @Amount >= @TotalDue
    	BEGIN
        	-- Fully repay the loan including interest
        	UPDATE Loans
        	SET LoanAmount = 0
        	WHERE CustomerID = @AliceCustomerID;
    	END
    	ELSE
    	BEGIN
        	-- Partially repay the loan and the interest
        	UPDATE Loans
        	SET LoanAmount = @TotalDue - @Amount
        	WHERE CustomerID = @AliceCustomerID;
    	END
	END
```
### Step 7: Implementing Triggers
**Trigger to Log Account Balance Changes**

**Purpose**: Automatically logs changes to account balances.
**Usage**: Provides an audit trail for changes, which can be useful for compliance and troubleshooting.

```sql
CREATE TRIGGER LogAccountBalanceChange
ON Accounts
AFTER UPDATE
AS
BEGIN
    INSERT INTO AccountBalanceLogs (AccountID, OldBalance, NewBalance, ChangeDate)
    SELECT 
        i.AccountID,
        d.Balance,
        i.Balance,
        GETDATE()
    FROM 
        inserted i
    JOIN 
        deleted d ON i.AccountID = d.AccountID;
END;
```

**Trigger to Automatically Create an Account When a New Customer is Added**
Automates the process of account creation whenever a new customer is added to the Customers table. This ensures that every new customer automatically receives a default account without requiring additional manual steps.

```sql
CREATE TRIGGER AddDefaultAccount
ON Customers
AFTER INSERT
AS
BEGIN
    INSERT INTO Accounts (CustomerID, AccountType, Balance, CreatedDate)
    SELECT CustomerID, 'Savings', 0.00, GETDATE()
    FROM inserted;
END;
```
### Step 8: Security Considerations
**Creating a Read-Only Role**

**Purpose**: To restrict users to only read access on specific tables.

```sql
-- Create a read-only role
CREATE ROLE ReadOnlyRole;

-- Grant select permissions to the read-only role
GRANT SELECT ON Customers TO ReadOnlyRole;
GRANT SELECT ON Accounts TO ReadOnlyRole;
GRANT SELECT ON Transactions TO ReadOnlyRole;
GRANT SELECT ON Loans TO ReadOnlyRole;

-- Assign the role to a user
ALTER ROLE ReadOnlyRole ADD MEMBER SomeUser;
```
**Purpose**: Restricts access to the database, allowing certain users to only read data without making changes.

**Usage**: Enhances security by controlling access levels based on user roles.
## Execution-with-Screenshots

-  Adding a new Customer named Alice.
Note: When we Add a new customer then a new account for him/her also gets created via trigger.
![](https://github.com/Kens3i/Banking-Database-Management-System/blob/main/SS/1.PNG?raw=true)

-  Adding another customer named Walter.
![](https://github.com/Kens3i/Banking-Database-Management-System/blob/main/SS/2.PNG?raw=true)
-  Displaying the Customer and Accounts Table for Clarification.
![](https://github.com/Kens3i/Banking-Database-Management-System/blob/main/SS/3.1.PNG?raw=true)
![](https://github.com/Kens3i/Banking-Database-Management-System/blob/main/SS/3.2.PNG?raw=true)

-  Alice deposited $300 and it will be reflected in transactions table.
![](https://github.com/Kens3i/Banking-Database-Management-System/blob/main/SS/4.1.PNG?raw=true)
![](https://github.com/Kens3i/Banking-Database-Management-System/blob/main/SS/4.2.PNG?raw=true)
-  Alice transfers $150 to Walter. Hence Walter will have now $150 and Alice will also have $150.
![](https://github.com/Kens3i/Banking-Database-Management-System/blob/main/SS/5.1.PNG?raw=true)
![](https://github.com/Kens3i/Banking-Database-Management-System/blob/main/SS/5.2.PNG?raw=true)
-  Alice withdraws $500, but her balance is only $150. So her account will show $0 and she will get a $350 loan.
![](https://github.com/Kens3i/Banking-Database-Management-System/blob/main/SS/6.1.PNG?raw=true)
![](https://github.com/Kens3i/Banking-Database-Management-System/blob/main/SS/6.2.PNG?raw=true)
![](https://github.com/Kens3i/Banking-Database-Management-System/blob/main/SS/6.3.PNG?raw=true)
-  Calculating the Interest (Rate of interest in this case is 5%) for Alice($350) after 1 year.
![](https://github.com/Kens3i/Banking-Database-Management-System/blob/main/SS/7.1.PNG?raw=true)
-  Now Alice decides deposit $500 in her account. So the loan amount will be 0 and he will be having 500-350-17.5(17.5 is interest) in her account which amounts to 132.5.
![](https://github.com/Kens3i/Banking-Database-Management-System/blob/main/SS/8.1.PNG?raw=true)
![](https://github.com/Kens3i/Banking-Database-Management-System/blob/main/SS/8.2.PNG?raw=true)
-  Alice now transfers $232.5 to Walter (she had 132.5 so balance should be 132.5-232.5=-100). So $100 will be loan.
![](https://github.com/Kens3i/Banking-Database-Management-System/blob/main/SS/9.1.PNG?raw=true)
![](https://github.com/Kens3i/Banking-Database-Management-System/blob/main/SS/9.2.PNG?raw=true)
-  Now Walter transfers $232.5+Interest to Alice on the same day, so she should have $132.5(232.5-100[loan]-0[Interest]) back in her account. Here Transfer happenes in the same day so interest should be 0.
![](https://github.com/Kens3i/Banking-Database-Management-System/blob/main/SS/10.1.PNG?raw=true)
![](https://github.com/Kens3i/Banking-Database-Management-System/blob/main/SS/10.2.PNG?raw=true)
![](https://github.com/Kens3i/Banking-Database-Management-System/blob/main/SS/10.3.PNG?raw=true)
-  Using the view to see the consolidated data from Customers table and Accounts table.
![](https://github.com/Kens3i/Banking-Database-Management-System/blob/main/SS/11.PNG?raw=true)
-  The AccountBalanceLogs keeps the logs of all the activities (deposits & withdrawals) that happens in the Accounts Table. we have used a trigger to facilitate this process, the dates are being picked up via GETDATE() function.
![](https://github.com/Kens3i/Banking-Database-Management-System/blob/main/SS/12.PNG?raw=true)



### Thankyou For Spending Your Precious Time Going Through This Project!
### If You Find Any Value In This Project Or Gained Something New Please Do Give A ⭐.
