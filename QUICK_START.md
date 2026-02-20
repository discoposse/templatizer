# Quick Start Guide

Get your modern Rails app up and running in minutes!

## 🚀 One-Command Setup

From the **templatizer** repo, run the template from the `templates/rails-modern` directory (or ensure you're in the right place so the script can find the template files):

```bash
# Make executable and run (PostgreSQL by default)
chmod +x templates/rails-modern/create_rails_app.sh
./templates/rails-modern/create_rails_app.sh MyApp

# Or use SQLite
./templates/rails-modern/create_rails_app.sh MyApp sqlite

# Navigate to your new app (created in parent directory)
cd ../myapp

# Start the development server
bin/dev
```

## ✅ Verified Working Features

All features have been tested and are working correctly:

- ✅ **Authentication**: Sign up, sign in, sign out
- ✅ **Navigation**: All links work correctly
- ✅ **Database**: Smart conflict detection and migration handling
- ✅ **UI**: Modern Tailwind CSS with responsive design
- ✅ **Routing**: Proper route configuration

## 📋 What You Get

✅ **Complete Authentication System**
- User registration and login
- Secure password handling
- Session management
- Admin role support

✅ **Modern UI with Tailwind CSS**
- Responsive design
- Beautiful components
- Mobile-first approach
- Professional styling

✅ **Hotwire Integration**
- Turbo for fast navigation
- Stimulus for interactivity
- No build step required
- Progressive enhancement

✅ **Database (PostgreSQL or SQLite)**
- PostgreSQL by default; use second argument `sqlite` for SQLite
- Secure data storage, migrations, and indexes
- Production ready

## 🎯 Next Steps

1. **Start Development**
   ```bash
   cd ../myapp
   bin/dev
   ```

2. **Visit Your App**
   Open http://localhost:3000

3. **Customize**
   - Update branding in views
   - Modify colors in Tailwind config
   - Add your features

## 📚 Documentation

- **[README.md](README.md)** - Complete overview
- **[SETUP.md](SETUP.md)** - Detailed setup guide
- **[FEATURES.md](FEATURES.md)** - Feature documentation
- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Optional Kamal deployment

## 🛠️ Requirements

- Ruby 3.1+
- Rails 8.0+
- PostgreSQL (default) or SQLite
- Node.js 18+

## 🆘 Need Help?

Check the [SETUP.md](SETUP.md) guide for troubleshooting and detailed instructions.

---

**Ready to build something amazing?** 🚀
