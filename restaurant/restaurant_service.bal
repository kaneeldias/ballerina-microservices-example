import ballerina/http;
import ballerina/sql;

# Request body to be used when creating a restaurant
type CreateRestaurantRequest record {|
    # The name of the restaurant
    string name;
    # The address of the restauarant
    string address;
    # The menus offered by the restaurant
    CreateRestaurantRequestMenu[] menus;
|};

# Representation for a menu to be used when creating a restaurant
type CreateRestaurantRequestMenu record {|
    # The name of the menue
    string name;
    # The items contained within the menu
    CreateMenuRequestMenuItem[] items;
|};

# Representation for a menu item to be used when creating a menu
type CreateMenuRequestMenuItem record {|
    # The name of the menu item
    string name;
    # The price of the menu item
    decimal price;
|};

# Request body to be used when creating a menu
type CreateMenuRequest record {|
    # The name of the menu
    string name;
    # The items contained within the menu
    CreateMenuRequestMenuItem[] menuItems;
|};

# Request body to be used when creating a menu item
type CreateMenuItemRequest record {|
    # The name of the menu item
    string name;
    # The price of the menu item
    decimal price;
|};

# The request body to be used when updating the details of a restaurant
type UpdateRestaurantRequest record {|
    # The updated name of the restaurant
    string name;
    # The updated address of the restaurant
    string address;
|};

# The request body to be used when updating the details of a menu
type UpdateMenuRequest record {|
    # The updated name of the menu
    string name;
|};

# The request body to be used when updating the details of a menu item
type UpdateMenuItemRequest record {|
    # The updated name of the menu item
    string name;
    # The price of the menu item
    decimal price;
|};

# Response for a successful restaurant creation
type RestaurantCreated record {|
    *http:Created;
    # Details of the created restaurant along with the HTTP links to manage it
    record {|
        *Restaurant;
        *http:Links;
    |} body;
|};

# Response for a successful menu creation
type MenuCreated record {|
    *http:Created;
    # Details of the created menu along with the HTTP links to manage it
    record {|
        *Menu;
        *http:Links;
    |} body;
|};

# Response for a successful menu item creation
type MenuItemCreated record {|
    *http:Created;
    # Details of the created menu item along with the HTTP links to manage it
    record {|
        *MenuItem;
        *http:Links;
    |} body;
|};

# Error response for when the requested restaurant cannot be found
type RestaurantNotFound record {|
    *http:NotFound;
    # Error message
    readonly record {} body = { 
        "message": "Restaurant cannot be found." 
    };
|};

# Error response for when the requested menu cannot be found
type MenuNotFound record {|
    *http:NotFound;
    # Error message
    readonly record {} body = { 
        "message": "Menu cannot be found." 
    };
|};

# Error response for when the requested menu item cannot be found
type MenuItemNotFound record {|
    *http:NotFound;
    # Error message
    readonly record {} body = { 
        "message": "Menu cannot be found." 
    };
|};

# Response for a successful restaurant retrieval
type RestaurantView record {|
    *http:Ok;
    # Details of the retrieved restaurant along with the HTTP links to manage it
    record {|
        *Restaurant;
        *http:Links;
    |} body;
|};

# Response for a successful menu retrieval
type MenuView record {|
    *http:Ok;
    # Details of the retrieved menu along with the HTTP links to manage it
    record {|
        *Menu;
        *http:Links;
    |} body;
|};

# Response for a successful menu item retrieval
type MenuItemView record {|
    *http:Ok;
    # Details of the retrieved menu item along with the HTTP links to manage it
    record {|
        *MenuItem;
        *http:Links;
    |} body;
|};

# Response for a successful restaurant deletion
type RestaurantDeleted record {|
    *http:Ok;
    # Details of the deleted restaurant
    Restaurant body;
|};

# Response for a successful menu deletion
type MenuDeleted record {|
    *http:Ok;
    # Details of the deleted menu
    Menu body;
|};

# Response for a successful menu item deletion
type MenuItemDeleted record {|
    *http:Ok;
    # Details of the deleted menu item
    MenuItem body;
|};

# Response for a successful restaurant update
type RestaurantUpdated record {|
    *http:Ok;
    # Details of the updated restaurant along with the HTTP links to manage it
    record {|
        *Restaurant;
        *http:Links;
    |} body;
|};

# Response for a successful menu update
type MenuUpdated record {|
    *http:Ok;
    # Details of the updated menu along with the HTTP links to manage itz
    record {|
        *Menu;
        *http:Links;
    |} body;
|};

# Response for a successful menu item update
type MenuItemUpdated record {|
    *http:Ok;
    # Details of the updated menu itemn along with the HTTP links to manage it
    record {|
        *MenuItem;
        *http:Links;
    |} body;
|};

# Represents an unexpected error
public type RestaurantInternalError record {|
   *http:InternalServerError;
    # Error payload
    record {| 
        string message;
    |} body;
|}; 


service on new http:Listener(8081) {

    isolated resource function post restaurant(@http:Payload CreateRestaurantRequest request) returns RestaurantCreated|RestaurantInternalError {
        do {
            transaction {
                Restaurant generatedRestaurant = check createRestaurant(request.name, request.address);

                foreach CreateRestaurantRequestMenu menu in request.menus {
                    Menu generatedMenu = check createMenu(menu.name, generatedRestaurant.id);

                    foreach CreateMenuRequestMenuItem menuItem in menu.items {
                        MenuItem generatedMenuItem = check createMenuItem(menuItem.name, menuItem.price, generatedMenu.id);
                        generatedMenu.items.push(generatedMenuItem);
                    }

                    generatedRestaurant.menus.push(generatedMenu);
                }

                check commit;

                return <RestaurantCreated>{ 
                    headers: {
                        location: "/restaurant/" + generatedRestaurant.id.toString()
                    },
                    body: {
                        ...generatedRestaurant,
                        links: getRestaurantLinks(generatedRestaurant.id)
                    }
                };
            }
        } on fail error e {
            return <RestaurantInternalError>{ body: { message: e.toString() }};
        }
    }

    isolated resource function post restaurant/[int restaurantId]/menu(@http:Payload CreateMenuRequest request) returns MenuCreated|RestaurantInternalError {
        do {
            transaction {
                Menu generatedMenu = check createMenu(request.name, restaurantId);

                foreach CreateMenuRequestMenuItem menuItem in request.menuItems {
                    MenuItem generatedMenuItem = check createMenuItem(menuItem.name, menuItem.price, generatedMenu.id);
                    generatedMenu.items.push(generatedMenuItem);
                }

                check commit;

                return <MenuCreated>{ 
                    headers: {
                        location: "/menu/" + generatedMenu.id.toString()
                    },
                    body: {
                        ...generatedMenu,
                        links: getMenuLinks(generatedMenu.id, restaurantId)
                    }
                };
            }
        } on fail error e {
            return <RestaurantInternalError>{ body: { message: e.toString() }};
        }
    }

    isolated resource function post restaurant/[int restaurantId]/menu/[int menuId]/item(@http:Payload CreateMenuItemRequest request) returns MenuItemCreated|RestaurantInternalError {
        do {
            MenuItem generatedMenuItem = check createMenuItem(request.name, request.price, menuId);
            return <MenuItemCreated>{ 
                headers: {
                    location: "/restaurant/" + restaurantId.toString() + "/menu/" + menuId.toString() + "/menuItem/" + generatedMenuItem.id.toString()
                },
                body: {
                    ...generatedMenuItem,
                    links: getMenuItemLinks(generatedMenuItem.id, menuId, restaurantId)
                }
            };
        } on fail error e {
            return <RestaurantInternalError>{ body: { message: e.toString() }};
        }
    }

    isolated resource function get restaurant/[int restaurantId]() returns RestaurantView|RestaurantNotFound|RestaurantInternalError {
        do {
            Restaurant restaurant = check getRestaurant(restaurantId);
            return <RestaurantView>{ 
                body: {
                    ...restaurant,
                    links: getRestaurantLinks(restaurant.id)
                }
            };
        } on fail error e {
            if e is sql:NoRowsError {
                return <RestaurantNotFound>{};
            }
            return <RestaurantInternalError>{ body: { message: e.toString() }};
        } 
    }

    isolated resource function get restaurant/[int restaurantId]/menu/[int menuId]() returns MenuView|MenuNotFound|RestaurantInternalError {
        do {
            Menu menu = check getMenu(menuId);
            return <MenuView>{ 
                body: {
                    ...menu,
                    links: getMenuLinks(menu.id, restaurantId)
                }
            };
        } on fail error e {
            if e is sql:NoRowsError {
                return <MenuNotFound>{};
            }
            return <RestaurantInternalError>{ body: { message: e.toString() }};
        } 
    }

    isolated resource function get restaurant/[int restaurantId]/menu/[int menuId]/item/[int menuItemId]() returns MenuItemView|MenuItemNotFound|RestaurantInternalError {
        do {
            MenuItem menuItem = check getMenuItem(menuItemId);
            return <MenuItemView>{ 
                body: {
                    ...menuItem,
                    links: getMenuItemLinks(menuItem.id, menuId, restaurantId)
                }
            };
        } on fail error e {
            if e is sql:NoRowsError {
                return <MenuItemNotFound>{};
            }
            return <RestaurantInternalError>{ body: { message: e.toString() }};
        } 
    }

    isolated resource function delete restaurant/[int restaurantId]() returns RestaurantDeleted|RestaurantNotFound|RestaurantInternalError {
        do {
            Restaurant restaurant = check deleteRestaurant(restaurantId);
            return <RestaurantDeleted>{ body: restaurant};
        } on fail error e {
            if e is sql:NoRowsError {
                return <RestaurantNotFound>{};
            }
            return <RestaurantInternalError>{ body: { message: e.toString() }};
        }   
    }

    isolated resource function delete restaurant/[int restaurantId]/menu/[int menuId]() returns MenuDeleted|MenuNotFound|RestaurantInternalError {
        do {
            Menu menu = check deleteMenu(menuId);
            return <MenuDeleted>{ body: menu};
        } on fail error e {
            if e is sql:NoRowsError {
                return <MenuNotFound>{};
            }
            return <RestaurantInternalError>{ body: { message: e.toString() }};
        }
    }

    isolated resource function delete restaurant/[int restaurantId]/menu/[int menuId]/menuItem/[int menuItemId]() returns MenuItemDeleted|MenuItemNotFound|RestaurantInternalError {
         do {
            MenuItem menuitem = check deleteMenuItem(menuItemId);
            return <MenuItemDeleted>{ body: menuitem};
        } on fail error e {
            if e is sql:NoRowsError {
                return <MenuItemNotFound>{};
            }
            return <RestaurantInternalError>{ body: { message: e.toString() }};
        }
    }

    isolated resource function put restaurant/[int restaurantId](@http:Payload UpdateRestaurantRequest request) returns RestaurantUpdated|RestaurantNotFound|RestaurantInternalError {
        do {
            Restaurant updatedRestaurant = check updateRestaurant(restaurantId, request.name, request.address);
            return <RestaurantUpdated>{ 
                body: { 
                    ...updatedRestaurant,
                    links: getRestaurantLinks(updatedRestaurant.id)
                }
            };
        } on fail error e {
            if e is sql:NoRowsError {
                return <RestaurantNotFound>{};
            }
            return <RestaurantInternalError>{ body: { message: e.toString() }};
        }       
    }

    isolated resource function put restaurant/[int restaurantId]/menu/[int menuId](@http:Payload UpdateMenuRequest request) returns MenuUpdated|MenuNotFound|RestaurantInternalError {
        do {
            Menu updatedMenu = check updateMenu(menuId, request.name);
            return <MenuUpdated>{ 
                body: {
                    ...updatedMenu,
                    links: getMenuLinks(updatedMenu.id, restaurantId)
                }
            };
        } on fail error e {
            if e is sql:NoRowsError {
                return <RestaurantNotFound>{};
            }
            return <RestaurantInternalError>{ body: { message: e.toString() }};
        }  
    }

    isolated resource function put restaurant/[int restaurantId]/menu/[int menuId]/item/[int menuItemId](@http:Payload UpdateMenuItemRequest request) returns MenuItemUpdated|MenuItemNotFound|RestaurantInternalError {
        do {
            MenuItem updatedMenuItem = check updateMenuItem(menuItemId, request.name, request.price);
            return <MenuItemUpdated>{ 
                body: {
                    ...updatedMenuItem,
                    links: getMenuItemLinks(updatedMenuItem.id, menuId, restaurantId)
                }
            };
        } on fail error e {
            if e is sql:NoRowsError {
                return <MenuItemNotFound>{};
            }
            return <RestaurantInternalError>{ body: { message: e.toString() }};
        }  
    }

}

isolated function getRestaurantLinks(int restaurantId) returns http:Link[] {
    return [
        {
            rel: "view",
            href: "/restaurant/" + restaurantId.toString(),
            methods: [http:GET]
        },
        {
            rel: "update",
            href: "/restaurant/" + restaurantId.toString(),
            methods: [http:PUT]
        },
        {
            rel: "delete",
            href: "/restaurant/" + restaurantId.toString(),
            methods: [http:DELETE]
        }
    ];
}

isolated function getMenuLinks(int menuId, int parentRestaurantId) returns http:Link[] {
    return [
        {
            rel: "view",
            href: "/restaurant/" + parentRestaurantId.toString() + "/menu/" + menuId.toString(),
            methods: [http:GET]
        },
        {
            rel: "update",
            href: "/restaurant/" + parentRestaurantId.toString() + "/menu/" + menuId.toString(),
            methods: [http:PUT]
        },
        {
            rel: "delete",
            href: "/restaurant/" + parentRestaurantId.toString() + "/menu/" + menuId.toString(),
            methods: [http:DELETE]
        },
        {
            rel: "parent restaurant",
            href: "/restaurant/" + parentRestaurantId.toString(),
            methods: [http:GET]
        }
    ];
}

isolated function getMenuItemLinks(int menuItemId, int parentMenuId, int parentRestaurantId) returns http:Link[] {
    return [
        {
            rel: "view",
            href: "/restaurant/" + parentRestaurantId.toString() + "/menu/" + parentMenuId.toString() + "/item/" + menuItemId.toString(),
            methods: [http:GET]
        },
        {
            rel: "update",
            href: "/restaurant/" + parentRestaurantId.toString() + "/menu/" + parentMenuId.toString() + "/item/" + menuItemId.toString(),
            methods: [http:PUT]
        },
        {
            rel: "delete",
            href: "/restaurant/" + parentRestaurantId.toString() + "/menu/" + parentMenuId.toString() + "/item/" + menuItemId.toString(),
            methods: [http:DELETE]
        },
        {
            rel: "parent menu",
            href: "/restaurant/" + parentRestaurantId.toString() + "/menu/" + parentMenuId.toString(),
            methods: [http:GET]
        },
        {
            rel: "parent restaurant",
            href: "/restaurant/" + parentRestaurantId.toString(),
            methods: [http:GET]
        }
    ];
}
