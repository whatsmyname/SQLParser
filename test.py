# -*- coding:utf-8 -*-

import z3

Q1 = "SELECT name FROM (SELECT id, name, age FROM EMP WHERE age > 25) WHERE age < 30"
Q2 = "SELECT name FROM (SELECT id, name, age FROM EMP WHERE age < 30) WHERE age > 25"
