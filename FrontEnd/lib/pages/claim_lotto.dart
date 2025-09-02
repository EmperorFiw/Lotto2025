import 'package:flutter/material.dart';

class ClaimLottoPage extends StatefulWidget {
  const ClaimLottoPage({super.key});

  @override
  _ClaimLottoPageState createState() => _ClaimLottoPageState();
}

class _ClaimLottoPageState extends State<ClaimLottoPage> {
  final TextEditingController _numberController = TextEditingController();
  int _currentIndex = 0; // สำหรับ nav footer

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text("LOTTO 2025"),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ClipOval(
            child: SizedBox(
              width: 40,
              height: 40,
              child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
            ),
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ขึ้นเงินรางวัล',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),

              // ฟอร์มกรอกเลขอย่างเดียว
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _numberController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "หมายเลขลอตเตอรี่ของคุณ",
                        hintText: "กรอกเลข 6 หลัก",
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: เช็กผลรางวัล
                          print("เลขที่กรอก: ${_numberController.text}");
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'ขึ้นรางวัล',
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
            ],
          ),
        ),
      ),
     
    );
  }

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }
}
