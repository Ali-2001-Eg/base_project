#!/usr/bin/env bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
    # Add new endpoint
    sed -i '' "/^}/i\\
  static const String $FEATURE_NAME_LOWER = \"$ENDPOINT_PATH\";" "$ENDPOINTS_FILE"
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
      cat > "lib/features/$FEATURE_NAME_LOWER/bloc/${method}_bloc.dart" << EOF
part of '../../${FEATURE_NAME_LOWER}.dart';
class ${method^}Bloc extends PaginatedBloc<${FEATURE_NAME_CAPITALIZED}Model> {
  final ${FEATURE_NAME_CAPITALIZED}DataSource _${FEATURE_NAME_LOWER}DataSource;
  ${method^}Bloc(this._${FEATURE_NAME_LOWER}DataSource): super(fetchPage: (page,limit,query,params) => _${FEATURE_NAME_LOWER}DataSource.$method(PaginationParams(limit: limit, page: page),query: params?["query"]??""),cacheKeyBuilder: (query,_)=> "$method");
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
    # Create event file
    cat > "lib/features/$FEATURE_NAME_LOWER/bloc/${method}_event.dart" << EOF
part of '../../${FEATURE_NAME_LOWER}.dart';
class ${method^}Event extends Equatable{
EOF
    
    if [[ "$type" == "fetchResult" || "$type" == "deleteData" ]]; then
      echo "  final int id;" >> "lib/features/$FEATURE_NAME_LOWER/bloc/${method}_event.dart"
      echo "  const ${method^}Event({required this.id});" >> "lib/features/$FEATURE_NAME_LOWER/bloc/${method}_event.dart"
      echo "  @override" >> "lib/features/$FEATURE_NAME_LOWER/bloc/${method}_event.dart"
      echo "  List<Object?> get props => [id];" >> "lib/features/$FEATURE_NAME_LOWER/bloc/${method}_event.dart"
    elif [[ "$type" == "postData" || "$type" == "updateData" ]]; then
      echo "  final ${FEATURE_NAME_CAPITALIZED}Model model;" >> "lib/features/$FEATURE_NAME_LOWER/bloc/${method}_event.dart"
      echo "  const ${method^}Event({required this.model});" >> "lib/features/$FEATURE_NAME_LOWER/bloc/${method}_event.dart"
      echo "  @override" >> "lib/features/$FEATURE_NAME_LOWER/bloc/${method}_event.dart"
      echo "  List<Object?> get props => [model];" >> "lib/features/$FEATURE_NAME_LOWER/bloc/${method}_event.dart"
    fi
    
    cat >> "lib/features/$FEATURE_NAME_LOWER/bloc/${method}_event.dart" << EOF

}
EOF
    
    # Create BLoC file
    cat > "lib/features/$FEATURE_NAME_LOWER/bloc/${method}_bloc.dart" << EOF
part of '../../${FEATURE_NAME_LOWER}.dart';
class ${method^}Bloc extends Bloc<${method^}Event, BaseState<void>>{
  final ${FEATURE_NAME_CAPITALIZED}DataSource _${FEATURE_NAME_LOWER}DataSource;
  ${method^}Bloc(this._${FEATURE_NAME_LOWER}DataSource):super(BaseState<void>()){
    on<${method^}Event>(_on${method^});
  }
  FutureOr<void> _on${method^}(${method^}Event event, Emitter<BaseState<void>> emit) async {
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
      cat >> "lib/features/$FEATURE_NAME_LOWER/bloc/${method}_bloc.dart" << EOF
    final result = await _${FEATURE_NAME_LOWER}DataSource.$method(${type == "deleteData" ? "event.id" : "event.model"});
    emit(
      result.fold(
          (leftFn) => state.copyWith(status: Status.failure, errorMessage: leftFn.message)
      , (rightFn) => state.copyWith(status: Status.success))
    );
EOF
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
  echo "part 'bloc/${method}/${method}_bloc.dart';" >> "$FEATURE_FILE"
  if [[ ! " ${METHOD_TYPES[*]} " =~ " fetchData " ]]; then
    echo "part 'bloc/${method}/${method}_event.dart';" >> "$FEATURE_FILE"
  fi
done

log_success "Created feature file: $FEATURE_FILE"

# 6. Hive integration
if [[ "$USE_HIVE" == "y" ]]; then
  log_info "Adding Hive integration..."
  
  # Add adapter to HiveServiceImpl
  HIVE_SERVICE_FILE="lib/core/local_storage/hive_service_impl.dart"
  if [[ -f "$HIVE_SERVICE_FILE" ]]; then
    # Add adapter registration
    sed -i '' "/Hive.registerAdapter(ProductsModelAdapter());/a\\
    Hive.registerAdapter(${FEATURE_NAME_CAPITALIZED}ModelAdapter());" "$HIVE_SERVICE_FILE"
    
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
    sed -i '' "/getIt.registerLazySingleton<IPaginatedCache<ProductsModel>>/a\\
    getIt.registerLazySingleton<IPaginatedCache<${FEATURE_NAME_CAPITALIZED}Model>>(() => ${FEATURE_NAME_CAPITALIZED}PaginatedCache(getIt<HiveServiceImpl>()));" "$HIVE_SERVICE_LOCATOR_FILE"
    
    log_success "Added paginated cache to Hive service locator"
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
  echo "    getIt.registerFactory<${method^}Bloc>(()=> ${method^}Bloc(getIt<${FEATURE_NAME_CAPITALIZED}DataSource>(),));" >> "$SERVICE_LOCATOR_FILE"
done

cat >> "$SERVICE_LOCATOR_FILE" << EOF
  }
}
EOF

log_success "Created service locator: $SERVICE_LOCATOR_FILE"

# 8. Add to main service locator
MAIN_SERVICE_LOCATOR_FILE="lib/core/service_locator/init/init.dart"
if [[ -f "$MAIN_SERVICE_LOCATOR_FILE" ]]; then
  sed -i '' "/await ProductsServiceLocator.execute(getIt: getIt);/a\\
    await ${FEATURE_NAME_CAPITALIZED}ServiceLocator.execute(getIt: getIt);" "$MAIN_SERVICE_LOCATOR_FILE"
  
  log_success "Added service locator to main init"
fi

# 9. Add to service locator exports
SERVICE_LOCATOR_EXPORTS_FILE="lib/core/service_locator/service_locator.dart"
if [[ -f "$SERVICE_LOCATOR_EXPORTS_FILE" ]]; then
  sed -i '' "/part 'products_service_locator\/products_service_locator.dart';/a\\
part '${FEATURE_NAME_LOWER}_service_locator\/${FEATURE_NAME_LOWER}_service_locator.dart';" "$SERVICE_LOCATOR_EXPORTS_FILE"
  
  log_success "Added to service locator exports"
fi

log_success "Feature '$FEATURE_NAME_CAPITALIZED' created successfully!"
log_info "Next steps:"
log_info "1. Run 'flutter packages pub run build_runner build' to generate Hive adapters"
log_info "2. Import the feature in your app: import 'package:base_project/features/$FEATURE_NAME_LOWER/${FEATURE_NAME_LOWER}.dart';"
log_info "3. Use the BLoCs in your UI widgets"

echo ""
log_info "Created files:"
echo "  - $MODEL_FILE"
echo "  - $DATASOURCE_FILE"
echo "  - $FEATURE_FILE"
echo "  - $SERVICE_LOCATOR_FILE"
for method in "${METHODS[@]}"; do
  echo "  - lib/features/$FEATURE_NAME_LOWER/bloc/${method}_bloc.dart"
  if [[ ! " ${METHOD_TYPES[*]} " =~ " fetchData " ]]; then
    echo "  - lib/features/$FEATURE_NAME_LOWER/bloc/${method}_event.dart"
  fi
done
if [[ "$USE_HIVE" == "y" ]]; then
  echo "  - $CACHE_FILE"
fi
