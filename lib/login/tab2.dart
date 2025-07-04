import 'package:flutter/material.dart';

// 검색 탭 화면
class SearchTab extends StatelessWidget {
  const SearchTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80, color: Colors.green),
          SizedBox(height: 20),
          Text(
            '검색 화면',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Text('여기서 검색 기능을 구현할 수 있어요!'),
        ],
      ),
    );
  }
}