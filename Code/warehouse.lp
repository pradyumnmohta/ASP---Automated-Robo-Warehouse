% Automated Warehouse Scenario - Pradyumn Mohta.

%
% Basic Declarations: Time steps and Movement Directions
%

#const maxtime=20.
step(0..maxtime).

% Define possible move directions (left, right, up, down)
move_dir(1,0). move_dir(-1,0). move_dir(0,1). move_dir(0,-1).

% Identify warehouse objects: Robots, Shelves, Products, and Orders
is_robot(B) :- init(object(robot,B),value(at,_)).
is_shelf(K) :- init(object(shelf,K),value(at,_)).
is_product(M) :- init(object(product,M),value(on,_)).
is_order(N) :- init(object(order,N),value(line,_)).

% Define grid nodes and mark highways
cell(U,V) :- init(object(node,_),value(at,pair(U,V))).
is_highway(U,V) :- init(object(highway,_),value(at,pair(U,V))).

% Define picking stations and their coordinates
station(W,U,V) :- init(object(pickingStation,W),value(at,pair(U,V))).

%
% Initial Setup of the Warehouse
%

% Robots and shelves initial positions at time 0
at(B,U,V,0) :- init(object(robot,B),value(at,pair(U,V))), step(0).
shelf_at(K,U,V,0) :- init(object(shelf,K),value(at,pair(U,V))), step(0).

% Products initially stored on shelves
stock(M,K,Q) :- init(object(product,M),value(on,pair(K,Q))).

% Products required by orders
pending(N,M,Q) :- init(object(order,N),value(line,pair(M,Q))).

%
% Definition of Possible Robot Actions
%

% Each robot can do exactly one action per time step: move, pickup, putdown, deliver, or stay idle
{ act(B,move(DU,DV),S) : move_dir(DU,DV) ; act(B,grab,S) ; act(B,drop,S) ; act(B,ship(N,M,Q),S) : is_order(N), is_product(M), pending(N,M,Q) ; wait(B,S) } = 1 :- is_robot(B), step(S), S > 0.

%
% Effects of Actions on the World
%

% Robot movement updates robot position
at(B,U2,V2,S) :- act(B,move(DU,DV),S), at(B,U1,V1,S-1), U2=U1+DU, V2=V1+DV, cell(U2,V2), is_robot(B), step(S).

% If a robot is carrying a shelf, the shelf moves along with it
holding(B,K,S) :- holding(B,K,S-1), act(B,move(_, _),S), is_robot(B), is_shelf(K), step(S).
shelf_at(K,U,V,S) :- holding(B,K,S), at(B,U,V,S), is_robot(B), is_shelf(K), step(S).

% Picking up a shelf: Robot and shelf must be at same cell
holding(B,K,S) :- act(B,grab,S), at(B,U,V,S-1), shelf_at(K,U,V,S-1), is_robot(B), is_shelf(K), step(S).
shelf_at(K,U,V,S) :- holding(B,K,S), at(B,U,V,S), is_robot(B), is_shelf(K), step(S).

% Putting down a shelf: Robot no longer carrying, shelf stays on the grid
holding(B,K,S) :- holding(B,K,S-1), not act(B,drop,S), is_robot(B), is_shelf(K), step(S).
shelf_at(K,U,V,S) :- shelf_at(K,U,V,S-1), not holding(_,K,S), is_shelf(K), step(S).

% Deliveries can only happen if the robot is carrying a shelf
:- act(B,ship(N,M,Q),S), not holding(B,_,S-1), is_robot(B), is_order(N), is_product(M), step(S).

%
% Warehouse Constraints
%

% Robots must not move outside the warehouse grid
:- act(B,move(DU,DV),S), at(B,U,V,S-1), U1=U+DU, V1=V+DV, not cell(U1,V1), is_robot(B), step(S).

% No two robots can occupy the same cell at the same time
:- at(B1,U,V,S), at(B2,U,V,S), B1 < B2, is_robot(B1;B2), step(S).

% Robots are not allowed to swap places in a single time step
:- at(B1,U1,V1,S-1), at(B2,U2,V2,S-1), act(B1,move(DU1,DV1),S), act(B2,move(DU2,DV2),S), U2=U1+DU1, V2=V1+DV1, U1=U2+DU2, V1=V2+DV2, is_robot(B1;B2), step(S).

% Robots carrying shelves cannot move underneath other shelves
:- act(B,move(DU,DV),S), holding(B,_,S-1), at(B,U,V,S-1), shelf_at(K,U+DU,V+DV,S-1), not holding(B,K,S-1), is_robot(B), is_shelf(K), step(S).

% Shelves cannot be placed on highway cells
:- shelf_at(K,U,V,S), is_highway(U,V), is_shelf(K), step(S).

% Products can only be delivered at picking stations
:- act(B,ship(N,M,Q),S), at(B,U,V,S-1), not station(_,U,V), is_robot(B), is_order(N), is_product(M), step(S).

% Robots cannot deliver more products than available
:- act(B,ship(N,M,Q),S), pending(N,M,Q1), Q > Q1, is_robot(B), is_order(N), is_product(M), step(S).

%
% Dynamic Tracking of Product Quantities
%

% Initialize shelf product quantities at time 0
prod_on(M,K,Q,0) :- stock(M,K,Q).

% Shelf quantities remain the same if no delivery occurs
prod_on(M,K,Q,S) :- prod_on(M,K,Q,S-1), not delivered(M,K,_,S), step(S), is_product(M), is_shelf(K).

% Define delivery from a shelf
delivered(M,K,Qd,S) :- act(B,ship(N,M,Qd),S), holding(B,K,S-1), is_robot(B), is_order(N), is_product(M), is_shelf(K).

% Update shelf quantities after delivery
prod_on(M,K,Qnew,S) :- prod_on(M,K,Qold,S-1), delivered(M,K,Qd,S), Qnew = Qold - Qd, Qnew >= 0.

% Initialize undelivered order quantities at time 0
undeliv(M,N,Q,0) :- pending(N,M,Q).

% Update undelivered order quantities over time
undeliv(M,N,Q,S) :- undeliv(M,N,Q,S-1), not delivered_order(M,N,_,S), step(S), is_product(M), is_order(N).

% Define delivery towards an order
delivered_order(M,N,Qd,S) :- act(B,ship(N,M,Qd),S), is_robot(B), is_order(N), is_product(M).

% Update undelivered quantities after delivery
undeliv(M,N,Qnew,S) :- undeliv(M,N,Qold,S-1), delivered_order(M,N,Qd,S), Qnew = Qold - Qd, Qnew >= 0.

%
% Final Goal: All Orders Must Be Completed
%

% Ensure no undelivered products remain at the final time step
:- undeliv(M,N,Q,maxtime), Q > 0.

%
% Output Definitions
%

#show act/3.

% Optimization: Minimize the number of actions/time steps
#minimize { S : act(_,_,S) }.
