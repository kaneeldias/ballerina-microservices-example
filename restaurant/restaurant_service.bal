import ballerina/http;
import ballerina/sql;

public type CreateMenuRequest record {|
    int restaurantId;
    Menu menu;
    MenuItem[] menuItems?;
|};

public type CreateMenuItemRequest record {|
    int menuId;
    MenuItem item;
|};

public type UpdateMenuRequest record {|
    string name;
|};

public type UpdateMenuItemRequest record {|
    string name;
    decimal price;
|};

service on new http:Listener(8081) {

    isolated resource function post restaurant(@http:Payload Restaurant restaurant) returns http:Created|error {
        Restaurant generatedRestaurant = check createRestaurant(restaurant);
        return <http:Created>{ body: {message: "New restaurant created", restaurant: generatedRestaurant} };
    }

    isolated resource function post menu(@http:Payload CreateMenuRequest menuRequest) returns http:Created|error {
        Menu generatedMenu = check createMenu(menuRequest.menu, menuRequest.restaurantId);
        return <http:Created>{ body: {message: "New menu created", menu: generatedMenu} };
    }

    isolated resource function post menuItem(@http:Payload CreateMenuItemRequest menuItemRequest) returns http:Created|error {
        MenuItem generatedMenuItem = check createMenuItem(menuItemRequest.item, menuItemRequest.menuId);
        return <http:Created>{ body: {message: "New menu item created", menuItem: generatedMenuItem} };
    }

    isolated resource function get restaurant/[int id]() returns Restaurant|http:NotFound|error {
        Restaurant|error restaurant = getRestaurant(id);
        if restaurant is sql:NoRowsError {
            return <http:NotFound>{ body: {message: "Cannot find restaurant with provided ID"} };
        }
        return restaurant;
    }

    isolated resource function get menu/[int id]() returns Menu|http:NotFound|error {
        Menu|error menu = getMenu(id);
        if menu is sql:NoRowsError {
            return <http:NotFound>{ body: {message: "Cannot find menu with provided ID"} };
        }
        return menu;
    }

    isolated resource function get menuItem/[int id]() returns MenuItem|http:NotFound|error {
        MenuItem|error menu = getMenuItem(id);
        if menu is sql:NoRowsError {
            return <http:NotFound>{ body: {message: "Cannot find menu with provided ID"} };
        }
        return menu;
    }

    isolated resource function delete restaurant/[int id]() returns http:Ok|error {
        _ = check deleteRestaurant(id);
        return <http:Ok>{ body: {message: "Restaurant deleted", id: id} };
    }

    isolated resource function delete menu/[int id]() returns http:Ok|error {
        _ = check deleteMenu(id);
        return <http:Ok>{ body: {message: "Menu deleted", id: id} };
    }

    isolated resource function delete menuItem/[int id]() returns http:Ok|error {
        _ = check deleteMenuItem(id);
        return <http:Ok>{ body: {message: "Menu item deleted", id: id} };
    }

    isolated resource function put restaurant/[int id](@http:Payload Restaurant restaurant) returns http:Ok|error {
        Restaurant generatedRestaurant = check updateRestaurant(restaurant, id);
        return <http:Ok>{ body: {message: "Restaurant updated", restaurant: generatedRestaurant} };
    }

    isolated resource function put menu/[int id](@http:Payload UpdateMenuRequest menu) returns http:Ok|error {
        Menu generatedMenu = check updateMenu(menu, id);
        return <http:Ok>{ body: {message: "Menu updated", menu: generatedMenu} };
    }

    isolated resource function put menuItem/[int id](@http:Payload UpdateMenuItemRequest menuItem) returns http:Ok|error {
        MenuItem generatedMenuItem = check updateMenuItem(menuItem, id);
        return <http:Ok>{ body: {message: "Menu item updated", menuItem: generatedMenuItem} };
    }

}
