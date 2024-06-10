-- Function to Calculate Loan Interest
-- We will adjust the function to calculate the interest based on the number of days since the loan was taken out.

-- Function to calculate loan interest based on the loan ID and the end date
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




-- Stored Procedure to Add a New Customer

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



-- Stored Procedure to Add a Transaction

-- Handles both withdrawal and deposit operations.
-- Ensures that if an account balance goes negative, the negative balance is recorded as a loan.
-- If the account balance is replenished, the loan amount is decreased accordingly.
-- If the deposit amount is enough to repay the loan fully, it adjusts the account balance and sets the loan amount to 0.
-- If the deposit amount is not enough to repay the loan fully, it reduces the loan amount by the deposit amount.

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

-- Create an index on CustomerID in the Accounts table
CREATE INDEX IDX_CustomerID ON Accounts(CustomerID);

-- Create an index on AccountID in the Transactions table
CREATE INDEX IDX_AccountID ON Transactions(AccountID);





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
    DECLARE @ToCustomerID INT;
    DECLARE @ToLoanID INT;
    DECLARE @ToLoanAmount DECIMAL(18, 2);
    DECLARE @Interest DECIMAL(18, 2);
    DECLARE @TotalDue DECIMAL(18, 2);
    DECLARE @RemainingAmount DECIMAL(18, 2);

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

        -- Set remaining amount to the full transfer amount since we are creating a loan for the shortfall
        SET @RemainingAmount = @Amount;
    END
    ELSE
    BEGIN
        -- Update the from account balance
        UPDATE Accounts
        SET Balance = Balance - @Amount
        WHERE AccountID = @FromAccountID;

        -- Set remaining amount to the transfer amount
        SET @RemainingAmount = @Amount;
    END

    -- Insert transactions for both accounts
    INSERT INTO Transactions (AccountID, TransactionType, Amount, TransactionDate, Description)
    VALUES (@FromAccountID, 'Transfer Out', @Amount, @TransactionDate, 'Transfer to another account');

    INSERT INTO Transactions (AccountID, TransactionType, Amount, TransactionDate, Description)
    VALUES (@ToAccountID, 'Transfer In', @Amount, @TransactionDate, 'Transfer from another account');

    -- Check if the recipient account has an outstanding loan
    SELECT @ToCustomerID = CustomerID FROM Accounts WHERE AccountID = @ToAccountID;

    IF EXISTS (SELECT 1 FROM Loans WHERE CustomerID = @ToCustomerID)
    BEGIN
        -- Get the recipient's loan details
        SELECT @ToLoanID = LoanID, @ToLoanAmount = LoanAmount FROM Loans WHERE CustomerID = @ToCustomerID;

        -- Calculate interest up to the transfer date
        SET @Interest = dbo.CalculateLoanInterest(@ToLoanID, @TransactionDate);
        SET @TotalDue = @ToLoanAmount + @Interest;

        IF @RemainingAmount >= @TotalDue
        BEGIN
            -- Fully repay the loan including interest
            UPDATE Loans
            SET LoanAmount = 0
            WHERE CustomerID = @ToCustomerID;

            -- Update the to account balance with the remaining amount after loan repayment
            SET @RemainingAmount = @RemainingAmount - @TotalDue;
            UPDATE Accounts
            SET Balance = Balance + @RemainingAmount
            WHERE AccountID = @ToAccountID;
        END
        ELSE
        BEGIN
            -- Partially repay the loan and the interest
            UPDATE Loans
            SET LoanAmount = @TotalDue - @RemainingAmount
            WHERE CustomerID = @ToCustomerID;

            -- Since the transfer amount was less than the total due, no remaining amount is added to the balance
            UPDATE Accounts
            SET Balance = Balance
            WHERE AccountID = @ToAccountID;
        END
    END
    ELSE
    BEGIN
        -- No loan to repay, so just update the to account balance with the transfer amount
        UPDATE Accounts
        SET Balance = Balance + @RemainingAmount
        WHERE AccountID = @ToAccountID;
    END
END;



-- Trigger to Log Account Balance Changes

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



-- Trigger to automatically create an account when a new customer is added
CREATE TRIGGER AddDefaultAccount
ON Customers
AFTER INSERT
AS
BEGIN
    INSERT INTO Accounts (CustomerID, AccountType, Balance, CreatedDate)
    SELECT CustomerID, 'Savings', 0.00, GETDATE()
    FROM inserted;
END;






-- Create a read-only role
CREATE ROLE ReadOnlyRole;

-- Grant select permissions to the read-only role
GRANT SELECT ON Customers TO ReadOnlyRole;
GRANT SELECT ON Accounts TO ReadOnlyRole;
GRANT SELECT ON Transactions TO ReadOnlyRole;
GRANT SELECT ON Loans TO ReadOnlyRole;

-- Assign the role to a user
-- ALTER ROLE ReadOnlyRole ADD MEMBER SomeUser;


