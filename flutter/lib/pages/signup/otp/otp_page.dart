import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vynx/pages/signup/otp/otp_ctrl.dart';

class OtpPage extends StatelessWidget {
  const OtpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OtpCtrl());
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1A0B2E), const Color(0xFF09040F)]
                : [const Color(0xFFF3E5F5), Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  const SizedBox(height: 50),
                  _buildIconHeader(),
                  const SizedBox(height: 30),
                  _buildTextHeader(controller, isDark),
                  const SizedBox(height: 40),
                  _buildOtpInput(
                    controller,
                    isDark,
                  ), // Logic inside this helper
                  const SizedBox(height: 30),
                  _buildTimerSection(controller, isDark),
                  const SizedBox(height: 100),
                  _buildVerifyButton(controller),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.vibration, size: 50, color: Colors.purple),
    );
  }

  Widget _buildTextHeader(OtpCtrl controller, bool isDark) {
    return Column(
      children: [
        Text(
          "Verify Phone",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "We sent a code to\n${controller.setupCtrl.completePhoneNumber.value}",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black54,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildOtpInput(OtpCtrl controller, bool isDark) {
    return Column(
      children: [
        TextField(
          controller: controller.otpController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          onChanged: (val) {
            if (controller.otpError.value.isNotEmpty) {
              controller.otpError.value = "";
            }
          },
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 15,
            color: isDark ? Colors.white : Colors.black,
          ),
          decoration: InputDecoration(
            counterText: "",
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            hintText: "000000",
            hintStyle: TextStyle(
              color: Colors.grey.withValues(alpha: 0.5),
              letterSpacing: 15,
            ),
          ),
        ),
        Obx(
          () => controller.otpError.value.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: Text(
                    controller.otpError.value,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildTimerSection(OtpCtrl controller, bool isDark) {
    return Obx(
      () => Column(
        children: [
          if (!controller.canResend.value)
            Text(
              "Resend code in ${controller.timerCount.value}s",
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
            )
          else
            TextButton(
              onPressed: controller.resendOtp,
              child: const Text(
                "Resend SMS",
                style: TextStyle(
                  color: Colors.purple,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVerifyButton(OtpCtrl controller) {
    return Obx(() {
      bool isLoading = controller.setupCtrl.isLoading.value;
      return SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          onPressed: isLoading ? null : () => controller.verifyAndRegister(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 0,
          ),
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  "Verify & Finish",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      );
    });
  }
}
