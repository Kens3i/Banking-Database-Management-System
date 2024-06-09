-- Adding a New Customer
-- Execute the stored procedure to add a new customer
EXEC AddCustomer 'Alice', 'Johnson', '1995-06-22', 'alice.johnson@example.com', '1122334455', '789 Pine St';

Select * from Customers;
SELECT * FROM Accounts;

EXEC AddCustomer 'Walter', 'White', '1990-02-21', 'walter.white@example.com', '123456789', '129 Melbourne St';




-- Execute the stored procedure to Adding a Transaction
-- Alice deposited 300 and it will be reflected in transactions table
EXEC AddTransaction 1, 'Deposit', 300.00, '2024-03-01', 'Bonus Payment';

Select * from Transactions;

-- Deposited 300 is also added in alice savings account
SELECT * FROM Accounts;



-- Transferring Funds Between Accounts
-- Execute the stored procedure to transfer funds
-- Note Transfer take place vai accountID and not CustomerID
-- Alice transfers 150 to Walter
EXEC TransferFunds 1, 2, 150.00,'2024-03-01';

-- Check the account balances and transactions
SELECT * FROM Accounts;
SELECT * FROM Transactions;



-- Alice withdraws 500, but her balance is only 150.
-- Note: Make sure the account with AccountID = 1 exists and belongs to Alice with an initial balance of 150.
EXEC AddTransaction @AccountID = 1, 
                    @TransactionType = 'Withdrawal', 
                    @Amount = 500.00, 
                    @TransactionDate = '2024-06-02', -- Use a specific date format
                    @Description = 'Purchase';


SELECT * FROM Accounts;
SELECT * FROM Loans;
SELECT * from Transactions;
-- She has now 350 Loan



-- Calculating Loan Interest
-- Calculate interest for a loan using the function after 1 year
SELECT dbo.CalculateLoanInterest(1,'2025-06-02') AS LoanInterest;



-- Alice deposits 500, back after 1 year.
-- Alice now has -350
-- Alice will deposit 500 after 1 year so interest for 1 year is 17.5
-- 500-350-17.5 = 132.5
EXEC AddTransaction @AccountID = 1, 
                    @TransactionType = 'Deposit', 
                    @Amount = 500.00, 
                    @TransactionDate = '2025-06-02', -- Use a specific date format
                    @Description = 'Depositing back the money';

SELECT * FROM Accounts;
SELECT * FROM Loans;


-- Alice now transfers 232.5 to Walter (she has 132.5 so balance should be -100)
EXEC TransferFunds 1, 2, 232.5,'2025-07-02';


SELECT * FROM Accounts;
SELECT * FROM Loans;
SELECT * FROM Customers;


-- Now Walter Transfers 232.5+Interest to Aice she should have 132.5(232.5-100[loan]) back in her account in the same day so interest should be 0.
-- First calculate the interest
SELECT dbo.CalculateLoanInterest(1,'2025-07-02') AS LoanInterest;

-- Now Walter Transfers back to Alice
EXEC TransferFunds 2, 1, 232.5,'2025-07-02';

SELECT * FROM Accounts;
SELECT * FROM Loans;


-- Using the View
-- Retrieve customer account summary
SELECT * FROM CustomerAccountSummary;



-- Check the account balance logs
SELECT * FROM AccountBalanceLogs;


--DELETE FROM Accounts;
--DELETE FROM AccountBalanceLogs;
--DELETE FROM Customers;
--DELETE FROM LOANS;
--DELETE FROM Transactions;
