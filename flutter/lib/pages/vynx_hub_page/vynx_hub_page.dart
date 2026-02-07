import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vynx/pages/vynx_hub_page/vynx_hub_contoller.dart';

class VynxHubPage extends StatelessWidget {
  const VynxHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VynxHubController());
    return Scaffold(
      body: Obx(
        () => IndexedStack(
          index: controller.currentIndex.value,
          children: const [
            // ChatListPage(),
            // StatusPage(),
            // CallsPage(),
            // SettingsPage(),
          ],
        ),
      ),
      bottomNavigationBar: Obx(
        () => BottomNavigationBar(
          currentIndex: controller.currentIndex.value,
          onTap: (index) => controller.currentIndex.value = index,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
            BottomNavigationBarItem(
              icon: Icon(Icons.circle_outlined),
              label: 'Status',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.call), label: 'Calls'),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
