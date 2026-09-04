loan risk analysis:

-- Planning Stage Process before attemp 1

## columns
dbo.loans:
- total outstanding loan balance
- number of active loans
- average interest rate

dbo.customers:
- average credit score of the borrowing customers

case statement:
- flagging loan's product type via avg credit score
a. 500 as 'High Risk'
b. between 500 and 700 as 'Medium Risk'
c. 700 and above as 'Low Risk'

## aggregation
dbo.loans:
- by product type

## filters
dbo.loans & dbo.accounts:
- active status must equalize

## Grain:
- one row per product type with both active status on loans and accounts

-- Deciding what structure would be fitted
## Structure Decision:
- I can use CTE with a better flow connection compare to my assigment solution. 
- I would now use commeting for explaing the syntax
- I am contemplating to adopt the pre-filter CTE of AI from the assignment 1 or not because I don't know how to execute it with just a filter, without using any columns because there is no other required columns. 

## Question before executing:
- context: Before coding, to get the average credit score of the borrowing customers, I need to join the tables from customers table's credit score to loan table. Upon checking from both tables, I notice that the loan has only 150 rows and the credit score rows from the customer's table has 200 rows. My assumption is that, there are 50 customers who are not a borrower or doesn't have a loan, so that there should be null values inside the credit score table from the customer table. However, after verifying my assumption, I discovered that there are 200 credit score rows exists in the credit score column. After running a query to check for null values, 0 values, or '' values, there is none, speculating that there are external factors or data that is not connected to the loans table that is recorded inside the credit score column of the customer's table. I am questioning the data integrity of this generated data from AI because my solution would possible lead to hidden issues even if the code is correct and in production standard. 

## AFTER ATTEMPT 1:
- I spent my last 3 hours figuring out how to include the average credit score to loan type because I know my result is not correct and has a wrong granularity. I never search for the answer because this is the type of struggle I want so that I can grow even more. At last, I submit my first attempt with the wrong asnwer, and I will try to implement the right syntax in the attemp 2 based on the critic of Claude AI.
- After taking the claude's review on my assignment #1, I realize that I am climbing the wrong tree: during the attempt 1, I keep executing the average credit score from the customer's table without realizing that every customer's credit score is unique and it doesn't make sense if I use group by clause using the customer's id because it would lead to the the same result as thier credit score. After reading the clues from Claude, I now understand that I need to execute the average credit score under loan's table using join. By then, I should get the right grain: one row per each loan type.
- I now know the problem and how to solve it if I encounter the same one.

## AFTER ATTEMPT 2: 
