# SQLParser
A parser for SQL (mainly MySQL and PSQL queries).

## 1. Grammar

[A latest SQL grammar](src/grammar/SQL.g4) for MySQL and PSQL. It also supports partial new features in MySQL 8. You can use this grammar for later reusing.

### Performance

Benchmark 1: [SQL-Testing](https://github.com/MIPL-group/SQL_Testing/tree/main/mysql_queries)

#Correct cases: 47,876 ,  #Wrong cases ([bad cases here](./src/grammar/bad_cases.txt)): 55, Rate: 99.89%



Benchmark 2: [Final-SQL-Optimization](https://github.com/MIPL-group/Final_SQL_Optimization/tree/main/benchmarks)

#Correct cases: 50,443 ,  #Wrong cases: 0, Rate: 100%



The 2 benchmarks have the following problems:

1) `table` `FROM` $\rightarrow$ `tableFORM`
2) Syntactically wrong queries
3) Unknown syntax rules, e.g., `FROM Users WHERE (mail REGEXP '^[a-zA-Z][a-zA-Z0-9_.-]*@leetcode.com$')`
4) `&amp;` 

## 2. Lexer & Parser

To implement visitors to transform a SQL query into json format.

## 3. Verification

TBC

