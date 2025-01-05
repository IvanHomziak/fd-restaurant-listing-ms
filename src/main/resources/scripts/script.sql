-- Create the database if it doesn't exist
CREATE DATABASE IF NOT EXISTS restaurantdb;

-- Switch to the database
USE restaurantdb;

-- Drop the table if it exists
DROP TABLE IF EXISTS restaurant;

-- Recreate the table
CREATE TABLE restaurant
(
    id                    INT AUTO_INCREMENT PRIMARY KEY,
    name                  VARCHAR(255) NOT NULL,
    address               VARCHAR(255) NOT NULL,
    city                  VARCHAR(100) NOT NULL,
    restaurant_description TEXT
);

-- Insert sample data
INSERT INTO restaurant (name, address, city, restaurant_description)
VALUES ('Pizza Paradise', '123 Main Street', 'New York', 'A cozy place for the best Italian pizzas.'),
       ('Sushi World', '456 Elm Avenue', 'San Francisco', 'Experience authentic Japanese sushi and sashimi.'),
       ('Burger Haven', '789 Maple Road', 'Chicago', 'The ultimate destination for gourmet burgers.'),
       ('Taco Fiesta', '321 Pine Street', 'Austin', 'Serving delicious Mexican tacos and burritos.'),
       ('Pasta House', '654 Cedar Lane', 'Boston', 'Freshly made pasta and classic Italian dishes.'),
       ('Curry Palace', '987 Walnut Avenue', 'Seattle', 'Exquisite Indian curries and naan bread.'),
       ('Steak Kingdom', '555 Oak Drive', 'Dallas', 'Juicy steaks and a luxurious dining experience.'),
       ('Seafood Delight', '777 Beach Boulevard', 'Miami', 'Fresh seafood and stunning ocean views.'),
       ('Vegan Corner', '222 Greenway', 'Portland', 'A healthy and eco-friendly vegan menu.'),
       ('Dessert Dreams', '999 Sugar Lane', 'Las Vegas', 'Indulge in the finest desserts and pastries.');
