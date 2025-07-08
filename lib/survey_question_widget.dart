import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SurveyQuestionWidget extends StatelessWidget {
  final String question;
  final int selectedOption;
  final Function(int) onOptionSelected;
  final bool isLast;

  const SurveyQuestionWidget({
    super.key,
    required this.question,
    required this.selectedOption,
    required this.onOptionSelected,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final options = ['Never', 'Rarely', 'Sometimes', 'Often', 'Very Often'];
    final Color primaryColor = Colors.black;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: GoogleFonts.poppins(
              fontSize: 20,
              color: Colors.black,
              fontWeight: FontWeight.w600,

            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(options.length, (index) {
            final isSelected = selectedOption == index;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: GestureDetector(
                onTap: () {
                  onOptionSelected(index);
                  // Trigger the animation
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.linearToEaseOut,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.teal : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? Colors.black : Colors.grey[300]!,
                      width: isSelected ? 2.0 : 1.5,
                    ),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: isSelected
                        ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 40,
                        offset: const Offset(0, 4),
                      )
                    ]
                        : [],
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.grey[400]!,
                            width: isSelected ? 2.0 : 1.5,
                          ),
                        ),
                        child: isSelected
                            ? Center(
                          child: AnimatedScale(
                            scale: isSelected ? 1.0 : 0.5,
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              width: 12,
                              height: 20,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                            : null,
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                          child: Text(options[index]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}