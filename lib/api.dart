/// The endpoint of the backend.
const String api = "https://debt-system.runasp.net";
const int companyId = 22;
const int userId = 41;

/// [API] is used to hold and save all the endpoints of the `users` of the app for ease of access;
class UsersAPI {
  /// [GET] request to the API for signing in.
  /// Needs /[username]/[password]
  static const String signin = "/api/Users/FintByAuth";

  /// [GET] all users
  static const String users = "/api/Users/GetAll";

  /// [GET] single user
  static const String user = "/api/Users/Find/koko/userID";

  /// [POST] create a user;
  static const String createUser = "/api/Users/New";

  /// [PUT] Edit a user;
  static const String editUser = "/api/Users/UpdateUser";

  /// [DELETE] Delete a user;
  static const String deleteUser = "/api/Users/Delete";
}

/// [API] is used to hold and save all the endpoints of the `customers` of the app for ease of access;
class CategoriesAPI {
  /// [POST] request to the API for creating a category.
  static const String create = "/api/Categories/New";

  /// [GET] request to the API for creating a category.
  /// Takes [CategoryName]/[CompanyID]
  static const String exists = "/api/Categories/IsExist";

  /// [GET] all categories
  static const String categories = "/api/Categories/GetAll";

  /// [DELETE] Delete a category;
  static const String deleteCategory = "/api/Categories/Delete";
}

/// [API] is used to hold and save all the endpoints of the `customers` of the app for ease of access;
class ProductsAPI {
  /// [POST] request to the API for creating a category.
  static const String create = "/api/Products/New";

  /// [GET] request to the API for creating a category.
  /// Takes [CategoryName]/[CompanyID]
  static const String exists = "/api/Products/IsExist";

  /// [GET] all products
  static const String products = "/api/Products/GetAll";

  /// [GET] get products by category id
  /// Takes [CategoryId]/[CompanyId]
  static const String productsByCategory = "/api/Products/GetByCategoryId";

  /// [DELETE] Delete a category;
  static const String deleteCategory = "/api/Products/Delete";
}
