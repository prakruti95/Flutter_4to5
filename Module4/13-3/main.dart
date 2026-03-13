import 'package:flutter/material.dart';

void main()
{
  runApp(const TopsTechApp());
}

class TopsTechApp extends StatelessWidget {
  const TopsTechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TOPS Technologies',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.indigo,
        // Using a professional color scheme
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A237E)),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // Data list for technologies and their icons
  final List<Map<String, String>> technologies = const [
    {'name': 'HTML', 'icon': 'https://img.icons8.com/color/144/html-5--v1.png'},
    {'name': 'CSS', 'icon': 'https://img.icons8.com/color/144/css3.png'},
    {
      'name': 'JavaScript',
      'icon': 'https://img.icons8.com/color/144/javascript--v1.png'
    },
    {'name': 'React', 'icon': 'https://img.icons8.com/officel/144/react.png'},
    {
      'name': 'Angular',
      'icon': 'https://img.icons8.com/color/144/angularjs.png'
    },
    {'name': 'Node.js', 'icon': 'https://img.icons8.com/color/144/nodejs.png'},
    {'name': 'Java', 'icon': 'https://img.icons8.com/color/144/java-code.png'},
    {
      'name': 'Python',
      'icon': 'https://img.icons8.com/color/144/python--v1.png'
    },
    {'name': 'PHP', 'icon': 'https://img.icons8.com/officel/144/php-logo.png'},
    {
      'name': 'MySQL',
      'icon': 'https://img.icons8.com/color/144/mysql-logo.png'
    },
    {
      'name': 'Android',
      'icon': 'https://img.icons8.com/color/144/android-os.png'
    },
    {
      'name': 'Flutter',
      'icon': 'https://img.icons8.com/shortcut/144/flutter.png'
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Determine screen width for responsiveness
    double screenWidth = MediaQuery
        .of(context)
        .size
        .width;

    // Adjust grid columns based on width
    int crossAxisCount = screenWidth > 900 ? 4 : (screenWidth > 600 ? 3 : 2);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- 1. HEADER SECTION ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: const BoxDecoration(
                color: Color(0xFF1A237E), // Deep professional blue
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.school, color: Colors.white, size: 50),
                  const SizedBox(height: 10),
                  Text(
                    'TOPS Technologies',
                    style: TextStyle(
                      fontSize: screenWidth > 600 ? 36 : 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Text(
                    'Enhancing Your Skills',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),

            // --- 2. BODY SECTION ---
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Our Services',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 4,
                    width: 60,
                    color: Colors.orangeAccent,
                  ),
                  const SizedBox(height: 30),

                  // Responsive Grid of Technology Cards
                  GridView.builder(
                    shrinkWrap: true,
                    // Needed inside SingleChildScrollView
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 1.0, // Square cards
                    ),
                    itemCount: technologies.length,
                    itemBuilder: (context, index) {
                      return TechnologyCard(
                        name: technologies[index]['name']!,
                        iconUrl: technologies[index]['icon']!,
                      );
                    },
                  ),
                ],
              ),
            ),

            // --- 3. FOOTER SECTION ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: Colors.grey[200],
              child: const Column(
                children: [
                  Text(
                    '© 2026 TOPS Technologies',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'ISO Certified Training Institute',
                    style: TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom widget for the Technology Cards
class TechnologyCard extends StatelessWidget {
  final String name;
  final String iconUrl;

  const TechnologyCard({
    super.key,
    required this.name,
    required this.iconUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.white,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Technology Logo from URL
            Image.network(
              iconUrl,
              height: 60,
              width: 60,
              errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.code, size: 50, color: Colors.grey),
            ),
            const SizedBox(height: 15),
            // Technology Name
            Text(
              name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}