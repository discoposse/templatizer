#!/bin/bash

# Comprehensive Test Runner
# Runs all template tests and validation checks

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

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

print_status "🧪 Running Templatizer Test Suite"
echo "================================================"

# Test results tracking
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to run a test and track results
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    print_test "Running: $test_name"
    
    if eval "$test_command" 2>/dev/null; then
        print_success "✅ $test_name: PASSED"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        print_error "❌ $test_name: FAILED"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

# 1. Validate template configurations
print_status "📋 Validating template configurations..."
for template_dir in templates/*/; do
    if [ -d "$template_dir" ] && [ "$(basename "$template_dir")" != "*.json" ]; then
        template_name=$(basename "$template_dir")
        if [ -f "$template_dir/template.json" ]; then
            run_test "Template config: $template_name" "jq empty '$template_dir/template.json'"
        else
            print_warning "Template $template_name missing template.json"
        fi
    fi
done

# 2. Test template scripts
print_status "🔧 Testing template scripts..."
for template_dir in templates/*/; do
    if [ -d "$template_dir" ] && [ "$(basename "$template_dir")" != "*.json" ]; then
        template_name=$(basename "$template_dir")
        script_file="$template_dir/create_rails_app.sh"
        if [ -f "$script_file" ]; then
            run_test "Script exists: $template_name" "test -f '$script_file'"
            run_test "Script executable: $template_name" "test -x '$script_file'"
        else
            print_warning "Template $template_name missing create script"
        fi
    fi
done

# 3. Test individual templates (if not in CI environment)
if [ -z "$CI" ]; then
    print_status "🚀 Testing template execution..."
    for template_dir in templates/*/; do
        if [ -d "$template_dir" ] && [ "$(basename "$template_dir")" != "*.json" ]; then
            template_name=$(basename "$template_dir")
            if [ -f "$template_dir/create_rails_app.sh" ]; then
                print_status "Testing template: $template_name"
                if ./scripts/test-template.sh "$template_name" "test_${template_name}_$(date +%s)"; then
                    print_success "✅ Template $template_name: PASSED"
                    PASSED_TESTS=$((PASSED_TESTS + 1))
                else
                    print_error "❌ Template $template_name: FAILED"
                    FAILED_TESTS=$((FAILED_TESTS + 1))
                fi
                TOTAL_TESTS=$((TOTAL_TESTS + 1))
            fi
        fi
    done
else
    print_warning "Skipping template execution tests in CI environment"
fi

# 4. Test project structure
print_status "📁 Validating project structure..."
run_test "Package.json exists" "test -f package.json"
run_test "Scripts directory exists" "test -d scripts"
run_test "Templates directory exists" "test -d templates"
run_test "Documentation exists" "test -f README.md"

# 5. Test documentation
print_status "📚 Validating documentation..."
run_test "README exists" "test -f README.md"
run_test "Quick start guide exists" "test -f QUICK_START.md"
run_test "Setup guide exists" "test -f SETUP.md"

# Print test summary
echo ""
echo "================================================"
print_status "📊 Test Results Summary"
echo "================================================"
print_success "Total Tests: $TOTAL_TESTS"
print_success "Passed: $PASSED_TESTS"
if [ $FAILED_TESTS -gt 0 ]; then
    print_error "Failed: $FAILED_TESTS"
else
    print_success "Failed: $FAILED_TESTS"
fi

# Calculate success rate
if [ $TOTAL_TESTS -gt 0 ]; then
    SUCCESS_RATE=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    print_status "Success Rate: $SUCCESS_RATE%"
    
    if [ $SUCCESS_RATE -eq 100 ]; then
        print_success "🎉 All tests passed!"
        exit 0
    elif [ $SUCCESS_RATE -ge 80 ]; then
        print_warning "⚠️  Most tests passed, but some issues found"
        exit 1
    else
        print_error "💥 Many tests failed, needs attention"
        exit 1
    fi
else
    print_warning "No tests were run"
    exit 1
fi
