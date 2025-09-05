import 'dart:math';

import 'package:flutter/material.dart';

class RandomLottoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: RandomLottoPC(),
    );
  }
}

class RandomLottoPC extends StatefulWidget {
  @override
  _RandomLottoPageState createState() => _RandomLottoPageState();
}

class _RandomLottoPageState extends State<RandomLottoPC> {
  List<String> currentNumbers = ['9', '9', '9', '9', '9', '9'];
  final Random _random = Random();

  void generateRandomNumbers() {
    setState(() {
      currentNumbers = List.generate(
        6,
        (index) => _random.nextInt(10).toString(),
      );
    });
  }

  void resetNumbers() {
    setState(() {
      currentNumbers = ['9', '9', '9', '9', '9', '9'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Random Number Generator Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ลอตโต้ประจำวันที่ 1 สิงหาคม 2568',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        GestureDetector(
                          onTap: resetNumbers,
                          child: Text(
                            'รีเซ็ทระบบ',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),

                    Text(
                      'กดปุ่มเพื่อสุ่มตัวเลขการออกรางวัล',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 20),

                    // Number Display
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: currentNumbers.map((number) {
                        return Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              number,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 24),

                    // Random Button (อยู่ตรงกลาง)
                    Center(
                      child: ElevatedButton(
                        onPressed: generateRandomNumbers,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFDC3545),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          'สุ่มออกรางวัล',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Prize List Section
              Column(
                children: [
                  _buildPrizeCard(
                    'รางวัลที่ 1',
                    'รางวัลละ 6,000,000 บาท',
                    '999999',
                  ),
                  SizedBox(height: 12),
                  _buildPrizeCard(
                    'รางวัลที่ 2',
                    'รางวัลละ 200,000 บาท',
                    '999999',
                  ),
                  SizedBox(height: 12),
                  _buildPrizeCard(
                    'รางวัลที่ 3',
                    'รางวัลละ 80,000 บาท',
                    '999999',
                  ),
                  SizedBox(height: 12),
                  _buildPrizeCard(
                    'รางวัลที่ 4',
                    'รางวัลละ 40,000 บาท',
                    '999999',
                  ),
                  SizedBox(height: 12),
                  _buildPrizeCard(
                    'รางวัลที่ 5',
                    'รางวัลละ 20,000 บาท',
                    '999999',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),

    );
  }

  Widget _buildPrizeCard(String prizeTitle, String prizeAmount, String number) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Prize Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Color(0xFFDC3545),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  prizeTitle,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  prizeAmount,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Prize Number
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
