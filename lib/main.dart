import 'package:flutter/material.dart';

import 'login/loginPage.dart';
import 'board/tab1.dart';
import 'gallery/tab2.dart';
import 'mypage/tab3.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Flow',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        scaffoldBackgroundColor: Colors.white,
        textTheme: Typography.blackMountainView,
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 45,  // AppBar 높이 조절 (기본값: 56)
        title: const Text('MeveryTime'),
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.tab,  // 인디케이터 크기
          labelPadding: EdgeInsets.symmetric(vertical: 3),  // 탭 패딩
          tabs: const [
            Tab(
              icon: Icon(Icons.home, size: 24),  // 아이콘 크기
              text: '홈',
              height: 60,  // 탭 높이
            ),
            Tab(
              icon: Icon(Icons.photo_library, size: 24),
              text: '갤러리',
              height: 60,
            ),
            Tab(
              icon: Icon(Icons.person, size: 24),
              text: '프로필', 
              height: 60,
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [HomeTab(), GalleryTab(), ProfileTab()],
      ),
    );
  }
}
