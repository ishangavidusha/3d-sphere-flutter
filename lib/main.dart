import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "3D Sphere in 2D Canvas",
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
      ),
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({ Key? key }) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late Timer timer;
  List<Particle> particles = [];
  Offset? mousePosition;

  @override
  void initState() {
    timer = Timer.periodic(const Duration(milliseconds: 1000 ~/ 60), update);
    WidgetsBinding.instance?.addPostFrameCallback((timeStamp) => generate());
    super.initState();
  }

  void update(Timer _timer) {
    setState(() {});
  }

  void generate() async {
    particles.clear();
    particles.addAll(List<Particle>.generate(1000, (index) => Particle.generate()));
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NotificationListener(
        onNotification: (SizeChangedLayoutNotification notification) {
          WidgetsBinding.instance?.addPostFrameCallback((timeStamp) => generate());
          return true;
        },
        child: SizeChangedLayoutNotifier(
          child: Stack(
            children: [
              Positioned.fill(child: Container(color: const Color.fromARGB(255, 46, 46, 46))),
              Positioned.fill(
                child: MouseRegion(
                  onHover: (event) {
                    setState(() {
                      mousePosition = event.localPosition;
                    });
                  },
                  onExit: (event) {
                    setState(() {
                      mousePosition = null;
                    });
                  },
                  child: CustomPaint(
                    painter: MyPainter(particles: particles, mousePosition: mousePosition),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  } 
}

class MyPainter extends CustomPainter {
  List<Particle> particles;
  Offset? mousePosition;
  MyPainter({
    required this.particles,
    this.mousePosition,
  });
  @override
  void paint(Canvas canvas, Size size) {
    Offset center = Offset(size.width / 2, size.height / 2);
    double perspective = size.width * 0.8;
    double globeRadius = size.width * 0.45;
    Color dotColor = Colors.amber;
    Paint paint = Paint();
    paint.color = dotColor;
    paint.style = PaintingStyle.fill;

    for (var element in particles) {
      element.project(center, perspective, globeRadius);
    }

    particles.sort((a, b) => a.projectedScale > b.projectedScale ? 1 : -1);

    for (var element in particles) {
      element.project(center, perspective, globeRadius);
      paint.color = dotColor.withOpacity(1 - (element.z / size.width));
      
      canvas.drawCircle(
        Offset(element.projectedX, element.projectedY),
        element.radius * element.projectedScale,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class Particle {
  double x;
  double y;
  double z;
  double theta;
  double phi;
  double radius;
  double projectedX;
  double projectedY;
  double projectedScale;
  Particle({
    required this.x,
    required this.y,
    required this.z,
    required this.theta,
    required this.phi,
    required this.radius,
    required this.projectedX,
    required this.projectedY,
    required this.projectedScale,
  });

  factory Particle.generate() {
    return Particle(
      x: 0,
      y: 0,
      z: 0,
      theta: RandomNum.nextDouble(max: 1) * 2 * pi,
      phi: acos((RandomNum.nextDouble(max: 1) * 2) - 1),
      radius: 4,
      projectedX: 0,
      projectedY: 0,
      projectedScale: 0,
    );
  }

  void project(Offset center, double perspective, double globeRadius) {
    theta += 0.001;
    x = globeRadius * sin(phi) * cos(theta);
    y = globeRadius * cos(phi);
    z = globeRadius * sin(phi) * sin(theta) + globeRadius;
    projectedScale = perspective / (perspective + z);
    projectedX = (x * projectedScale) + center.dx;
    projectedY = (y * projectedScale) + center.dy;
  }
}

class RandomNum {
  static final Random _random = Random(DateTime.now().millisecondsSinceEpoch);

  static double nextDouble({double min = 0, required double max}) {
    return _random.nextDouble() * (max - min) + min;
  }

  static int nextInt({int min = 0, required int max}) {
    return min + _random.nextInt(max - min);
  }
}