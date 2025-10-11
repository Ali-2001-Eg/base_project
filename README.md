# Base Project

A Flutter base project with common setup (routing, localization, theming, networking, storage, notifications) for rapid app bootstrapping.

## 🚀 Quick Start

### Scaffold this project into a new directory

Use the scaffold script to copy this project into a new location, excluding build artefacts and caches.

#### Usage

```bash
./tools/scaffold.sh /absolute/path/to/new_project
```

**Notes:**
- Provide an absolute destination path.
- Existing destination directory is allowed; existing files are left untouched unless `--force` is used.
- Run from the repository root.

#### Options

- `--force`: Overwrite existing files in destination.
- `--name <app_name>`: Replace occurrences of `base_project` with your chosen name in key files.
- `--display-name <display_name>`: Set human-friendly app name (Android label, iOS display/name).
- `--android-id <package_id>`: Set Android applicationId and namespace (e.g. com.example.app).
- `--ios-id <bundle_id>`: Set iOS bundle identifier (e.g. com.example.app).

#### What gets excluded

- `build/`, `ios/Pods/`, `android/.gradle/`, platform build artefacts
- system files like `.DS_Store`
- IDE metadata like `.idea/`, `.vscode/`

#### Example

```bash
./tools/scaffold.sh ~/StudioProjects/my_new_app \
  --name my_new_app \
  --display-name "My New App" \
  --android-id com.example.mynewapp \
  --ios-id com.example.mynewapp
```

## 🛠️ Development Tools

### newFeature Script

Create complete features with full architecture setup using the interactive `newFeature` script.

#### Usage

```bash
./tools/newFeature.sh
```

#### What it creates

The script interactively guides you through creating:

1. **Endpoint Definition** - Adds new endpoint to `lib/core/http/endpoints.dart`
2. **Model** - Creates model with optional Hive support
3. **Data Source** - Generates data source with configurable methods
4. **BLoCs** - Creates appropriate BLoCs (paginated or individual)
5. **Service Locator** - Registers all dependencies
6. **Hive Integration** - Adds caching support if needed

#### Interactive Prompts

1. **Feature Name** (e.g., "users", "orders")
2. **Endpoint Path** (e.g., "/api/users")
3. **Hive Support** (yes/no for local caching)
4. **Model Fields** (name and type for each field)
5. **Data Source Methods** (1-5 methods with type selection)
6. **Method Types**:
   - `fetchData` - GET with pagination (creates PaginatedBloc)
   - `fetchResult` - GET single result
   - `postData` - POST
   - `updateData` - PUT
   - `deleteData` - DELETE

#### Generated File Structure

```
lib/features/{feature_name}/
├── models/
│   └── {feature_name}_model.dart
├── data_source/
│   ├── {feature_name}_data_source.dart
│   └── {feature_name}_paginated_cache.dart (if Hive enabled)
├── bloc/
│   ├── {method}_bloc.dart
│   └── {method}_event.dart (for non-paginated methods)
└── {feature_name}.dart (main feature file)
```

#### Example: Creating a "Users" Feature

```bash
$ ./tools/newFeature.sh

Enter feature name: users
Enter endpoint path: /api/users
Use Hive for caching? (y/n): y
Enter model fields (press Enter with empty field name to finish):
Field name: id
Field type: String
Field name: name
Field type: String
Field name: email
Field type: String
Field name: 
How many methods in data source? (1-5): 3
Method 1 name: getUsers
Choose method type (1-5): 1
Method 2 name: addUser
Choose method type (1-5): 3
Method 3 name: deleteUser
Choose method type (1-5): 5
```

#### Generated Files

**Model** (`lib/features/users/models/users_model.dart`):
```dart
@HiveType(typeId: 123)
class UsersModel extends Equatable {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String email;
  
  // Constructor, fromJson, toJson, props...
}
```

**Data Source** (`lib/features/users/data_source/users_data_source.dart`):
```dart
abstract interface class UsersDataSource {
  Future<Either<Failure, List<UsersModel>>> getUsers(PaginationParams params, {String? query});
  Future<Either<Failure, void>> addUser(UsersModel model);
  Future<Either<Failure, void>> deleteUser(int id);
}

class UsersDataSourceImpl implements UsersDataSource {
  // Implementation using GenericDataSource...
}
```

**BLoCs**:
- `GetUsersBloc` - Extends `PaginatedBloc<UsersModel>` for pagination
- `AddUserBloc` - Individual BLoC with `AddUserEvent`
- `DeleteUserBloc` - Individual BLoC with `DeleteUserEvent`

**Service Locator** (`lib/core/service_locator/users_service_locator/users_service_locator.dart`):
```dart
class UsersServiceLocator {
  static Future<void> execute({required GetIt getIt}) async {
    getIt.registerLazySingleton<UsersDataSource>(() => UsersDataSourceImpl(getIt<GenericDataSource>()));
    getIt.registerFactory<GetUsersBloc>(() => GetUsersBloc(getIt<UsersDataSource>()));
    getIt.registerFactory<AddUserBloc>(() => AddUserBloc(getIt<UsersDataSource>()));
    getIt.registerFactory<DeleteUserBloc>(() => DeleteUserBloc(getIt<UsersDataSource>()));
  }
}
```

#### Post-Generation Steps

1. **Generate Hive adapters** (if Hive was enabled):
   ```bash
   flutter packages pub run build_runner build
   ```

2. **Import in your app**:
   ```dart
   import 'package:base_project/features/users/users.dart';
   ```

3. **Use BLoCs in UI**:
   ```dart
   BlocProvider(
     create: (context) => getIt<GetUsersBloc>(),
     child: YourWidget(),
   )
   ```

## 🏗️ Architecture

### Core Components

- **Generic Data Source** - Handles all API calls with consistent error handling
- **Paginated BLoC** - Manages paginated data with caching and sync
- **Service Locator** - Dependency injection using GetIt
- **Hive Integration** - Local storage with type-safe caching
- **Base State** - Consistent state management across BLoCs

### Feature Structure

Each feature follows a consistent pattern:
- **Models** - Data classes with JSON serialization
- **Data Sources** - API interaction layer
- **BLoCs** - Business logic and state management
- **Service Locators** - Dependency registration

### Supported Operations

- **CRUD Operations** - Create, Read, Update, Delete
- **Pagination** - Automatic pagination with caching
- **Search/Filtering** - Query parameter support
- **Offline Support** - Hive-based local caching
- **Error Handling** - Consistent error states

## 📦 Dependencies

Key packages included:
- `flutter_bloc` - State management
- `dio` - HTTP client
- `hive_flutter` - Local storage
- `get_it` - Dependency injection
- `equatable` - Value equality
- `easy_localization` - Internationalization
- `go_router` - Navigation

## 🔧 Development

### Prerequisites

- Flutter SDK ^3.6.1
- Dart SDK
- iOS/Android development environment

### Setup

1. Clone the repository
2. Run `flutter pub get`
3. Generate code (if needed): `flutter packages pub run build_runner build`
4. Run the app: `flutter run`

### Code Generation

The project uses code generation for:
- Hive adapters (`hive_generator`)
- Build runner for additional code generation

Run after adding new Hive models:
```bash
flutter packages pub run build_runner build
```

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📞 Support

For questions or support, please open an issue in the repository.

lib/features/{feature_name}/
├── models/
│   ├── {feature_name}_model.dart
│   └── {feature_name}_model.g.dart (if Hive enabled)
├── data_source/
│   ├── {feature_name}_data_source.dart
│   └── {feature_name}_paginated_cache.dart (if Hive enabled)
├── bloc/
│   ├── {method}_bloc.dart
│   └── {method}_event.dart (for non-paginated methods)
├── presentation/
│   ├── pages/
│   │   └── {feature_name}_page.dart
│   └── widgets/
│       └── {feature_name}_widget.dart
└── {feature_name}.dart (main feature file)