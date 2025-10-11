#!/bin/bash

# Template Debugging Tool
# Helps troubleshoot template issues and provides detailed diagnostics

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

print_debug() {
    echo -e "${PURPLE}[DEBUG]${NC} $1"
}

print_section() {
    echo -e "${CYAN}[SECTION]${NC} $1"
}

# Check if template name is provided
if [ $# -eq 0 ]; then
    print_error "Please provide a template name"
    echo "Usage: $0 <template_name> [debug_level]"
    echo "Debug levels: basic, detailed, verbose"
    echo "Available templates:"
    ls templates/ | grep -v "\.json$" | sed 's/^/  - /'
    exit 1
fi

TEMPLATE_NAME=$1
DEBUG_LEVEL=${2:-"basic"}
TEMPLATE_DIR="templates/$TEMPLATE_NAME"

print_section "🔍 Debugging Template: $TEMPLATE_NAME"
echo "================================================"

# Check if template exists
if [ ! -d "$TEMPLATE_DIR" ]; then
    print_error "Template '$TEMPLATE_NAME' not found"
    exit 1
fi

# 1. Template Structure Analysis
print_section "📁 Template Structure Analysis"
echo "----------------------------------------"

print_debug "Template directory: $TEMPLATE_DIR"
print_debug "Contents:"
ls -la "$TEMPLATE_DIR" | sed 's/^/  /'

# Check for required files
print_debug "Required files check:"
[ -f "$TEMPLATE_DIR/template.json" ] && print_success "✅ template.json exists" || print_error "❌ template.json missing"
[ -f "$TEMPLATE_DIR/create_rails_app.sh" ] && print_success "✅ create_rails_app.sh exists" || print_error "❌ create_rails_app.sh missing"

# 2. Template Configuration Analysis
print_section "⚙️  Template Configuration Analysis"
echo "----------------------------------------"

if [ -f "$TEMPLATE_DIR/template.json" ]; then
    print_debug "Configuration details:"
    echo "  Name: $(jq -r '.name' "$TEMPLATE_DIR/template.json")"
    echo "  Description: $(jq -r '.description' "$TEMPLATE_DIR/template.json")"
    echo "  Framework: $(jq -r '.framework' "$TEMPLATE_DIR/template.json")"
    echo "  Version: $(jq -r '.framework_version' "$TEMPLATE_DIR/template.json")"
    
    print_debug "Dependencies:"
    jq -r '.dependencies | to_entries[] | "  \(.key): \(.value)"' "$TEMPLATE_DIR/template.json"
    
    print_debug "Features:"
    jq -r '.features[] | "  - \(.)"' "$TEMPLATE_DIR/template.json"
    
    print_debug "Validation checks:"
    jq -r '.validation_checks[] | "  - \(.)"' "$TEMPLATE_DIR/template.json"
else
    print_error "Cannot analyze configuration - template.json missing"
fi

# 3. Script Analysis
print_section "🔧 Script Analysis"
echo "----------------------------------------"

if [ -f "$TEMPLATE_DIR/create_rails_app.sh" ]; then
    print_debug "Script analysis:"
    echo "  Size: $(wc -c < "$TEMPLATE_DIR/create_rails_app.sh") bytes"
    echo "  Lines: $(wc -l < "$TEMPLATE_DIR/create_rails_app.sh")"
    echo "  Executable: $([ -x "$TEMPLATE_DIR/create_rails_app.sh" ] && echo "Yes" || echo "No")"
    
    # Check for common issues
    print_debug "Common issues check:"
    
    # Check for hardcoded paths
    if grep -q "cd.*\.\." "$TEMPLATE_DIR/create_rails_app.sh"; then
        print_success "✅ Uses parent directory (../) correctly"
    else
        print_warning "⚠️  May not use parent directory structure"
    fi
    
    # Check for database handling
    if grep -q "db:drop\|db:create" "$TEMPLATE_DIR/create_rails_app.sh"; then
        print_success "✅ Has database reset logic"
    else
        print_warning "⚠️  May not handle existing databases"
    fi
    
    # Check for conflict detection
    if grep -q "CONFLICTS_FOUND\|conflict" "$TEMPLATE_DIR/create_rails_app.sh"; then
        print_success "✅ Has conflict detection"
    else
        print_warning "⚠️  May not detect conflicts"
    fi
    
    # Check for migration handling
    if grep -q "migration\|db:migrate" "$TEMPLATE_DIR/create_rails_app.sh"; then
        print_success "✅ Handles migrations"
    else
        print_warning "⚠️  May not handle migrations properly"
    fi
    
    # Check for Tailwind setup
    if grep -q "tailwind" "$TEMPLATE_DIR/create_rails_app.sh"; then
        print_success "✅ Has Tailwind CSS setup"
    else
        print_warning "⚠️  May not set up Tailwind CSS"
    fi
else
    print_error "Cannot analyze script - create_rails_app.sh missing"
fi

# 4. System Requirements Check
print_section "🖥️  System Requirements Check"
echo "----------------------------------------"

print_debug "System information:"
echo "  OS: $(uname -s)"
echo "  Architecture: $(uname -m)"
echo "  Shell: $SHELL"

print_debug "Required tools check:"
command -v ruby >/dev/null 2>&1 && print_success "✅ Ruby: $(ruby --version)" || print_error "❌ Ruby not found"
command -v rails >/dev/null 2>&1 && print_success "✅ Rails: $(rails --version)" || print_error "❌ Rails not found"
command -v psql >/dev/null 2>&1 && print_success "✅ PostgreSQL: $(psql --version)" || print_error "❌ PostgreSQL not found"
command -v node >/dev/null 2>&1 && print_success "✅ Node.js: $(node --version)" || print_error "❌ Node.js not found"
command -v jq >/dev/null 2>&1 && print_success "✅ jq: $(jq --version)" || print_error "❌ jq not found"

# 5. Detailed Analysis (if requested)
if [ "$DEBUG_LEVEL" = "detailed" ] || [ "$DEBUG_LEVEL" = "verbose" ]; then
    print_section "🔍 Detailed Analysis"
    echo "----------------------------------------"
    
    print_debug "Script syntax check:"
    if bash -n "$TEMPLATE_DIR/create_rails_app.sh" 2>/dev/null; then
        print_success "✅ Script syntax is valid"
    else
        print_error "❌ Script has syntax errors"
        bash -n "$TEMPLATE_DIR/create_rails_app.sh"
    fi
    
    print_debug "Shell script best practices:"
    # Check for set -e
    if grep -q "set -e" "$TEMPLATE_DIR/create_rails_app.sh"; then
        print_success "✅ Uses 'set -e' for error handling"
    else
        print_warning "⚠️  Does not use 'set -e'"
    fi
    
    # Check for proper error handling
    if grep -q "print_error\|echo.*ERROR" "$TEMPLATE_DIR/create_rails_app.sh"; then
        print_success "✅ Has error handling"
    else
        print_warning "⚠️  May lack proper error handling"
    fi
fi

# 6. Verbose Analysis (if requested)
if [ "$DEBUG_LEVEL" = "verbose" ]; then
    print_section "🔬 Verbose Analysis"
    echo "----------------------------------------"
    
    print_debug "Full script content analysis:"
    echo "  Functions defined: $(grep -c "^[a-zA-Z_][a-zA-Z0-9_]*()" "$TEMPLATE_DIR/create_rails_app.sh" || echo "0")"
    echo "  Print statements: $(grep -c "print_" "$TEMPLATE_DIR/create_rails_app.sh" || echo "0")"
    echo "  Rails commands: $(grep -c "rails " "$TEMPLATE_DIR/create_rails_app.sh" || echo "0")"
    echo "  Database commands: $(grep -c "db:" "$TEMPLATE_DIR/create_rails_app.sh" || echo "0")"
    
    print_debug "Potential issues:"
    # Check for hardcoded values
    if grep -q "localhost:3000" "$TEMPLATE_DIR/create_rails_app.sh"; then
        print_warning "⚠️  Contains hardcoded localhost:3000"
    fi
    
    # Check for missing error handling
    if grep -q "rails new" "$TEMPLATE_DIR/create_rails_app.sh" && ! grep -q "set -e" "$TEMPLATE_DIR/create_rails_app.sh"; then
        print_warning "⚠️  Rails new command without error handling"
    fi
fi

# 7. Recommendations
print_section "💡 Recommendations"
echo "----------------------------------------"

print_debug "Based on the analysis, here are some recommendations:"

# Check if template has all recommended features
if [ -f "$TEMPLATE_DIR/template.json" ]; then
    if jq -e '.validation_checks[] | select(. == "database_connection")' "$TEMPLATE_DIR/template.json" >/dev/null; then
        print_success "✅ Has database connection validation"
    else
        print_warning "💡 Consider adding database connection validation"
    fi
    
    if jq -e '.validation_checks[] | select(. == "migration_success")' "$TEMPLATE_DIR/template.json" >/dev/null; then
        print_success "✅ Has migration validation"
    else
        print_warning "💡 Consider adding migration validation"
    fi
fi

print_debug "General recommendations:"
print_warning "💡 Ensure all dependencies are documented"
print_warning "💡 Add comprehensive error handling"
print_warning "💡 Include rollback procedures for failed installations"
print_warning "💡 Test on multiple environments"

print_section "🏁 Debug Analysis Complete"
echo "================================================"
print_status "Debug analysis completed for template: $TEMPLATE_NAME"
print_status "Debug level: $DEBUG_LEVEL"
print_status "For more detailed analysis, run with 'detailed' or 'verbose' level"
