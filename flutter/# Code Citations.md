# Code Citations

## License: unknown
https://github.com/garumugamtvm/01_silent_moon/blob/8705e1bdcd124ede307f3b54c2c202f4c502e2c0/lib/screens/welcome.dart

```
I'll help you implement these fixes. Let me start with the Welcome Screen:

````dart
// filepath: c:\Users\koira\Projects\plant_disease_app\lib\screens\welcome_screen.dart
import 'package:flutter/material.dart';
import 'home_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/welcome_bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column
```


## License: unknown
https://github.com/garumugamtvm/01_silent_moon/blob/8705e1bdcd124ede307f3b54c2c202f4c502e2c0/lib/screens/welcome.dart

```
I'll help you implement these fixes. Let me start with the Welcome Screen:

````dart
// filepath: c:\Users\koira\Projects\plant_disease_app\lib\screens\welcome_screen.dart
import 'package:flutter/material.dart';
import 'home_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/welcome_bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column
```


## License: unknown
https://github.com/garumugamtvm/01_silent_moon/blob/8705e1bdcd124ede307f3b54c2c202f4c502e2c0/lib/screens/welcome.dart

```
I'll help you implement these fixes. Let me start with the Welcome Screen:

````dart
// filepath: c:\Users\koira\Projects\plant_disease_app\lib\screens\welcome_screen.dart
import 'package:flutter/material.dart';
import 'home_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/welcome_bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column
```


## License: unknown
https://github.com/fikkoooooo/project_akhir/blob/51a6b132f6f652d62c3fbfd7fd14257f43ac89eb/lib/konversi/kamera.dart

```
I'll help you implement these fixes. Let me start with the Welcome Screen:

````dart
// filepath: c:\Users\koira\Projects\plant_disease_app\lib\screens\welcome_screen.dart
import 'package:flutter/material.dart';
import 'home_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/welcome_bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushPageRoute(
                        page: const HomeScreen(),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.eco,
                        size: 120,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    Text(
                      'PlantDoc',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'AI-powered plant disease detection',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on NavigatorState {
  void pushPageRoute({required Widget page}) {
    push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
      ),
    );
  }
}
````

Now update the Home Screen with the hero background:

````dart
// filepath: c:\Users\koira\Projects\plant_disease_app\lib\screens\home_screen.dart
// ...existing code...

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: SingleChildScrollView(
      child: Column(
        children: [
          // Hero Background Image
          Container(
            height: 280,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/home_hero.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.3),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome Back',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // ...rest of your home screen content...
        ],
      ),
    ),
    bottomNavigationBar: BottomNavBar(
      onNavigation: (index) {
        // Handle navigation
      },
    ),
  );
}

// ...existing code...
````

Create a new Profile Screen:

````dart
// filepath: c:\Users\koira\Projects\plant_disease_app\lib\screens\profile_screen.dart
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with background
            Container(
              height: 200,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/bg.jpg'),
                  fit: BoxFit.cover,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.green.withOpacity(0.3),
                    Colors.green.withOpacity(0.1),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.green[100],
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.green[700],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Farmer Profile',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _buildProfileOption(context, 'Edit Profile', Icons.edit),
                  const SizedBox(height: 12),
                  _buildProfileOption(context, 'Settings', Icons.settings),
                  const SizedBox(height: 12),
                  _buildProfileOption(context, 'Help & Support', Icons.help),
                  const SizedBox(height: 12),
                  _buildProfileOption(context, 'About', Icons.info),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // Handle logout
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[400],
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Logout'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption(BuildContext context, String title, IconData icon) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.green[700]),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
````

Update the Bottom Navigation:

````dart
// filepath: c:\Users\koira\Projects\plant_disease_app\lib\widgets\bottom_nav.dart
import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';

class BottomNavBar extends StatefulWidget {
  final Function(int) onNavigation;

  const BottomNavBar({
    Key? key,
    required this.onNavigation,
  }) : super(key: key);

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0;

  void _navigateToScreen(int index, BuildContext context) {
    setState(() {
      _selectedIndex = index;
    });

    Widget screen;
    switch (index) {
      case 0:
        screen = const HomeScreen();
        break;
      case 2:
        screen = const ProfileScreen();
        break;
      default:
        return;
    }

    Navigator.of(context).pushPageRoute(page: screen);
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) => _navigateToScreen(index, context),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.camera_alt),
          label: 'Camera',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}

extension on NavigatorState {
  void pushPageRoute({required Widget page}) {
    push(
      PageRouteBuilder(
        pageBuilder: (
```

