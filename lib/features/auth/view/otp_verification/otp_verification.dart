import 'dart:async';
import 'package:expense_tracker/core/constants/color_constants.dart';
import 'package:expense_tracker/features/dashboard/view/bottom_nav_bar/bottom_nav_bar_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class OtpVerification extends StatefulWidget {
  final String contact; // email or phone number

  const OtpVerification({super.key, required this.contact});

  @override
  State<OtpVerification> createState() => _OtpVerificationState();
}

class _OtpVerificationState extends State<OtpVerification> {
  final TextEditingController otp = TextEditingController();
  Timer? _timer;
  int _secondsRemaining = 30;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _secondsRemaining = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return; // ✅ FIX ADDED

      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  void _resendOtp() {
    // TODO: call your resend OTP API here
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("OTP Resent Successfully")));
    _startTimer();
  }

  @override
  void dispose() {
    otp.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _verifyOtp() {
    if (otp.text.length != 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter valid 6-digit OTP")));
      return;
    }

    // TODO: Verify OTP with Backend/Firebase
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const BottomNavBarScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Verify Your Account",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  color: ColorConstants.navy,
                ),
              ),
              Text(
                "Enter the 6-digit code sent to ${widget.contact}",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: ColorConstants.grey,
                ),
              ),
              const SizedBox(height: 30),

              PinCodeTextField(
                appContext: context,
                controller: otp,
                length: 6,
                keyboardType: TextInputType.number,
                animationType: AnimationType.scale,
                cursorColor: ColorConstants.black,
                textStyle: const TextStyle(
                  // Already a constant
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(10),
                  fieldHeight: 55,
                  fieldWidth: 50,
                  activeColor: ColorConstants.navy,
                  inactiveColor: ColorConstants.grey, // Already a constant
                  selectedColor: ColorConstants.navy,
                ),
                onChanged: (value) {},
              ),

              const SizedBox(height: 15),

              Center(
                child: GestureDetector(
                  onTap: _secondsRemaining == 0 ? _resendOtp : null,
                  child: Text(
                    _secondsRemaining > 0
                        ? "Resend OTP in 00:${_secondsRemaining.toString().padLeft(2, '0')}"
                        : "Resend OTP",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _secondsRemaining == 0
                          ? ColorConstants.navy
                          : ColorConstants.grey,
                    ),
                  ),
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstants.navy,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: _verifyOtp,
            child: Text(
              "Verify",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: ColorConstants.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
