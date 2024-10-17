#!/bin/bash
set -e  # Detener el script si ocurre algún error

# Cargar las variables de entorno desde el archivo .env
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)  # Carga de variables ignorando líneas de comentarios
fi

# Función para verificar que todas las variables requeridas para una base de datos estén definidas
check_db_vars() {
    local prefix=$1
    local required_vars=("${prefix}_DB_NAME" "${prefix}_DB_USER" "${prefix}_DB_PASSWORD" "${prefix}_DB_HOST" "${prefix}_DB_PORT")
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            echo "Error: Variable de entorno $var no está definida."
            return 1
        fi
    done
    return 0
}

# Crear función para verificar y crear base de datos y usuario
create_db_and_user() {
    local db_name=$1
    local db_user=$2
    local db_password=$3
    local db_host=$4
    local db_port=$5

    echo "Creating database '$db_name' and user '$db_user'..."

    PSQL="psql -h $db_host -p $db_port -U postgres"

    # Crear el usuario si no existe
    if ! $PSQL -tc "SELECT 1 FROM pg_roles WHERE rolname='$db_user'" | grep -q 1; then
        $PSQL -c "CREATE USER $db_user WITH PASSWORD '$db_password';"
    else
        echo "User '$db_user' already exists."
    fi

    # Crear la base de datos si no existe
    if ! $PSQL -tc "SELECT 1 FROM pg_database WHERE datname = '$db_name'" | grep -q 1; then
        $PSQL -c "CREATE DATABASE $db_name OWNER $db_user;"
    else
        echo "Database '$db_name' already exists."
    fi

    echo "Database '$db_name' and user '$db_user' created or already exist."
}

# Crear base de datos principal
if check_db_vars "POSTGRES"; then
    create_db_and_user "$POSTGRES_DB" "$POSTGRES_USER" "$POSTGRES_PASSWORD" "$POSTGRES_HOST" "$POSTGRES_PORT"
else
    echo "Error: No se pudieron crear las variables de la base de datos principal."
    exit 1
fi

# Crear base de datos para Binance Trader
if check_db_vars "BINANCE_TRADER"; then
    create_db_and_user "$BINANCE_TRADER_DB_NAME" "$BINANCE_TRADER_DB_USER" "$BINANCE_TRADER_DB_PASSWORD" "$BINANCE_TRADER_DB_HOST" "$BINANCE_TRADER_DB_PORT"
else
    echo "Error: No se pudieron crear las variables de la base de datos Binance Trader."
    exit 1
fi

echo "All databases and users are set up."
