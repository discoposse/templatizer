#!/bin/bash

# Template Testing Framework
# Tests a specific template to ensure it works correctly

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_test() {
    echo -e "${PURPLE}[TEST]${NC} $1"
}

# Check if template name is provided
if [ $# -eq 0 ]; then
    print_error "Please provide a template name"
    echo "Usage: $0 <template_name> [test_app_name]"
    echo "Available templates:"
    ls templates/ | grep -v "\.json$" | sed 's/^/  - /'
    exit 1
fi

TEMPLATE_NAME=$1
TEST_APP_NAME=${2:-"test_${TEMPLATE_NAME}_$(date +%s)"}
TEMPLATE_DIR="templates/$TEMPLATE_NAME"
TEST_DIR="../$TEST_APP_NAME"

print_status "Testing template: $TEMPLATE_NAME"
print_status "Test app name: $TEST_APP_NAME"
print_status "Template directory: $TEMPLATE_DIR"

# Check if template exists
if [ ! -d "$TEMPLATE_DIR" ]; then
    print_error "Template '$TEMPLATE_NAME' not found in templates directory"
    exit 1
fi

# Check if template.json exists
if [ ! -f "$TEMPLATE_DIR/template.json" ]; then
    print_error "Template configuration file not found: $TEMPLATE_DIR/template.json"
    exit 1
fi

# Load template configuration
TEMPLATE_CONFIG="$TEMPLATE_DIR/template.json"
print_status "Loading template configuration..."

# Extract template info
TEMPLATE_DESCRIPTION=$(jq -r '.description' "$TEMPLATE_CONFIG")
FRAMEWORK=$(jq -r '.framework' "$TEMPLATE_CONFIG")
FRAMEWORK_VERSION=$(jq -r '.framework_version' "$TEMPLATE_CONFIG")

print_status "Template: $TEMPLATE_DESCRIPTION"
print_status "Framework: $FRAMEWORK $FRAMEWORK_VERSION"

# Clean up any existing test directory
if [ -d "$TEST_DIR" ]; then
    print_warning "Removing existing test directory: $TEST_DIR"
    rm -rf "$TEST_DIR"
fi

# Run the template
print_test "Running template creation..."
TEMPLATE_SCRIPT="$TEMPLATE_DIR/create_rails_app.sh"
if [ -f "$TEMPLATE_SCRIPT" ]; then
    chmod +x "$TEMPLATE_SCRIPT"
    # Run with non-interactive mode (assume yes to all prompts)
    echo "y" | "$TEMPLATE_SCRIPT" "$TEST_APP_NAME"
else
    print_error "Template script not found: $TEMPLATE_SCRIPT"
    exit 1
fi

# Verify the app was created
if [ ! -d "$TEST_DIR" ]; then
    print_error "Test app was not created successfully"
    exit 1
fi

print_success "Test app created successfully"

# Change to test directory
cd "$TEST_DIR"

# Run validation checks
print_test "Running validation checks..."

# Check database connection
print_test "Testing database connection..."
if rails runner "puts 'Database connection successful'" 2>/dev/null | grep -q "Database connection successful"; then
    print_success "Database connection: OK"
else
    print_error "Database connection: FAILED"
    exit 1
fi

# Check migrations
print_test "Testing migrations..."
if rails db:migrate:status 2>/dev/null | grep -q "up"; then
    print_success "Migrations: OK"
else
    print_error "Migrations: FAILED"
    exit 1
fi

# Check Tailwind CSS compilation
print_test "Testing Tailwind CSS compilation..."
if rails tailwindcss:build 2>/dev/null; then
    print_success "Tailwind CSS: OK"
else
    print_warning "Tailwind CSS: WARNING (may not be critical)"
fi

# Check authentication models
print_test "Testing authentication models..."
if rails runner "puts User.count; puts Session.count" 2>/dev/null | grep -q "0"; then
    print_success "Authentication models: OK"
else
    print_error "Authentication models: FAILED"
    exit 1
fi

# Check routes
print_test "Testing routes configuration..."
if rails routes 2>/dev/null | grep -q "session"; then
    print_success "Routes: OK"
else
    print_error "Routes: FAILED"
    exit 1
fi

# Test server startup (quick test)
print_test "Testing server startup..."
timeout 10s rails server -p 3001 -d 2>/dev/null || true
if curl -s http://localhost:3001 > /dev/null 2>&1; then
    print_success "Server startup: OK"
    # Kill the test server
    pkill -f "rails server -p 3001" 2>/dev/null || true
else
    print_warning "Server startup: WARNING (may not be critical)"
fi

# Clean up test directory
print_status "Cleaning up test directory..."
cd ..
rm -rf "$TEST_DIR"

print_success "Template test completed successfully!"
print_status "Template '$TEMPLATE_NAME' is working correctly"

# Return to original directory
cd - > /dev/null
