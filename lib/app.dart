import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/report_provider.dart';
import 'screens/auth_gate.dart';

class SafeRouteApp extends StatelessWidget {
	const SafeRouteApp({super.key});

	@override
	Widget build(BuildContext context) {
		return MultiProvider(
			providers: [
				ChangeNotifierProvider(create: (_) => ReportProvider()),
			],
			child: const MaterialApp(
				debugShowCheckedModeBanner: false,
				home: AuthGate(),
			),
		);
	}
}
