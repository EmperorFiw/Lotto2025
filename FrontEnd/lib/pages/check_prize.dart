import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CheckPrize extends StatefulWidget {
  const CheckPrize({super.key});

  @override
  State<CheckPrize> createState() => _CheckPrizeState();
}

class _CheckPrizeState extends State<CheckPrize> {
  final FocusNode firstFieldFocus = FocusNode();
  final List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());

  // เก็บค่าหมายเลข 6 หลัก
  List<String> currentNumbers = List.filled(6, '-');
  // ตัวควบคุม TextField
  final List<TextEditingController> controller = List.generate(
    6,
    (_) => TextEditingController(),
  );

  // ฟังก์ชันตรวจรางวัล
  void checkPrizeLotto() {
    final inputNumber = controller[0].text;

    if (inputNumber.length < 6 || inputNumber.isEmpty) {
      // ถ้าไม่ครบ 6 หลัก
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 5,
          backgroundColor: const Color.fromARGB(255, 241, 185, 185),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning,
                  size: 48,
                  color: const Color.fromARGB(255, 255, 234, 5),
                ),
                const SizedBox(height: 16),
                Text(
                  'ตัวเลขสลากไม่ครบ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                Text(
                  'กรุณากรอกเลขสลากให้ครบ 6 ตัวเลข',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),

                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'ยืนยัน',
                    style: TextStyle(
                      color: Color.fromARGB(255, 255, 255, 255),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }

    //ไม่ถูกรางวัล
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 5,
        backgroundColor: const Color.fromARGB(255, 241, 185, 185),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ผลการตรวจสลากหมายเลข',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                '$inputNumber',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  color: Color.fromARGB(255, 255, 4, 4),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'คุณไม่ถูกรางวัล',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),

                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'ยืนยัน',
                  style: TextStyle(
                    color: Color.fromARGB(255, 255, 255, 255),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // ถ้าตรวจถูกรางวัล (ตัวอย่างนี้สมมติถูกรางวัล)
    // showDialog(
    //   context: context,
    //   builder: (context) => Dialog(
    //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    //     elevation: 5,
    //     backgroundColor: Colors.white,
    //     child: Padding(
    //       padding: const EdgeInsets.all(20),
    //       child: Column(
    //         mainAxisSize: MainAxisSize.min,
    //         children: [
    //           Icon(
    //             Icons.check_box,
    //             size: 48,
    //             color: const Color.fromARGB(255, 44, 229, 8),
    //           ),
    //           const SizedBox(height: 16),
    //           Text(
    //             'ยินดีด้วยคุณถูกรางวัล',
    //             style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    //           ),
    //           const SizedBox(height: 8),
    //           Text(
    //             'หมายเลขที่คุณกรอก: $inputNumber',
    //             textAlign: TextAlign.center,
    //           ),
    //           const SizedBox(height: 16),
    //           ElevatedButton(
    //             onPressed: () => Navigator.pop(context),
    //             style: ElevatedButton.styleFrom(
    //               backgroundColor: const Color.fromARGB(255, 16, 163, 35),
    //               shape: RoundedRectangleBorder(
    //                 borderRadius: BorderRadius.circular(12),
    //               ),
    //             ),
    //             child: Text(
    //               'ขึ้นเงินรางวัล',
    //               style: TextStyle(
    //                 color: Color.fromARGB(255, 255, 255, 255),
    //                 fontWeight: FontWeight.bold,
    //               ),
    //             ),
    //           ),
    //         ],
    //       ),
    //     ),
    //   ),
    // );
  }

  @override
  void initState() {
    super.initState();
    controller[0].clear();
  }

  // ฟังก์ชันล้างค่า
  void resetNumbers() {
    controller[0].clear();
  }

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
        //actions: [IconButton(icon: const Icon(Icons.menu), onPressed: () {})],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ข้อมูลล็อตโต้
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(255, 146, 143, 143),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
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
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            letterSpacing: 0,
                          ),
                        ),
                        GestureDetector(
                          onTap: resetNumbers,
                          child: Text(
                            'ล้างค่า',
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
                    SizedBox(height: 10),
                    Text(
                      'กรอกตัวเลขสลากที่ต้องการตรวจสอบ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                        letterSpacing: 0,
                      ),
                    ),
                    SizedBox(height: 20),

                    // ช่องกรอกหมายเลข 6 หลัก
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(248, 246, 171, 171),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SizedBox(
                          width: 240,
                          child: TextField(
                            controller: controller[0],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 6,
                            inputFormatters: [
                              FilteringTextInputFormatter
                                  .digitsOnly, // ใส่ได้แต่ตัวเลข
                            ],
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              letterSpacing: 8,
                            ),
                            decoration: const InputDecoration(
                              counterText: "",
                              hintText: 'กรอกเลขสลาก',
                              hintStyle: TextStyle(
                                color: Color.fromARGB(255, 241, 223, 223),
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 24),

                    // check Button (อยู่ตรงกลาง)
                    Center(
                      child: ElevatedButton(
                        onPressed: checkPrizeLotto,
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
                          'ตรวจรางวัล',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // รายการรางวัล
              Column(
                children: [
                  _buildPrizeCard(
                    'รางวัลที่ 1',
                    'รางวัลละ 6,000,000 บาท',
                    '999999',
                  ),
                  const SizedBox(height: 12),
                  _buildPrizeCard(
                    'รางวัลที่ 2',
                    'รางวัลละ 200,000 บาท',
                    '999999',
                  ),
                  const SizedBox(height: 12),
                  _buildPrizeCard(
                    'รางวัลที่ 3',
                    'รางวัลละ 80,000 บาท',
                    '999999',
                  ),
                  const SizedBox(height: 12),
                  _buildPrizeCard(
                    'รางวัลที่ 4',
                    'รางวัลละ 40,000 บาท',
                    '999999',
                  ),
                  const SizedBox(height: 12),
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

  // การ์ดรางวัลแต่ละประเภท
  Widget _buildPrizeCard(String prizeTitle, String prizeAmount, String number) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey,
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ส่วนหัว
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  prizeAmount,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // หมายเลขรางวัล
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
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
