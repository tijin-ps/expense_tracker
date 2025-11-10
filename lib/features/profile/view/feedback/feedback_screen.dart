import 'package:expense_tracker/core/constants/color_constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen>
    with SingleTickerProviderStateMixin {
  int rating = 0;
  TextEditingController feedbackController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final List<String> _emojiLabels = [
    "Terrible",
    "Bad",
    "Okay",
    "Good",
    "Excellent",
  ];

  final List<Color> _starColors = [
    ColorConstants.red400,
    ColorConstants.orange, // Already a constant
    ColorConstants.amber400,
    ColorConstants.lightGreen400, // Already a constant
    ColorConstants.green,
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.blues50,
      appBar: AppBar(
        backgroundColor: ColorConstants.navy,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: ColorConstants.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Feedback",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: ColorConstants.white,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // Content
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    decoration: BoxDecoration(
                      color: ColorConstants.white,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        children: [
                          // Header Section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: ColorConstants.navy,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.sentiment_satisfied_alt_rounded,
                                  size: 48,
                                  color: ColorConstants.white,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "How are you feeling?",
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                    color: ColorConstants.white,
                                  ), // Already a constant
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Your input helps us understand your needs and tailor our service accordingly.",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 13, // Already a constant
                                    color: ColorConstants.white.withOpacity(
                                      0.8,
                                    ),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Rating Label
                          if (rating > 0)
                            TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 300),
                              tween: Tween(begin: 0.0, end: 1.0),
                              builder: (context, value, child) {
                                return Opacity(
                                  opacity: value,
                                  child: Transform.scale(
                                    scale: value,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            _starColors[rating - 1],
                                            _starColors[rating - 1].withOpacity(
                                              0.7,
                                            ),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        _emojiLabels[rating - 1],
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: ColorConstants.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                          if (rating > 0) const SizedBox(height: 20),

                          // Star Rating Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              bool isSelected = index < rating;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    rating = index + 1;
                                  });
                                  // Haptic feedback simulation
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 1,
                                  ),
                                  child: TweenAnimationBuilder<double>(
                                    duration: const Duration(milliseconds: 200),
                                    tween: Tween(
                                      begin: 1.0,
                                      end: isSelected ? 1.2 : 1.0,
                                    ),
                                    builder: (context, scale, child) {
                                      return Transform.scale(
                                        scale: scale,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),

                                          child: Icon(
                                            isSelected
                                                ? Icons.star_rounded
                                                : Icons.star_outline_rounded,
                                            size: 30,
                                            color: isSelected
                                                ? _starColors[index]
                                                : ColorConstants.grey
                                                      .withOpacity(0.4),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            }),
                          ),

                          const SizedBox(height: 20),

                          // Feedback TextField
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: ColorConstants.blues50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.edit_note_rounded,
                                      size: 20,
                                      color: ColorConstants
                                          .navy, // Already a constant
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    "Tell us more",
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: ColorConstants.navy,
                                    ), // Already a constant
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: ColorConstants.grey.withOpacity(0.2),
                                    width: 1.5,
                                  ),
                                ),
                                child: TextField(
                                  controller: feedbackController,
                                  maxLines: 6,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    height: 1.6,
                                  ),
                                  decoration: InputDecoration(
                                    hintText:
                                        "Share your thoughts, suggestions, or concerns...",
                                    hintStyle: GoogleFonts.inter(fontSize: 14),
                                    filled: true,
                                    fillColor: ColorConstants.blues50
                                        .withOpacity(0.3),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.all(16),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Submit Button
                          _buildSubmitButton(),

                          const SizedBox(height: 16),

                          // Info text
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.lock_outline,
                                size: 14,
                                color: ColorConstants.grey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Your feedback is anonymous and secure",
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: ColorConstants.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [ColorConstants.navy, ColorConstants.blue],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.navy.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (rating == 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        Icons.star_outline, // Already a constant
                        color: ColorConstants.white,
                      ), // Already a constant
                      const SizedBox(width: 12),
                      Text(
                        "Please select a rating first",
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  backgroundColor: ColorConstants.orange,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.all(16),
                ),
              );
              return;
            }

            // Show success dialog
            _showSuccessDialog();
          },
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Text(
              "Submit Feedback",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: ColorConstants.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ), // Already a constant
          contentPadding: const EdgeInsets.all(32),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [ColorConstants.green, ColorConstants.green],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 48,
                  color: ColorConstants.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Thank You!",
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: ColorConstants.navy,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Your feedback has been received. We appreciate you taking the time to help us improve!",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: ColorConstants.grey,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Go back to previous screen
                  }, // Already a constant
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.navy,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "Done",
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: ColorConstants.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
