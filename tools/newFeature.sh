#!/usr/bin/env bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to capitalize first letter (compatible with bash 3.2+)
capitalize() {
  echo "$1" | sed 's/^./\U&/'
}

print_usage() {
  cat <<'USAGE'
Create a new feature with complete architecture setup.

Usage:
  tools/newFeature.sh

This script will interactively guide you through creating:
- Endpoint definition
- Model (with optional Hive support)
- Data source with methods
- BLoCs (with optional pagination)
- Service locator integration
- Hive integration (if needed)

Run from the repository root.
USAGE
}

log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running from repo root
if [[ ! -f "pubspec.yaml" ]]; then
  log_error "Run this script from the repository root (pubspec.yaml not found)."
  exit 1
fi

# Feature name input
read -p "Enter feature name (e.g., 'users', 'orders'): " FEATURE_NAME
if [[ -z "$FEATURE_NAME" ]]; then
  log_error "Feature name is required"
  exit 1
fi

# Convert to proper case
FEATURE_NAME_LOWER=$(echo "$FEATURE_NAME" | tr '[:upper:]' '[:lower:]')
FEATURE_NAME_CAPITALIZED=$(echo "$FEATURE_NAME_LOWER" | sed 's/^./\U&/')
FEATURE_NAME_UPPERCASE=$(echo "$FEATURE_NAME_LOWER" | tr '[:lower:]' '[:upper:]')

log_info "Creating feature: $FEATURE_NAME_CAPITALIZED"

# 1. Add endpoint
log_info "Adding endpoint..."
read -p "Enter endpoint path (e.g., '/api/users'): " ENDPOINT_PATH
if [[ -z "$ENDPOINT_PATH" ]]; then
  log_error "Endpoint path is required"
  exit 1
fi

# Add to endpoints.dart
ENDPOINTS_FILE="lib/core/http/endpoints.dart"
if [[ -f "$ENDPOINTS_FILE" ]]; then
  # Check if endpoint already exists
  if grep -q "static const String $FEATURE_NAME_LOWER" "$ENDPOINTS_FILE"; then
    log_warning "Endpoint already exists in $ENDPOINTS_FILE"
  else
    # Add new endpoint (use perl for cross-platform compatibility)
    perl -i -pe 'print "  static const String '"$FEATURE_NAME_LOWER"' = \"'"$ENDPOINT_PATH"'\";\n" if /^}/ && !$done++' "$ENDPOINTS_FILE"
    log_success "Added endpoint: $FEATURE_NAME_LOWER = \"$ENDPOINT_PATH\""
  fi
else
  log_error "Endpoints file not found: $ENDPOINTS_FILE"
  exit 1
fi

# 2. Model creation
log_info "Creating model..."
read -p "Use Hive for caching? (y/n): " USE_HIVE

# Get model fields
log_info "Enter model fields (press Enter with empty field name to finish):"
MODEL_FIELDS=()
FIELD_TYPES=()
while true; do
  read -p "Field name: " FIELD_NAME
  if [[ -z "$FIELD_NAME" ]]; then
    break
  fi
  read -p "Field type (String, int, bool, etc.): " FIELD_TYPE
  if [[ -z "$FIELD_TYPE" ]]; then
    FIELD_TYPE="String"
  fi
  MODEL_FIELDS+=("$FIELD_NAME")
  FIELD_TYPES+=("$FIELD_TYPE")
done

if [[ ${#MODEL_FIELDS[@]} -eq 0 ]]; then
  log_error "At least one field is required"
  exit 1
fi

# Create model file
MODEL_FILE="lib/features/$FEATURE_NAME_LOWER/models/${FEATURE_NAME_LOWER}_model.dart"
mkdir -p "lib/features/$FEATURE_NAME_LOWER/models"

cat > "$MODEL_FILE" << EOF
import 'package:equatable/equatable.dart';
EOF

if [[ "$USE_HIVE" == "y" ]]; then
  cat >> "$MODEL_FILE" << EOF
import 'package:hive_flutter/hive_flutter.dart';
part '${FEATURE_NAME_LOWER}_model.g.dart';
@HiveType(typeId: $((RANDOM % 1000 + 100)))
EOF
else
  cat >> "$MODEL_FILE" << EOF
part '${FEATURE_NAME_LOWER}_model.g.dart';
EOF
fi

cat >> "$MODEL_FILE" << EOF
class ${FEATURE_NAME_CAPITALIZED}Model extends Equatable{
EOF

# Add Hive fields if needed
if [[ "$USE_HIVE" == "y" ]]; then
  for i in "${!MODEL_FIELDS[@]}"; do
    echo "  @HiveField($i)" >> "$MODEL_FILE"
    echo "  final ${FIELD_TYPES[$i]} ${MODEL_FIELDS[$i]};" >> "$MODEL_FILE"
  done
else
  for i in "${!MODEL_FIELDS[@]}"; do
    echo "  final ${FIELD_TYPES[$i]} ${MODEL_FIELDS[$i]};" >> "$MODEL_FILE"
  done
fi

cat >> "$MODEL_FILE" << EOF

  const ${FEATURE_NAME_CAPITALIZED}Model({
EOF

for field in "${MODEL_FIELDS[@]}"; do
  echo "    required this.$field," >> "$MODEL_FILE"
done

cat >> "$MODEL_FILE" << EOF
  });

  factory ${FEATURE_NAME_CAPITALIZED}Model.fromJson(Map<String, dynamic> json) =>
      ${FEATURE_NAME_CAPITALIZED}Model(
EOF

for i in "${!MODEL_FIELDS[@]}"; do
  field="${MODEL_FIELDS[$i]}"
  type="${FIELD_TYPES[$i]}"
  if [[ "$type" == "String" ]]; then
    echo "        $field: json['$field'] ?? \"\"," >> "$MODEL_FILE"
  elif [[ "$type" == "int" ]]; then
    echo "        $field: json['$field'] ?? 0," >> "$MODEL_FILE"
  elif [[ "$type" == "bool" ]]; then
    echo "        $field: json['$field'] ?? false," >> "$MODEL_FILE"
  else
    echo "        $field: json['$field']," >> "$MODEL_FILE"
  fi
done

cat >> "$MODEL_FILE" << EOF
      );

  Map<String, dynamic> toJson() => {
EOF

for field in "${MODEL_FIELDS[@]}"; do
  echo "    '$field': $field," >> "$MODEL_FILE"
done

cat >> "$MODEL_FILE" << EOF
  };

  @override
  List<Object?> get props => [${MODEL_FIELDS[*]}];

}
EOF

log_success "Created model: $MODEL_FILE"

# 3. Data source creation
log_info "Creating data source..."
read -p "How many methods in data source? (1-5): " METHOD_COUNT
if ! [[ "$METHOD_COUNT" =~ ^[1-5]$ ]]; then
  log_error "Method count must be between 1 and 5"
  exit 1
fi

# Get methods
METHODS=()
METHOD_TYPES=()
for ((i=1; i<=METHOD_COUNT; i++)); do
  read -p "Method $i name (e.g., 'getUsers', 'addUser'): " METHOD_NAME
  if [[ -z "$METHOD_NAME" ]]; then
    log_error "Method name is required"
    exit 1
  fi

  echo "Method types:"
  echo "1) fetchData (GET with pagination)"
  echo "2) fetchResult (GET single result)"
  echo "3) postData (POST)"
  echo "4) updateData (PUT)"
  echo "5) deleteData (DELETE)"
  read -p "Choose method type (1-5): " METHOD_TYPE_CHOICE

  case $METHOD_TYPE_CHOICE in
    1) METHOD_TYPE="fetchData" ;;
    2) METHOD_TYPE="fetchResult" ;;
    3) METHOD_TYPE="postData" ;;
    4) METHOD_TYPE="updateData" ;;
    5) METHOD_TYPE="deleteData" ;;
    *) log_error "Invalid method type"; exit 1 ;;
  esac

  METHODS+=("$METHOD_NAME")
  METHOD_TYPES+=("$METHOD_TYPE")
done

# Create data source file
DATASOURCE_FILE="lib/features/$FEATURE_NAME_LOWER/data_source/${FEATURE_NAME_LOWER}_data_source.dart"
mkdir -p "lib/features/$FEATURE_NAME_LOWER/data_source"

cat > "$DATASOURCE_FILE" << EOF
part of "../${FEATURE_NAME_LOWER}.dart";
abstract interface class ${FEATURE_NAME_CAPITALIZED}DataSource{
EOF

# Add method signatures
for i in "${!METHODS[@]}"; do
  method="${METHODS[$i]}"
  type="${METHOD_TYPES[$i]}"

  if [[ "$type" == "fetchData" ]]; then
    echo "  Future<Either<Failure,List<${FEATURE_NAME_CAPITALIZED}Model>>> $method(PaginationParams params,{String? query});" >> "$DATASOURCE_FILE"
  elif [[ "$type" == "fetchResult" ]]; then
    echo "  Future<Either<Failure,${FEATURE_NAME_CAPITALIZED}Model>> $method(int id);" >> "$DATASOURCE_FILE"
  elif [[ "$type" == "postData" ]]; then
    echo "  Future<Either<Failure,void>> $method(${FEATURE_NAME_CAPITALIZED}Model model);" >> "$DATASOURCE_FILE"
  elif [[ "$type" == "updateData" ]]; then
    echo "  Future<Either<Failure,void>> $method(${FEATURE_NAME_CAPITALIZED}Model model);" >> "$DATASOURCE_FILE"
  elif [[ "$type" == "deleteData" ]]; then
    echo "  Future<Either<Failure,void>> $method(int id);" >> "$DATASOURCE_FILE"
  fi
done

cat >> "$DATASOURCE_FILE" << EOF
}
class ${FEATURE_NAME_CAPITALIZED}DataSourceImpl implements ${FEATURE_NAME_CAPITALIZED}DataSource{
  final GenericDataSource _genericDataSource;
  ${FEATURE_NAME_CAPITALIZED}DataSourceImpl(this._genericDataSource);

EOF

# Add method implementations
for i in "${!METHODS[@]}"; do
  method="${METHODS[$i]}"
  type="${METHOD_TYPES[$i]}"

  echo "  @override" >> "$DATASOURCE_FILE"

  if [[ "$type" == "fetchData" ]]; then
    cat >> "$DATASOURCE_FILE" << EOF
  Future<Either<Failure, List<${FEATURE_NAME_CAPITALIZED}Model>>> $method(PaginationParams params, {String? query}) {
   return _genericDataSource.fetchData<${FEATURE_NAME_CAPITALIZED}Model>(endpoint: Endpoints.$FEATURE_NAME_LOWER, fromJson: ${FEATURE_NAME_CAPITALIZED}Model.fromJson,queryParameters: {
     'query': query,
   });
  }
EOF
  elif [[ "$type" == "fetchResult" ]]; then
    cat >> "$DATASOURCE_FILE" << EOF
  Future<Either<Failure, ${FEATURE_NAME_CAPITALIZED}Model>> $method(int id) {
    return _genericDataSource.fetchResult<${FEATURE_NAME_CAPITALIZED}Model>(endpoint: Endpoints.$FEATURE_NAME_LOWER, queryParameters: {'id': id}, fromJson: ${FEATURE_NAME_CAPITALIZED}Model.fromJson);
  }
EOF
  elif [[ "$type" == "postData" ]]; then
    cat >> "$DATASOURCE_FILE" << EOF
  Future<Either<Failure, void>> $method(${FEATURE_NAME_CAPITALIZED}Model model) {
    return _genericDataSource.postData<void>(endpoint: Endpoints.$FEATURE_NAME_LOWER, data: model.toJson());
  }
EOF
  elif [[ "$type" == "updateData" ]]; then
    cat >> "$DATASOURCE_FILE" << EOF
  Future<Either<Failure, void>> $method(${FEATURE_NAME_CAPITALIZED}Model model) {
   return  _genericDataSource.updateData(endpoint: Endpoints.$FEATURE_NAME_LOWER,data: model.toJson());
  }
EOF
  elif [[ "$type" == "deleteData" ]]; then
    cat >> "$DATASOURCE_FILE" << EOF
  Future<Either<Failure, void>> $method(int id) {
    return _genericDataSource.deleteData<void>(endpoint: Endpoints.$FEATURE_NAME_LOWER,data: {'id':id});
  }
EOF
  fi

  echo "" >> "$DATASOURCE_FILE"
done

cat >> "$DATASOURCE_FILE" << EOF
}
EOF

log_success "Created data source: $DATASOURCE_FILE"

# 4. BLoC creation
log_info "Creating BLoCs..."

# Check if any method uses fetchData (pagination)
HAS_PAGINATION=false
for type in "${METHOD_TYPES[@]}"; do
  if [[ "$type" == "fetchData" ]]; then
    HAS_PAGINATION=true
    break
  fi
done

# Create BLoCs directory
mkdir -p "lib/features/$FEATURE_NAME_LOWER/bloc"

# Create paginated BLoC if needed
if [[ "$HAS_PAGINATION" == "true" ]]; then
  for i in "${!METHODS[@]}"; do
    method="${METHODS[$i]}"
    type="${METHOD_TYPES[$i]}"

    if [[ "$type" == "fetchData" ]]; then
      METHOD_CAPITALIZED=$(capitalize "$method")
      cat > "lib/features/$FEATURE_NAME_LOWER/bloc/${method}_bloc.dart" << EOF
part of '../${FEATURE_NAME_LOWER}.dart';
class ${METHOD_CAPITALIZED}Bloc extends PaginatedBloc<${FEATURE_NAME_CAPITALIZED}Model> {
  final ${FEATURE_NAME_CAPITALIZED}DataSource _${FEATURE_NAME_LOWER}DataSource;
  ${METHOD_CAPITALIZED}Bloc(this._${FEATURE_NAME_LOWER}DataSource): super(fetchPage: (page,limit,query,params) => _${FEATURE_NAME_LOWER}DataSource.$method(PaginationParams(limit: limit, page: page),query: params?["query"]??""),cacheKeyBuilder: (query,_)=> "$method");
}
EOF
      log_success "Created paginated BLoC: ${method}_bloc.dart"
    fi
  done
fi

# Create individual BLoCs for non-paginated methods
for i in "${!METHODS[@]}"; do
  method="${METHODS[$i]}"
  type="${METHOD_TYPES[$i]}"

  if [[ "$type" != "fetchData" ]]; then
    METHOD_CAPITALIZED=$(capitalize "$method")

    # Create event file
    cat > "lib/features/$FEATURE_NAME_LOWER/bloc/${method}_event.dart" << EOF
part of '../${FEATURE_NAME_LOWER}.dart';
class ${METHOD_CAPITALIZED}Event extends Equatable{
EOF

    if [[ "$type" == "fetchResult" || "$type" == "deleteData" ]]; then
      echo "  final int id;" >> "lib/features/$FEATURE_NAME_LOWER/bloc/${method}_event.dart"
      echo "  const ${METHOD_CAPITALIZED}Event({required this.id});" >> "lib/features/$FEATURE_NAME_LOWER/bloc/${method}_event.dart"
      echo "  @override" >> "lib/features/$FEATURE_NAME_LOWER/bloc/${method}_event.dart"
      echo "  List<Object?> get props => [id];" >> "lib/features/$FEATURE_NAME_LOWER/bloc/${method}_event.dart"
    elif [[ "$type" == "postData" || "$type" == "updateData" ]]; then
      echo "  final ${FEATURE_NAME_CAPITALIZED}Model model;" >> "lib/features/$FEATURE_NAME_LOWER/bloc/${method}_event.dart"
      echo "  const ${METHOD_CAPITALIZED}Event({required this.model});" >> "lib/features/$FEATURE_NAME_LOWER/bloc/${method}_event.dart"
      echo "  @override" >> "lib/features/$FEATURE_NAME_LOWER/bloc/${method}_event.dart"
      echo "  List<Object?> get props => [model];" >> "lib/features/$FEATURE_NAME_LOWER/bloc/${method}_event.dart"
    fi

    cat >> "lib/features/$FEATURE_NAME_LOWER/bloc/${method}_event.dart" << EOF

}
EOF

    # Create BLoC file
    cat > "lib/features/$FEATURE_NAME_LOWER/bloc/${method}_bloc.dart" << EOF
part of '../${FEATURE_NAME_LOWER}.dart';
class ${METHOD_CAPITALIZED}Bloc extends Bloc<${METHOD_CAPITALIZED}Event, BaseState<void>>{
  final ${FEATURE_NAME_CAPITALIZED}DataSource _${FEATURE_NAME_LOWER}DataSource;
  ${METHOD_CAPITALIZED}Bloc(this._${FEATURE_NAME_LOWER}DataSource):super(BaseState<void>()){
    on<${METHOD_CAPITALIZED}Event>(_on${METHOD_CAPITALIZED});
  }
  FutureOr<void> _on${METHOD_CAPITALIZED}(${METHOD_CAPITALIZED}Event event, Emitter<BaseState<void>> emit) async {
    emit(state.copyWith(status: Status.loading));
EOF

    if [[ "$type" == "fetchResult" ]]; then
      cat >> "lib/features/$FEATURE_NAME_LOWER/bloc/${method}_bloc.dart" << EOF
    final result = await _${FEATURE_NAME_LOWER}DataSource.$method(event.id);
    emit(
      result.fold(
          (leftFn) => state.copyWith(status: Status.failure, errorMessage: leftFn.message)
      , (rightFn) => state.copyWith(status: Status.success, data: rightFn))
    );
EOF
    else
      if [[ "$type" == "deleteData" ]]; then
        cat >> "lib/features/$FEATURE_NAME_LOWER/bloc/${method}_bloc.dart" << EOF
    final result = await _${FEATURE_NAME_LOWER}DataSource.$method(event.id);
    emit(
      result.fold(
          (leftFn) => state.copyWith(status: Status.failure, errorMessage: leftFn.message)
      , (rightFn) => state.copyWith(status: Status.success))
    );
EOF
      else
        cat >> "lib/features/$FEATURE_NAME_LOWER/bloc/${method}_bloc.dart" << EOF
    final result = await _${FEATURE_NAME_LOWER}DataSource.$method(event.model);
    emit(
      result.fold(
          (leftFn) => state.copyWith(status: Status.failure, errorMessage: leftFn.message)
      , (rightFn) => state.copyWith(status: Status.success))
    );
EOF
      fi
    fi

    cat >> "lib/features/$FEATURE_NAME_LOWER/bloc/${method}_bloc.dart" << EOF

  }
}
EOF

    log_success "Created BLoC: ${method}_bloc.dart and ${method}_event.dart"
  fi
done

# 5. Create main feature file
FEATURE_FILE="lib/features/$FEATURE_NAME_LOWER/${FEATURE_NAME_LOWER}.dart"
cat > "$FEATURE_FILE" << EOF
import 'dart:async';

import 'package:base_project/core/bloc/paginated_bloc/exports.dart';
import 'package:base_project/core/enum/status.dart';
import 'package:base_project/core/helpers/helpers.dart';
import 'package:base_project/core/http/either.dart';
import 'package:base_project/core/http/failure.dart';
import 'package:base_project/core/http/http.dart';
import 'package:base_project/core/params/params.dart';
import 'package:base_project/features/$FEATURE_NAME_LOWER/models/${FEATURE_NAME_LOWER}_model.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part "data_source/${FEATURE_NAME_LOWER}_data_source.dart";
EOF

# Add part files for BLoCs
for method in "${METHODS[@]}"; do
  echo "part 'bloc/${method}_bloc.dart';" >> "$FEATURE_FILE"
  # Check if this specific method is not fetchData
  for i in "${!METHODS[@]}"; do
    if [[ "${METHODS[$i]}" == "$method" && "${METHOD_TYPES[$i]}" != "fetchData" ]]; then
      echo "part 'bloc/${method}_event.dart';" >> "$FEATURE_FILE"
      break
    fi
  done
done

log_success "Created feature file: $FEATURE_FILE"

# 5.5. Create presentation directories
log_info "Creating presentation directories..."
mkdir -p "lib/features/$FEATURE_NAME_LOWER/presentation/pages"
mkdir -p "lib/features/$FEATURE_NAME_LOWER/presentation/widgets"

# Create placeholder files
cat > "lib/features/$FEATURE_NAME_LOWER/presentation/pages/${FEATURE_NAME_LOWER}_page.dart" << EOF
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:base_project/features/$FEATURE_NAME_LOWER/${FEATURE_NAME_LOWER}.dart';
import 'package:base_project/core/service_locator/service_locator.dart';

class ${FEATURE_NAME_CAPITALIZED}Page extends StatelessWidget {
  const ${FEATURE_NAME_CAPITALIZED}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${FEATURE_NAME_CAPITALIZED}'),
      ),
      body: BlocProvider(
        create: (context) => getIt<Get${FEATURE_NAME_CAPITALIZED}Bloc>(),
        child: const ${FEATURE_NAME_CAPITALIZED}View(),
      ),
    );
  }
}

class ${FEATURE_NAME_CAPITALIZED}View extends StatelessWidget {
  const ${FEATURE_NAME_CAPITALIZED}View({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<Get${FEATURE_NAME_CAPITALIZED}Bloc, BaseState<${FEATURE_NAME_CAPITALIZED}Model>>(
      builder: (context, state) {
        if (state.status == Status.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (state.status == Status.failure) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: \${state.errorMessage}'),
                ElevatedButton(
                  onPressed: () {
                    context.read<Get${FEATURE_NAME_CAPITALIZED}Bloc>().add(
                      LoadFirstPage<${FEATURE_NAME_CAPITALIZED}Model>(params: null, query: null),
                    );
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          itemCount: state.items.length,
          itemBuilder: (context, index) {
            final item = state.items[index];
            return ListTile(
              title: Text(item.toString()),
              // Add more UI elements based on your model fields
            );
          },
        );
      },
    );
  }
}
EOF

cat > "lib/features/$FEATURE_NAME_LOWER/presentation/widgets/${FEATURE_NAME_LOWER}_widget.dart" << EOF
import 'package:flutter/material.dart';
import 'package:base_project/features/$FEATURE_NAME_LOWER/${FEATURE_NAME_LOWER}.dart';

class ${FEATURE_NAME_CAPITALIZED}Widget extends StatelessWidget {
  final ${FEATURE_NAME_CAPITALIZED}Model ${FEATURE_NAME_LOWER};
  
  const ${FEATURE_NAME_CAPITALIZED}Widget({
    super.key,
    required this.${FEATURE_NAME_LOWER},
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(${FEATURE_NAME_LOWER}.toString()),
        // Customize based on your model fields
        // Example: Text(${FEATURE_NAME_LOWER}.name),
      ),
    );
  }
}
EOF

log_success "Created presentation directories and files"

# 6. Hive integration
if [[ "$USE_HIVE" == "y" ]]; then
  log_info "Adding Hive integration..."

  # Add adapter to HiveServiceImpl
  HIVE_SERVICE_FILE="lib/core/local_storage/hive_service_impl.dart"
  if [[ -f "$HIVE_SERVICE_FILE" ]]; then
    # Add adapter registration (use perl for cross-platform compatibility)
    perl -i -pe 'print "    Hive.registerAdapter('"${FEATURE_NAME_CAPITALIZED}"'ModelAdapter());\n" if /Hive.registerAdapter\(ProductsModelAdapter\(\)\);/ && !$done++' "$HIVE_SERVICE_FILE"

    log_success "Added Hive adapter registration"
  fi

  # Create paginated cache implementation
  CACHE_FILE="lib/features/$FEATURE_NAME_LOWER/data_source/${FEATURE_NAME_LOWER}_paginated_cache.dart"
  cat > "$CACHE_FILE" << EOF
part of '../${FEATURE_NAME_LOWER}.dart';

class ${FEATURE_NAME_CAPITALIZED}PaginatedCache implements IPaginatedCache<${FEATURE_NAME_CAPITALIZED}Model> {
  final HiveServiceImpl _hiveService;

  const ${FEATURE_NAME_CAPITALIZED}PaginatedCache(this._hiveService);

  @override
  Future<void> cachePage(List<${FEATURE_NAME_CAPITALIZED}Model> items, {required String cacheKey}) async {
    await _hiveService._cachePage(items, cacheKey: cacheKey);
  }

  @override
  Future<List<${FEATURE_NAME_CAPITALIZED}Model>> getCachedPage({required String cacheKey}) async {
    return await _hiveService._getCachedPage<${FEATURE_NAME_CAPITALIZED}Model>(cacheKey: cacheKey);
  }

  @override
  Future<void> clearCachedPage({required String cacheKey}) async {
    await _hiveService._clearCachedPage<${FEATURE_NAME_CAPITALIZED}Model>(cacheKey: cacheKey);
  }
}
EOF

  # Add to feature file
  echo "part 'data_source/${FEATURE_NAME_LOWER}_paginated_cache.dart';" >> "$FEATURE_FILE"

  # Add to Hive service locator
  HIVE_SERVICE_LOCATOR_FILE="lib/core/service_locator/hive_service_locator/hive_service_locator.dart"
  if [[ -f "$HIVE_SERVICE_LOCATOR_FILE" ]]; then
    perl -i -pe 'print "    getIt.registerLazySingleton<IPaginatedCache<'"${FEATURE_NAME_CAPITALIZED}"'Model>>(() => '"${FEATURE_NAME_CAPITALIZED}"'PaginatedCache(getIt<HiveServiceImpl>()));\n" if /getIt.registerLazySingleton<IPaginatedCache<ProductsModel>>/ && !$done++' "$HIVE_SERVICE_LOCATOR_FILE"

  log_success "Added paginated cache to Hive service locator"
  
  # Create generated model file placeholder
  GENERATED_MODEL_FILE="lib/features/$FEATURE_NAME_LOWER/models/${FEATURE_NAME_LOWER}_model.g.dart"
  cat > "$GENERATED_MODEL_FILE" << EOF
// GENERATED CODE - DO NOT MODIFY BY HAND

part of '${FEATURE_NAME_LOWER}_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ${FEATURE_NAME_CAPITALIZED}ModelAdapter extends TypeAdapter<${FEATURE_NAME_CAPITALIZED}Model> {
  @override
  final int typeId = $((RANDOM % 1000 + 100));

  @override
  ${FEATURE_NAME_CAPITALIZED}Model read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ${FEATURE_NAME_CAPITALIZED}Model(
EOF

  # Add field assignments for generated model
  for i in "${!MODEL_FIELDS[@]}"; do
    field="${MODEL_FIELDS[$i]}"
    type="${FIELD_TYPES[$i]}"
    echo "      $field: fields[$i] as $type," >> "$GENERATED_MODEL_FILE"
  done

  cat >> "$GENERATED_MODEL_FILE" << EOF
    );
  }

  @override
  void write(BinaryWriter writer, ${FEATURE_NAME_CAPITALIZED}Model obj) {
    writer
      ..writeByte(${#MODEL_FIELDS[@]})
EOF

  # Add field writes for generated model
  for i in "${!MODEL_FIELDS[@]}"; do
    field="${MODEL_FIELDS[$i]}"
    echo "      ..writeByte($i)" >> "$GENERATED_MODEL_FILE"
    echo "      ..write(obj.$field);" >> "$GENERATED_MODEL_FILE"
  done

  cat >> "$GENERATED_MODEL_FILE" << EOF
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ${FEATURE_NAME_CAPITALIZED}ModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
EOF

  log_success "Created generated model file: $GENERATED_MODEL_FILE"
fi
fi

# 7. Create service locator
SERVICE_LOCATOR_FILE="lib/core/service_locator/${FEATURE_NAME_LOWER}_service_locator/${FEATURE_NAME_LOWER}_service_locator.dart"
mkdir -p "lib/core/service_locator/${FEATURE_NAME_LOWER}_service_locator"

cat > "$SERVICE_LOCATOR_FILE" << EOF
part of '../service_locator.dart';
class ${FEATURE_NAME_CAPITALIZED}ServiceLocator {
  static Future<void> execute({required GetIt getIt}) async {
    getIt.registerLazySingleton<${FEATURE_NAME_CAPITALIZED}DataSource>(()=> ${FEATURE_NAME_CAPITALIZED}DataSourceImpl(getIt<GenericDataSource>()),);
EOF

# Add BLoC registrations
for method in "${METHODS[@]}"; do
  METHOD_CAPITALIZED=$(capitalize "$method")
  echo "    getIt.registerFactory<${METHOD_CAPITALIZED}Bloc>(()=> ${METHOD_CAPITALIZED}Bloc(getIt<${FEATURE_NAME_CAPITALIZED}DataSource>(),));" >> "$SERVICE_LOCATOR_FILE"
done

cat >> "$SERVICE_LOCATOR_FILE" << EOF
  }
}
EOF

log_success "Created service locator: $SERVICE_LOCATOR_FILE"

# 8. Add to main service locator
MAIN_SERVICE_LOCATOR_FILE="lib/core/service_locator/init/init.dart"
if [[ -f "$MAIN_SERVICE_LOCATOR_FILE" ]]; then
  perl -i -pe 'print "    await '"${FEATURE_NAME_CAPITALIZED}"'ServiceLocator.execute(getIt: getIt);\n" if /await ProductsServiceLocator.execute\(getIt: getIt\);/ && !$done++' "$MAIN_SERVICE_LOCATOR_FILE"

  log_success "Added service locator to main init"
fi

# 9. Add to service locator exports
SERVICE_LOCATOR_EXPORTS_FILE="lib/core/service_locator/service_locator.dart"
if [[ -f "$SERVICE_LOCATOR_EXPORTS_FILE" ]]; then
  perl -i -pe 'print "part '\'''"${FEATURE_NAME_LOWER}"'_service_locator/'"${FEATURE_NAME_LOWER}"'_service_locator.dart'\'';\n" if /part '\''products_service_locator\/products_service_locator.dart'\'';/ && !$done++' "$SERVICE_LOCATOR_EXPORTS_FILE"

  log_success "Added to service locator exports"
fi

log_success "Feature '$FEATURE_NAME_CAPITALIZED' created successfully!"
log_info "Next steps:"
log_info "1. Run 'flutter packages pub run build_runner build' to generate files"
log_info "2. Import the feature in your app: import 'package:base_project/features/$FEATURE_NAME_LOWER/${FEATURE_NAME_LOWER}.dart';"
log_info "3. Use the BLoCs in your UI widgets"

echo ""
log_info "Created files:"
echo "  - $MODEL_FILE"
echo "  - $DATASOURCE_FILE"
echo "  - $FEATURE_FILE"
echo "  - $SERVICE_LOCATOR_FILE"
echo "  - lib/features/$FEATURE_NAME_LOWER/presentation/pages/${FEATURE_NAME_LOWER}_page.dart"
echo "  - lib/features/$FEATURE_NAME_LOWER/presentation/widgets/${FEATURE_NAME_LOWER}_widget.dart"
for i in "${!METHODS[@]}"; do
  method="${METHODS[$i]}"
  type="${METHOD_TYPES[$i]}"
  echo "  - lib/features/$FEATURE_NAME_LOWER/bloc/${method}_bloc.dart"
  if [[ "$type" != "fetchData" ]]; then
    echo "  - lib/features/$FEATURE_NAME_LOWER/bloc/${method}_event.dart"
  fi
done
if [[ "$USE_HIVE" == "y" ]]; then
  echo "  - $CACHE_FILE"
  echo "  - $GENERATED_MODEL_FILE"
fi