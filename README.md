# ASP---Automated-Robo-Warehouse
This project models a simplified warehouse automation problem using Answer Set Programming (ASP) with Clingo. It simulates a fleet of robots tasked with transporting shelves to picking stations while avoiding collisions and respecting movement constraints.

## Problem Overview

- Robots move on a grid.
- Robots carry shelves with products.
- Deliver to picking stations.
- Avoid highways, collisions, and invalid movements.

## Technologies Used
- [Clingo 5.7.1](https://potassco.org/clingo/)
- Answer Set Programming (ASP)

## Repository Structure
- code/ → ASP logic program and instance files
- report/ → Project report (PDF)
- README.md → Project summary and usage

## Run Instructions
clingo code/warehouse.lp code/inst1.asp --opt-mode=opt

## Report
For a detailed explanation of the problem, approach, and results, see report/Pradyumn_Mohta_Milestone2.pdf

## Author
Pradyumn Mohta
Arizona State University.
