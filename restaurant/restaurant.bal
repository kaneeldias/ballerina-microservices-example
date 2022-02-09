import ballerinax/mysql;
import ballerina/sql;

public type Restaurant record {|
    int id?;
    string name;
    string address;
    Menu[] menus?;
|};

public type Menu record {|
    int id?;
    string name;
    MenuItem[] items?;
|};

public type MenuItem record {|
    int id?;
    string name;
    decimal price;
|};

configurable string USER = ?;
configurable string PASSWORD = ?;
configurable string HOST = ?;
configurable int PORT = ?;
configurable string DATABASE = ?;

final mysql:Client dbClient = check new(host=HOST, user=USER, password=PASSWORD, port=PORT, database="Restaurant");

isolated function createRestaurant(Restaurant restaurant) returns Restaurant|error {
    sql:ExecutionResult result = check dbClient->execute(`INSERT INTO Restaurants (name, address) VALUES (${restaurant.name}, ${restaurant.address})`);
    int|string? generatedRestaurantId = result.lastInsertId;
    if generatedRestaurantId is string? {
        return error("Unable to retrieve generated ID of restaurant.");
    }
    restaurant.id = generatedRestaurantId;

    Menu[]? menus = restaurant.menus;
    if menus is Menu[] {
        foreach Menu menu in menus {
            Menu generatedMenu = check createMenu(menu, generatedRestaurantId);
            menu.id = <int>generatedMenu.id;
        }
    }

    return restaurant;
}

isolated function createMenu(Menu menu, int restaurantId) returns Menu|error {
    sql:ExecutionResult result = check dbClient->execute(`INSERT INTO Menus (name, restaurantId) VALUES (${menu.name}, ${restaurantId})`);
    int|string? generatedMenuId = result.lastInsertId;
    if generatedMenuId is string? {
        return error("Unable to retrieve ID of menu.");
    }
    menu.id = generatedMenuId;

    MenuItem[]? menuItems = menu.items;
    if menuItems is MenuItem[] {
        foreach MenuItem menuItem in menuItems {
            MenuItem generatedMenuItem = check createMenuItem(menuItem, generatedMenuId);
            menuItem.id = <int>generatedMenuItem.id;
        }
    }

    return menu;
}

isolated function createMenuItem(MenuItem menuItem, int menuId) returns MenuItem|error {
    sql:ExecutionResult result = check dbClient->execute(`INSERT INTO MenuItems (name, price, menuId) VALUES (${menuItem.name}, ${menuItem.price}, ${menuId})`);
    int|string? generatedMenuItemId = result.lastInsertId;
    if generatedMenuItemId is string? {
        return error("Unable to retrieve ID of menu item.");
    }
    menuItem.id = generatedMenuItemId;
    return menuItem;
}

isolated function getRestaurant(int restaurantId) returns Restaurant|error {
    Restaurant restaurant = check dbClient->queryRow(`SELECT id, name, address FROM Restaurants WHERE id = ${restaurantId}`);
    restaurant.menus = check getMenus(restaurantId);
    return restaurant;
}

isolated function getMenu(int menuId) returns Menu|error {
    Menu menu = check dbClient->queryRow(`SELECT id, name, address FROM Menus WHERE id = ${menuId}`);
    menu.items = check getMenuItems(menuId);
    return menu;
}

isolated function getMenuItem(int menuItemId) returns MenuItem|error {
    MenuItem menuItem = check dbClient->queryRow(`SELECT id, name, price FROM MenuItems WHERE id = ${menuItemId}`);
    return menuItem;
}

isolated function getMenus(int? restaurantId) returns Menu[]|error {
    Menu[] menus = [];
    stream<Menu, error?> resultStream = dbClient->query(`SELECT id, name FROM Menus WHERE restaurantId = ${restaurantId}`);
    check from Menu menu in resultStream
        do {
            menu.items = check getMenuItems(menu.id);
            menus.push(menu);
        };
    return menus;
}

isolated function getMenuItems(int? menuId) returns MenuItem[]|error {
    MenuItem[] menuItems = [];
    stream<MenuItem, error?> resultStream = dbClient->query(`SELECT id, name, price FROM MenuItems WHERE menuId = ${menuId}`);
    check from MenuItem menuItem in resultStream
        do {
            menuItems.push(menuItem);
        };
    return menuItems;
}

isolated function deleteRestaurant(int restaurantId) returns error? {
    _ = check dbClient->execute(`DELETE FROM Restaurants WHERE id = ${restaurantId}`);
}

isolated function deleteMenu(int menuId) returns error? {
    _ = check dbClient->execute(`DELETE FROM Menus WHERE id = ${menuId}`);
}

isolated function deleteMenuItem(int menuItem) returns error? {
    _ = check dbClient->execute(`DELETE FROM MenuItems WHERE id = ${menuItem}`);
}

isolated function updateRestaurant(Restaurant restaurant, int id) returns Restaurant|error {
    _ = check dbClient->execute(`UPDATE Restaurants SET name=${restaurant.name}, address=${restaurant.address} WHERE id = ${id}`);
    restaurant.id = id;
    return restaurant;
}

isolated function updateMenu(Menu menu, int id) returns Menu|error {
    _ = check dbClient->execute(`UPDATE Menus SET name=${menu.name} WHERE id = ${id}`);
    menu.id = id;
    return menu;
}

isolated function updateMenuItem(MenuItem menuItem, int id) returns MenuItem|error {
    _ = check dbClient->execute(`UPDATE MenuItems SET name=${menuItem.name}, price=${menuItem.price} WHERE id = ${id}`);
    menuItem.id = id;
    return menuItem;
}
