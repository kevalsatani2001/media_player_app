import 'package:flutter/material.dart';

class PlaybackSpeedDialog extends StatelessWidget {
  final List<double> speeds;
  final double selectedSpeed;

  const PlaybackSpeedDialog({
    super.key,
    required this.speeds,
    required this.selectedSpeed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // બોટમ શીટની આજુબાજુ થોડું પેડિંગ જેથી તે ચોંટેલી ન લાગે
      padding: const EdgeInsets.only(top: 12, bottom: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ટોચની ગ્રે લાઇન (Drag Handle)
          Container(
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 15),

          const Text(
            "Playback Speed",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 12),
          const Divider(color: Colors.grey, thickness: 0.5),

          // સ્પીડ ઓપ્શન્સ લિસ્ટ
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              physics: const BouncingScrollPhysics(),
              itemCount: speeds.length,
              itemBuilder: (context, index) {
                final speed = speeds[index];
                final bool isSelected = speed == selectedSpeed;

                return InkWell(
                  onTap: () => Navigator.pop(context, speed),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      // સિલેક્ટેડ આઈટમ માટે હળવો બેકગ્રાઉન્ડ કલર
                      color: isSelected ? const Color(0XFF3D57F9).withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.speed_rounded,
                          size: 22,
                          color: isSelected ? const Color(0XFF3D57F9) : Colors.black54,
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            speed == 1.0 ? "Normal" : "${speed}x",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected ? const Color(0XFF3D57F9) : Colors.black,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0XFF3D57F9),
                            size: 22,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}