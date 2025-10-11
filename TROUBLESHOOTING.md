# 🔧 Troubleshooting Guide

This guide covers common issues and their solutions when using Templatizer.

## 🚨 Critical Issues (Fixed in Current Version)

### 1. Authentication System Errors

#### Problem: `NoMethodError: undefined method 'unauthenticated_access_only'`
```
NoMethodError (undefined method 'unauthenticated_access_only' for class SignUpsController)
```

**Root Cause**: The `unauthenticated_access_only` method was defined as an instance method instead of a class method.

**Solution**: ✅ **FIXED** - The template now properly defines this method in the `class_methods` block:

```ruby
class_methods do
  def unauthenticated_access_only(**options)
    allow_unauthenticated_access(**options)
    before_action -> { redirect_to root_path if authenticated? }, **options
  end
end
```

**If you encounter this in an existing app**:
1. Update `app/controllers/concerns/authentication.rb`
2. Move `unauthenticated_access_only` into the `class_methods` block
3. Restart your Rails server

### 2. Routing Errors

#### Problem: `ActionController::RoutingError: No route matches [GET] "/sign_up"`
```
ActionController::RoutingError (No route matches [GET] "/sign_up")
```

**Root Cause**: Navigation links were pointing to `/sign_up` instead of `/sign_up/new`.

**Solution**: ✅ **FIXED** - All navigation links now use correct route helpers:
- Sign up form: `new_sign_up_path` → `/sign_up/new`
- Sign in form: `new_session_path` → `/session/new`

**If you encounter this in an existing app**:
1. Update navigation links in `app/views/layouts/application.html.erb`
2. Update home page links in `app/views/home/index.html.erb`
3. Change `sign_up_path` to `new_sign_up_path`

### 3. Database Conflicts

#### Problem: `PG::DuplicateTable: ERROR: relation "users" already exists`
```
PG::DuplicateTable: ERROR: relation "users" already exists
```

**Root Cause**: Running the script multiple times without proper database cleanup.

**Solution**: ✅ **FIXED** - Template now includes smart conflict detection:
- Automatically detects existing databases
- Prompts user for overwrite confirmation
- Performs clean database reset when needed

**If you encounter this**:
```bash
# Manual database reset
rails db:drop db:create db:migrate
```

### 4. Migration Errors

#### Problem: `ActiveRecord::DuplicateMigrationNameError`
```
ActiveRecord::DuplicateMigrationNameError: Multiple migrations have the name AddIndexesToUsers
```

**Root Cause**: Script was creating duplicate migration files.

**Solution**: ✅ **FIXED** - Template now:
- Finds existing generated migrations
- Updates content without creating duplicates
- Handles index creation intelligently

### 5. Duplicate Index Errors

#### Problem: `PG::DuplicateTable: ERROR: relation "index_users_on_email_address" already exists`
```
PG::DuplicateTable: ERROR: relation "index_users_on_email_address" already exists
```

**Root Cause**: Rails automatically creates indexes for `string:uniq` fields, but migrations were trying to create them again.

**Solution**: ✅ **FIXED** - Template now:
- Only adds necessary indexes in migrations
- Avoids duplicate index creation
- Handles unique constraints properly

### 6. Tailwind CSS Issues

#### Problem: `Specified input file ./app/assets/tailwind/application.css does not exist`
```
Specified input file ./app/assets/tailwind/application.css does not exist
```

**Root Cause**: Tailwind build command expected an input file that wasn't created.

**Solution**: ✅ **FIXED** - Template now:
- Creates required input file automatically
- Sets up proper Tailwind directory structure
- Ensures build process works correctly

## 🔍 Debugging Steps

### 1. Check Server Logs
Look at your Rails server output for specific error messages:
```bash
# Start server and watch logs
bin/dev
```

### 2. Test Sample Application
Use the included sample app to verify functionality:
```bash
# Test the sample app
./scripts/test-sample-app.sh

# Navigate to sample app
cd sample-app
bin/dev
```

### 3. Debug Template
Use debug mode for detailed output:
```bash
# Debug with detailed output
./scripts/debug-template.sh rails-modern detailed
```

### 4. Check Routes
Verify your routes are correct:
```bash
# In your Rails app directory
rails routes | grep -E "(session|sign_up)"
```

### 5. Database Status
Check your database state:
```bash
# Check if database exists
rails db:version

# Check migrations
rails db:migrate:status
```

## 🛠️ Manual Fixes

### Fix Authentication Concern
If you have the old authentication concern:

```ruby
# app/controllers/concerns/authentication.rb
module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end

    def require_admin_access(**options)
      before_action :require_admin, **options
    end

    # MOVE THIS METHOD HERE
    def unauthenticated_access_only(**options)
      allow_unauthenticated_access(**options)
      before_action -> { redirect_to root_path if authenticated? }, **options
    end
  end

  # ... rest of the concern
end
```

### Fix Navigation Links
Update your view files:

```erb
<!-- app/views/layouts/application.html.erb -->
<%= link_to "Sign up", new_sign_up_path, class: "..." %>

<!-- app/views/home/index.html.erb -->
<%= link_to "Get started", new_sign_up_path, class: "..." %>
```

### Fix Routes
Update your routes file:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  root "home#index"

  resource :session, only: [:new, :create, :destroy]
  resource :sign_up, only: [:new, :create]
end
```

## 🚀 Prevention

### Use Latest Template
Always use the latest version of the template script:
```bash
# Make sure you have the latest version
git pull origin main
```

### Test Before Use
Test the template before using it:
```bash
# Test the template
./scripts/test-template.sh rails-modern
```

### Clean Environment
Start with a clean environment:
```bash
# Remove any existing test directories
rm -rf ../test-app
```

## 📞 Getting Help

### 1. Check Documentation
- [README.md](README.md) - Complete overview
- [QUICK_START.md](QUICK_START.md) - Quick start guide
- [CONTRIBUTING.md](CONTRIBUTING.md) - Development guide

### 2. Use Debug Tools
```bash
# Debug template with detailed output
./scripts/debug-template.sh rails-modern detailed

# Test sample application
./scripts/test-sample-app.sh
```

### 3. Check System Requirements
Ensure you have the required dependencies:
- Ruby 3.1+
- Rails 8.0+
- PostgreSQL 14+
- Node.js 18+

### 4. Report Issues
When reporting issues, include:
- Template name and version
- Steps to reproduce
- Error messages and logs
- System information (OS, Ruby version, etc.)

## ✅ Verification Checklist

After creating an app, verify these work:

- [ ] **Home page loads**: http://localhost:3000
- [ ] **Sign up form**: http://localhost:3000/sign_up/new
- [ ] **Sign in form**: http://localhost:3000/session/new
- [ ] **User registration**: Can create new accounts
- [ ] **User login**: Can sign in with credentials
- [ ] **User logout**: Can sign out successfully
- [ ] **Navigation**: All links work correctly
- [ ] **Database**: Migrations run successfully
- [ ] **Tailwind**: CSS styling loads correctly

## 🎯 Success Indicators

Your app is working correctly when:
- ✅ No authentication errors in server logs
- ✅ All navigation links work
- ✅ Users can register and login
- ✅ Database migrations complete successfully
- ✅ Tailwind CSS styling appears correctly
- ✅ No routing errors in server logs

---

**Need more help?** Check the [README.md](README.md) or create an issue on GitHub.
