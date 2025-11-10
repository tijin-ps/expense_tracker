import 'package:expense_tracker/core/constants/color_constants.dart';
import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.labelText,
    this.validator,
    this.obscureText = false,
    this.readOnly = false, // ✅ Added
    this.onTap, // ✅ Added
  });

  final TextEditingController controller;
  final String hintText;
  final String labelText;
  final String? Function(String?)? validator;
  final bool obscureText;
  final bool readOnly; // ✅ Added
  final VoidCallback? onTap; // ✅ Added

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      readOnly: readOnly, // ✅ Support read-only mode
      onTap: onTap, // ✅ Trigger date picker
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ColorConstants.navy),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ColorConstants.navy, width: 2),
        ),
      ),
      style: TextStyle(
        fontSize: 16,
        color: ColorConstants.black,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
