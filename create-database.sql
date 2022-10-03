/* Online Shopping Database */
/* Create table statements */ 
CREATE TABLE User_set (
  User_Id        integer not null,
  User_Name      char(50) not null, 
  Gender         integer, 
  Phone_Number      char(50) not null, 
  Password      char(50) not null, 
  Country      char(50),
  primary key (User_Id),
  unique (User_Name)
);

CREATE TABLE User_Address (
  User_Id        integer not null,
  Address      char(50) not null, 
  primary key (User_Id,Address)
);

CREATE TABLE Shop (
  Shop_Id        integer not null,
  Shop_Name      char(50) not null, 
  License      char(50) not null, 
  Country      char(50), 
  Credit      integer DEFAULT 0,
  User_Id        integer not null,
  primary key (Shop_Id),
  unique (Shop_Name)
);

CREATE TABLE Shop_Location (
  Shop_Id        integer not null,
  Location      char(50) not null, 
  primary key (Shop_Id,Location)
);

CREATE TABLE Item (
  Item_Id        integer not null,
  Item_Name      char(50) not null, 
  Start_Date      date, 
  Remaining_Quantity integer not null,
  Description   char(500) not null, 
  Price          decimal(12,2),
  Popularity    integer DEFAULT 0,
  Shop_Id        integer not null,
  Company_Id        integer not null,
  primary key (Item_Id)
);

CREATE TABLE Item_Category (
  Item_Id        integer not null,
  Category      char(50) not null, 
  primary key (Item_Id,Category)
);

CREATE TABLE Group_set (
  Group_Id        integer not null,
  Group_Name      char(50) not null, 
  Description   char(500) not null, 
  Announcement   char(500) not null, 
  Creation_Date      date, 
  Manager integer not null,
  primary key (Group_Id),
  unique (Group_Name)
);

CREATE TABLE Group_Topic (
  Group_Id        integer not null,
  Topic      char(50) not null, 
  primary key (Group_Id,Topic)
);

CREATE TABLE Logistic_Company (
  Company_Id        integer not null,
  Company_Name      char(50) not null, 
  Country      char(50), 
  Credit      integer DEFAULT 0,
  primary key (Company_Id),
  unique (Company_Name)
);

CREATE TABLE Company_Location (
  Company_Id        integer not null,
  Location      char(50) not null, 
  primary key (Company_Id,Location)
);

CREATE TABLE Bill (
  Bill_Id        integer not null,
  User_Id        integer not null,
  Item_Id        integer not null,
  Creation_Date      date, 
  Comment_Content char(500),
  primary key (Bill_Id,User_Id,Item_Id)
);

CREATE TABLE User_Comment_Shop (
  User_Id        integer not null,
  Shop_Id        integer not null,
  Content   char(500) not null, 
  Creation_Date      date, 
  Score integer DEFAULT 10,
  primary key (User_Id,Shop_Id)
);

CREATE TABLE Shop_Comment_Company (
  Shop_Id        integer not null,
  Company_Id        integer not null,
  Content   char(500) not null, 
  Creation_Date      date, 
  primary key (Shop_Id,Company_Id)
);

CREATE TABLE Shopping_Cart (
  User_Id        integer not null,
  Item_Id        integer not null,
  Add_Date      date, 
  primary key (User_Id,Item_Id)
);

CREATE TABLE User_Join_Group (
  User_Id        integer not null,
  Group_Id        integer not null,
  Password      char(50) not null, 
  primary key (User_Id,Group_Id)
);


/* Add Foreign Keys */
ALTER TABLE Group_set ADD CONSTRAINT fke1 FOREIGN KEY(Manager) REFERENCES User_set(User_Id);
ALTER TABLE Shop_Comment_Company ADD CONSTRAINT fke2 FOREIGN KEY(Company_Id) REFERENCES Logistic_Company(Company_Id);
ALTER TABLE Shop_Comment_Company ADD CONSTRAINT fke3 FOREIGN KEY(Shop_Id) REFERENCES Shop(Shop_Id);
ALTER TABLE Group_Topic ADD CONSTRAINT fke4 FOREIGN KEY(Group_Id) REFERENCES Group_set(Group_Id);
ALTER TABLE User_Comment_Shop ADD CONSTRAINT fke5 FOREIGN KEY(User_Id) REFERENCES User_set(User_Id);
ALTER TABLE User_Comment_Shop ADD CONSTRAINT fke6 FOREIGN KEY(Shop_Id) REFERENCES Shop(Shop_Id);
ALTER TABLE User_Join_Group ADD CONSTRAINT fke7 FOREIGN KEY(User_Id) REFERENCES User_set(User_Id);
ALTER TABLE User_Join_Group ADD CONSTRAINT fke8 FOREIGN KEY(Group_Id) REFERENCES Group_set(Group_Id);
ALTER TABLE Company_Location ADD CONSTRAINT fke9 FOREIGN KEY(Company_Id) REFERENCES Logistic_Company(Company_Id);
ALTER TABLE Shop ADD CONSTRAINT fke10 FOREIGN KEY(User_Id) REFERENCES User_set(User_Id);
ALTER TABLE Bill ADD CONSTRAINT fke11 FOREIGN KEY(User_Id) REFERENCES User_set(User_Id);
ALTER TABLE Bill ADD CONSTRAINT fke12 FOREIGN KEY(Item_Id) REFERENCES Item(Item_Id);
ALTER TABLE Item ADD CONSTRAINT fke13 FOREIGN KEY(Shop_Id) REFERENCES Shop(Shop_Id);
ALTER TABLE Item ADD CONSTRAINT fke14 FOREIGN KEY(Company_Id) REFERENCES Logistic_Company(Company_Id);
ALTER TABLE Shopping_Cart ADD CONSTRAINT fke15 FOREIGN KEY(User_Id) REFERENCES User_set(User_Id);
ALTER TABLE Shopping_Cart ADD CONSTRAINT fke16 FOREIGN KEY(Item_Id) REFERENCES Item(Item_Id);
ALTER TABLE User_Address ADD CONSTRAINT fke17 FOREIGN KEY(User_Id) REFERENCES User_set(User_Id);
ALTER TABLE Shop_Location ADD CONSTRAINT fke18 FOREIGN KEY(Shop_Id) REFERENCES Shop(Shop_Id);
ALTER TABLE Item_Category ADD CONSTRAINT fke19 FOREIGN KEY(Item_Id) REFERENCES Item(Item_Id);


/* Procedures */
/* Once a user bought an item, the popularity of this item will increase by 2, and when the item was added 
into a shopping cart, its popularity will increase by 1 */
create or replace view Bill_Count
as select Item_Id, count(*) as billitem FROM Bill group by Bill.Item_Id;

create or replace PROCEDURE Popularity_Calculation_Bill AS 
CURSOR Item_CURSOR IS
SELECT Item_Id, count(*) as billitem FROM Bill group by Bill.Item_Id;
thisItem Bill_Count%ROWTYPE;
BEGIN
OPEN Item_CURSOR;
LOOP
  FETCH Item_CURSOR INTO thisItem;
  EXIT WHEN (Item_CURSOR%NOTFOUND);
  UPDATE Item SET Popularity = Popularity + thisItem.billitem * 2
  WHERE Item.Item_Id = thisItem.Item_Id;
END LOOP;
CLOSE Item_CURSOR;
END;

create or replace view Cart_Count
as select Item_Id, count(*) as cartitem FROM Shopping_Cart group by Shopping_Cart.Item_Id;

create or replace PROCEDURE Popularity_Calculation_Cart AS 
CURSOR Item_CURSOR IS
SELECT Item_Id, count(*) as cartitem FROM Shopping_Cart group by Shopping_Cart.Item_Id;
thisItem Cart_Count%ROWTYPE;
BEGIN
OPEN Item_CURSOR;
LOOP
  FETCH Item_CURSOR INTO thisItem;
  EXIT WHEN (Item_CURSOR%NOTFOUND);
  UPDATE Item SET Popularity = Popularity + thisItem.cartitem
  WHERE Item.Item_Id = thisItem.Item_Id;
END LOOP;
CLOSE Item_CURSOR;
END;


/* The store's credit is the average of all user reviews */
create or replace view Shop_Avg_Credit
as select Shop_Id, AVG(User_Comment_Shop.Score) as Avg_Credit FROM User_Comment_Shop group by User_Comment_Shop.Shop_Id;

create or replace PROCEDURE Credit_Calculation AS 
CURSOR Shop_Credit IS
SELECT Shop_Id, AVG(User_Comment_Shop.Score) as Avg_Credit FROM User_Comment_Shop group by User_Comment_Shop.Shop_Id;
thisCredit Shop_Avg_Credit%ROWTYPE;
BEGIN
OPEN Shop_Credit;
LOOP
  FETCH Shop_Credit INTO thisCredit;
  EXIT WHEN (Shop_Credit%NOTFOUND);
  UPDATE Shop SET Credit = thisCredit.Avg_Credit
  WHERE Shop.Shop_Id = thisCredit.Shop_Id;
END LOOP;
CLOSE Shop_Credit;
END;


/* Triggers */
/* Before adding or updating the score of shop made by user, system will check if the score is in the range of 0 to 10 */
create or replace TRIGGER Check_Score
AFTER INSERT OR UPDATE OF Score ON User_Comment_Shop
FOR EACH ROW 
DECLARE
    New_Score number;
BEGIN 
	New_Score := :NEW.Score;
	if New_Score < 0 then
 		Raise_Application_Error(-20000, 'Score is too small');
	end if;
	if New_Score > 10 then
 		Raise_Application_Error(-20000, 'Score is too big');
	end if;
END;


/* Before creating a bill, system will check if the remaining quantity of the corresponding item is large than 0 */
create or replace TRIGGER Check_Quantity
BEFORE INSERT ON Bill
FOR EACH ROW 
DECLARE
    Item_Quantity number;
BEGIN 
	select Item.Remaining_Quantity into Item_Quantity from Item where Item.Item_Id = :NEW.Item_Id;
	if Item_Quantity < 1 then
 		Raise_Application_Error(-20000, 'There is not enough stock');
	end if;
	if Item_Quantity >= 1 then
		UPDATE Item SET Remaining_Quantity = Remaining_Quantity - 1
  	WHERE Item.Item_Id = :NEW.Item_Id;
	end if;
END;


/* Import the tables into APEX */
CREATE TABLE DEMO_Project.User_set as (select * from ADMIN.User_set);
CREATE TABLE DEMO_Project.User_Address as (select * from ADMIN.User_Address);
CREATE TABLE DEMO_Project.Shop as (select * from ADMIN.Shop);
CREATE TABLE DEMO_Project.Shop_Location as (select * from ADMIN.Shop_Location); 
CREATE TABLE DEMO_Project.Item as (select * from ADMIN.Item);
CREATE TABLE DEMO_Project.Item_Category as (select * from ADMIN.Item_Category);
CREATE TABLE DEMO_Project.Group_set as (select * from ADMIN.Group_set);
CREATE TABLE DEMO_Project.Group_Topic as (select * from ADMIN.Group_Topic);
CREATE TABLE DEMO_Project.Logistic_Company as (select * from ADMIN.Logistic_Company);
CREATE TABLE DEMO_Project.Company_Location as (select * from ADMIN.Company_Location);
CREATE TABLE DEMO_Project.Bill as (select * from ADMIN.Bill);
CREATE TABLE DEMO_Project.User_Comment_Shop as (select * from ADMIN.User_Comment_Shop);
CREATE TABLE DEMO_Project.Shop_Comment_Company as (select * from ADMIN.Shop_Comment_Company);
CREATE TABLE DEMO_Project.Shopping_Cart as (select * from ADMIN.Shopping_Cart);
CREATE TABLE DEMO_Project.User_Join_Group as (select * from ADMIN.User_Join_Group);


DROP TABLE User_set;
DROP TABLE User_Address;
DROP TABLE Shop;
DROP TABLE Shop_Location; 
DROP TABLE Item;
DROP TABLE Item_Category;
DROP TABLE Group_set;
DROP TABLE Group_Topic;
DROP TABLE Logistic_Company;
DROP TABLE Company_Location;
DROP TABLE Bill;
DROP TABLE User_Comment_Shop;
DROP TABLE Shop_Comment_Company;
DROP TABLE Shopping_Cart;
DROP TABLE User_Join_Group;
