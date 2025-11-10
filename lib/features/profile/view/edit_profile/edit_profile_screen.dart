import 'dart:io';
import 'package:expense_tracker/core/constants/color_constants.dart';
import 'package:expense_tracker/core/database/db_helper.dart';
import 'package:expense_tracker/features/profile/view/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  File? _profileImage;
  final dbHelper = DBHelper();

  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController dobController = TextEditingController();

  String? selectedGender;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    dobController.dispose();
    super.dispose();
  }

  Future pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  void _loadProfile() async {
    final stored = await dbHelper.getProfile();
    if (stored != null) {
      setState(() {
        firstNameController.text = stored['first_name'] as String;
        lastNameController.text = stored['last_name'] as String;
        dobController.text = stored['dob'] as String;
        selectedGender = stored['gender'] as String?;
        if (stored['image_path'] != null) {
          _profileImage = File(stored['image_path'] as String);
        }
      });
    }
  }

  Future selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: ColorConstants.navy, // Already a constant
              onPrimary: ColorConstants.white,
              surface: ColorConstants.white,
              onSurface: ColorConstants.navy,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        dobController.text =
            "${pickedDate.day.toString().padLeft(2, '0')}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.year}";
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      await dbHelper.saveProfile(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        dob: dobController.text.trim(),
        gender: selectedGender ?? "",
        imagePath: _profileImage?.path,
      );

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                "Profile Updated Successfully!",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          backgroundColor: ColorConstants.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ColorConstants.navy,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: ColorConstants.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Edit Profile",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: ColorConstants.white,
          ),
        ),
      ),
      backgroundColor: ColorConstants.blues50,
      body: CustomScrollView(
        slivers: [
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // Profile Image with Gradient Border
                  _buildProfileImagePicker(),

                  const SizedBox(height: 30),

                  // Form Container
                  Container(
                    decoration: BoxDecoration(
                      color: ColorConstants.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Personal Information",
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: ColorConstants.navy,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // First Name
                          _buildTextField(
                            controller: firstNameController,
                            label: "First Name",
                            icon: Icons.person_outline,
                            validator: (value) =>
                                value!.isEmpty ? "Enter first name" : null,
                            hint: "Enter your first name",
                          ),
                          const SizedBox(height: 16),

                          // Last Name
                          _buildTextField(
                            controller: lastNameController,
                            label: "Last Name",
                            icon: Icons.person_outline,
                            validator: (value) =>
                                value!.isEmpty ? "Enter last name" : null,
                            hint: "Enter your last name",
                          ),
                          const SizedBox(height: 16),

                          // DOB
                          _buildTextField(
                            controller: dobController,
                            label: "Date of Birth",
                            icon: Icons.cake_outlined,
                            validator: (value) =>
                                value!.isEmpty ? "Enter DOB" : null,
                            hint: "Select your birth date",
                            readOnly: true,
                            suffixIcon: Icons.calendar_month_outlined,
                            onTap: () => selectDate(context),
                          ),
                          const SizedBox(height: 16),

                          // Gender Dropdown
                          _buildGenderDropdown(),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Submit Button with Gradient
                  _buildGradientButton(
                    text: "Save Changes",
                    gradientColors: [ColorConstants.navy, ColorConstants.blue],
                    onPressed: _saveProfile,
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImagePicker() {
    return Center(
      child: Stack(
        children: [
          // Outer gradient ring
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ColorConstants.navy,
            ),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ColorConstants.white,
              ),
              child: CircleAvatar(
                radius: 40,
                backgroundColor: ColorConstants.blues50,
                backgroundImage:
                    _profileImage !=
                        null // Already a constant
                    ? FileImage(_profileImage!)
                    : null,
                child: _profileImage == null
                    ? Icon(
                        Icons.person,
                        size: 40,
                        color: ColorConstants.navy.withOpacity(0.5),
                      )
                    : null,
              ),
            ),
          ),

          // Camera button
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 40,
                width: 40,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ColorConstants.blue,
                      ColorConstants.blue,
                    ], // Already a constant
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: ColorConstants.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: ColorConstants.blue.withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  color: ColorConstants.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    bool readOnly = false,
    IconData? suffixIcon,
    String? Function(String?)? validator,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: ColorConstants.navy,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: ColorConstants.grey,
              fontSize: 14,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ColorConstants.blues50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: ColorConstants.navy, size: 20),
            ),
            suffixIcon: suffixIcon != null
                ? Icon(suffixIcon, color: ColorConstants.navy)
                : null,
            filled: true,
            fillColor: ColorConstants.blues50.withOpacity(0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: ColorConstants.grey.withOpacity(0.2),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: ColorConstants.navy, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Gender",
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600, // Already a constant
            color: ColorConstants.navy,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedGender,
          hint: Text(
            "Select your gender",
            style: GoogleFonts.inter(
              color: ColorConstants.grey,
              fontSize: 14,
            ), // Already a constant
          ),
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: ColorConstants.navy,
          ),
          decoration: InputDecoration(
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ColorConstants.blues50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.wc_outlined,
                color: ColorConstants.navy,
                size: 20,
              ),
            ),
            filled: true,
            fillColor: ColorConstants.blues50.withOpacity(0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: ColorConstants.grey.withOpacity(0.2),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: ColorConstants.navy, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          items: ["Male", "Female", "Other"].map((gender) {
            return DropdownMenuItem(value: gender, child: Text(gender));
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedGender = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildGradientButton({
    required String text,
    required List<Color> gradientColors,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            color: ColorConstants.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
