import 'package:Lotto2025/model/user/user_state.dart';
import 'package:Lotto2025/pages/admin/random_lotto.dart';
import 'package:Lotto2025/pages/admin/reset.dart';
import 'package:Lotto2025/pages/login.dart';
import 'package:flutter/material.dart';

void main() {
	runApp(MyApp());
}

class MyApp extends StatelessWidget {
	@override
	Widget build(BuildContext context) {
		return MaterialApp(
			title: 'InwzaLotto',
			debugShowCheckedModeBanner: false,
			home: AdminDashboardPage(),
		);
	}
}

class AdminDashboardPage extends StatefulWidget {
	@override
	_AdminDashboardPageState createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
	int _currentIndex = 0;

	late final List<Widget> _pages;

	@override
	void initState() {
		super.initState();
		_pages = [
			RandomLottoPage(),
			ResetPage(),
		];
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
			),
			body: IndexedStack(
				index: _currentIndex,
				children: _pages,
			),
			bottomNavigationBar: Container(
				height: 70,
				color: const Color(0xFFDC3545),
				child: Row(
					mainAxisAlignment: MainAxisAlignment.spaceEvenly,
					children: [
						_buildNavItem(Icons.home, 'หน้าแรก', _currentIndex == 0, () {
							setState(() => _currentIndex = 0);
						}),
						_buildNavItem(Icons.refresh, 'จัดการระบบ', _currentIndex == 1, () {
							setState(() => _currentIndex = 1);
						}),
						_buildNavItem(Icons.logout_outlined, 'ออกจากระบบ', false, () async {
							final confirm = await showDialog<bool>(
								context: context,
								builder: (ctx) {
									return AlertDialog(
										title: const Text("ยืนยันการออกจากระบบ"),
										content: const Text("คุณต้องการออกจากระบบจริงหรือไม่?"),
										actions: [
											TextButton(
												onPressed: () => Navigator.pop(ctx, false),
												child: const Text("ยกเลิก"),
											),
											TextButton(
												onPressed: () => Navigator.pop(ctx, true),
												child: const Text(
													"ออกจากระบบ",
													style: TextStyle(color: Colors.red),
												),
											),
										],
									);
								},
							);

							if (confirm == true) {
								await UserState().logout();
								Navigator.pushReplacement(
									context,
									MaterialPageRoute(builder: (_) => const LoginPage()),
								);
							}
						}),
					],
				),
			),
		);
	}

	Widget _buildNavItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
		return GestureDetector(
			onTap: onTap,
			child: Column(
				mainAxisAlignment: MainAxisAlignment.center,
				children: [
					Icon(icon, color: isActive ? Colors.white : Colors.white70),
					const SizedBox(height: 4),
					Text(
						label,
						style: TextStyle(
							color: isActive ? Colors.white : Colors.white70,
							fontSize: 12,
						),
					),
				],
			),
		);
	}
}
